from typing import List, Optional

from pydantic import BaseModel, field_validator


class ChatHistoryItem(BaseModel):
    id: str
    session_id: str
    user_message: str
    bot_response: Optional[str] = None
    intent: Optional[str] = None
    location: Optional[str] = None
    created_at: str

    @field_validator("id", mode="before")
    @classmethod
    def _coerce_id_to_str(cls, value):
        # Supabase/Postgres may hand back an integer id (e.g. a bigint
        # primary key) rather than a uuid string. Pydantic v2 does not
        # coerce int -> str automatically, so without this a row with an
        # integer id would 500 the whole /history/{session_id} response.
        return str(value) if value is not None else value


class ChatHistoryResponse(BaseModel):
    success: bool
    session_id: str
    count: int
    history: List[ChatHistoryItem]