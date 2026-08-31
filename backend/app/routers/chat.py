from fastapi import APIRouter, HTTPException

from app.schemas.chat import ChatRequest, ChatResponse
from app.services.chat_service import chat_service
from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.utils.weather_codes import get_weather_info


router = APIRouter(
    prefix="/api/v1/chat",
    tags=["Chat"]
)


@router.post("/", response_model=ChatResponse)
async def chat(request: ChatRequest):

    message = request.message

    # ----------------------------------------
    # UNDERSTAND USER MESSAGE
    # ----------------------------------------

    intent = chat_service.detect_intent(message)

    time_reference = chat_service.detect_time(message)

    city = chat_service.extract_location_candidate(message)


    # ----------------------------------------
    # CHECK LOCATION
    # ----------------------------------------

    if not city:

        return ChatResponse(
            answer=(
                "Please mention a location. "
                "For example: What is the weather in Delhi?"
            ),
            intent=intent,
            time=time_reference,
            city=None
        )


    try:

        # ----------------------------------------
        # GET LOCATION COORDINATES
        # ----------------------------------------

        location_data = await location_service.search_location(
            city=city,
            count=1
        )

        results = location_data.get("results")

        if not results:

            raise HTTPException(
                status_code=404,
                detail=f"Location '{city}' not found"
            )

        location = results[0]

        latitude = location["latitude"]
        longitude = location["longitude"]


        # ========================================
        # CURRENT WEATHER DATA
        # ========================================

        if time_reference in ["current", "today"]:

            weather_data = await weather_service.get_current_weather(
                latitude,
                longitude
            )

            current = weather_data["current"]

            weather_info = get_weather_info(
                current["weather_code"]
            )


            # 🌡️ TEMPERATURE
            if intent == "temperature":

                answer = (
                    f"The current temperature in {city} is "
                    f"{current['temperature_2m']}°C."
                )


            # 💧 HUMIDITY
            elif intent == "humidity":

                answer = (
                    f"The current humidity in {city} is "
                    f"{current['relative_humidity_2m']}%."
                )


            # 💨 WIND
            elif intent == "wind":

                answer = (
                    f"The current wind speed in {city} is "
                    f"{current['wind_speed_10m']} km/h."
                )


            # 🌧️ RAIN
            elif intent == "rain":

                answer = (
                    f"The current weather in {city} is "
                    f"{weather_info['description']}."
                )


            # 🌤️ GENERAL WEATHER
            elif intent in ["weather", "forecast"]:

                answer = (
                    f"The current weather in {city} is "
                    f"{weather_info['description']}. "
                    f"The temperature is {current['temperature_2m']}°C "
                    f"with humidity of "
                    f"{current['relative_humidity_2m']}%."
                )


            else:

                answer = (
                    "I can help you with weather, temperature, "
                    "rain, humidity, wind, and forecasts."
                )


        # ========================================
        # TOMORROW FORECAST
        # ========================================

        elif time_reference == "tomorrow":

            forecast_data = await weather_service.get_forecast(
                latitude,
                longitude,
                days=2
            )

            daily = forecast_data["daily"]

            tomorrow_index = 1

            temperature_max = daily["temperature_2m_max"][tomorrow_index]

            temperature_min = daily["temperature_2m_min"][tomorrow_index]

            rain_probability = daily[
                "precipitation_probability_max"
            ][tomorrow_index]

            weather_code = daily["weather_code"][tomorrow_index]

            weather_info = get_weather_info(weather_code)


            # 🌧️ RAIN TOMORROW
            if intent == "rain":

                answer = (
                    f"The probability of precipitation tomorrow in "
                    f"{city} is {rain_probability}%. "
                    f"The expected weather is "
                    f"{weather_info['description']}."
                )


            # 🌡️ TEMPERATURE TOMORROW
            elif intent == "temperature":

                answer = (
                    f"Tomorrow in {city}, the temperature is expected "
                    f"to range from {temperature_min}°C to "
                    f"{temperature_max}°C."
                )


            # 🌤️ GENERAL FORECAST
            else:

                answer = (
                    f"Tomorrow in {city}, the expected weather is "
                    f"{weather_info['description']}. "
                    f"Temperatures may range from "
                    f"{temperature_min}°C to {temperature_max}°C. "
                    f"The probability of precipitation is "
                    f"{rain_probability}%."
                )


        # ========================================
        # WEEKLY FORECAST
        # ========================================

        elif time_reference in ["this_week", "next_week"]:

            forecast_data = await weather_service.get_forecast(
                latitude,
                longitude,
                days=7
            )

            daily = forecast_data["daily"]

            max_temp = max(daily["temperature_2m_max"])

            min_temp = min(daily["temperature_2m_min"])

            max_rain_probability = max(
                daily["precipitation_probability_max"]
            )

            answer = (
                f"The weather forecast for {city} over the coming days "
                f"shows temperatures ranging approximately from "
                f"{min_temp}°C to {max_temp}°C. "
                f"The highest probability of precipitation is "
                f"{max_rain_probability}%."
            )


        return ChatResponse(
            answer=answer,
            intent=intent,
            time=time_reference,
            city=city
        )


    except HTTPException:
        raise

    except Exception as error:

        raise HTTPException(
            status_code=500,
            detail=f"Unable to process request: {str(error)}"
        )