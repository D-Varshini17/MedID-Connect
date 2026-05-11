from collections.abc import Generator

from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import settings


class Base(DeclarativeBase):
    pass


def _create_engine():
    try:
        return create_engine(
            settings.sqlalchemy_database_url,
            pool_pre_ping=True,
            pool_recycle=300,
        )
    except Exception as exc:
        print(f"Database engine configuration error: {exc}")
        print("Falling back to local SQLite so the API can still start.")
        return create_engine(
            "sqlite:///./medid_connect_fallback.db",
            connect_args={"check_same_thread": False},
            pool_pre_ping=True,
        )


engine = _create_engine()
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def check_database_connection() -> bool:
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        print("Database connection successful.")
        return True
    except SQLAlchemyError as exc:
        print(f"Database connection failed: {exc}")
        print("Backend will continue running. Protected data routes may fail until the database is reachable.")
        return False
    except Exception as exc:
        print(f"Unexpected database startup error: {exc}")
        print("Backend will continue running. Check DATABASE_URL and Render PostgreSQL settings.")
        return False


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
