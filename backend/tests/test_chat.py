from unittest.mock import AsyncMock

from app.services import nlu_service as nlu_service_module
from app.services import location_service as location_service_module
from app.services import weather_service as weather_service_module
from app.services import history_service as history_service_module


def _mock_nlu(intent="current_weather", location="Delhi", time=None, domain="general"):
    """Stub nlu_service.process_query with a deterministic parse, so chat
    tests exercise the orchestrator's routing/response logic instead of the
    (temporary, rule-based) NLU itself."""
    return AsyncMock(
        return_value={"intent": intent, "location": location, "time": time, "domain": domain}
    )


class TestChatCurrentWeatherFlow:

    def test_returns_weather_route_with_response_text(
        self, client, monkeypatch, mock_location, mock_current_weather
    ):
        monkeypatch.setattr(
            nlu_service_module.nlu_service,
            "process_query",
            _mock_nlu(intent="current_weather"),
        )
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
            history_service_module.history_service,
            "save_turn",
            AsyncMock(return_value="session-123"),
        )

        response = client.post(
            "/api/v1/chat/", json={"message": "What is the weather in Delhi?"}
        )

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is True
        assert body["route"] == "weather"
        assert body["location"]["city"] == "Delhi"
        assert body["session_id"] == "session-123"
        assert "Delhi" in body["response"]


class TestChatForecastFlow:

    def test_multi_day_forecast_when_no_specific_day_requested(
        self, client, monkeypatch, mock_location, mock_forecast_7day
    ):
        monkeypatch.setattr(
            nlu_service_module.nlu_service,
            "process_query",
            _mock_nlu(intent="forecast", time=None),
        )
        monkeypatch.setattr(
            location_service_module.location_service,
            "resolve_location",
            AsyncMock(return_value=mock_location),
        )
        monkeypatch.setattr(
            weather_service_module.weather_service,
            "get_forecast",
            AsyncMock(return_value=mock_forecast_7day),
        )
        monkeypatch.setattr(
            history_service_module.history_service,
            "save_turn",
            AsyncMock(return_value="session-456"),
        )

        response = client.post("/api/v1/chat/", json={"message": "7 day forecast for Delhi"})

        assert response.status_code == 200
        body = response.json()
        assert body["route"] == "forecast"
        assert isinstance(body["forecast"], list)
        assert len(body["forecast"]) == 7


class TestChatAlertFlow:

    def test_severe_conditions_produce_alerts(
        self,
        client,
        monkeypatch,
        mock_location,
        mock_current_weather,
        mock_forecast_2day_severe,
    ):
        monkeypatch.setattr(
            nlu_service_module.nlu_service,
            "process_query",
            _mock_nlu(intent="weather_alert"),
        )
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
            history_service_module.history_service,
            "save_turn",
            AsyncMock(return_value="session-789"),
        )

        response = client.post(
            "/api/v1/chat/", json={"message": "Is there a cyclone warning in Delhi?"}
        )

        assert response.status_code == 200
        body = response.json()
        assert body["route"] == "alert"
        assert body["overall_risk"]["risk"] == "SEVERE"
        assert len(body["alerts"]) > 0


class TestChatLocationHandling:

    def test_missing_location_returns_helpful_message_not_an_error(self, client, monkeypatch):
        monkeypatch.setattr(
            nlu_service_module.nlu_service,
            "process_query",
            _mock_nlu(intent="current_weather", location=None),
        )

        response = client.post("/api/v1/chat/", json={"message": "What's the weather?"})

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is False
        assert "location" in body["message"].lower()

    def test_unresolvable_location_returns_helpful_message(self, client, monkeypatch):
        monkeypatch.setattr(
            nlu_service_module.nlu_service,
            "process_query",
            _mock_nlu(intent="current_weather", location="Atlantis"),
        )
        monkeypatch.setattr(
            location_service_module.location_service,
            "resolve_location",
            AsyncMock(return_value=None),
        )

        response = client.post("/api/v1/chat/", json={"message": "Weather in Atlantis?"})

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is False
        assert "atlantis" in body["message"].lower()


class TestChatHistoryPersistence:

    def test_session_id_from_history_service_is_returned(
        self, client, monkeypatch, mock_location, mock_current_weather
    ):
        monkeypatch.setattr(
            nlu_service_module.nlu_service,
            "process_query",
            _mock_nlu(intent="current_weather"),
        )
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
        save_turn_mock = AsyncMock(return_value="generated-session-id")
        monkeypatch.setattr(
            history_service_module.history_service, "save_turn", save_turn_mock
        )

        response = client.post(
            "/api/v1/chat/",
            json={"message": "Weather in Delhi?", "session_id": None},
        )

        assert response.json()["session_id"] == "generated-session-id"
        save_turn_mock.assert_awaited_once()


class TestChatValidation:

    def test_empty_message_rejected(self, client):
        response = client.post("/api/v1/chat/", json={"message": ""})
        assert response.status_code == 422

    def test_missing_message_field_rejected(self, client):
        response = client.post("/api/v1/chat/", json={})
        assert response.status_code == 422
