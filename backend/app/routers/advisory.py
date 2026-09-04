from fastapi import APIRouter, HTTPException

from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.services.advisory_service import advisory_service


router = APIRouter(
    prefix="/api/v1/advisory",
    tags=["Weather Advisory"]
)


@router.get("/")
async def get_weather_advisory(city: str):

    try:

        # Get coordinates
        location_data = await location_service.search_location(
            city=city,
            count=1
        )

        results = location_data.get("results")

        if not results:
            raise HTTPException(
                status_code=404,
                detail="Location not found"
            )

        location = results[0]

        latitude = location["latitude"]
        longitude = location["longitude"]

        # Current weather
        weather_data = await weather_service.get_current_weather(
            latitude,
            longitude
        )

        current = weather_data["current"]

        # Forecast
        forecast_data = await weather_service.get_forecast(
            latitude,
            longitude,
            days=2
        )

        daily = forecast_data["daily"]

        rain_probability = daily[
            "precipitation_probability_max"
        ][1]

        advisories = advisory_service.generate_advisory(
            temperature=current.get("temperature_2m"),
            humidity=current.get("relative_humidity_2m"),
            wind_speed=current.get("wind_speed_10m"),
            rain_probability=rain_probability
        )

        return {

            "city": location["name"],

            "current_weather": {
                "temperature": current.get("temperature_2m"),
                "humidity": current.get("relative_humidity_2m"),
                "wind_speed": current.get("wind_speed_10m")
            },

            "tomorrow_rain_probability": rain_probability,

            "advisories": advisories
        }

    except HTTPException:
        raise

    except Exception as error:

        raise HTTPException(
            status_code=500,
            detail=str(error)
        )