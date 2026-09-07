class AviationAdvisoryService:

    def generate_aviation_advisory(
        self,
        wind_speed: float,
        rain_probability: float,
        precipitation: float
    ):

        risk_score = 0

        issues = []

        # =====================================
        # WIND ANALYSIS
        # =====================================

        if wind_speed >= 50:

            risk_score += 50

            issues.append(
                "Strong winds may affect flight operations."
            )

        elif wind_speed >= 30:

            risk_score += 25

            issues.append(
                "Moderate winds may cause flight delays."
            )


        # =====================================
        # RAIN ANALYSIS
        # =====================================

        if rain_probability >= 80:

            risk_score += 30

            issues.append(
                "Heavy rainfall conditions may affect visibility and operations."
            )

        elif rain_probability >= 50:

            risk_score += 15

            issues.append(
                "Rain may cause minor flight delays."
            )


        # =====================================
        # PRECIPITATION ANALYSIS
        # =====================================

        if precipitation >= 20:

            risk_score += 30

            issues.append(
                "Heavy precipitation may significantly affect aviation conditions."
            )


        # =====================================
        # FINAL RISK LEVEL
        # =====================================

        if risk_score >= 60:

            risk = "HIGH"

            recommendation = (
                "Aviation conditions may be unsafe. "
                "Passengers should monitor airline and airport updates."
            )

        elif risk_score >= 30:

            risk = "MODERATE"

            recommendation = (
                "Some weather-related disruptions may occur."
            )

        else:

            risk = "LOW"

            recommendation = (
                "Weather conditions are generally suitable for aviation."
            )


        return {

            "risk": risk,

            "score": risk_score,

            "issues": issues,

            "recommendation": recommendation
        }


aviation_advisory_service = AviationAdvisoryService()