from fastapi import APIRouter, HTTPException, Query

from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.services.risk_service import risk_service


router = APIRouter(
    prefix="/api/v1/risk",
    tags=["Extreme Weather Risk"]
)


@router.get("/")
async def get_weather_risk(
    city: str = Query(..., description="City name")
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

        tomorrow_index = 1


        rain_probability_data = daily.get(
            "precipitation_probability_max",
            []
        )

        rain_probability = (
            rain_probability_data[tomorrow_index]
            if len(rain_probability_data) > tomorrow_index
            else 0
        )

        precipitation_data = daily.get("precipitation_sum", [])

        precipitation = (
            precipitation_data[tomorrow_index]
            if len(precipitation_data) > tomorrow_index
            else 0
        )


        heat_risk = risk_service.calculate_heat_risk(
            current.get("temperature_2m")
        )

        rain_risk = risk_service.calculate_rain_risk(
            rain_probability,
            precipitation
        )

        wind_risk = risk_service.calculate_wind_risk(
            current.get("wind_speed_10m")
        )

        flood_risk = risk_service.calculate_flood_risk(
            rain_probability,
            precipitation
        )


        overall_risk = risk_service.calculate_overall_risk(
            heat_risk,
            rain_risk,
            wind_risk,
            flood_risk
        )



        return {

            "location": {
                "city": location["name"],
                "latitude": latitude,
                "longitude": longitude
            },

            "weather_data": {

                "temperature": current.get(
                    "temperature_2m"
                ),

                "wind_speed": current.get(
                    "wind_speed_10m"
                ),

                "tomorrow_rain_probability":
                    rain_probability,

                "tomorrow_precipitation":
                    precipitation
            },

            "risks": {

                "heat": heat_risk,

                "rain": rain_risk,

                "wind": wind_risk,

                "flood": flood_risk
            },

            "overall_risk": overall_risk
        }


    except HTTPException:
        raise

    except Exception as error:

        raise HTTPException(
            status_code=500,
            detail=str(error)
        )