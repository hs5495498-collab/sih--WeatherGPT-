from fastapi import FastAPI

from app.core.config import settings
from app.routers import weather, location, chat


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG
)

app.include_router(weather.router)
app.include_router(location.router)
app.include_router(chat.router)

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