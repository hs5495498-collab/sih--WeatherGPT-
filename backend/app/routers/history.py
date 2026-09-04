import logging

from fastapi import APIRouter, HTTPException, Query

from app.services.history_service import history_service
from app.schemas.history import ChatHistoryResponse

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/history",
    tags=["Chat History"]
)


@router.get("/{session_id}", response_model=ChatHistoryResponse)
async def get_chat_history(
    session_id: str,
    limit: int = Query(
        default=50,
        ge=1,
        le=200,
        description="Max number of turns to return"
    )
):
    try:
        history = await history_service.get_history(
            session_id=session_id,
            limit=limit
        )

        return ChatHistoryResponse(
            success=True,
            session_id=session_id,
            count=len(history),
            history=history
        )

    except Exception as error:
        logger.error("Unexpected error fetching chat history: %s", error)
        raise


@router.delete("/{session_id}")
async def delete_chat_history(session_id: str):
    try:
        deleted_count = await history_service.clear_history(session_id)

        return {
            "success": True,
            "session_id": session_id,
            "deleted_count": deleted_count
        }

    except Exception as error:
        logger.error("Unexpected error deleting chat history: %s", error)
        raise