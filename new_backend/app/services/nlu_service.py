import re
from typing import Dict, Any


class NLUService:

    async def process_query(self, message: str) -> Dict[str, Any]:
        """
        Temporary rule-based NLU.

        This will later be replaced by the trained ML NLU model.
        """

        message_lower = message.lower()

        intent = self.detect_intent(message_lower)
        location = self.extract_location(message)
        time = self.extract_time(message_lower)
        domain = self.detect_domain(message_lower)

        return {
            "intent": intent,
            "location": location,
            "time": time,
            "domain": domain,
            "confidence": 0.75
        }

    def detect_intent(self, message: str) -> str:

        message = message.lower()
        # ==========================================
        # ALERT / DANGEROUS WEATHER
        # Must be checked BEFORE current weather
        # ==========================================

        alert_keywords = [
            "alert",
            "warning",
            "dangerous",
            "danger",
            "risk",
            "cyclone",
            "storm warning",
            "extreme weather",
            "disaster",
            "flood"
        ]

        if any(keyword in message for keyword in alert_keywords):
            return "weather_alert"

        # Farmer advisory should be checked first
        if any(word in message for word in [
            "farmer",
            "farmers",
            "farm",
            "farming",
            "farm activity",
            "farm activities",
            "crop",
            "crops",
            "irrigate",
            "irrigation",
            "agriculture",
            "agricultural",
            "harvest",
            "cultivation",
            "planting",
            "sowing"
        ]):
            return "farmer_advisory"

        # Weather alerts
        if any(word in message for word in [
            "alert", "warning", "cyclone",
            "flood", "heatwave", "storm"
        ]):
            return "weather_alert"

        # Forecast
        if any(word in message for word in [
            "forecast", "tomorrow", "next week",
            "will it rain", "will it be"
        ]):
            return "forecast"

        # Current weather
        if any(word in message for word in [
            "temperature", "weather", "current weather",
            "how hot", "how cold", "weather now"
        ]):
            return "current_weather"

        return "unknown"

    def detect_domain(self, message: str) -> str:

        if any(word in message for word in [
            "crop",
            "farmer",
            "farmers",
            "farm",
            "farming",
            "agriculture",
            "agricultural",
            "irrigation",
            "irrigate",
            "harvest",
            "cultivation",
            "planting",
            "sowing"

        ]):
            return "farmer"

        if any(word in message for word in [
            "flight",
            "flights",
            "fly",
            "flying",
            "aviation",
            "airport",
            "pilot",
            "air travel",
            "airplane",
            "plane"
        ]):
            return "aviation"

        if any(word in message for word in [
            "boat",
            "ship",
            "marine",
            "sea",
            "fishing",
            "fish",
            "fisherman",
            "fishermen",
            "fisher",
            "sailing",
            "sail",
            "go to sea",
            "ocean"
        ]):
            return "marine"

        # =====================================
        # OUTDOOR ACTIVITIES
        # =====================================

        if any(word in message for word in [

            "outdoor",
            "outdoors",
            "outside",
            "play cricket",
            "cricket",
            "football",
            "picnic",
            "hiking",
            "trekking",
            "walking",
            "jogging",
            "running",
            "cycling",
            "camping"

        ]):

            return "outdoor"

        return "general"

    def extract_time(self, message: str) -> str:

        # Check longer phrases FIRST
        if "day after tomorrow" in message:
            return "day_after_tomorrow"

        if "tomorrow" in message:
            return "tomorrow"

        if "today" in message:
            return "today"

        if "next week" in message:
            return "next_week"

        return "current"
    
    def extract_location(self, message: str):

        message = message.strip()

        # ==========================================
        # PATTERN 1: "weather in Delhi"
        # "forecast for Mumbai"
        # "temperature at Jaipur"
        # ==========================================

        patterns = [

            r"\bin\s+([A-Za-z\s]+?)(?:\?|$)",

            r"\bat\s+([A-Za-z\s]+?)(?:\?|$)",

            r"\bfor\s+([A-Za-z\s]+?)(?:\?|$)",

            r"\bof\s+([A-Za-z\s]+?)(?:\?|$)"
        ]

        for pattern in patterns:

            match = re.search(
                pattern,
                message,
                re.IGNORECASE
            )

            if match:
                location = match.group(1).strip()
                location = self.clean_location(location)

                if location:
                    return location
        # ==========================================
        # PATTERN 2:
        # "Weather Delhi"
        # "Forecast Mumbai"
        # ==========================================

        patterns = [

            r"^(?:weather|forecast|temperature|rain|humidity|wind)\s+([A-Za-z\s]+)$",
            r"^([A-Za-z\s]+)\s+(?:weather|forecast)$"
        ]

        for pattern in patterns:
            match = re.search(
                pattern,
                message,
                re.IGNORECASE
            )
            if match:
                location = self.clean_location(match.group(1))
                return location or None
        return None

    def clean_location(self, location: str) -> str:

        location = re.sub(
            r"\b(today|tomorrow|now|please)\b",
            "",
            location,
            flags=re.IGNORECASE
        )

        location = re.sub(
            r"^(?:of|in|at|for|the)\s+",
            "",
            location,
            flags=re.IGNORECASE
        )

        return re.sub(r"\s+", " ", location).strip(" ,.?\t\n")
    
nlu_service = NLUService()