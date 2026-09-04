from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):


    APP_NAME: str = "WeatherGPT API"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = True

    WEATHER_API_BASE_URL: str = "https://api.open-meteo.com/v1"

    SUPABASE_URL: str | None = None
    SUPABASE_KEY: str | None = None


    NLU_ENABLED: bool = False
    NLU_MODEL_PATH: str = "weathergpt_nlu_export"


 
    RAG_ENABLED: bool = False


    RATE_LIMIT: str = "30/minute"


    ALERT_POLL_INTERVAL_SECONDS: int = 60

        # Comma-separated list of allowed frontend origins, e.g.
    # "http://localhost:3000,https://weathergpt-demo.vercel.app"
    # Set to "*" to allow any origin (only safe because we then
    # automatically disable credentialed requests -- see main.py).
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173"

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",") if origin.strip()]


    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()