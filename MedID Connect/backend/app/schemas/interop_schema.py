from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ConsentCreate(BaseModel):
    grantee_name: str = Field(min_length=2, max_length=160)
    grantee_type: str = "doctor"
    hospital_name: str | None = None
    doctor_name: str | None = None
    purpose: str | None = None
    allowed_resources: list[str] = [
        "Patient",
        "AllergyIntolerance",
        "MedicationRequest",
        "Condition",
        "Observation",
        "DiagnosticReport",
    ]
    expires_at: datetime


class ConsentRead(BaseModel):
    id: int
    user_id: int
    grantee_name: str
    grantee_type: str
    hospital_name: str | None = None
    doctor_name: str | None = None
    purpose: str | None = None
    allowed_resources: list[str]
    share_url: str | None = None
    expires_at: datetime
    revoked_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ConsentCreateResponse(ConsentRead):
    share_token: str
    share_url: str


class ConsentAccessLogRead(BaseModel):
    id: int
    consent_id: int
    accessed_by: str | None = None
    ip_address: str | None = None
    user_agent: str | None = None
    resource_accessed: str
    accessed_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProviderRead(BaseModel):
    id: str
    provider_name: str
    provider_type: str
    provider_base_url: str | None = None
    status: str = "available"
    notes: str


class ProviderConnectionRead(BaseModel):
    id: int
    provider_name: str
    provider_type: str
    provider_base_url: str | None = None
    scopes: list[str]
    token_expires_at: datetime | None = None
    last_sync_at: datetime | None = None
    status: str

    model_config = ConfigDict(from_attributes=True)


class ProviderConnectStart(BaseModel):
    provider_id: str
    scopes: list[str] = ["patient/*.read", "openid", "fhirUser"]


class ProviderConnectCallback(BaseModel):
    provider_id: str
    auth_code: str = "demo-code"


class ProviderSyncResponse(BaseModel):
    provider_connection_id: int
    imported_counts: dict[str, int]
    message: str


class FhirBundle(BaseModel):
    resourceType: str = "Bundle"
    type: str = "searchset"
    entry: list[dict[str, Any]]


class OcrConfirmRequest(BaseModel):
    extracted_text: str | None = None
    confirm_save: bool = True
