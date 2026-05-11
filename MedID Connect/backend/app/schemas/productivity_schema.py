from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class HealthWalletSummary(BaseModel):
    patient: dict[str, Any]
    blood_group: str | None
    allergies: list[dict[str, Any]]
    chronic_conditions: list[dict[str, Any]]
    current_medications: list[dict[str, Any]]
    emergency_contacts: list[dict[str, Any]]
    vaccination_summary: list[dict[str, Any]]
    insurance_id_placeholder: str
    emergency_card: dict[str, Any]


class WellnessLogCreate(BaseModel):
    log_date: datetime | None = None
    water_ml: int = Field(default=0, ge=0, le=10000)
    sleep_hours: float | None = Field(default=None, ge=0, le=24)
    steps: int | None = Field(default=None, ge=0, le=100000)
    mood: str | None = None
    exercise_minutes: int | None = Field(default=None, ge=0, le=600)
    notes: str | None = None


class WellnessLogRead(WellnessLogCreate):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class HealthScoreResponse(BaseModel):
    score: int
    adherence_percent: int
    water_percent: int
    sleep_percent: int
    observations_percent: int
    suggestions: list[str]


class SosAlertCreate(BaseModel):
    message: str = "Emergency help needed. This is a MedID Connect mock SOS alert."
    latitude: float | None = None
    longitude: float | None = None


class SosAlertRead(BaseModel):
    id: int
    message: str
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AnalyticsSummary(BaseModel):
    weekly_health_score: int
    medication_adherence: int
    water_average_ml: int
    sleep_average_hours: float
    abnormal_observations: int
    most_common_symptoms: list[str]
    progress_timeline: list[dict[str, Any]]
    trend_cards: list[dict[str, Any]]


class DocumentFlagCreate(BaseModel):
    favorite: bool = False
    pinned: bool = False
    note: str | None = None
