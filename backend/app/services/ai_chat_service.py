from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.services.domain_advisory_service import domain_advisory_service
from app.services.advisory_service import advisory_service
from app.services.risk_service import risk_service


class AIChatService:

    async def process_message(
        self,
        message: str
    ):

        # ==========================================
        # STEP 1: UNDERSTAND USER QUESTION
        # ==========================================

        understanding = llm_service.understand_query(message)

        intent = understanding.get("intent", "weather")
        city = understanding.get("location")
        time = understanding.get("time", "current")
        domain = understanding.get("domain", "general")


        if not city:

            return {
                "success": False,
                "response": (
                    "Please provide a location or city so I can "
                    "give you accurate weather information."
                ),
                "understanding": understanding
            }


        location_data = await location_service.search_location(
            city=city,
            count=1
        )

        results = location_data.get("results")

        if not results:

            return {
                "success": False,
                "response": f"I could not find the location '{city}'.",
                "understanding": understanding
            }


        location = results[0]

        latitude = location["latitude"]
        longitude = location["longitude"]

        city_name = location["name"]


        weather_data = await weather_service.get_current_weather(
            latitude,
            longitude
        )

        current = weather_data.get("current", {})


        forecast_data = await weather_service.get_forecast(
            latitude,
            longitude,
            days=2
        )

        daily = forecast_data.get("daily", {})



        tomorrow_index = 1

        rain_probability_list = daily.get(
            "precipitation_probability_max",
            []
        )

        precipitation_list = daily.get(
            "precipitation_sum",
            []
        )

        rain_probability = (
            rain_probability_list[tomorrow_index]
            if len(rain_probability_list) > tomorrow_index
            else None
        )

        precipitation = (
            precipitation_list[tomorrow_index]
            if len(precipitation_list) > tomorrow_index
            else None
        )


        weather_context = {

            "location": city_name,

            "current_weather": {

                "temperature": current.get(
                    "temperature_2m"
                ),

                "humidity": current.get(
                    "relative_humidity_2m"
                ),

                "wind_speed": current.get(
                    "wind_speed_10m"
                ),

                "weather_code": current.get(
                    "weather_code"
                )
            },

            "tomorrow_forecast": {

                "rain_probability": rain_probability,

                "precipitation": precipitation
            }
        }



        if domain in [
            "farmer",
            "aviation",
            "marine",
            "urban"
        ]:

            domain_advice = (
                domain_advisory_service.generate_advisory(

                    domain=domain,

                    temperature=current.get(
                        "temperature_2m"
                    ),

                    humidity=current.get(
                        "relative_humidity_2m"
                    ),

                    wind_speed=current.get(
                        "wind_speed_10m"
                    ),

                    rain_probability=rain_probability
                )
            )

            weather_context["domain_advisory"] = (
                domain_advice
            )


        elif intent in [
            "weather",
            "forecast",
            "temperature",
            "rain"
        ]:

            general_advice = (
                advisory_service.generate_advisory(

                    temperature=current.get(
                        "temperature_2m"
                    ),

                    humidity=current.get(
                        "relative_humidity_2m"
                    ),

                    wind_speed=current.get(
                        "wind_speed_10m"
                    ),

                    rain_probability=rain_probability
                )
            )

            weather_context["advisory"] = general_advice



        elif intent == "risk":

            heat_risk = (
                risk_service.calculate_heat_risk(
                    current.get("temperature_2m")
                )
            )

            rain_risk = (
                risk_service.calculate_rain_risk(
                    rain_probability,
                    precipitation
                )
            )

            wind_risk = (
                risk_service.calculate_wind_risk(
                    current.get("wind_speed_10m")
                )
            )

            flood_risk = (
                risk_service.calculate_flood_risk(
                    rain_probability,
                    precipitation
                )
            )

            overall_risk = (
                risk_service.calculate_overall_risk(
                    heat_risk,
                    rain_risk,
                    wind_risk,
                    flood_risk
                )
            )

            weather_context["risk_analysis"] = {

                "heat": heat_risk,

                "rain": rain_risk,

                "wind": wind_risk,

                "flood": flood_risk,

                "overall": overall_risk
            }


        final_response = (
            llm_service.generate_weather_response(

                user_message=message,

                weather_context=weather_context
            )
        )


 
        return {

            "success": True,

            "response": final_response,

            "understanding": understanding,

            "weather_data": weather_context
        }


ai_chat_service = AIChatService()