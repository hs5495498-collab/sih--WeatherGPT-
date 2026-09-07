from pydantic import BaseModel
from typing import Optional


class LocationResponse(BaseModel):
    name: str
    latitude: float
    longitude: float
    country: Optional[str] = None
    country_code: Optional[str] = None
    state: Optional[str] = None
    timezone: Optional[str] = None