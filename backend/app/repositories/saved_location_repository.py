from typing import Any, Dict, List, Optional

from supabase import create_client

from app.core.config import settings
from database.supabase import supabase


class SavedLocationRepository:
    TABLE = "user_locations"

    async def insert(
        self,
        user_id: str,
        city: str,
        latitude: float,
        longitude: float,
        state: Optional[str] = None,
        country: Optional[str] = None,
        access_token: Optional[str] = None,
    ) -> Dict[str, Any]:

        payload = {
            "user_id": user_id,
            "city": city,
            "state": state,
            "country": country,
            "latitude": latitude,
            "longitude": longitude,
        }

        client = supabase
        if access_token:
            client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
            client.postgrest.auth(access_token)

        response = (
            client
            .table(self.TABLE)
            .insert(payload)
            .execute()
        )

        return response.data[0] if response.data else {}

    async def get_all_for_user(self, user_id: str) -> List[Dict[str, Any]]:

        response = (
            supabase
            .table(self.TABLE)
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )

        return response.data or []

    async def delete(self, user_id: str, location_id: str) -> bool:

        response = (
            supabase
            .table(self.TABLE)
            .delete()
            .eq("user_id", user_id)
            .eq("id", location_id)
            .execute()
        )

        return bool(response.data)


saved_location_repository = SavedLocationRepository()