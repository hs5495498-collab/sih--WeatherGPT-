from typing import Any, Dict

from starlette.concurrency import run_in_threadpool

from database.supabase import supabase


class AuthService:
    """
    Thin wrapper around Supabase Auth. Supabase already provides the
    full authentication system (signup, login, JWT issuing, password
    hashing, email verification, etc.) via its built-in `auth.users`
    table — we don't build or store any of that ourselves. This class
    just calls into it and shapes the response for our API.
    """

    async def sign_up(self, email: str, password: str) -> Dict[str, Any]:
        response = await run_in_threadpool(
            supabase.auth.sign_up,
            {"email": email, "password": password}
        )
        return self._serialize(response)

    async def sign_in(self, email: str, password: str) -> Dict[str, Any]:
        response = await run_in_threadpool(
            supabase.auth.sign_in_with_password,
            {"email": email, "password": password}
        )
        return self._serialize(response)

    def _serialize(self, response) -> Dict[str, Any]:
        user = getattr(response, "user", None)
        session = getattr(response, "session", None)

        return {
            "user": {
                "id": user.id,
                "email": user.email
            } if user else None,
            "access_token": getattr(session, "access_token", None) if session else None,
            "refresh_token": getattr(session, "refresh_token", None) if session else None,
        }


auth_service = AuthService()