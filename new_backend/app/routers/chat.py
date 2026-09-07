from fastapi import APIRouter, HTTPException

from app.schemas.chat import ChatRequest, ChatResponse
from app.services.chat_orchestrator import chat_orchestrator
from app.services.history_service import history_service
from app.services.translation_service import translation_service

import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/chat",
    tags=["Chat"]
)


@router.post(
    "/",
    response_model=ChatResponse
)
async def chat(request: ChatRequest):

    try:

        lang = (request.lang or "en").lower()
        message = request.message

        # STEP 0: translate the incoming message to English before it ever
        # reaches the NLU -- nlu_service's location/intent extraction is
        # pattern-matched against English text (city names, keywords like
        # "weather", "rain", "flowering"), so passing it non-English text
        # directly would silently misroute almost everything.
        if lang != "en":
            message, _ = await translation_service.translate(
                message, source=lang, target="en"
            )

        result = await chat_orchestrator.process_message(
            message
        )

        # STEP 2: translate the generated English reply back into the
        # user's language. Every field this touches is optional and this
        # never raises -- a translation failure falls back to the English
        # text untouched (see ChatResponse.translated).
        translated = False
        if lang != "en":
            for field in ("response", "message"):
                original = result.get(field)
                if isinstance(original, str) and original.strip():
                    translated_text, ok = await translation_service.translate(
                        original, source="en", target=lang
                    )
                    result[field] = translated_text
                    translated = translated or ok

        result["lang"] = lang
        result["translated"] = translated

        # Persist this turn to chat history. This never raises —
        # a Supabase outage should never break the chat response itself.
        # NOTE: intentionally stores the original English message + English
        # NLU-facing text, not the localized one, so a human reviewing
        # history sees what the pipeline actually reasoned over.
        session_id = await history_service.save_turn(
            session_id=request.session_id,
            user_message=request.message,
            bot_response=result.get("response") or result.get("message"),
            intent=result.get("intent"),
            location=result.get("location"),
        )

        result["session_id"] = session_id

        return result

    except HTTPException:
        raise

    except Exception as error:
        # Unexpected/unknown failure — log the real cause here, but let
        # the centralized handler (app/core/exception_handlers.py) send
        # back a safe generic message instead of leaking error internals.
        logger.error("Unexpected error processing chat message: %s", error)
        raise