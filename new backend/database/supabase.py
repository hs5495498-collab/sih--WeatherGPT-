from typing import Optional

from supabase import create_client, Client

from app.core.config import settings

# Whether real Supabase credentials were supplied. Auth, chat history, and
# saved-location endpoints depend on Supabase; weather, alerts, and advisory
# endpoints do not. This flag lets those independent features boot and work
# normally even when Supabase isn't configured (e.g. a fresh Railway deploy
# before env vars are set, or a demo run with no backing database).
is_configured: bool = bool(settings.SUPABASE_URL and settings.SUPABASE_KEY)


class _UnconfiguredSupabaseClient:
    """Stand-in used when Supabase isn't configured.

    Importing this module must never crash the whole app just because one
    optional integration isn't set up -- that would take down weather,
    alerts, and advisory endpoints too, which have nothing to do with
    Supabase. Any attempt to actually use the client raises a clear,
    actionable error at the point of use instead.
    """

    def __getattr__(self, name):
        raise RuntimeError(
            "Supabase is not configured (set SUPABASE_URL and SUPABASE_KEY). "
            "Auth, chat history, and saved locations need it; weather, "
            "alerts, and advisory features work fine without it."
        )


_client: Optional[Client] = (
    create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    if is_configured
    else None
)

supabase: Client = _client if _client is not None else _UnconfiguredSupabaseClient()  # type: ignore[assignment]