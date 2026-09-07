class AdvisoryService:

    def generate_advisory(
        self,
        temperature=None,
        humidity=None,
        wind_speed=None,
        rain_probability=None
    ):

        advisories = []

        # 🌡️ High Temperature
        if temperature is not None and temperature >= 40:
            advisories.append(
                "Extreme heat conditions are possible. "
                "Avoid prolonged exposure to direct sunlight and stay hydrated."
            )

        elif temperature is not None and temperature >= 35:
            advisories.append(
                "High temperature conditions are expected. "
                "Stay hydrated and avoid outdoor activities during peak afternoon hours."
            )

        # 🥶 Cold Temperature
        if temperature is not None and temperature <= 10:
            advisories.append(
                "Cold weather conditions are expected. "
                "Wear appropriate warm clothing."
            )

        # 🌧️ Heavy Rain Probability
        if rain_probability is not None and rain_probability >= 70:
            advisories.append(
                "There is a high probability of rainfall. "
                "Carry rain protection and monitor local weather alerts."
            )

        elif rain_probability is not None and rain_probability >= 40:
            advisories.append(
                "Rainfall is possible. "
                "Consider carrying an umbrella or raincoat."
            )

        # 💨 Strong Wind
        if wind_speed is not None and wind_speed >= 50:
            advisories.append(
                "Strong winds are expected. "
                "Avoid unsecured outdoor structures and monitor official warnings."
            )

        # 💧 High Humidity
        if humidity is not None and humidity >= 80:
            advisories.append(
                "High humidity may make the weather feel uncomfortable. "
                "Stay hydrated and avoid excessive physical activity."
            )

        # Default
        if not advisories:
            advisories.append(
                "Weather conditions appear normal. Continue monitoring updates for changes."
            )

        return advisories


advisory_service = AdvisoryService()