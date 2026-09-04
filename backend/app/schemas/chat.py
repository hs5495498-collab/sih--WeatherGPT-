from typing import Any, Dict

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):

    message: str = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="User weather query"
    )

    session_id: str | None = Field(
        default=None,
        description=(
            "Existing chat session id to continue a conversation's "
            "history. Omit to start a new session — the server will "
            "generate and return one."
        )
    )


class ChatResponse(BaseModel):

    success: bool

    session_id: str | None = None

    intent: str | None = None
    route: str | None = None

    time: str | None = None

    response: str | None = None

    # NOTE: the catch-all "unknown intent" branch in chat_orchestrator
    # returns `location` as a plain city-name string rather than a dict,
    # so this is typed loosely (Any) rather than Dict[str, Any] to avoid
    # a response-validation error on that path.
    location: Any | None = None

    weather: Dict[str, Any] | None = None

    forecast: Any | None = None

    advisory: Dict[str, Any] | None = None

    overall_risk: Dict[str, Any] | None = None

    alerts: list[Dict[str, Any]] | None = None

    message: str | None = None

    weather_data: Dict[str, Any] | None = None