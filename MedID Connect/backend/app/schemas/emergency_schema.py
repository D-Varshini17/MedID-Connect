from datetime import datetime

from pydantic import BaseModel

from app.schemas.medication_schema import AllergyRead, MedicationRead
from app.schemas.user_schema import EmergencyContactRead


class EmergencyTokenResponse(BaseModel):
    token: str
    emergency_url: str
    expires_at: datetime


class EmergencyTokenRequest(BaseModel):
    expires_in_minutes: int = 60


class EmergencyViewResponse(BaseModel):
    patient_name: str
    blood_group: str | None = None
    allergies: list[AllergyRead]
    emergency_contacts: list[EmergencyContactRead]
    current_medications: list[MedicationRead]
    critical_conditions: list[str]
    expires_at: datetime


class EmergencyAccessLogRead(BaseModel):
    id: int
    accessed_at: datetime
    ip_address: str | None = None
    user_agent: str | None = None
