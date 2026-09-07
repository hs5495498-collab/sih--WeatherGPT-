"""
Real weather + geocoding client using Open-Meteo — free, keyless, no signup required.
This replaces the app's MockDataService for anything actually deployed: the mock service
stays useful as an offline/demo fallback, but this is what should back real answers.

Why Open-Meteo instead of IMD directly: IMD does not currently offer a simple, free,
publicly documented REST API for citizen-facing apps (India's official real-time weather
data is largely distributed through NOAA/WMO GTS feeds and IMD's own portals, not a clean
public API) — Open-Meteo aggregates multiple national weather models (including data over
India) into one free, well-documented API, which is why it's the practical choice for a
buildable hackathon project. If your team gets access to IMD's own data feeds later
(sometimes available to registered research/government projects), swap the fetch functions
here for that source — everything downstream (NLU, generation, the app) stays unchanged
since they only depend on the WeatherFacts shape below, not on Open-Meteo specifically.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Optional
import requests

GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
_TIMEOUT = 6


@dataclass
class WeatherFacts:
    """The grounding facts passed to the answer generator. Keeping this as one
    explicit, typed shape (rather than raw API JSON) means the generation step
    never has to know which weather provider the facts came from."""
    location_name: str
    latitude: float
    longitude: float
    date: str                      # ISO date this data describes
    temp_max_c: Optional[float] = None
    temp_min_c: Optional[float] = None
    current_temp_c: Optional[float] = None
    precipitation_mm: Optional[float] = None
    precipitation_probability_pct: Optional[int] = None
    wind_speed_kmh: Optional[float] = None
    humidity_pct: Optional[int] = None
    weather_code: Optional[int] = None
    condition_label: str = "cloudy"
    notes: list = field(default_factory=list)


# Open-Meteo's WMO weather codes, collapsed to the condition vocabulary the rest
# of the app already expects (matches the Flutter app's `sunny|rainy|cloudy|storm|snow`).
def _condition_from_wmo_code(code: int) -> str:
    if code in (0, 1):
        return "sunny"
    if code in (2, 3, 45, 48):
        return "cloudy"
    if code in (51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82):
        return "rainy"
    if code in (71, 73, 75, 77, 85, 86):
        return "snow"
    if code in (95, 96, 99):
        return "storm"
    return "cloudy"


class WeatherClient:
    def __init__(self, session: Optional[requests.Session] = None):
        self.session = session or requests.Session()

    def geocode(self, place_name: str) -> Optional[tuple[float, float, str]]:
        """Returns (lat, lon, resolved_name) for a place, biased toward India,
        or None if nothing matched — callers must handle that gracefully rather
        than assuming every location string resolves."""
        try:
            resp = self.session.get(
                GEOCODE_URL,
                params={"name": place_name, "count": 1, "language": "en", "format": "json"},
                timeout=_TIMEOUT,
            )
            resp.raise_for_status()
            results = resp.json().get("results") or []
            if not results:
                return None
            top = results[0]
            return (top["latitude"], top["longitude"], top.get("name", place_name))
        except (requests.RequestException, KeyError, ValueError):
            return None

    def get_weather(
        self, place_name: str, when: str = "today"
    ) -> Optional[WeatherFacts]:
        """Fetches current + relevant forecast-day data for a place and an
        approximate day reference ('today', 'tomorrow', 'this weekend', etc — see
        _resolve_date_offset). Returns None if geocoding or the API call fails;
        callers should fall back to mock data or a clarifying question, never
        fabricate facts silently."""
        geocoded = self.geocode(place_name)
        if geocoded is None:
            return None
        lat, lon, resolved_name = geocoded

        day_offset = _resolve_date_offset(when)
        target_date = (datetime.utcnow() + timedelta(days=day_offset)).date()

        try:
            resp = self.session.get(
                FORECAST_URL,
                params={
                    "latitude": lat,
                    "longitude": lon,
                    "current": "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code",
                    "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,"
                             "precipitation_probability_max,wind_speed_10m_max,weather_code",
                    "timezone": "auto",
                    "forecast_days": max(day_offset + 1, 1),
                },
                timeout=_TIMEOUT,
            )
            resp.raise_for_status()
            data = resp.json()
        except (requests.RequestException, ValueError):
            return None

        daily = data.get("daily", {})
        current = data.get("current", {})

        try:
            idx = daily["time"].index(target_date.isoformat())
        except (KeyError, ValueError):
            idx = 0  # fall back to the first available day rather than crashing

        code = daily.get("weather_code", [0])[idx] if daily.get("weather_code") else 0

        return WeatherFacts(
            location_name=resolved_name,
            latitude=lat,
            longitude=lon,
            date=daily.get("time", [target_date.isoformat()])[idx],
            temp_max_c=_safe_index(daily.get("temperature_2m_max"), idx),
            temp_min_c=_safe_index(daily.get("temperature_2m_min"), idx),
            current_temp_c=current.get("temperature_2m"),
            precipitation_mm=_safe_index(daily.get("precipitation_sum"), idx),
            precipitation_probability_pct=_safe_index(daily.get("precipitation_probability_max"), idx),
            wind_speed_kmh=_safe_index(daily.get("wind_speed_10m_max"), idx) or current.get("wind_speed_10m"),
            humidity_pct=current.get("relative_humidity_2m"),
            weather_code=code,
            condition_label=_condition_from_wmo_code(code),
        )


def _safe_index(lst, idx):
    if not lst or idx >= len(lst):
        return None
    return lst[idx]


def _resolve_date_offset(when: Optional[str]) -> int:
    """Very deliberately simple: maps common phrasings to a day offset. This is
    NOT meant to handle every possible date expression robustly — if your NLU's
    `datetime` slot is empty or doesn't match anything here, default to today
    (offset 0) rather than guessing wildly."""
    if not when:
        return 0
    w = when.lower()
    if "tomorrow" in w:
        return 1
    if "weekend" in w:
        today = datetime.utcnow().weekday()  # Monday=0
        days_to_saturday = (5 - today) % 7
        return days_to_saturday or 6
    if "next week" in w:
        return 7
    for i, day_name in enumerate(
        ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    ):
        if day_name in w:
            today = datetime.utcnow().weekday()
            return (i - today) % 7 or 7
    if "3 days" in w or "three days" in w:
        return 3
    return 0
