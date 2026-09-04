from typing import List, Optional

from pydantic import BaseModel, Field


class SaveLocationRequest(BaseModel):
    city: str = Field(..., min_length=2, description="City name to save, e.g. 'Delhi'")


class SavedLocationResponse(BaseModel):
    id: str
    city: str
    state: Optional[str] = None
    country: Optional[str] = None
    latitude: float
    longitude: float
    created_at: str


class SavedLocationListResponse(BaseModel):
    success: bool
    count: int
    locations: List[SavedLocationResponse]


class DeleteLocationResponse(BaseModel):
    success: bool
    deleted: bool
    id: str