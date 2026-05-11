import os
from functools import lru_cache
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from pydantic_settings import BaseSettings, SettingsConfigDict

LOCAL_DATABASE_URL = "postgresql+psycopg2://medid:medid_password@localhost:5432/medid_connect"


class Settings(BaseSettings):
    app_name: str = "MedID Connect API"
    environment: str = "development"
    database_url: str = LOCAL_DATABASE_URL
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

    @property
    def sqlalchemy_database_url(self) -> str:
        """Return a SQLAlchemy-compatible PostgreSQL URL for local and Render.

        Render may expose DATABASE_URL with the legacy postgres:// scheme.
        External Render PostgreSQL URLs also commonly require sslmode=require.
        This normalization is intentionally defensive so a malformed env var is
        reported clearly without crashing settings import.
        """
        return normalize_database_url(self.database_url)


def normalize_database_url(raw_url: str | None) -> str:
    database_url = (raw_url or "").strip()
    if not database_url:
        print("DATABASE_URL is empty. Falling back to local development database URL.")
        database_url = LOCAL_DATABASE_URL

    if database_url.startswith("postgres://"):
        database_url = "postgresql://" + database_url.removeprefix("postgres://")

    if database_url.startswith("postgresql://") or database_url.startswith("postgresql+psycopg2://"):
        split = urlsplit(database_url)
        query = dict(parse_qsl(split.query, keep_blank_values=True))
        render_runtime = os.getenv("RENDER") or "render.com" in split.netloc
        if render_runtime and "sslmode" not in query:
            query["sslmode"] = "require"
            database_url = urlunsplit(
                (split.scheme, split.netloc, split.path, urlencode(query), split.fragment)
            )

    return database_url


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
