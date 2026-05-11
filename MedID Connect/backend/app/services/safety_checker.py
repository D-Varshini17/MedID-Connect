from sqlalchemy.orm import Session

from app.models.medication import Allergy, Medication
from app.schemas.medication_schema import SafetyWarning


def check_medication_safety(db: Session, user_id: int) -> list[SafetyWarning]:
    allergies = db.query(Allergy).filter(Allergy.user_id == user_id).all()
    medications = db.query(Medication).filter(Medication.user_id == user_id).all()
    warnings: list[SafetyWarning] = []

    for medication in medications:
        med_name = medication.medicine_name.lower()
        for allergy in allergies:
            allergen = allergy.allergen.lower()
            if allergen and allergen in med_name:
                warnings.append(
                    SafetyWarning(
                        medication_id=medication.id,
                        medicine_name=medication.medicine_name,
                        warning=f"{medication.medicine_name} may conflict with allergy: {allergy.allergen}.",
                        severity=allergy.severity or "high",
                    )
                )

    if not warnings:
        for medication in medications:
            if "cetirizine" in medication.medicine_name.lower():
                warnings.append(
                    SafetyWarning(
                        medication_id=medication.id,
                        medicine_name=medication.medicine_name,
                        warning="Cetirizine may cause drowsiness and should not be mixed with alcohol or sedatives.",
                        severity="moderate",
                    )
                )
    return warnings
