WEATHER_CODES = {
    0: {
        "condition": "Clear",
        "description": "Clear sky",
        "icon": "clear"
    },
    1: {
        "condition": "Mainly Clear",
        "description": "Mainly clear",
        "icon": "clear"
    },
    2: {
        "condition": "Partly Cloudy",
        "description": "Partly cloudy",
        "icon": "partly_cloudy"
    },
    3: {
        "condition": "Cloudy",
        "description": "Overcast",
        "icon": "cloudy"
    },
    45: {
        "condition": "Fog",
        "description": "Foggy conditions",
        "icon": "fog"
    },
    48: {
        "condition": "Fog",
        "description": "Depositing rime fog",
        "icon": "fog"
    },
    51: {
        "condition": "Drizzle",
        "description": "Light drizzle",
        "icon": "drizzle"
    },
    53: {
        "condition": "Drizzle",
        "description": "Moderate drizzle",
        "icon": "drizzle"
    },
    55: {
        "condition": "Drizzle",
        "description": "Heavy drizzle",
        "icon": "drizzle"
    },
    61: {
        "condition": "Rain",
        "description": "Slight rain",
        "icon": "rain"
    },
    63: {
        "condition": "Rain",
        "description": "Moderate rain",
        "icon": "rain"
    },
    65: {
        "condition": "Rain",
        "description": "Heavy rain",
        "icon": "heavy_rain"
    },
    71: {
        "condition": "Snow",
        "description": "Slight snowfall",
        "icon": "snow"
    },
    73: {
        "condition": "Snow",
        "description": "Moderate snowfall",
        "icon": "snow"
    },
    75: {
        "condition": "Snow",
        "description": "Heavy snowfall",
        "icon": "snow"
    },
    80: {
        "condition": "Rain Showers",
        "description": "Slight rain showers",
        "icon": "rain"
    },
    81: {
        "condition": "Rain Showers",
        "description": "Moderate rain showers",
        "icon": "rain"
    },
    82: {
        "condition": "Heavy Rain Showers",
        "description": "Violent rain showers",
        "icon": "heavy_rain"
    },
    95: {
        "condition": "Thunderstorm",
        "description": "Thunderstorm",
        "icon": "thunderstorm"
    },
    96: {
        "condition": "Thunderstorm",
        "description": "Thunderstorm with slight hail",
        "icon": "thunderstorm"
    },
    99: {
        "condition": "Thunderstorm",
        "description": "Thunderstorm with heavy hail",
        "icon": "thunderstorm"
    }
}


def get_weather_info(weather_code: int):
    return WEATHER_CODES.get(
        weather_code,
        {
            "condition": "Unknown",
            "description": "Weather information unavailable",
            "icon": "unknown"
        }
    )