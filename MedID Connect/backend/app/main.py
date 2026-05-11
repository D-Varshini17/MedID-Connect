from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import check_database_connection
from app.routes import (
    admin_routes,
    ai_routes,
    allergy_routes,
    auth_routes,
    consent_routes,
    emergency_routes,
    family_routes,
    insight_routes,
    medical_routes,
    medication_engine_routes,
    medication_routes,
    notification_routes,
    observation_routes,
    ocr_routes,
    provider_routes,
    fhir_routes,
    product_analytics_routes,
    search_routes,
    security_routes,
    sos_routes,
    sync_routes,
    telemedicine_routes,
    user_routes,
    wallet_routes,
    wellness_routes,
)
from app.services.rate_limit import RateLimitMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting MedID Connect backend...")
    try:
        print("Connecting database...")
        check_database_connection()
        print("Backend initialized successfully")
    except Exception as exc:
        print(f"Startup error: {exc}")
        print("Backend initialized with degraded database status.")
    yield


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Production-ready scaffold for the MedID Connect healthcare platform.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(RateLimitMiddleware)

app.include_router(auth_routes.router)
app.include_router(user_routes.router)
app.include_router(medical_routes.router)
app.include_router(medication_routes.router)
app.include_router(allergy_routes.router)
app.include_router(observation_routes.router)
app.include_router(emergency_routes.router)
app.include_router(insight_routes.router)
app.include_router(ai_routes.router)
app.include_router(family_routes.router)
app.include_router(medication_engine_routes.router)
app.include_router(notification_routes.router)
app.include_router(sync_routes.router)
app.include_router(telemedicine_routes.router)
app.include_router(search_routes.router)
app.include_router(security_routes.router)
app.include_router(consent_routes.router)
app.include_router(consent_routes.share_router)
app.include_router(fhir_routes.router)
app.include_router(provider_routes.router)
app.include_router(ocr_routes.router)
app.include_router(wallet_routes.router)
app.include_router(wellness_routes.router)
app.include_router(sos_routes.router)
app.include_router(product_analytics_routes.router)
app.include_router(admin_routes.router)


@app.get("/", tags=["health"])
def root() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health", tags=["health"])
def render_health() -> dict[str, str]:
    return {"status": "healthy"}


@app.get("/api/health", tags=["health"])
def health() -> dict[str, str]:
    return {
        "status": "healthy",
        "service": "MedID Connect API",
        "environment": settings.environment,
    }
