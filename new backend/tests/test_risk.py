from unittest.mock import AsyncMock

from app.services.risk_service import risk_service
from app.services import location_service as location_service_module
from app.services import weather_service as weather_service_module


class TestRiskLevelThresholds:
    """get_risk_level() drives every other risk calculation, so its
    boundaries (30/60/80) are worth pinning down explicitly."""

    def test_severe_at_and_above_80(self):
        assert risk_service.get_risk_level(80) == "SEVERE"
        assert risk_service.get_risk_level(95) == "SEVERE"

    def test_high_between_60_and_79(self):
        assert risk_service.get_risk_level(60) == "HIGH"
        assert risk_service.get_risk_level(79) == "HIGH"

    def test_moderate_between_30_and_59(self):
        assert risk_service.get_risk_level(30) == "MODERATE"
        assert risk_service.get_risk_level(59) == "MODERATE"

    def test_low_below_30(self):
        assert risk_service.get_risk_level(29) == "LOW"
        assert risk_service.get_risk_level(0) == "LOW"


class TestHeatRisk:

    def test_severe_at_45_and_above(self):
        result = risk_service.calculate_heat_risk(46)
        assert result["risk"] == "SEVERE"
        assert result["score"] == 90

    def test_high_between_40_and_44(self):
        result = risk_service.calculate_heat_risk(41)
        assert result["risk"] == "HIGH"

    def test_moderate_between_35_and_39(self):
        result = risk_service.calculate_heat_risk(36)
        assert result["risk"] == "MODERATE"

    def test_low_below_35(self):
        result = risk_service.calculate_heat_risk(25)
        assert result["risk"] == "LOW"

    def test_unknown_when_temperature_missing(self):
        result = risk_service.calculate_heat_risk(None)
        assert result["risk"] == "UNKNOWN"
        assert result["score"] == 0


class TestRainRisk:

    def test_severe_when_precipitation_50_or_more(self):
        result = risk_service.calculate_rain_risk(rain_probability=90, precipitation=60)
        assert result["risk"] == "SEVERE"

    def test_low_when_only_probability_high_but_precipitation_small(self):
        result = risk_service.calculate_rain_risk(rain_probability=80, precipitation=2)
        assert result["risk"] == "LOW"
        assert result["score"] == 20

    def test_defaults_to_low_when_values_missing(self):
        result = risk_service.calculate_rain_risk(rain_probability=None, precipitation=None)
        assert result["risk"] == "LOW"
        assert result["score"] == 10


class TestWindRisk:

    def test_severe_at_80_and_above(self):
        result = risk_service.calculate_wind_risk(85)
        assert result["risk"] == "SEVERE"

    def test_unknown_when_missing(self):
        result = risk_service.calculate_wind_risk(None)
        assert result["risk"] == "UNKNOWN"


class TestFloodRisk:

    def test_severe_when_precipitation_75_or_more(self):
        result = risk_service.calculate_flood_risk(rain_probability=90, precipitation=80)
        assert result["risk"] == "SEVERE"

    def test_low_when_precipitation_small(self):
        result = risk_service.calculate_flood_risk(rain_probability=10, precipitation=1)
        assert result["risk"] == "LOW"


class TestOverallRisk:

    def test_takes_the_highest_of_the_four_scores(self):
        overall = risk_service.calculate_overall_risk(
            heat_risk={"score": 10, "risk": "LOW"},
            rain_risk={"score": 70, "risk": "HIGH"},
            wind_risk={"score": 40, "risk": "MODERATE"},
            flood_risk={"score": 10, "risk": "LOW"},
        )
        assert overall["score"] == 70
        assert overall["risk"] == "HIGH"


class TestRiskEndpoint:
    """Integration tests for GET /api/v1/risk/ -- external APIs mocked out."""

    def test_get_weather_risk_success_for_severe_conditions(
        self,
        client,
        monkeypatch,
        mock_location_search_response,
        mock_current_weather,
        mock_forecast_2day_severe,
    ):
        """
        NOTE: unlike risk_service.analyze_location() (used by /alerts and
        chat), this router computes heat/wind risk from *current* weather
        and rain/flood risk from *tomorrow's forecast* -- see risk.py. So
        with the calm mock_current_weather fixture, heat/wind stay LOW even
        though the forecast fixture is severe; only rain/flood go SEVERE.
        """
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(return_value=mock_location_search_response),
        )
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_current_weather",
            AsyncMock(return_value=mock_current_weather),
        )
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_forecast",
            AsyncMock(return_value=mock_forecast_2day_severe),
        )

        response = client.get("/api/v1/risk/", params={"city": "Delhi"})

        assert response.status_code == 200
        body = response.json()
        assert body["location"]["city"] == "Delhi"
        assert body["overall_risk"]["risk"] == "SEVERE"
        assert body["risks"]["rain"]["risk"] == "SEVERE"
        assert body["risks"]["flood"]["risk"] == "SEVERE"
        assert body["risks"]["heat"]["risk"] == "LOW"  # driven by current, not forecast, weather

    def test_get_weather_risk_heat_and_wind_use_current_conditions(
        self,
        client,
        monkeypatch,
        mock_location_search_response,
        mock_forecast_2day_calm,
    ):
        """Confirms heat/wind risk tracks *current* weather_data, independent
        of the forecast used for rain/flood."""
        severe_current_weather = {
            "current": {
                "temperature_2m": 46.0,
                "relative_humidity_2m": 15,
                "wind_speed_10m": 85.0,
                "weather_code": 0,
            }
        }
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(return_value=mock_location_search_response),
        )
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_current_weather",
            AsyncMock(return_value=severe_current_weather),
        )
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_forecast",
            AsyncMock(return_value=mock_forecast_2day_calm),
        )

        response = client.get("/api/v1/risk/", params={"city": "Delhi"})

        assert response.status_code == 200
        body = response.json()
        assert body["risks"]["heat"]["risk"] == "SEVERE"
        assert body["risks"]["wind"]["risk"] == "SEVERE"

    def test_get_weather_risk_location_not_found(self, client, monkeypatch):
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(return_value={"results": []}),
        )

        response = client.get("/api/v1/risk/", params={"city": "Nowhereville"})
        assert response.status_code == 404

    def test_get_weather_risk_missing_city_param_rejected(self, client):
        response = client.get("/api/v1/risk/")
        assert response.status_code == 422
