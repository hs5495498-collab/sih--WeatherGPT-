import logging

from app.utils.weather_codes import get_weather_info

from fastapi import APIRouter, HTTPException, Query

from app.services.weather_service import weather_service
from app.services.location_service import location_service

from app.schemas.weather import (
    CurrentWeatherResponse,
    ForecastResponse,
    DailyForecast,
    Location,
    CityWeatherResponse,
)

router = APIRouter(prefix="/api/v1/weather", tags=["Weather"])

logger = logging.getLogger(__name__)

# Current Weather


@router.get("/current", response_model=CurrentWeatherResponse)
async def get_current_weather(latitude: float, longitude: float):

    try:
        data = await weather_service.get_current_weather(latitude, longitude)

        current = data["current"]

        weather_info = get_weather_info(current["weather_code"])

        return CurrentWeatherResponse(
            location=Location(latitude=latitude, longitude=longitude),
            temperature=current["temperature_2m"],
            humidity=current["relative_humidity_2m"],
            wind_speed=current["wind_speed_10m"],
            weather_code=current["weather_code"],
            weather_condition=weather_info["condition"],
            description=weather_info["description"],
            icon=weather_info["icon"],
        )

    except Exception as error:
        logger.error("Unexpected error fetching current weather (lat=%s, lon=%s): %s", latitude, longitude, error)
        raise HTTPException(
            status_code=500, detail="Unable to fetch weather data."
        )


# Weather Forecast


@router.get("/forecast", response_model=ForecastResponse)
async def get_weather_forecast(
    latitude: float,
    longitude: float,
    days: int = Query(default=7, ge=1, le=16, description="Number of forecast days"),
):

    try:

        data = await weather_service.get_forecast(
            latitude=latitude, longitude=longitude, days=days
        )

        daily = data["daily"]

        forecast = []

        for i in range(len(daily["time"])):

            weather_info = get_weather_info(
                daily["weather_code"][i]
            )

            forecast.append(
                DailyForecast(
                    date=daily["time"][i],
                    weather_code=daily["weather_code"][i],
                    weather_condition=weather_info["condition"],
                    description=weather_info["description"],
                    icon=weather_info["icon"],
                    temperature_max=daily["temperature_2m_max"][i],
                    temperature_min=daily["temperature_2m_min"][i],
                    precipitation_probability_max=daily[
                        "precipitation_probability_max"
                    ][i],
                )
            )

        return ForecastResponse(
            location=Location(latitude=latitude, longitude=longitude), forecast=forecast
        )

    except Exception:
        raise HTTPException(status_code=500, detail="Unable to fetch weather forecast")


@router.get("/by-city", response_model=CityWeatherResponse)
async def get_weather_by_city(
    city: str = Query(..., min_length=2, description="City name")
):

    try:
        # Step 1: Search for city
        location_data = await location_service.search_location(city=city, count=1)

        results = location_data.get("results")

        if not results:
            raise HTTPException(status_code=404, detail="City not found")

        location = results[0]

        latitude = location["latitude"]
        longitude = location["longitude"]

        # Step 2: Get weather using coordinates
        weather_data = await weather_service.get_current_weather(
            latitude=latitude, longitude=longitude
        )

        current = weather_data["current"]

        weather_info = get_weather_info(
            current["weather_code"]
        )

        # Step 3: Return combined data
        return CityWeatherResponse(
            city=location["name"],
            state=location.get("admin1"),
            country=location.get("country"),
            latitude=latitude,
            longitude=longitude,
            temperature=current["temperature_2m"],
            humidity=current["relative_humidity_2m"],
            wind_speed=current["wind_speed_10m"],
            weather_code=current["weather_code"],
            weather_condition=weather_info["condition"],
            description=weather_info["description"],
            icon=weather_info["icon"]
        )

    except HTTPException:
        raise

    except Exception as error:
        logger.error("Unexpected error fetching weather for city='%s': %s", city, error)
        raise HTTPException(
            status_code=500, detail="Unable to fetch weather."
        )
