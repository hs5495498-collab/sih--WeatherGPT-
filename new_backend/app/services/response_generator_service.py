class ResponseGeneratorService:
    # ==========================================
    # CURRENT WEATHER RESPONSE
    # ==========================================
    def generate_weather_response(self, data):

        location = data["location"]["city"]
        weather = data["weather"]

        return (
            f"The current weather in {location} is "
            f"{weather['condition'].lower()}. "
            f"The temperature is {weather['temperature']}°C, "
            f"humidity is {weather['humidity']}%, "
            f"and wind speed is {weather['wind_speed']} km/h."
        )
    # ==========================================
    # FORECAST RESPONSE
    # ==========================================

    def generate_forecast_response(self, data):

        location = data["location"]["city"]
        forecast = data["forecast"]

        # Single day forecast
        if isinstance(forecast, dict):

            return (
                f"The forecast for {location} on "
                f"{forecast['date']} shows "
                f"{forecast['condition'].lower()} conditions. "
                f"The maximum temperature will be "
                f"{forecast['temperature_max']}°C and the minimum "
                f"temperature will be {forecast['temperature_min']}°C. "
                f"The probability of rain is "
                f"{forecast['precipitation_probability']}%."
            )

        # Multiple-day forecast
        return (
            f"Here is the weather forecast for {location}. "
            f"You can check the daily forecast details."
        )
    # ==========================================
    # WEATHER ALERT RESPONSE
    # ==========================================

    def generate_alert_response(self, data):

        location = data["location"]["city"]

        overall_risk = data["overall_risk"]

        alerts = data.get("alerts", [])

        if not alerts:

            return (
                f"No significant dangerous weather conditions are "
                f"currently detected for {location}."
            )

        alert_messages = []

        for alert in alerts:

            alert_messages.append(
                alert["message"]
            )

        return (
            f"⚠️ Weather alert for {location}. "
            f"The overall weather risk is "
            f"{overall_risk['risk']}. "
            + " ".join(alert_messages)
        )
    # ==========================================
    # FARMER ADVISORY RESPONSE
    # ==========================================

    def generate_farmer_response(self, data):

        location = data["location"]["city"]

        forecast = data["forecast"]

        advisory = data["advisory"]

        irrigation = advisory["irrigation"]

        heat = advisory["heat"]

        wind = advisory["wind"]

        return (
            f"🌾 Farmer Advisory for {location}. "

            f"The maximum temperature is expected to be "
            f"{forecast['temperature_max']}°C. "

            f"The probability of rain is "
            f"{forecast['rain_probability']}%, with expected "
            f"precipitation of {forecast['precipitation']} mm. "

            f"The maximum wind speed may reach "
            f"{forecast['wind_speed_max']} km/h. "

            f"💧 Irrigation: {irrigation['message']} "

            f"🌡️ Heat: {heat['message']} "

            f"💨 Wind: {wind['message']}"
        )


response_generator_service = ResponseGeneratorService()