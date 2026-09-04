from app.utils.time_utils import get_target_date

from app.services.nlu_service import nlu_service
from app.services.intent_router_service import intent_router_service

from app.services.location_service import location_service
from app.services.weather_service import weather_service
from app.services.risk_service import risk_service
from app.services.farmer_advisory_service import farmer_advisory_service
from app.services.response_generator_service import response_generator_service
from app.services.alert_service import alert_service
from app.services.aviation_advisory_service import aviation_advisory_service
from app.services.marine_advisory_service import marine_advisory_service
from app.services.outdoor_advisory_service import outdoor_advisory_service

from app.utils.weather_codes import get_weather_info


class ChatOrchestrator:

    async def process_message(self, message: str):

        # =====================================
        # STEP 1: NLU PROCESSING
        # =====================================

        nlu_result = await nlu_service.process_query(message)


        # =====================================
        # STEP 2: INTENT ROUTING
        # =====================================

        route = await intent_router_service.route(nlu_result)

        location_name = nlu_result.get("location")

        # =====================================
        # LOCATION REQUIRED
        # =====================================

        if not location_name:

            return {
                "success": False,
                "message": "Please provide a location.",
                "intent": nlu_result.get("intent"),
                "route": route
            }

        # =====================================
        # STEP 3: GET LOCATION COORDINATES
        # =====================================

        location = await location_service.resolve_location(
            location_name
        )

        if not location:

            return {
                "success": False,
                "message": f"I couldn't find the location '{location_name}'.",
                "intent": nlu_result.get("intent"),
                "route": route
            }


        latitude = location["latitude"]
        longitude = location["longitude"]

        # =====================================
        # STEP 4: CURRENT WEATHER
        # =====================================

        if route == "weather":

            weather_data = await weather_service.get_current_weather(
                latitude=latitude,
                longitude=longitude
            )

            current = weather_data["current"]

            weather_info = get_weather_info(
                current["weather_code"]
            )

            result = {

                "success": True,

                "intent": nlu_result.get("intent"),

                "route": route,

                "location": {
                    "city": location["name"],
                    "country": location.get("country"),
                    "latitude": latitude,
                    "longitude": longitude
                },

                "weather": {
                    "temperature": current["temperature_2m"],
                    "humidity": current["relative_humidity_2m"],
                    "wind_speed": current["wind_speed_10m"],
                    "condition": weather_info["condition"],
                    "description": weather_info["description"],
                    "icon": weather_info["icon"]
                }
            }

            result["response"] = (
                response_generator_service.generate_weather_response(result)
            )

            return result

        # =====================================
        # STEP 5: FORECAST
        # =====================================

        elif route == "forecast":

            weather_data = await weather_service.get_forecast(
                latitude=latitude,
                longitude=longitude,
                days=7
            )

            daily = weather_data["daily"]

            time_reference = nlu_result.get("time")

            # =====================================
            # SELECT SPECIFIC DATE
            # =====================================

            if time_reference in [
                "today",
                "tomorrow",
                "day_after_tomorrow"
            ]:

                target_date = get_target_date(time_reference)

                if target_date not in daily["time"]:

                    return {
                        "success": False,
                        "message": "Forecast data is not available for the requested date."
                    }

                index = daily["time"].index(target_date)

                weather_info = get_weather_info(
                    daily["weather_code"][index]
                )

                selected_forecast = {
                    "date": daily["time"][index],

                    "temperature_max":
                        daily["temperature_2m_max"][index],

                    "temperature_min":
                        daily["temperature_2m_min"][index],

                    "precipitation_probability":
                        daily["precipitation_probability_max"][index],

                    "condition":
                        weather_info["condition"],

                    "description":
                        weather_info["description"]
                }

                result = {

                    "success": True,

                    "intent": nlu_result.get("intent"),

                    "route": route,

                    "time": time_reference,

                    "location": {
                        "city": location["name"],
                        "country": location.get("country"),
                        "latitude": latitude,
                        "longitude": longitude
                    },

                    "forecast": selected_forecast
                }

                result["response"] = (
                    response_generator_service.generate_forecast_response(result)
                )

                return result

            # =====================================
            # RETURN MULTI-DAY FORECAST
            # =====================================

            forecast = []

            for i in range(len(daily["time"])):

                weather_info = get_weather_info(
                    daily["weather_code"][i]
                )

                forecast.append({
                    "date": daily["time"][i],
                    "temperature_max": daily["temperature_2m_max"][i],
                    "temperature_min": daily["temperature_2m_min"][i],
                    "precipitation_probability":
                        daily["precipitation_probability_max"][i],
                    "condition": weather_info["condition"],
                    "description": weather_info["description"]
                })

            return {
                "success": True,
                "intent": nlu_result.get("intent"),
                "route": route,
                "time": time_reference,
                "location": {
                    "city": location["name"],
                    "country": location.get("country"),
                    "latitude": latitude,
                    "longitude": longitude
                },

                "forecast": forecast
            }

        # =====================================
        # EXTREME WEATHER ALERT / RISK
        # =====================================

        elif route == "alert":

            risk_result = await risk_service.analyze_location(
                city=location_name,
                location_service=location_service,
                weather_service=weather_service
            )

            if not risk_result.get("success"):

                return risk_result

            overall = risk_result["overall_risk"]

            risks = risk_result["risks"]

            active_alerts = alert_service.generate_alerts(
                risks
            )

            if not active_alerts:

                alert_message = (
                    f"No significant weather risks are currently detected "
                    f"for {risk_result['location']['city']}."
                )

            else:

                alert_message = (
                    f"{overall['risk']} weather risk detected for "
                    f"{risk_result['location']['city']}."
                )

            result = {

                "success": True,
                "intent": nlu_result.get("intent"),
                "route": route,
                "location": risk_result["location"],
                "overall_risk": overall,
                "alerts": active_alerts,
                "message": alert_message,
                "weather_data": risk_result["forecast"]
            }

            result["response"] = (
                response_generator_service.generate_alert_response(result)
            )

            return result

        # =====================================
        # FARMER ADVISORY
        # =====================================

        elif route == "farmer_advisory":

            forecast_data = await weather_service.get_forecast(
                latitude=latitude,
                longitude=longitude,
                days=2
            )

            daily = forecast_data["daily"]

            # Tomorrow
            time_reference = nlu_result.get("time", "tomorrow")

            # Default farmer advisory to tomorrow
            if time_reference == "current":
                time_reference = "tomorrow"

            target_date = get_target_date(time_reference)

            if target_date not in daily["time"]:

                return {
                    "success": False,
                    "message": "Forecast data is not available for the requested date."
                }

            index = daily["time"].index(target_date)

            temperature = daily["temperature_2m_max"][index]

            rain_probability = (
                daily["precipitation_probability_max"][index]
            )

            precipitation = (
                daily["precipitation_sum"][index]
            )

            wind_speed = (
                daily["wind_speed_10m_max"][index]
            )

            # Generate agricultural advisories

            irrigation_advisory = (
                farmer_advisory_service.generate_irrigation_advisory(
                    rain_probability=rain_probability,
                    precipitation=precipitation,
                    temperature=temperature
                )
            )

            heat_advisory = (
                farmer_advisory_service.generate_heat_advisory(
                    temperature
                )
            )

            wind_advisory = (
                farmer_advisory_service.generate_wind_advisory(
                    wind_speed
                )
            )

            result = {

                "success": True,

                "intent": nlu_result.get("intent"),

                "route": route,

                "location": {
                    "city": location["name"],
                    "country": location.get("country"),
                    "latitude": latitude,
                    "longitude": longitude
                },

                "forecast": {
                    "temperature_max": temperature,
                    "rain_probability": rain_probability,
                    "precipitation": precipitation,
                    "wind_speed_max": wind_speed
                },

                "advisory": {

                    "irrigation": irrigation_advisory,

                    "heat": heat_advisory,

                    "wind": wind_advisory
                }
            }

            result["response"] = (
                response_generator_service.generate_farmer_response(result)
            )

            return result

        # =====================================
        # AVIATION ADVISORY
        # =====================================

        elif route == "aviation_advisory":

            forecast_data = await weather_service.get_forecast(
                latitude=latitude,
                longitude=longitude,
                days=2
            )

            daily = forecast_data["daily"]

            time_reference = nlu_result.get("time", "tomorrow")

            # Default aviation advisory to tomorrow
            if time_reference == "current":
                time_reference = "tomorrow"

            target_date = get_target_date(time_reference)

            if target_date not in daily["time"]:

                return {
                    "success": False,
                    "message": "Forecast data is not available for the requested date."
                }

            index = daily["time"].index(target_date)

            wind_speed = daily[
                "wind_speed_10m_max"
            ][index]

            rain_probability = daily[
                "precipitation_probability_max"
            ][index]

            precipitation = daily[
                "precipitation_sum"
            ][index]


            aviation_advisory = (
                aviation_advisory_service.generate_aviation_advisory(
                    wind_speed=wind_speed,
                    rain_probability=rain_probability,
                    precipitation=precipitation
                )
            )


            result = {

                "success": True,

                "intent": nlu_result.get("intent"),

                "route": route,

                "location": {
                    "city": location["name"],
                    "country": location.get("country"),
                    "latitude": latitude,
                    "longitude": longitude
                },

                "forecast": {
                    "wind_speed_max": wind_speed,
                    "rain_probability": rain_probability,
                    "precipitation": precipitation
                },

                "advisory": aviation_advisory
            }


            result["response"] = (
                f"✈️ Aviation Advisory for {location['name']}. "
                f"The weather risk is {aviation_advisory['risk']}. "
                f"{aviation_advisory['recommendation']}"
            )

            return result

        # =====================================
        # MARINE ADVISORY
        # =====================================

        elif route == "marine_advisory":

            forecast_data = await weather_service.get_forecast(
                latitude=latitude,
                longitude=longitude,
                days=2
            )

            daily = forecast_data["daily"]

            time_reference = nlu_result.get("time", "tomorrow")

            # Default marine advisory to tomorrow
            if time_reference == "current":
                time_reference = "tomorrow"

            target_date = get_target_date(time_reference)

            if target_date not in daily["time"]:

                return {
                    "success": False,
                    "message": "Forecast data is not available for the requested date."
                }

            index = daily["time"].index(target_date)

            wind_speed = daily[
                "wind_speed_10m_max"
            ][index]

            rain_probability = daily[
                "precipitation_probability_max"
            ][index]

            precipitation = daily[
                "precipitation_sum"
            ][index]


            marine_advisory = (
                marine_advisory_service.generate_marine_advisory(
                    wind_speed=wind_speed,
                    rain_probability=rain_probability,
                    precipitation=precipitation
                )
            )


            result = {

                "success": True,

                "intent": nlu_result.get("intent"),

                "route": route,

                "location": {
                    "city": location["name"],
                    "country": location.get("country"),
                    "latitude": latitude,
                    "longitude": longitude
                },

                "forecast": {
                    "wind_speed_max": wind_speed,
                    "rain_probability": rain_probability,
                    "precipitation": precipitation
                },

                "advisory": marine_advisory
            }


            result["response"] = (
                f"🌊 Marine Advisory for {location['name']}. "
                f"The weather risk is {marine_advisory['risk']}. "
                f"{marine_advisory['recommendation']}"
            )

            return result

        # =====================================
        # OUTDOOR ACTIVITY ADVISORY
        # =====================================

        elif route == "outdoor_advisory":

            forecast_data = await weather_service.get_forecast(
                latitude=latitude,
                longitude=longitude,
                days=2
            )

            daily = forecast_data["daily"]

            time_reference = nlu_result.get("time", "tomorrow")

            # Default outdoor advisory to tomorrow

            if time_reference == "current":
                time_reference = "tomorrow"


            target_date = get_target_date(time_reference)


            if target_date not in daily["time"]:

                return {
                    "success": False,
                    "message": (
                        "Forecast data is not available "
                        "for the requested date."
                    )
                }


            index = daily["time"].index(target_date)


            # =====================================
            # GET WEATHER VALUES
            # =====================================

            temperature = daily[
                "temperature_2m_max"
            ][index]


            rain_probability = daily[
                "precipitation_probability_max"
            ][index]


            precipitation = daily[
                "precipitation_sum"
            ][index]


            wind_speed = daily[
                "wind_speed_10m_max"
            ][index]


            # =====================================
            # GENERATE ADVISORY
            # =====================================

            advisory = outdoor_advisory_service.generate_advisory(

                temperature=temperature,

                rain_probability=rain_probability,

                precipitation=precipitation,

                wind_speed=wind_speed
            )


            # =====================================
            # RETURN RESULT
            # =====================================

            result = {

                "success": True,

                "intent": nlu_result.get("intent"),

                "route": route,

                "location": {
                    "city": location["name"],
                    "country": location.get("country"),
                    "latitude": latitude,
                    "longitude": longitude
                },

                "forecast": {

                    "temperature_max": temperature,

                    "rain_probability": rain_probability,

                    "precipitation": precipitation,

                    "wind_speed_max": wind_speed
                },

                "advisory": advisory
            }


            result["response"] = (
                f"🏞️ Outdoor Activity Advisory for "
                f"{location['name']}. "

                f"The weather risk is {advisory['risk']}. "

                f"{advisory['recommendation']}"
            )


            return result

        # =====================================
        # OTHER ROUTES
        # =====================================

        return {
            "success": True,

            "message": "Intent detected successfully. Service integration coming next.",

            "intent": nlu_result.get("intent"),

            "route": route,

            "location": location_name
        }


chat_orchestrator = ChatOrchestrator()