from fastapi import APIRouter, Depends

from app.dependencies.auth import get_current_user
from app.schemas.saved_location import (
    SaveLocationRequest,
    SavedLocationResponse,
    SavedLocationListResponse,
    DeleteLocationResponse,
)
from app.services.saved_location_service import saved_location_service


router = APIRouter(prefix="/api/v1/users/locations", tags=["Saved Locations"])


@router.post("/", response_model=SavedLocationResponse)
async def save_location(
    request: SaveLocationRequest,
    current_user=Depends(get_current_user)
):
    return await saved_location_service.save_location(
        user_id=current_user.id,
        city=request.city
    )


@router.get("/", response_model=SavedLocationListResponse)
async def get_saved_locations(current_user=Depends(get_current_user)):
    locations = await saved_location_service.list_locations(
        user_id=current_user.id
    )

    return SavedLocationListResponse(
        success=True,
        count=len(locations),
        locations=locations
    )


@router.delete("/{location_id}", response_model=DeleteLocationResponse)
async def delete_saved_location(
    location_id: str,
    current_user=Depends(get_current_user)
):
    await saved_location_service.delete_location(
        user_id=current_user.id,
        location_id=location_id
    )

    return DeleteLocationResponse(success=True, deleted=True, id=location_id)