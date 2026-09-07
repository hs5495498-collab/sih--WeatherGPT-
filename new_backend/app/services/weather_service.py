import time

import httpx


class WeatherService:

    BASE_URL = "https://api.open-meteo.com/v1/forecast"

    # Tiny in-memory TTL cache. Open-Meteo is free and has no auth, but it
    # (like any public API) is still worth not hammering: every chat
    # message, dashboard refresh, alert-poll tick, and domain-advisory call
    # for the same city within a short window reuses one response instead
    # of firing a fresh HTTP request each time. Keyed to 2-decimal lat/lon
    # (~1km) so nearby requests for "the same place" still share an entry.
    # Intentionally simple (no Redis) -- resets on restart, which is fine
    # for a single-process deployment; swapping in Redis later wouldn't
    # change any caller.
    _CACHE_TTL_SECONDS = 300  # 5 minutes: long enough to matter, short enough to stay "current"
    _cache: dict = {}

    def _cache_get(self, key):
        entry = self._cache.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if time.monotonic() > expires_at:
            del self._cache[key]
            return None
        return value

    def _cache_set(self, key, value):
        self._cache[key] = (value, time.monotonic() + self._CACHE_TTL_SECONDS)

    async def get_current_weather(
        self,
        latitude: float,
        longitude: float
    ):
        cache_key = ("current", round(latitude, 2), round(longitude, 2))
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached

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

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                self.BASE_URL,
                params=params
            )

            response.raise_for_status()

            data = response.json()
            self._cache_set(cache_key, data)
            return data

    async def get_forecast(
        self,
        latitude: float,
        longitude: float,
        days: int = 7
    ):
        cache_key = ("forecast", round(latitude, 2), round(longitude, 2), days)
        cached = self._cache_get(cache_key)
        if cached is not None:
            return cached

        params = {
            "latitude": latitude,
            "longitude": longitude,
            "forecast_days": days,
            # NOTE: this MUST be one comma-joined string, not a tuple. An
            # earlier version had a stray comma inside the parens, which
            # silently turned this into a 2-item tuple -- httpx then sent
            # `daily=` as two separate query params instead of one combined
            # field list, risking Open-Meteo dropping
            # precipitation_probability_max and wind_speed_10m_max, both of
            # which are load-bearing for alerts, risk scoring, and domain
            # advisories. Every test in test_weather.py mocks get_forecast()
            # directly, so unit tests never exercised the real HTTP call
            # and never caught this.
            "daily": (
                "weather_code,"
                "temperature_2m_max,"
                "temperature_2m_min,"
                "precipitation_sum,"
                "precipitation_probability_max,"
                "wind_speed_10m_max"
            ),
            "timezone": "auto"
        }

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                self.BASE_URL,
                params=params
            )

            response.raise_for_status()

            data = response.json()
            self._cache_set(cache_key, data)
            return data


weather_service = WeatherService()
