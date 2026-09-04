from typing import Any, Dict, List, Optional

from database.supabase import supabase


class ChatRepository:
    """
    Data-access layer for the `chat_history` table.
    No business logic here — only Supabase reads/writes.
    """

    TABLE = "chat_history"

    async def insert_message(
        self,
        session_id: str,
        user_message: str,
        bot_response: Optional[str] = None,
        intent: Optional[str] = None,
        location: Optional[str] = None,
    ) -> Dict[str, Any]:

        payload = {
            "session_id": session_id,
            "user_message": user_message,
            "bot_response": bot_response,
            "intent": intent,
            "location": location,
        }

        response = (
            supabase
            .table(self.TABLE)
            .insert(payload)
            .execute()
        )

        return response.data[0] if response.data else {}

    async def get_history_by_session(
        self,
        session_id: str,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:

        response = (
            supabase
            .table(self.TABLE)
            .select("*")
            .eq("session_id", session_id)
            .order("created_at", desc=False)
            .limit(limit)
            .execute()
        )

        return response.data or []

    async def delete_session(self, session_id: str) -> int:

        response = (
            supabase
            .table(self.TABLE)
            .delete()
            .eq("session_id", session_id)
            .execute()
        )

        return len(response.data or [])


chat_repository = ChatRepository()