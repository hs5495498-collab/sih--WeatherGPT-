import httpx

class LocationService:
    BASE_URL = "https://geocoding-api.open-meteo.com/v1/search"

    async def search_location(
        self,
        city: str,
        count: int = 10
    ):

        requested_count = max(1, count)
        params = {
            "name": city,
            "count": max(requested_count, 10),
            "language": "en",
            "format": "json",
            "countryCode": "IN"
        }

        async with httpx.AsyncClient(timeout=10.0) as client:

            response = await client.get(
                self.BASE_URL,
                params=params
            )

            response.raise_for_status()

            data = response.json()
            results = data.get("results", [])
            location_lower = city.strip().lower()

            results.sort(
                key=lambda location: (
                    location.get("country_code") != "IN",
                    location.get("name", "").lower() != location_lower,
                )
            )
            data["results"] = results[:requested_count]

            return data


    async def resolve_location(
        self,
        location_name: str
    ):

        data = await self.search_location(
            city=location_name,
            count=10
        )

        results = data.get("results", [])

        if not results:
            return None

        location_lower = location_name.strip().lower()

        # =====================================
        # EXACT MATCH IN INDIA
        # =====================================

        for location in results:

            if (
                location.get("name", "").lower()
                == location_lower

                and location.get("country_code") == "IN"
            ):

                return location
        # =====================================
        # ANY MATCH IN INDIA
        # =====================================

        for location in results:

            if location.get("country_code") == "IN":

                return location
        # =====================================
        # EXACT NAME MATCH
        # =====================================

        for location in results:

            if (
                location.get("name", "").lower()
                == location_lower
            ):

                return location
        # =====================================
        # FALLBACK
        # =====================================
        return results[0]
location_service = LocationService()