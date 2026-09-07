from fastapi import APIRouter, HTTPException
from starlette.concurrency import run_in_threadpool

from database.supabase import supabase

import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/database",
    tags=["Database"]
)


@router.get("/test")
async def test_database():
    """
    Lightweight Supabase connectivity check.

    Intentionally does NOT return the queried rows: this endpoint is
    unauthenticated, and echoing back real `profiles` data (or a raw
    exception message, which can leak schema/connection details) to
    any caller would be a data-exposure risk. It only confirms the
    connection works and how many matching rows exist.
    """

    try:

        query = supabase.table("profiles").select("id").limit(1)
        response = await run_in_threadpool(query.execute)

        return {
            "status": "success",
            "message": "Supabase connected successfully",
            "row_count": len(response.data or [])
        }

    except Exception as error:

        logger.error("Database connectivity check failed: %s", error)

        raise HTTPException(
            status_code=500,
            detail="Database connection failed."
        )