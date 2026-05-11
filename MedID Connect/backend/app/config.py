from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "MedID Connect API"
    environment: str = "development"
    database_url: str = "postgresql+psycopg2://medid:medid_password@localhost:5432/medid_connect"
    jwt_secret_key: str = "change-this-before-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440
    emergency_token_expire_minutes: int = 60
    backend_public_url: str = "http://localhost:8000"
    cors_origins: str = "http://localhost:3000,http://localhost:8000,http://10.0.2.2:8000"
    hapi_fhir_base_url: str = "https://hapi.fhir.org/baseR4"
    epic_client_id: str = "placeholder"
    cerner_client_id: str = "placeholder"
    abdm_client_id: str = "placeholder"
    abdm_client_secret: str = "placeholder"
    google_vision_api_key: str = "placeholder"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
