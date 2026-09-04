class DomainAdvisoryService:

    def generate_advisory(
        self,
        domain: str,
        temperature=None,
        humidity=None,
        wind_speed=None,
        rain_probability=None
    ):

        domain = domain.lower()

        if domain == "farmer":
            return self.farmer_advisory(
                temperature,
                humidity,
                wind_speed,
                rain_probability
            )

        elif domain == "aviation":
            return self.aviation_advisory(
                temperature,
                humidity,
                wind_speed,
                rain_probability
            )

        elif domain == "marine":
            return self.marine_advisory(
                temperature,
                humidity,
                wind_speed,
                rain_probability
            )

        elif domain in ["urban", "public", "general"]:
            return self.urban_advisory(
                temperature,
                humidity,
                wind_speed,
                rain_probability
            )

        else:
            return [
                "Unknown advisory domain. "
                "Available domains are farmer, aviation, marine, and urban."
            ]


    def farmer_advisory(
        self,
        temperature,
        humidity,
        wind_speed,
        rain_probability
    ):

        advisories = []

        if rain_probability is not None:

            if rain_probability >= 70:
                advisories.append(
                    "High probability of rainfall. Avoid unnecessary irrigation "
                    "and ensure proper drainage in agricultural fields."
                )

            elif rain_probability >= 40:
                advisories.append(
                    "Rainfall is possible. Monitor field conditions before irrigation."
                )

            else:
                advisories.append(
                    "Low probability of rainfall. Check soil moisture before irrigation."
                )

        if temperature is not None and temperature >= 40:

            advisories.append(
                "Extreme heat conditions may cause crop stress. "
                "Ensure adequate irrigation and protect sensitive crops."
            )

        elif temperature is not None and temperature >= 35:

            advisories.append(
                "High temperatures may increase water requirements for crops."
            )

        if wind_speed is not None and wind_speed >= 40:

            advisories.append(
                "Strong winds may damage crops and agricultural structures. "
                "Secure lightweight equipment."
            )

        if not advisories:
            advisories.append(
                "Weather conditions appear generally suitable for normal farming activities."
            )

        return advisories


    def aviation_advisory(
        self,
        temperature,
        humidity,
        wind_speed,
        rain_probability
    ):

        advisories = []

        if wind_speed is not None:

            if wind_speed >= 50:
                advisories.append(
                    "Strong wind conditions detected. Aviation operations should "
                    "monitor wind conditions and official aviation weather reports."
                )

            elif wind_speed >= 30:
                advisories.append(
                    "Moderate winds may affect flight operations. "
                    "Monitor local aviation weather information."
                )

        if rain_probability is not None and rain_probability >= 70:

            advisories.append(
                "High probability of rainfall. Reduced visibility and wet runway "
                "conditions may occur."
            )

        elif rain_probability is not None and rain_probability >= 40:

            advisories.append(
                "Rainfall is possible. Monitor visibility and runway conditions."
            )

        if temperature is not None and temperature >= 40:

            advisories.append(
                "High temperatures may affect aircraft performance. "
                "Follow standard operational procedures."
            )

        if not advisories:
            advisories.append(
                "No major weather-related risks detected for general aviation activity."
            )

        return advisories


    def marine_advisory(
        self,
        temperature,
        humidity,
        wind_speed,
        rain_probability
    ):

        advisories = []

        if wind_speed is not None:

            if wind_speed >= 50:

                advisories.append(
                    "Strong winds detected. Marine operators should monitor "
                    "official marine weather warnings before departure."
                )

            elif wind_speed >= 30:

                advisories.append(
                    "Moderate winds may affect sea conditions. "
                    "Exercise caution during marine activities."
                )

        if rain_probability is not None and rain_probability >= 70:

            advisories.append(
                "Heavy rainfall may reduce visibility. "
                "Monitor weather updates during marine operations."
            )

        elif rain_probability is not None and rain_probability >= 40:

            advisories.append(
                "Rainfall is possible. Ensure appropriate safety precautions."
            )

        if not advisories:

            advisories.append(
                "No major weather risks detected for general marine activity."
            )

        return advisories


    def urban_advisory(
        self,
        temperature,
        humidity,
        wind_speed,
        rain_probability
    ):

        advisories = []

        if temperature is not None:

            if temperature >= 40:

                advisories.append(
                    "Extreme heat conditions possible. Avoid prolonged outdoor "
                    "exposure and stay hydrated."
                )

            elif temperature >= 35:

                advisories.append(
                    "High temperature expected. Avoid outdoor activity during "
                    "peak afternoon hours."
                )

        if rain_probability is not None:

            if rain_probability >= 70:

                advisories.append(
                    "Heavy rainfall is possible. Avoid waterlogged areas and "
                    "monitor local weather warnings."
                )

            elif rain_probability >= 40:

                advisories.append(
                    "Rainfall is possible. Carry appropriate rain protection."
                )

        if wind_speed is not None and wind_speed >= 50:

            advisories.append(
                "Strong winds possible. Secure loose outdoor objects and avoid "
                "unsafe structures."
            )

        if not advisories:

            advisories.append(
                "Weather conditions appear suitable for normal daily activities."
            )

        return advisories


domain_advisory_service = DomainAdvisoryService()