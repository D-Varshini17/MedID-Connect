from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class ExtractedMedication(BaseModel):
    medicine_name: str
    dosage: str | None = None
    timing: str | None = None
    duration: str | None = None
    confidence: float = 0.72


class PrescriptionOcrResponse(BaseModel):
    document_id: int
    doctor_name: str | None = None
    hospital_name: str | None = None
    extracted_text: str
    medications: list[ExtractedMedication]
    created_medication_ids: list[int]
    cleanup_notes: list[str]


class LabMarker(BaseModel):
    observation_type: str
    value: float
    unit: str | None = None
    normal_min: float | None = None
    normal_max: float | None = None
    status: str
    explanation: str


class LabAnalyzerResponse(BaseModel):
    document_id: int
    summary: str
    markers: list[LabMarker]
    warnings: list[str]
    created_observation_ids: list[int]


class VoiceAssistantRequest(BaseModel):
    text: str = Field(min_length=1, max_length=500)
    language: str = "en"


class VoiceAssistantResponse(BaseModel):
    intent: str
    spoken_reply: str
    display_cards: list[dict[str, Any]] = []
    language: str


class FamilyMemberCreate(BaseModel):
    full_name: str = Field(min_length=2, max_length=160)
    relationship: str = Field(min_length=2, max_length=80)
    age: int | None = None
    gender: str | None = None
    blood_group: str | None = None
    emergency_enabled: bool = True
    profile_payload: dict[str, Any] = {}


class FamilyMemberRead(FamilyMemberCreate):
    id: int
    owner_user_id: int
    linked_user_id: int | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class FamilyInvitationCreate(BaseModel):
    invitee_email: EmailStr
    relationship: str | None = None
    role: str = "caregiver"


class FamilyInvitationRead(BaseModel):
    id: int
    invitee_email: EmailStr
    relationship: str | None = None
    role: str
    token: str
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MedicationScheduleCreate(BaseModel):
    medication_id: int
    schedule_time: str = Field(pattern=r"^\d{2}:\d{2}$")
    timezone: str = "Asia/Kolkata"
    days_of_week: list[str] = []
    refill_due_at: datetime | None = None
    reminder_enabled: bool = True


class MedicationScheduleRead(MedicationScheduleCreate):
    id: int
    user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MedicationLogCreate(BaseModel):
    medication_id: int
    schedule_id: int | None = None
    status: str = "taken"
    taken_at: datetime | None = None
    notes: str | None = None


class MedicationLogRead(MedicationLogCreate):
    id: int
    user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DailyMedicationChecklist(BaseModel):
    date: datetime
    items: list[dict[str, Any]]
    safety_warnings: list[dict[str, Any]]


class NotificationDeviceCreate(BaseModel):
    platform: str = "android"
    fcm_token: str
    device_id: str | None = None


class NotificationRead(BaseModel):
    id: int
    title: str
    body: str
    category: str
    priority: str
    payload: dict[str, Any]
    read_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SyncEventIn(BaseModel):
    client_event_id: str
    entity_type: str
    entity_id: str | None = None
    operation: str
    payload: dict[str, Any] = {}
    client_updated_at: datetime | None = None


class SyncPushRequest(BaseModel):
    events: list[SyncEventIn]


class SyncPullResponse(BaseModel):
    server_time: datetime
    records: dict[str, list[dict[str, Any]]]
    conflicts: list[dict[str, Any]]


class DoctorProfileRead(BaseModel):
    id: int
    full_name: str
    specialty: str
    hospital_name: str | None = None
    city: str | None = None
    rating: float | None = None
    languages: list[str]
    telemedicine_enabled: bool

    model_config = ConfigDict(from_attributes=True)


class AppointmentCreate(BaseModel):
    doctor_id: int | None = None
    appointment_type: str = "telemedicine"
    scheduled_at: datetime
    reason: str | None = None


class AppointmentRead(AppointmentCreate):
    id: int
    user_id: int
    status: str
    meeting_url: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RiskScoreRead(BaseModel):
    risk_type: str
    score_percent: float
    band: str
    factors: list[dict[str, Any]]
    recommendations: list[str]
    calculated_at: datetime


class NaturalSearchRequest(BaseModel):
    query: str = Field(min_length=2, max_length=500)


class NaturalSearchResponse(BaseModel):
    interpreted_filters: dict[str, Any]
    results: list[dict[str, Any]]
    semantic_search_ready: bool = True


class ConsentCreate(BaseModel):
    grantee_name: str
    grantee_type: str = "provider"
    scopes: list[str]
    purpose: str | None = None
    expires_at: datetime | None = None


class ConsentRead(ConsentCreate):
    id: int
    user_id: int
    revoked_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DeviceRegisterRequest(BaseModel):
    device_id: str
    device_name: str | None = None
    platform: str = "android"


class SecurityEventRead(BaseModel):
    id: int
    event_type: str
    severity: str
    details: dict[str, Any]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AdminAnalyticsResponse(BaseModel):
    total_users: int
    total_records: int
    total_emergency_accesses: int
    total_notifications: int
    open_support_tickets: int
    ai_documents_processed: int


class SupportTicketCreate(BaseModel):
    subject: str
    description: str
    priority: str = "normal"
