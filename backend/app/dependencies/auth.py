import logging

from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from starlette.concurrency import run_in_threadpool

from database.supabase import supabase

logger = logging.getLogger(__name__)

# auto_error=False so we can raise our own clear 401 message instead of
# FastAPI's generic "Not authenticated" when no token is sent at all.
bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme)
):
    """
    FastAPI dependency that validates the Supabase access token sent by
    the client and returns the Supabase auth user object.

    Because this uses HTTPBearer, every route that depends on this gets
    its own lock icon in Swagger UI (/docs) -- click it and paste just the
    raw access_token (no need to type "Bearer " yourself).

    Supabase Auth already handles signup, login, password hashing and
    JWT issuing (see app/services/auth_service.py) -- this dependency
    just verifies the token on incoming requests and tells the route
    who is calling.

    Usage:
        @router.get("/protected")
        async def protected(current_user = Depends(get_current_user)):
            user_id = current_user.id
    """

    if credentials is None:
        raise HTTPException(
            status_code=401,
            detail="Missing bearer token. Click the lock icon in /docs and paste your access_token."
        )

    token = credentials.credentials

    try:
        # supabase-py's auth client is synchronous under the hood, so this
        # is offloaded to a threadpool to avoid blocking the event loop.
        response = await run_in_threadpool(supabase.auth.get_user, token)

    except Exception as error:
        logger.warning("Token validation failed: %s", error)
        raise HTTPException(status_code=401, detail="Invalid or expired token.")

    user = getattr(response, "user", None)

    if not user:
        raise HTTPException(status_code=401, detail="Invalid or expired token.")

    return user