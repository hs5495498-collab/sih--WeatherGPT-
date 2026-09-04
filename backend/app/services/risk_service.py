class RiskService:

    def get_risk_level(self, score: int):

        if score >= 80:
            return "SEVERE"

        elif score >= 60:
            return "HIGH"

        elif score >= 30:
            return "MODERATE"

        return "LOW"


    def calculate_heat_risk(self, temperature):

        if temperature is None:
            return {
                "risk": "UNKNOWN",
                "score": 0,
                "message": "Temperature data is unavailable."
            }

        if temperature >= 45:

            return {
                "risk": "SEVERE",
                "score": 90,
                "message": (
                    "Extreme heat conditions detected. "
                    "Avoid outdoor exposure and stay hydrated."
                )
            }

        elif temperature >= 40:

            return {
                "risk": "HIGH",
                "score": 70,
                "message": (
                    "Very high temperature detected. "
                    "Limit outdoor activities."
                )
            }

        elif temperature >= 35:

            return {
                "risk": "MODERATE",
                "score": 40,
                "message": (
                    "High temperature conditions detected. "
                    "Take precautions against heat exposure."
                )
            }

        return {
            "risk": "LOW",
            "score": 10,
            "message": "No significant heat risk detected."
        }


    def calculate_rain_risk(
        self,
        rain_probability,
        precipitation
    ):

        rain_probability = rain_probability or 0
        precipitation = precipitation or 0

        if precipitation >= 50:

            return {
                "risk": "SEVERE",
                "score": 90,
                "message": (
                    "Very heavy rainfall may occur. "
                    "Avoid flood-prone areas and monitor official warnings."
                )
            }

        elif precipitation >= 25:

            return {
                "risk": "HIGH",
                "score": 70,
                "message": (
                    "Heavy rainfall may occur. "
                    "Stay updated with weather alerts."
                )
            }

        elif precipitation >= 10:

            return {
                "risk": "MODERATE",
                "score": 40,
                "message": (
                    "Moderate rainfall may occur."
                )
            }

        elif rain_probability >= 70:

            return {
                "risk": "LOW",
                "score": 20,
                "message": (
                    "Rain is likely, but heavy rainfall is not currently expected."
                )
            }

        return {
            "risk": "LOW",
            "score": 10,
            "message": "No significant rainfall risk detected."
        }



    def calculate_wind_risk(self, wind_speed):

        if wind_speed is None:

            return {
                "risk": "UNKNOWN",
                "score": 0,
                "message": "Wind data is unavailable."
            }

        if wind_speed >= 80:

            return {
                "risk": "SEVERE",
                "score": 90,
                "message": (
                    "Extremely strong winds detected. "
                    "Avoid outdoor activities and follow official warnings."
                )
            }

        elif wind_speed >= 60:

            return {
                "risk": "HIGH",
                "score": 70,
                "message": (
                    "Strong winds detected. "
                    "Secure outdoor objects and avoid unsafe structures."
                )
            }

        elif wind_speed >= 35:

            return {
                "risk": "MODERATE",
                "score": 40,
                "message": (
                    "Moderately strong winds detected."
                )
            }

        return {
            "risk": "LOW",
            "score": 10,
            "message": "No significant wind risk detected."
        }



    def calculate_flood_risk(
        self,
        rain_probability,
        precipitation
    ):

        rain_probability = rain_probability or 0
        precipitation = precipitation or 0

        if precipitation >= 75:

            return {
                "risk": "SEVERE",
                "score": 90,
                "message": (
                    "Very heavy rainfall may create serious flooding conditions. "
                    "Avoid low-lying areas and follow official warnings."
                )
            }

        elif precipitation >= 50:

            return {
                "risk": "HIGH",
                "score": 70,
                "message": (
                    "Heavy rainfall may increase localized flooding risk."
                )
            }

        elif precipitation >= 25:

            return {
                "risk": "MODERATE",
                "score": 40,
                "message": (
                    "Localized waterlogging may be possible."
                )
            }

        return {
            "risk": "LOW",
            "score": 10,
            "message": (
                "No significant flood risk indicated by the forecast."
            )
        }



    def calculate_overall_risk(
        self,
        heat_risk,
        rain_risk,
        wind_risk,
        flood_risk
    ):

        scores = [
            heat_risk["score"],
            rain_risk["score"],
            wind_risk["score"],
            flood_risk["score"]
        ]

        highest_score = max(scores)

        overall_risk = self.get_risk_level(highest_score)

        return {
            "risk": overall_risk,
            "score": highest_score
        }

    async def analyze_location(
        self,
        city: str,
        location_service,
        weather_service
    ):
        # -----------------------------------------
        # Find location
        # -----------------------------------------

        location = await location_service.resolve_location(
            city
        )

        if not location:
            return {
                "success": False,
                "message": f"Location '{city}' could not be found."
            }

        latitude = location["latitude"]
        longitude = location["longitude"]

        # -----------------------------------------
        # Current weather
        # -----------------------------------------

        weather_data = await weather_service.get_current_weather(
            latitude=latitude,
            longitude=longitude
        )

        current = weather_data["current"]

        # -----------------------------------------
        # Tomorrow forecast
        # -----------------------------------------

        forecast_data = await weather_service.get_forecast(
            latitude=latitude,
            longitude=longitude,
            days=2
        )

        daily = forecast_data["daily"]

        tomorrow_index = 1

        rain_probability_data = daily.get(
            "precipitation_probability_max",
            []
        )

        precipitation_data = daily.get(
            "precipitation_sum",
            []
        )

        wind_data = daily.get(
            "wind_speed_10m_max",
            []
        )

        temperature_data = daily.get(
            "temperature_2m_max",
            []
        )

        rain_probability = (
            rain_probability_data[tomorrow_index]
            if len(rain_probability_data) > tomorrow_index
            else 0
        )

        precipitation = (
            precipitation_data[tomorrow_index]
            if len(precipitation_data) > tomorrow_index
            else 0
        )

        forecast_wind = (
            wind_data[tomorrow_index]
            if len(wind_data) > tomorrow_index
            else current.get("wind_speed_10m")
        )

        forecast_temperature = (
            temperature_data[tomorrow_index]
            if len(temperature_data) > tomorrow_index
            else current.get("temperature_2m")
        )

        # -----------------------------------------
        # Risk calculations
        # -----------------------------------------

        heat_risk = self.calculate_heat_risk(
            forecast_temperature
        )

        rain_risk = self.calculate_rain_risk(
            rain_probability,
            precipitation
        )

        wind_risk = self.calculate_wind_risk(
            forecast_wind
        )

        flood_risk = self.calculate_flood_risk(
            rain_probability,
            precipitation
        )

        overall_risk = self.calculate_overall_risk(
            heat_risk,
            rain_risk,
            wind_risk,
            flood_risk
        )

        return {
            "success": True,

            "location": {
                "city": location["name"],
                "state": location.get("admin1"),
                "country": location.get("country"),
                "latitude": latitude,
                "longitude": longitude
            },

            "forecast": {
                "temperature_max": forecast_temperature,
                "wind_speed_max": forecast_wind,
                "rain_probability": rain_probability,
                "precipitation": precipitation
            },

            "risks": {
                "heat": heat_risk,
                "rain": rain_risk,
                "wind": wind_risk,
                "flood": flood_risk
            },

            "overall_risk": overall_risk
        }


risk_service = RiskService()