from typing import List, Optional

from pydantic import BaseModel, Field, field_validator


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

    @field_validator("id", mode="before")
    @classmethod
    def _coerce_id_to_str(cls, value):
        # Supabase/Postgres may hand back an integer id (e.g. a bigint
        # primary key) rather than a uuid string. Pydantic v2 does not
        # coerce int -> str automatically, so without this a row with an
        # integer id would 500 the whole saved-locations response.
        return str(value) if value is not None else value


class SavedLocationListResponse(BaseModel):
    success: bool
    count: int
    locations: List[SavedLocationResponse]


class DeleteLocationResponse(BaseModel):
    success: bool
    deleted: bool
    id: str