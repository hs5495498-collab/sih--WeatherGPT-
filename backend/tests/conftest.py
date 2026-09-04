import os
import sys

# Make sure "app" resolves regardless of the directory pytest is invoked from.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    """
    TestClient wrapped as a context manager so FastAPI's lifespan runs
    (starts/stops the alert_poller cleanly instead of leaking a task).
    """
    with TestClient(app) as test_client:
        yield test_client


# ---------------------------------------------------------------------------
# Shared fake data. These mirror the *raw* shapes returned by Open-Meteo's
# geocoding/forecast APIs (see location_service.py / weather_service.py),
# so tests stay honest about what the services actually hand back.
# ---------------------------------------------------------------------------


@pytest.fixture
def mock_location():
    """A single Open-Meteo geocoding result for Delhi."""
    return {
        "name": "Delhi",
        "latitude": 28.6139,
        "longitude": 77.2090,
        "country": "India",
        "country_code": "IN",
        "admin1": "Delhi",
        "timezone": "Asia/Kolkata",
    }


@pytest.fixture
def mock_location_search_response(mock_location):
    """Raw shape returned by location_service.search_location()."""
    return {"results": [mock_location]}


@pytest.fixture
def mock_current_weather():
    """Raw shape returned by weather_service.get_current_weather()."""
    return {
        "current": {
            "temperature_2m": 32.0,
            "relative_humidity_2m": 45,
            "wind_speed_10m": 12.0,
            "weather_code": 1,
        }
    }


@pytest.fixture
def mock_forecast_7day():
    """7-day forecast, matches what /weather/forecast requests by default."""
    return {
        "daily": {
            "time": [f"2026-09-{d:02d}" for d in range(4, 11)],
            "weather_code": [1, 2, 3, 61, 80, 0, 2],
            "temperature_2m_max": [33, 34, 35, 30, 29, 31, 32],
            "temperature_2m_min": [22, 23, 24, 21, 20, 22, 23],
            "precipitation_sum": [0, 0, 5, 15, 20, 0, 0],
            "precipitation_probability_max": [10, 20, 40, 70, 80, 10, 15],
            "wind_speed_10m_max": [10, 12, 15, 20, 25, 11, 13],
        }
    }


@pytest.fixture
def mock_forecast_2day_calm():
    """Two-day forecast with nothing risky on 'tomorrow' (index 1)."""
    return {
        "daily": {
            "time": ["2026-09-04", "2026-09-05"],
            "weather_code": [1, 2],
            "temperature_2m_max": [30, 28],
            "temperature_2m_min": [20, 19],
            "precipitation_sum": [0, 2],
            "precipitation_probability_max": [10, 20],
            "wind_speed_10m_max": [10, 15],
        }
    }


@pytest.fixture
def mock_forecast_2day_severe():
    """Two-day forecast with severe heat/rain/wind/flood risk on 'tomorrow' (index 1)."""
    return {
        "daily": {
            "time": ["2026-09-04", "2026-09-05"],
            "weather_code": [1, 65],
            "temperature_2m_max": [33, 47],
            "temperature_2m_min": [20, 30],
            "precipitation_sum": [0, 80],
            "precipitation_probability_max": [10, 95],
            "wind_speed_10m_max": [10, 85],
        }
    }
