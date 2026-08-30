from pydantic import BaseModel
from typing import List


class Location(BaseModel):
    latitude: float
    longitude: float


class CurrentWeatherResponse(BaseModel):
    location: Location
    temperature: float
    humidity: float
    wind_speed: float

    weather_code: int
    weather_condition: str
    description: str
    icon: str


class DailyForecast(BaseModel):
    date: str

    weather_code: int
    weather_condition: str
    description: str
    icon: str

    temperature_max: float
    temperature_min: float
    precipitation_probability_max: float


class ForecastResponse(BaseModel):
    location: Location
    forecast: List[DailyForecast]


class CityWeatherResponse(BaseModel):
    city: str
    state: str | None = None
    country: str | None = None

    latitude: float
    longitude: float

    temperature: float
    humidity: float
    wind_speed: float

    weather_code: int
    weather_condition: str
    description: str
    icon: str