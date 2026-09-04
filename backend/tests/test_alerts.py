from unittest.mock import AsyncMock

from app.services.alert_service import alert_service
from app.services import location_service as location_service_module
from app.services import weather_service as weather_service_module
from app.services import notification_service as notification_service_module


class TestAlertServiceGeneration:

    def test_skips_low_and_unknown_risks(self):
        risks = {
            "heat": {"risk": "LOW", "score": 10, "message": "fine"},
            "wind": {"risk": "UNKNOWN", "score": 0, "message": "n/a"},
        }
        assert alert_service.generate_alerts(risks) == []

    def test_includes_moderate_and_above(self):
        risks = {
            "heat": {"risk": "SEVERE", "score": 90, "message": "hot"},
            "rain": {"risk": "MODERATE", "score": 40, "message": "wet"},
            "wind": {"risk": "LOW", "score": 10, "message": "calm"},
        }
        alerts = alert_service.generate_alerts(risks)
        types = {a["type"] for a in alerts}
        assert types == {"HEAT", "RAIN"}
        assert len(alerts) == 2


class TestCreateAlert:

    def test_shape_and_title_for_known_type(self):
        alert = alert_service.create_alert(
            risk_type="flood", risk_level="HIGH", score=70, message="flooding expected"
        )
        assert alert["type"] == "FLOOD"
        assert alert["title"] == "Flood Risk Alert"
        assert alert["severity"] == "HIGH"
        assert alert["score"] == 70
        assert alert["message"] == "flooding expected"
        assert len(alert["recommendations"]) > 0

    def test_falls_back_to_generic_title_for_unknown_type(self):
        alert = alert_service.create_alert(
            risk_type="earthquake", risk_level="HIGH", score=70, message="shaking"
        )
        assert alert["title"] == "Weather Alert"


class TestGetRecommendations:

    def test_returns_specific_recommendations_for_known_types(self):
        recs = alert_service.get_recommendations("heat", "SEVERE")
        assert "Stay hydrated." in recs

    def test_falls_back_for_unknown_type(self):
        recs = alert_service.get_recommendations("earthquake", "HIGH")
        assert recs == [
            "Monitor weather conditions.",
            "Follow official safety instructions.",
        ]


class TestAlertsEndpoint:

    def test_returns_active_alerts_for_severe_weather(
        self,
        client,
        monkeypatch,
        mock_location,
        mock_current_weather,
        mock_forecast_2day_severe,
    ):
        monkeypatch.setattr(
            location_service_module.location_service,
            "resolve_location",
            AsyncMock(return_value=mock_location),
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
        monkeypatch.setattr(
            notification_service_module.notification_service,
            "notify",
            AsyncMock(return_value={}),
        )

        response = client.get("/api/v1/alerts/", params={"city": "Delhi"})

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is True
        assert body["alert_count"] > 0
        assert body["overall_risk"]["risk"] == "SEVERE"

    def test_no_alerts_for_calm_weather(
        self,
        client,
        monkeypatch,
        mock_location,
        mock_current_weather,
        mock_forecast_2day_calm,
    ):
        monkeypatch.setattr(
            location_service_module.location_service,
            "resolve_location",
            AsyncMock(return_value=mock_location),
        )
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_current_weather",
            AsyncMock(return_value=mock_current_weather),
        )
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_forecast",
            AsyncMock(return_value=mock_forecast_2day_calm),
        )
        monkeypatch.setattr(
            notification_service_module.notification_service,
            "notify",
            AsyncMock(return_value={}),
        )

        response = client.get("/api/v1/alerts/", params={"city": "Delhi"})

        assert response.status_code == 200
        body = response.json()
        assert body["alert_count"] == 0
        assert body["alerts"] == []

    def test_location_not_found_returns_404(self, client, monkeypatch):
        monkeypatch.setattr(
            location_service_module.location_service,
            "resolve_location",
            AsyncMock(return_value=None),
        )

        response = client.get("/api/v1/alerts/", params={"city": "Nowhereville"})
        assert response.status_code == 404

    def test_pushes_result_through_notification_service(
        self,
        client,
        monkeypatch,
        mock_location,
        mock_current_weather,
        mock_forecast_2day_severe,
    ):
        """Every alerts call should fan out via notification_service.notify(),
        which is what feeds the WebSocket subscribers in real time."""
        monkeypatch.setattr(
            location_service_module.location_service,
            "resolve_location",
            AsyncMock(return_value=mock_location),
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
        notify_mock = AsyncMock(return_value={"websocket": True})
        monkeypatch.setattr(
            notification_service_module.notification_service, "notify", notify_mock
        )

        client.get("/api/v1/alerts/", params={"city": "Delhi"})

        notify_mock.assert_awaited_once()
        _, kwargs = notify_mock.call_args
        assert kwargs["city"] == "Delhi"
        assert kwargs["overall_risk"]["risk"] == "SEVERE"

    def test_missing_city_param_rejected(self, client):
        response = client.get("/api/v1/alerts/")
        assert response.status_code == 422
