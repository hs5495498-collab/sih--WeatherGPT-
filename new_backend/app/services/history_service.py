import logging
import uuid
from typing import Any, Dict, List, Optional

from app.repositories.chat_repository import chat_repository

logger = logging.getLogger(__name__)


class HistoryService:

    def generate_session_id(self) -> str:
        return str(uuid.uuid4())

    async def save_turn(
        self,
        session_id: Optional[str],
        user_message: str,
        bot_response: Optional[str] = None,
        intent: Optional[str] = None,
        location: Optional[Any] = None,
    ) -> Optional[str]:
        """
        Persist one chat turn. Returns the session_id used (generating one
        if the caller didn't supply one).

        Never raises — a Supabase outage should never break the chat
        response itself. Errors are logged and swallowed.
        """

        resolved_session_id = session_id or self.generate_session_id()

        # location may arrive as a dict (e.g. {"city": "Delhi", ...})
        # from the orchestrator — normalize to a plain string for storage.
        location_str = None
        if isinstance(location, dict):
            location_str = location.get("city")
        elif isinstance(location, str):
            location_str = location

        try:
            await chat_repository.insert_message(
                session_id=resolved_session_id,
                user_message=user_message,
                bot_response=bot_response,
                intent=intent,
                location=location_str,
            )

        except Exception as error:
            logger.error(
                "Failed to save chat history for session %s: %s",
                resolved_session_id,
                error,
            )

        return resolved_session_id

    async def get_history(
        self,
        session_id: str,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:

        return await chat_repository.get_history_by_session(
            session_id=session_id,
            limit=limit,
        )

    async def clear_history(self, session_id: str) -> int:
        return await chat_repository.delete_session(session_id)


history_service = HistoryService()