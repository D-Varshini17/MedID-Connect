from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class MedicalRecordBase(BaseModel):
    record_type: str = Field(min_length=2, max_length=80)
    title: str = Field(min_length=2, max_length=180)
    description: str | None = None
    provider_name: str | None = None
    doctor_name: str | None = None
    record_date: datetime
    fhir_resource_type: str | None = None
    fhir_payload: dict[str, Any] = {}


class MedicalRecordCreate(MedicalRecordBase):
    pass


class MedicalRecordUpdate(BaseModel):
    record_type: str | None = None
    title: str | None = None
    description: str | None = None
    provider_name: str | None = None
    doctor_name: str | None = None
    record_date: datetime | None = None
    fhir_resource_type: str | None = None
    fhir_payload: dict[str, Any] | None = None


class MedicalRecordRead(MedicalRecordBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
