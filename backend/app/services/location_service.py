import httpx


class LocationService:

    BASE_URL = "https://geocoding-api.open-meteo.com/v1/search"

    async def search_location(
        self,
        city: str,
        count: int = 5
    ):
        params = {
            "name": city,
            "count": count,
            "language": "en",
            "format": "json"
        }

        async with httpx.AsyncClient() as client:

            response = await client.get(
                self.BASE_URL,
                params=params
            )

            response.raise_for_status()

            return response.json()


location_service = LocationService()