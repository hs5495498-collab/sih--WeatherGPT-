from typing import Optional

from pydantic import BaseModel, Field


# ==========================================
# CHAT
# ==========================================

class ChatRequest(BaseModel):

    message: str = Field(
        ...,
        min_length=1,
        description="User weather-related question"
    )

    session_id: Optional[str] = None

    language: str = "en"


# ==========================================
# NLU RESULT
# ==========================================

class NLUResult(BaseModel):

    intent: str

    location: Optional[str] = None

    time: Optional[str] = "current"

    domain: Optional[str] = "general"

    confidence: Optional[float] = None


# ==========================================
# CHAT RESPONSE
# ==========================================

class ChatResponse(BaseModel):

    success: bool

    response: str

    intent: Optional[str] = None

    location: Optional[str] = None

    data: Optional[dict] = None


# ==========================================
# ALERT
# ==========================================

class AlertResponse(BaseModel):

    level: str

    title: str

    message: str