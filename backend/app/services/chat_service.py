import re


class ChatService:

    # INTENT DETECTION
    # ----------------------------------------

    def detect_intent(self, message: str):

        message = message.lower()

        # Rain
        if any(word in message for word in [
            "rain",
            "raining",
            "rainfall",
            "precipitation"
        ]):
            return "rain"

        # Temperature
        if any(word in message for word in [
            "temperature",
            "temp",
            "hot",
            "cold",
            "heat"
        ]):
            return "temperature"

        # Humidity
        if any(word in message for word in [
            "humidity",
            "humid"
        ]):
            return "humidity"

        # Wind
        if any(word in message for word in [
            "wind",
            "windy",
            "breeze"
        ]):
            return "wind"

        # Forecast
        if any(word in message for word in [
            "forecast",
            "tomorrow",
            "next week",
            "this week",
            "coming days"
        ]):
            return "forecast"

        # General Weather
        if any(word in message for word in [
            "weather",
            "mausam"
        ]):
            return "weather"

        return "unknown"

    # TIME DETECTION
    # ----------------------------------------

    def detect_time(self, message: str):

        message = message.lower()

        if "tomorrow" in message:
            return "tomorrow"

        if "next week" in message:
            return "next_week"

        if "this week" in message:
            return "this_week"

        if "today" in message:
            return "today"

        if "now" in message or "currently" in message:
            return "current"

        return "current"
    # ----------------------------------------
    # LOCATION EXTRACTION
    # ----------------------------------------

    def extract_location_candidate(self, message: str):

        patterns = [

            r"\bin\s+([a-zA-Z\s]+?)(?:\?|$)",

            r"\bfor\s+([a-zA-Z\s]+?)(?:\?|$)",

            r"\bat\s+([a-zA-Z\s]+?)(?:\?|$)"
        ]

        for pattern in patterns:

            match = re.search(
                pattern,
                message,
                re.IGNORECASE
            )

            if match:

                location = match.group(1).strip()

                # Remove unnecessary time words
                location = re.sub(
                    r"\b(today|tomorrow|now|currently|this week|next week)\b",
                    "",
                    location,
                    flags=re.IGNORECASE
                ).strip()

                if location:
                    return location.title()

        return None

chat_service = ChatService()
