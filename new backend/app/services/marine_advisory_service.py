class MarineAdvisoryService:

    def generate_marine_advisory(
        self,
        wind_speed: float,
        rain_probability: float,
        precipitation: float
    ):

        risk_score = 0

        issues = []

        # =====================================
        # WIND CONDITIONS
        # =====================================

        if wind_speed >= 40:

            risk_score += 50

            issues.append(
                "Strong winds may create dangerous sea conditions."
            )

        elif wind_speed >= 25:

            risk_score += 25

            issues.append(
                "Moderate winds may create rough sea conditions."
            )


        # =====================================
        # RAIN CONDITIONS
        # =====================================

        if rain_probability >= 80:

            risk_score += 30

            issues.append(
                "Heavy rainfall may reduce visibility at sea."
            )

        elif rain_probability >= 50:

            risk_score += 15

            issues.append(
                "Rain may affect marine activities."
            )


        # =====================================
        # HEAVY PRECIPITATION
        # =====================================

        if precipitation >= 20:

            risk_score += 30

            issues.append(
                "Heavy precipitation may create unsafe marine conditions."
            )


        # =====================================
        # DETERMINE RISK
        # =====================================

        if risk_score >= 60:

            risk = "HIGH"

            recommendation = (
                "Marine conditions may be dangerous. "
                "Avoid going to sea unless advised otherwise by local authorities."
            )

        elif risk_score >= 30:

            risk = "MODERATE"

            recommendation = (
                "Marine conditions may be challenging. "
                "Exercise caution and monitor official weather warnings."
            )

        else:

            risk = "LOW"

            recommendation = (
                "Weather conditions are generally suitable for marine activities."
            )


        return {

            "risk": risk,

            "score": risk_score,

            "issues": issues,

            "recommendation": recommendation
        }


marine_advisory_service = MarineAdvisoryService()