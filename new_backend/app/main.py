import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging_config import setup_logging
from app.core.exception_handlers import register_exception_handlers
from app.core.middleware import RequestLoggingMiddleware
from app.routers import weather, location, chat, database, advisory, domain_advisory, risk, alerts, history, auth, user_locations, websocket
from app.services.alert_poller import alert_poller

setup_logging(debug=settings.DEBUG)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):

    logger.info("Starting WeatherGPT Backend")
    alert_poller.start()
    yield
    await alert_poller.stop()
    logger.info("Shutting down WeatherGPT Backend")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
     description=(
        "AI-powered conversational platform for weather "
        "forecasting, alerts and climate intelligence."
    ),
    debug=settings.DEBUG,
    lifespan=lifespan
)

register_exception_handlers(app)

app.add_middleware(RequestLoggingMiddleware)

# allow_credentials=True is invalid together with a wildcard origin
# (browsers reject it outright) -- so wildcard mode automatically runs
# without credentials instead of silently being broken.
if settings.ALLOWED_ORIGINS.strip() == "*":
    cors_kwargs = {"allow_origins": ["*"], "allow_credentials": False}
else:
    cors_kwargs = {"allow_origins": settings.cors_origins, "allow_credentials": True}

app.add_middleware(

    CORSMiddleware,
    allow_methods=["*"],
    allow_headers=["*"],
    **cors_kwargs
)

app.include_router(weather.router)
app.include_router(location.router)
app.include_router(chat.router)
app.include_router(database.router)
app.include_router(advisory.router)
app.include_router(domain_advisory.router)
app.include_router(risk.router)
app.include_router(alerts.router)
app.include_router(history.router)
app.include_router(auth.router)
app.include_router(user_locations.router)
app.include_router(websocket.router)



@app.get("/")
async def root():
    return {
        "message": "Welcome to WeatherGPT API",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION
    }