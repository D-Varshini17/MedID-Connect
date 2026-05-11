from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.medical_record import MedicalRecord
from app.models.medication import Allergy, Medication
from app.models.user import User
from app.schemas.productivity_schema import HealthWalletSummary
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/wallet", tags=["smart-health-wallet"])


@router.get("/summary", response_model=HealthWalletSummary)
def wallet_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HealthWalletSummary:
    allergies = db.query(Allergy).filter(Allergy.user_id == current_user.id).all()
    medications = db.query(Medication).filter(Medication.user_id == current_user.id, Medication.active.is_(True)).all()
    conditions = (
        db.query(MedicalRecord)
        .filter(MedicalRecord.user_id == current_user.id, MedicalRecord.record_type.ilike("%diagnosis%"))
        .limit(8)
        .all()
    )
    vaccinations = (
        db.query(MedicalRecord)
        .filter(MedicalRecord.user_id == current_user.id, MedicalRecord.record_type.ilike("%vaccination%"))
        .limit(6)
        .all()
    )
    emergency_contacts = current_user.emergency_contacts
    emergency_card = {
        "name": current_user.full_name,
        "blood_group": current_user.blood_group,
        "allergies": [row.allergen for row in allergies],
        "medications": [row.medicine_name for row in medications],
        "contacts": [row.phone for row in emergency_contacts],
        "chronic_conditions": [row.title for row in conditions],
    }
    return HealthWalletSummary(
        patient={
            "id": current_user.id,
            "name": current_user.full_name,
            "age": current_user.age,
            "gender": current_user.gender,
            "phone": current_user.phone,
        },
        blood_group=current_user.blood_group,
        allergies=[{"id": row.id, "allergen": row.allergen, "severity": row.severity, "reaction": row.reaction} for row in allergies],
        chronic_conditions=[{"id": row.id, "title": row.title, "provider": row.provider_name} for row in conditions],
        current_medications=[{"id": row.id, "medicine_name": row.medicine_name, "dosage": row.dosage, "frequency": row.frequency} for row in medications],
        emergency_contacts=[
            {"id": row.id, "name": row.name, "relationship": row.relationship, "phone": row.phone, "email": row.email}
            for row in emergency_contacts
        ],
        vaccination_summary=[{"id": row.id, "title": row.title, "date": row.record_date.isoformat()} for row in vaccinations],
        insurance_id_placeholder="INS-MEDID-0000",
        emergency_card=emergency_card,
    )
