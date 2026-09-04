class AlertService:

    def generate_alerts(self, risks: dict):

        alerts = []

        for risk_type, risk_data in risks.items():

            risk_level = risk_data.get("risk")
            score = risk_data.get("score", 0)

            # Ignore low and unknown risks
            if risk_level in ["LOW", "UNKNOWN"]:
                continue

            alert = self.create_alert(
                risk_type=risk_type,
                risk_level=risk_level,
                score=score,
                message=risk_data.get("message", "")
            )

            alerts.append(alert)

        return alerts


    def create_alert(
        self,
        risk_type: str,
        risk_level: str,
        score: int,
        message: str
    ):

        alert_titles = {

            "heat": "Extreme Heat Alert",

            "rain": "Heavy Rainfall Alert",

            "wind": "Strong Wind Alert",

            "flood": "Flood Risk Alert"
        }


        title = alert_titles.get(
            risk_type,
            "Weather Alert"
        )


        recommendations = self.get_recommendations(
            risk_type,
            risk_level
        )


        return {

            "type": risk_type.upper(),

            "title": title,

            "severity": risk_level,

            "score": score,

            "message": message,

            "recommendations": recommendations
        }


    def get_recommendations(
        self,
        risk_type: str,
        risk_level: str
    ):

        recommendations = {

            "heat": [

                "Stay hydrated.",

                "Avoid prolonged outdoor exposure.",

                "Avoid strenuous activities during peak heat."
            ],

            "rain": [

                "Carry appropriate rain protection.",

                "Avoid unnecessary travel during heavy rainfall.",

                "Monitor local weather updates."
            ],

            "wind": [

                "Secure loose outdoor objects.",

                "Avoid standing near unstable structures.",

                "Follow local safety instructions."
            ],

            "flood": [

                "Avoid flooded roads and low-lying areas.",

                "Do not attempt to cross flooded streets.",

                "Monitor official emergency warnings."
            ]
        }


        return recommendations.get(
            risk_type,
            [
                "Monitor weather conditions.",
                "Follow official safety instructions."
            ]
        )


alert_service = AlertService()