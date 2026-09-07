from unittest.mock import AsyncMock

from app.services import location_service as location_service_module
from app.services import weather_service as weather_service_module


class TestCurrentWeatherEndpoint:

    def test_get_current_weather_success(self, client, monkeypatch, mock_current_weather):
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_current_weather",
            AsyncMock(return_value=mock_current_weather),
        )

        response = client.get(
            "/api/v1/weather/current",
            params={"latitude": 28.6139, "longitude": 77.2090},
        )

        assert response.status_code == 200
        body = response.json()
        assert body["temperature"] == 32.0
        assert body["humidity"] == 45
        assert body["wind_speed"] == 12.0
        assert body["location"] == {"latitude": 28.6139, "longitude": 77.2090}

    def test_get_current_weather_upstream_failure_returns_500(self, client, monkeypatch):
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_current_weather",
            AsyncMock(side_effect=Exception("upstream timeout")),
        )

        response = client.get(
            "/api/v1/weather/current",
            params={"latitude": 28.6139, "longitude": 77.2090},
        )

        assert response.status_code == 500

    def test_get_current_weather_missing_params_rejected(self, client):
        response = client.get("/api/v1/weather/current")
        assert response.status_code == 422


class TestForecastEndpoint:

    def test_get_weather_forecast_success(self, client, monkeypatch, mock_forecast_7day):
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_forecast",
            AsyncMock(return_value=mock_forecast_7day),
        )

        response = client.get(
            "/api/v1/weather/forecast",
            params={"latitude": 28.6139, "longitude": 77.2090, "days": 7},
        )

        assert response.status_code == 200
        body = response.json()
        assert len(body["forecast"]) == 7
        assert body["forecast"][0]["date"] == "2026-09-04"
        assert body["forecast"][0]["temperature_max"] == 33

    def test_get_weather_forecast_invalid_days_rejected(self, client):
        response = client.get(
            "/api/v1/weather/forecast",
            params={"latitude": 28.6139, "longitude": 77.2090, "days": 20},
        )
        assert response.status_code == 422

    def test_get_weather_forecast_upstream_failure_returns_500(self, client, monkeypatch):
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_forecast",
            AsyncMock(side_effect=Exception("upstream timeout")),
        )

        response = client.get(
            "/api/v1/weather/forecast",
            params={"latitude": 28.6139, "longitude": 77.2090},
        )
        assert response.status_code == 500


class TestWeatherByCityEndpoint:

    def test_get_weather_by_city_success(
        self, client, monkeypatch, mock_location_search_response, mock_current_weather
    ):
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

        response = client.get("/api/v1/weather/by-city", params={"city": "Delhi"})

        assert response.status_code == 200
        body = response.json()
        assert body["city"] == "Delhi"
        assert body["country"] == "India"
        assert body["temperature"] == 32.0

    def test_get_weather_by_city_not_found(self, client, monkeypatch):
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(return_value={"results": []}),
        )

        response = client.get("/api/v1/weather/by-city", params={"city": "Nowhereville"})
        assert response.status_code == 404

    def test_get_weather_by_city_query_too_short_rejected(self, client):
        response = client.get("/api/v1/weather/by-city", params={"city": "D"})
        assert response.status_code == 422
