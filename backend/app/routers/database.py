from fastapi import APIRouter, HTTPException

from database.supabase import supabase


router = APIRouter(
    prefix="/api/v1/database",
    tags=["Database"]
)


@router.get("/test")
async def test_database():

    try:

        response = (
            supabase
            .table("profiles")
            .select("*")
            .limit(1)
            .execute()
        )

        return {
            "status": "success",
            "message": "Supabase connected successfully",
            "data": response.data
        }

    except Exception as error:

        raise HTTPException(
            status_code=500,
            detail=f"Database connection failed: {str(error)}"
        )