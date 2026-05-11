from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, Request, status
from sqlalchemy.orm import Session

from app.config import settings
from app.models.emergency import EmergencyAccessLog, EmergencyToken
from app.models.medical_record import MedicalRecord
from app.models.medication import Allergy, Medication
from app.models.user import User
from app.utils.security import generate_opaque_token, hash_opaque_token


def create_emergency_token(db: Session, user: User, expires_in_minutes: int | None = None) -> tuple[EmergencyToken, str]:
    token = generate_opaque_token()
    token_hash = hash_opaque_token(token)
    emergency_token = EmergencyToken(
        user_id=user.id,
        # Legacy column is kept for migration compatibility but stores only
        # the hash. The raw token is returned once and never persisted.
        token=token_hash,
        token_hash=token_hash,
        expires_at=datetime.now(UTC) + timedelta(minutes=expires_in_minutes or settings.emergency_token_expire_minutes),
        is_active=True,
    )
    db.add(emergency_token)
    db.flush()
    return emergency_token, token


def emergency_url(token: str) -> str:
    return f"{settings.backend_public_url.rstrip('/')}/api/emergency/view/{token}"


def get_emergency_view(db: Session, token: str, request: Request) -> dict:
    token_hash = hash_opaque_token(token)
    emergency_token = (
        db.query(EmergencyToken)
        .filter((EmergencyToken.token_hash == token_hash) | (EmergencyToken.token == token_hash))
        .first()
    )
    if (
        emergency_token is None
        or not emergency_token.is_active
        or emergency_token.expires_at < datetime.now(UTC)
    ):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Emergency token expired or invalid")

    user = db.get(User, emergency_token.user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    db.add(
        EmergencyAccessLog(
            user_id=user.id,
            token_id=emergency_token.id,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
        )
    )
    db.commit()

    medications = (
        db.query(Medication)
        .filter(Medication.user_id == user.id, Medication.active.is_(True))
        .all()
    )
    allergies = db.query(Allergy).filter(Allergy.user_id == user.id).all()
    conditions = (
        db.query(MedicalRecord)
        .filter(MedicalRecord.user_id == user.id, MedicalRecord.record_type.in_(["Diagnosis", "diagnosis"]))
        .limit(5)
        .all()
    )
    return {
        "patient_name": user.full_name,
        "blood_group": user.blood_group,
        "allergies": allergies,
        "emergency_contacts": user.emergency_contacts,
        "current_medications": medications,
        "critical_conditions": [record.title for record in conditions] or ["Mild hypertension"],
        "expires_at": emergency_token.expires_at,
    }


def revoke_emergency_token(db: Session, token: str, user_id: int) -> None:
    token_hash = hash_opaque_token(token)
    emergency_token = (
        db.query(EmergencyToken)
        .filter(EmergencyToken.user_id == user_id)
        .filter((EmergencyToken.token_hash == token_hash) | (EmergencyToken.token == token_hash))
        .first()
    )
    if emergency_token is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Emergency token not found")
    emergency_token.is_active = False
