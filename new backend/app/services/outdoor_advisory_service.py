class OutdoorAdvisoryService:

    def generate_advisory(
        self,
        temperature: float,
        rain_probability: float,
        precipitation: float,
        wind_speed: float
    ):

        score = 0
        issues = []

        # =====================================
        # RAIN CONDITIONS
        # =====================================

        if rain_probability >= 80:

            score += 30

            issues.append(
                "A high probability of rain may affect outdoor activities."
            )

        elif rain_probability >= 50:

            score += 15

            issues.append(
                "Rain is possible during outdoor activities."
            )


        # =====================================
        # HEAVY PRECIPITATION
        # =====================================

        if precipitation >= 20:

            score += 30

            issues.append(
                "Heavy rainfall may make outdoor conditions unsafe."
            )

        elif precipitation >= 10:

            score += 15

            issues.append(
                "Moderate rainfall may affect outdoor plans."
            )


        # =====================================
        # HIGH TEMPERATURE
        # =====================================

        if temperature >= 42:

            score += 30

            issues.append(
                "Extreme heat may create unsafe outdoor conditions."
            )

        elif temperature >= 38:

            score += 20

            issues.append(
                "High temperatures may cause heat stress."
            )

        elif temperature >= 35:

            score += 10

            issues.append(
                "Warm weather may cause discomfort during outdoor activities."
            )


        # =====================================
        # WIND CONDITIONS
        # =====================================

        if wind_speed >= 50:

            score += 30

            issues.append(
                "Strong winds may create dangerous outdoor conditions."
            )

        elif wind_speed >= 30:

            score += 15

            issues.append(
                "Strong winds may affect outdoor activities."
            )


        # =====================================
        # DETERMINE RISK LEVEL
        # =====================================

        if score >= 60:

            risk = "HIGH"

            recommendation = (
                "Outdoor activities are not recommended. "
                "Consider postponing your plans."
            )

        elif score >= 30:

            risk = "MODERATE"

            recommendation = (
                "Outdoor activities may be affected by weather conditions. "
                "Exercise caution and monitor the weather."
            )

        else:

            risk = "LOW"

            recommendation = (
                "Weather conditions are generally suitable "
                "for outdoor activities."
            )


        return {

            "risk": risk,

            "score": score,

            "issues": issues,

            "recommendation": recommendation
        }


outdoor_advisory_service = OutdoorAdvisoryService()