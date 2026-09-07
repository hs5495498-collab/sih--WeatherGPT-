from typing import Any, Dict, List
import logging

from fastapi import HTTPException

from app.repositories.saved_location_repository import saved_location_repository
from app.services.location_service import location_service

logger = logging.getLogger(__name__)


class SavedLocationService:

    async def save_location(
        self,
        user_id: str,
        city: str,
    ) -> Dict[str, Any]:

        # Resolve the city to verified coordinates via the existing
        # geocoding service — never store an unverified location name.
        geo_data = await location_service.search_location(city=city, count=1)
        results = geo_data.get("results")

        if not results:
            raise HTTPException(
                status_code=404,
                detail=f"Location '{city}' could not be found."
            )

        location = results[0]

        try:
            saved = await saved_location_repository.insert(
                user_id=user_id,
                city=location["name"],
                state=location.get("admin1"),
                country=location.get("country"),
                latitude=location["latitude"],
                longitude=location["longitude"],
            )

        except Exception as error:
            logger.warning(
                "Failed to save location '%s' for user %s: %s", city, user_id, error
            )

            if getattr(error, "code", None) == "23505":
                raise HTTPException(
                    status_code=409,
                    detail=f"'{location['name']}' is already saved."
                )

            raise HTTPException(
                status_code=500,
                detail="Unable to save location."
            )

        return saved

    async def list_locations(self, user_id: str) -> List[Dict[str, Any]]:
        return await saved_location_repository.get_all_for_user(user_id)

    async def delete_location(self, user_id: str, location_id: str) -> None:
        deleted = await saved_location_repository.delete(user_id, location_id)

        if not deleted:
            raise HTTPException(
                status_code=404,
                detail="Saved location not found."
            )


saved_location_service = SavedLocationService()