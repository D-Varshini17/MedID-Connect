from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class AllergyRead(BaseModel):
    id: int
    allergen: str
    severity: str | None = None
    reaction: str | None = None

    model_config = ConfigDict(from_attributes=True)


class MedicationBase(BaseModel):
    medicine_name: str = Field(min_length=2, max_length=180)
    dosage: str | None = None
    frequency: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    prescribing_doctor: str | None = None
    active: bool = True
    notes: str | None = None


class MedicationCreate(MedicationBase):
    pass


class MedicationUpdate(BaseModel):
    medicine_name: str | None = None
    dosage: str | None = None
    frequency: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    prescribing_doctor: str | None = None
    active: bool | None = None
    notes: str | None = None


class MedicationRead(MedicationBase):
    id: int
    user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SafetyWarning(BaseModel):
    medication_id: int | None = None
    medicine_name: str
    warning: str
    severity: str


class SafetyCheckResponse(BaseModel):
    warnings: list[SafetyWarning]
