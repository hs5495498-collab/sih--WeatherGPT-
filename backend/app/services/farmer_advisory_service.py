class FarmerAdvisoryService:

    # =====================================
    # IRRIGATION ADVISORY
    # =====================================

    def generate_irrigation_advisory(
        self,
        rain_probability,
        precipitation,
        temperature
    ):

        rain_probability = rain_probability or 0
        precipitation = precipitation or 0
        temperature = temperature or 0

        if precipitation >= 20:

            return {
                "action": "DO_NOT_IRRIGATE",
                "priority": "HIGH",
                "message": (
                    "Avoid irrigation because significant rainfall "
                    "is expected."
                )
            }

        elif rain_probability >= 70:

            return {
                "action": "DELAY_IRRIGATION",
                "priority": "MEDIUM",
                "message": (
                    "Rain is likely. Consider delaying irrigation "
                    "and monitor local conditions."
                )
            }

        elif temperature >= 35:

            return {
                "action": "IRRIGATION_RECOMMENDED",
                "priority": "HIGH",
                "message": (
                    "Hot conditions are expected with limited rainfall. "
                    "Irrigation may be required."
                )
            }

        return {
            "action": "MONITOR_CONDITIONS",
            "priority": "LOW",
            "message": (
                "No immediate irrigation recommendation. "
                "Monitor soil moisture and local crop conditions."
            )
        }


    # =====================================
    # HEAT ADVISORY
    # =====================================

    def generate_heat_advisory(self, temperature):

        temperature = temperature or 0

        if temperature >= 40:

            return {
                "risk": "HIGH",
                "message": (
                    "High heat may cause crop stress. "
                    "Ensure adequate irrigation and avoid field work "
                    "during peak afternoon hours."
                )
            }

        elif temperature >= 35:

            return {
                "risk": "MODERATE",
                "message": (
                    "Warm conditions may increase crop water requirements."
                )
            }

        return {
            "risk": "LOW",
            "message": (
                "No significant heat stress is expected."
            )
        }


    # =====================================
    # WIND ADVISORY
    # =====================================

    def generate_wind_advisory(self, wind_speed):

        wind_speed = wind_speed or 0

        if wind_speed >= 50:

            return {
                "risk": "HIGH",
                "message": (
                    "Strong winds are expected. Avoid pesticide spraying "
                    "and secure vulnerable crops or structures."
                )
            }

        elif wind_speed >= 30:

            return {
                "risk": "MODERATE",
                "message": (
                    "Moderate winds are expected. "
                    "Be cautious when spraying pesticides."
                )
            }

        return {
            "risk": "LOW",
            "message": (
                "Wind conditions are generally suitable for farm activities."
            )
        }


    # =====================================
    # COMBINED FARMER ADVISORY
    # NEW METHOD
    # =====================================

    def generate_advisory(
        self,
        temperature,
        rain_probability,
        precipitation,
        wind_speed
    ):

        irrigation = self.generate_irrigation_advisory(
            rain_probability=rain_probability,
            precipitation=precipitation,
            temperature=temperature
        )

        heat = self.generate_heat_advisory(
            temperature=temperature
        )

        wind = self.generate_wind_advisory(
            wind_speed=wind_speed
        )

        # =====================================
        # CALCULATE OVERALL RISK
        # =====================================

        risk_scores = {
            "LOW": 0,
            "MODERATE": 30,
            "HIGH": 60
        }

        score = 0

        score = max(
            risk_scores.get(heat["risk"], 0),
            risk_scores.get(wind["risk"], 0)
        )

        # Irrigation priority also affects risk

        if irrigation["priority"] == "HIGH":
            score = max(score, 60)

        elif irrigation["priority"] == "MEDIUM":
            score = max(score, 30)


        # =====================================
        # DETERMINE OVERALL RISK
        # =====================================

        if score >= 60:

            overall_risk = "HIGH"

            recommendation = (
                "Weather conditions may significantly affect farming "
                "activities. Take necessary precautions."
            )

        elif score >= 30:

            overall_risk = "MODERATE"

            recommendation = (
                "Plan farming activities carefully and monitor "
                "weather conditions."
            )

        else:

            overall_risk = "LOW"

            recommendation = (
                "Weather conditions are generally suitable for "
                "normal farming activities."
            )


        return {

            "overall_risk": overall_risk,
            "score": score,
            "recommendation": recommendation,
            "irrigation": irrigation,
            "heat": heat,
            "wind": wind
        }


farmer_advisory_service = FarmerAdvisoryService()