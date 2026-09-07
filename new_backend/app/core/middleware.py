import logging
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

logger = logging.getLogger("weathergpt.requests")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Logs one line per request: a short request id, method, path, status
    code, and duration. Also stamps the id onto the response as
    X-Request-ID so a specific request can be traced through the logs
    (handy when debugging a report from the frontend team).
    """

    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid.uuid4())[:8]
        start_time = time.perf_counter()

        response = await call_next(request)

        duration_ms = (time.perf_counter() - start_time) * 1000
        response.headers["X-Request-ID"] = request_id

        logger.info(
            "[%s] %s %s -> %s (%.1fms)",
            request_id,
            request.method,
            request.url.path,
            response.status_code,
            duration_ms,
        )

        return response