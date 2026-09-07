from typing import Optional


class AppException(Exception):
    """
    Base class for expected, business-logic errors the app raises on
    purpose (as opposed to bugs). Carries an HTTP status code and a
    machine-readable error_code so a frontend can branch on the error
    type without string-matching the message.

    Existing routers don't have to use this — they can keep raising
    fastapi.HTTPException like they already do. This is here for new
    code, and both types get the same consistent response shape via
    app/core/exception_handlers.py.
    """

    status_code: int = 500
    error_code: str = "internal_error"

    def __init__(
        self,
        message: str,
        status_code: Optional[int] = None,
        error_code: Optional[str] = None,
    ):
        self.message = message
        if status_code is not None:
            self.status_code = status_code
        if error_code is not None:
            self.error_code = error_code
        super().__init__(message)


class LocationNotFoundError(AppException):
    status_code = 404
    error_code = "location_not_found"

    def __init__(self, city: str):
        super().__init__(f"Location '{city}' could not be found.")


class WeatherServiceError(AppException):
    status_code = 502
    error_code = "weather_service_error"


class DatabaseError(AppException):
    status_code = 503
    error_code = "database_error"


class AuthenticationError(AppException):
    status_code = 401
    error_code = "authentication_error"