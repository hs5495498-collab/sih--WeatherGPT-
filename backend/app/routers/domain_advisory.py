from fastapi import APIRouter, HTTPException, Query

from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.services.domain_advisory_service import domain_advisory_service


router = APIRouter(
    prefix="/api/v1/domain-advisory",
    tags=["Domain Advisory"]
)


@router.get("/")
async def get_domain_advisory(
    city: str = Query(..., description="City name"),
    domain: str = Query(
        ...,
        description="farmer, aviation, marine, or urban"
    )
):

    try:

 
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


        weather_data = await weather_service.get_current_weather(
            latitude,
            longitude
        )

        current = weather_data["current"]


        forecast_data = await weather_service.get_forecast(
            latitude,
            longitude,
            days=2
        )

        daily = forecast_data["daily"]

        rain_probability = (
            daily["precipitation_probability_max"][1]
        )


        advisories = domain_advisory_service.generate_advisory(

            domain=domain,

            temperature=current.get("temperature_2m"),

            humidity=current.get("relative_humidity_2m"),

            wind_speed=current.get("wind_speed_10m"),

            rain_probability=rain_probability
        )


        return {

            "city": location["name"],

            "domain": domain,

            "weather_data": {

                "temperature": current.get("temperature_2m"),

                "humidity": current.get(
                    "relative_humidity_2m"
                ),

                "wind_speed": current.get(
                    "wind_speed_10m"
                ),

                "tomorrow_rain_probability": rain_probability
            },

            "advisories": advisories
        }


    except HTTPException:
        raise


    except Exception as error:

        raise HTTPException(
            status_code=500,
            detail=str(error)
        )