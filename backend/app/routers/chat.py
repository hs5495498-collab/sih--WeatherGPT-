from fastapi import APIRouter, HTTPException

from app.schemas.chat import ChatRequest, ChatResponse
from app.services.chat_orchestrator import chat_orchestrator
from app.services.history_service import history_service

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

        result = await chat_orchestrator.process_message(
            request.message
        )

        # Persist this turn to chat history. This never raises —
        # a Supabase outage should never break the chat response itself.
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