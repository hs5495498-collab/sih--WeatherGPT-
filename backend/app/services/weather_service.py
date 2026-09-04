import httpx


class WeatherService:

    BASE_URL = "https://api.open-meteo.com/v1/forecast"

    async def get_current_weather(
        self,
        latitude: float,
        longitude: float
    ):
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "current": (
                "temperature_2m,"
                "relative_humidity_2m,"
                "wind_speed_10m,"
                "weather_code"
            )
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.BASE_URL,
                params=params
            )

            response.raise_for_status()

            return response.json()

    async def get_forecast(
        self,
        latitude: float,
        longitude: float,
        days: int = 7
    ):
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "forecast_days": days,
            "daily": (
                "weather_code,"
                "temperature_2m_max,"
                "temperature_2m_min,"
                "precipitation_sum",
                "precipitation_probability_max",
                "wind_speed_10m_max"
            ),
            "timezone": "auto"
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.BASE_URL,
                params=params
            )

            response.raise_for_status()

            return response.json()


weather_service = WeatherService()