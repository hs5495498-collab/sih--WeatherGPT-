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

    lang: str | None = Field(
        default="en",
        description=(
            "BCP-47-ish language code the user is speaking/reading in "
            "(en, hi, mr, bn, pa, ta, te, gu, kn). The NLU/response layer "
            "itself is English-only, so when this is not 'en' the message "
            "is translated to English before processing and the reply is "
            "translated back -- see app/services/translation_service.py."
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

    # Honesty fields for the translation pass (see translation_service.py).
    # `translated` is False whenever the reply is still in English --
    # either because the request asked for English, or because
    # translation was attempted and failed/was skipped. A client should
    # not assume `response` is in `lang` just because `lang` was requested.
    lang: str | None = None
    translated: bool = False