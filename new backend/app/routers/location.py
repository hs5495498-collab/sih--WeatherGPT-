from fastapi import APIRouter, HTTPException, Query
from typing import List

from app.services.location_service import location_service
from app.schemas.location import LocationResponse


router = APIRouter(
    prefix="/api/v1/location",
    tags=["Location"]
)


@router.get(
    "/search",
    response_model=List[LocationResponse]
)
async def search_location(
    city: str = Query(
        ...,
        min_length=2,
        description="City or location name"
    )
):

    try:

        data = await location_service.search_location(city)

        results = data.get("results")

        if not results:
            raise HTTPException(
                status_code=404,
                detail="Location not found"
            )

        locations = []

        for location in results:

            locations.append(
                LocationResponse(
                    name=location["name"],
                    latitude=location["latitude"],
                    longitude=location["longitude"],
                    country=location.get("country"),
                    country_code=location.get("country_code"),
                    state=location.get("admin1"),
                    timezone=location.get("timezone")
                )
            )

        return locations

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Unable to search location"
        )