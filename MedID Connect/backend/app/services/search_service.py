import re
from datetime import datetime
from typing import Any

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.medical_record import MedicalRecord
from app.models.observation import Observation


def natural_record_search(db: Session, user_id: int, query: str) -> dict[str, Any]:
    lower = query.lower()
    interpreted: dict[str, Any] = {"raw": query}
    results: list[dict[str, Any]] = []

    record_query = db.query(MedicalRecord).filter(MedicalRecord.user_id == user_id)
    if "diabetes" in lower or "sugar" in lower:
        interpreted["topic"] = "diabetes"
        record_query = record_query.filter(
            or_(
                MedicalRecord.title.ilike("%diabetes%"),
                MedicalRecord.description.ilike("%diabetes%"),
                MedicalRecord.title.ilike("%glucose%"),
                MedicalRecord.description.ilike("%glucose%"),
            )
        )
    if "cholesterol" in lower:
        interpreted["topic"] = "cholesterol"
        record_query = record_query.filter(
            or_(MedicalRecord.title.ilike("%cholesterol%"), MedicalRecord.description.ilike("%cholesterol%"))
        )
    month_match = re.search(
        r"(january|february|march|april|may|june|july|august|september|october|november|december)",
        lower,
    )
    if month_match:
        interpreted["month"] = month_match.group(1)

    for record in record_query.order_by(MedicalRecord.record_date.desc()).limit(12).all():
        results.append(
            {
                "kind": "medical_record",
                "id": record.id,
                "title": record.title,
                "record_type": record.record_type,
                "date": record.record_date.isoformat(),
            }
        )

    above_match = re.search(r"(?:above|over|greater than)\s+(\d+)", lower)
    if "bp" in lower or "blood pressure" in lower:
        interpreted["observation_type"] = "Blood Pressure"
        observation_query = db.query(Observation).filter(
            Observation.user_id == user_id, Observation.observation_type.ilike("%blood%")
        )
        if above_match:
            threshold = float(above_match.group(1))
            interpreted["value_above"] = threshold
            observation_query = observation_query.filter(Observation.value > threshold)
        for observation in observation_query.order_by(Observation.observed_at.desc()).limit(12).all():
            results.append(
                {
                    "kind": "observation",
                    "id": observation.id,
                    "title": observation.observation_type,
                    "value": observation.value,
                    "unit": observation.unit,
                    "status": observation.status,
                    "date": observation.observed_at.isoformat(),
                }
            )

    interpreted["vector_search"] = "ready_for_pgvector_or_managed_vector_db"
    interpreted["searched_at"] = datetime.utcnow().isoformat()
    return {"interpreted_filters": interpreted, "results": results, "semantic_search_ready": True}
