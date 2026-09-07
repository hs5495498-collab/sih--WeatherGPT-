from unittest.mock import AsyncMock

from app.services import location_service as location_service_module


class TestLocationSearchEndpoint:

    def test_search_location_success(self, client, monkeypatch, mock_location_search_response):
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(return_value=mock_location_search_response),
        )

        response = client.get("/api/v1/location/search", params={"city": "Delhi"})

        assert response.status_code == 200
        body = response.json()
        assert len(body) == 1
        assert body[0]["name"] == "Delhi"
        assert body[0]["country_code"] == "IN"
        assert body[0]["state"] == "Delhi"

    def test_search_location_maps_admin1_to_state(
        self, client, monkeypatch, mock_location_search_response
    ):
        """LocationResponse.state comes from the raw 'admin1' field."""
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(return_value=mock_location_search_response),
        )

        response = client.get("/api/v1/location/search", params={"city": "Delhi"})

        assert response.json()[0]["state"] == mock_location_search_response["results"][0]["admin1"]

    def test_search_location_not_found(self, client, monkeypatch):
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(return_value={"results": []}),
        )

        response = client.get("/api/v1/location/search", params={"city": "Nowhereville"})
        assert response.status_code == 404

    def test_search_location_missing_query_param_rejected(self, client):
        response = client.get("/api/v1/location/search")
        assert response.status_code == 422

    def test_search_location_query_too_short_rejected(self, client):
        response = client.get("/api/v1/location/search", params={"city": "D"})
        assert response.status_code == 422

    def test_search_location_upstream_error_returns_500(self, client, monkeypatch):
        monkeypatch.setattr(
            location_service_module.location_service,
            "search_location",
            AsyncMock(side_effect=Exception("geocoding API down")),
        )

        response = client.get("/api/v1/location/search", params={"city": "Delhi"})
        assert response.status_code == 500
