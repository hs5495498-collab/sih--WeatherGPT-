import logging
import traceback

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.exceptions import AppException

logger = logging.getLogger(__name__)


def _error_response(status_code: int, error_code: str, message: str, details=None) -> JSONResponse:
    # Keeps the "detail" key FastAPI's default HTTPException responses
    # already use (so existing frontend code checking response.detail
    # keeps working), while adding structured fields on top.
    body = {
        "success": False,
        "detail": message,
        "error_code": error_code,
    }
    if details is not None:
        body["details"] = details

    return JSONResponse(status_code=status_code, content=body)


def register_exception_handlers(app: FastAPI) -> None:
    """
    Registers one handler per error type so every error response has
    the same shape and gets logged exactly once, regardless of which
    router or service raised it. Routers keep raising HTTPException (or
    the new AppException) exactly like before — nothing about existing
    route code needs to change.
    """

    @app.exception_handler(AppException)
    async def handle_app_exception(request: Request, exc: AppException):
        logger.warning(
            "AppException on %s %s: %s", request.method, request.url.path, exc.message
        )
        return _error_response(exc.status_code, exc.error_code, exc.message)

    @app.exception_handler(StarletteHTTPException)
    async def handle_http_exception(request: Request, exc: StarletteHTTPException):
        # This is what most existing routers raise today via HTTPException.
        # Wrapping it here just gives it the same response shape as
        # AppException, without touching any router code.
        logger.warning(
            "HTTPException on %s %s: %s", request.method, request.url.path, exc.detail
        )
        return _error_response(exc.status_code, "http_error", str(exc.detail))

    @app.exception_handler(RequestValidationError)
    async def handle_validation_error(request: Request, exc: RequestValidationError):
        logger.info(
            "Validation error on %s %s: %s", request.method, request.url.path, exc.errors()
        )
        return _error_response(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "validation_error",
            "Request validation failed.",
            details=exc.errors(),
        )

    @app.exception_handler(Exception)
    async def handle_unhandled_exception(request: Request, exc: Exception):
        # Anything reaching here is a genuine bug, not an expected error
        # path. Log the full traceback for debugging but never leak it
        # to the client.
        logger.error(
            "Unhandled exception on %s %s:\n%s",
            request.method,
            request.url.path,
            "".join(traceback.format_exception(type(exc), exc, exc.__traceback__)),
        )
        return _error_response(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "internal_error",
            "Something went wrong on our end. Please try again.",
        )