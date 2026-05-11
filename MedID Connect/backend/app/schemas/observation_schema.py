from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ObservationBase(BaseModel):
    observation_type: str = Field(min_length=2, max_length=80)
    value: float
    unit: str | None = None
    normal_min: float | None = None
    normal_max: float | None = None
    status: str = "normal"
    observed_at: datetime
    fhir_payload: dict[str, Any] = {}


class ObservationCreate(ObservationBase):
    pass


class ObservationRead(ObservationBase):
    id: int
    user_id: int

    model_config = ConfigDict(from_attributes=True)


class ObservationTrend(BaseModel):
    observation_type: str
    points: list[ObservationRead]
