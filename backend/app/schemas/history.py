from typing import List, Optional

from pydantic import BaseModel


class ChatHistoryItem(BaseModel):
    id: str
    session_id: str
    user_message: str
    bot_response: Optional[str] = None
    intent: Optional[str] = None
    location: Optional[str] = None
    created_at: str


class ChatHistoryResponse(BaseModel):
    success: bool
    session_id: str
    count: int
    history: List[ChatHistoryItem]