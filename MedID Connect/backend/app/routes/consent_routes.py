from datetime import datetime, UTC

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.interop import Consent, ConsentAccessLog
from app.models.medical_record import MedicalRecord
from app.models.medication import Allergy, Medication
from app.models.observation import Observation
from app.models.user import User
from app.schemas.interop_schema import (
    ConsentAccessLogRead,
    ConsentCreate,
    ConsentCreateResponse,
    ConsentRead,
)
from app.services.audit_service import write_audit_log
from app.services.consent_service import create_share_consent, share_url, validate_share_token
from app.services.fhir_mapper import (
    allergy_to_fhir,
    bundle,
    condition_to_fhir,
    diagnostic_report_to_fhir,
    medication_to_fhir_medication_request,
    observation_to_fhir,
    user_to_fhir_patient,
)
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/consents", tags=["consent"])
share_router = APIRouter(prefix="/api/share", tags=["public-hospital-share"])


def _with_share_url(consent: Consent) -> ConsentRead:
    return ConsentRead.model_validate(consent).model_copy(
        update={"share_url": "Share URL is only shown immediately after creation for security."}
    )


@router.get("", response_model=list[ConsentRead])
def list_consents(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ConsentRead]:
    consents = db.query(Consent).filter(Consent.user_id == current_user.id).order_by(Consent.created_at.desc()).all()
    return [_with_share_url(consent) for consent in consents]


@router.post("", response_model=ConsentCreateResponse, status_code=status.HTTP_201_CREATED)
def create_consent(
    payload: ConsentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConsentCreateResponse:
    consent, raw_token = create_share_consent(db, current_user.id, payload)
    write_audit_log(db, current_user.id, "create", "consent", str(consent.id))
    db.commit()
    db.refresh(consent)
    base = ConsentRead.model_validate(consent).model_dump()
    return ConsentCreateResponse(**base, share_token=raw_token, share_url=share_url(raw_token))


@router.delete("/{consent_id}/revoke", response_model=ConsentRead)
@router.post("/{consent_id}/revoke", response_model=ConsentRead)
def revoke_consent(
    consent_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConsentRead:
    consent = db.get(Consent, consent_id)
    if consent is None or consent.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Consent not found")
    consent.revoked_at = datetime.now(UTC)
    write_audit_log(db, current_user.id, "revoke", "consent", str(consent.id))
    db.commit()
    db.refresh(consent)
    return _with_share_url(consent)


@router.get("/{consent_id}/logs", response_model=list[ConsentAccessLogRead])
def consent_logs(
    consent_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ConsentAccessLog]:
    consent = db.get(Consent, consent_id)
    if consent is None or consent.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Consent not found")
    return (
        db.query(ConsentAccessLog)
        .filter(ConsentAccessLog.consent_id == consent.id)
        .order_by(ConsentAccessLog.accessed_at.desc())
        .all()
    )


def _share_resources(db: Session, user_id: int, resource: str) -> list[dict]:
    if resource == "Patient":
        user = db.get(User, user_id)
        return [user_to_fhir_patient(user)] if user else []
    if resource == "Observation":
        return [observation_to_fhir(row) for row in db.query(Observation).filter(Observation.user_id == user_id).all()]
    if resource == "MedicationRequest":
        return [medication_to_fhir_medication_request(row) for row in db.query(Medication).filter(Medication.user_id == user_id).all()]
    if resource == "AllergyIntolerance":
        return [allergy_to_fhir(row) for row in db.query(Allergy).filter(Allergy.user_id == user_id).all()]
    if resource == "Condition":
        rows = db.query(MedicalRecord).filter(MedicalRecord.user_id == user_id, MedicalRecord.record_type.ilike("%diagnosis%")).all()
        return [condition_to_fhir(row) for row in rows]
    if resource == "DiagnosticReport":
        rows = db.query(MedicalRecord).filter(MedicalRecord.user_id == user_id, MedicalRecord.record_type.ilike("%lab%")).all()
        return [diagnostic_report_to_fhir(row) for row in rows]
    return []


@share_router.get("/{share_token}/summary")
def share_summary(share_token: str, request: Request, db: Session = Depends(get_db)) -> dict:
    consent = validate_share_token(db, share_token, request, "summary")
    user = db.get(User, consent.user_id)
    return {
        "patient": user_to_fhir_patient(user) if user else None,
        "grantee": consent.grantee_name,
        "purpose": consent.purpose,
        "allowed_resources": consent.allowed_resources,
        "expires_at": consent.expires_at,
        "disclaimer": "Shared by patient consent. Access is logged by MedID Connect.",
    }


@share_router.get("/{share_token}/fhir/{resource_type}")
def share_fhir_resource(share_token: str, resource_type: str, request: Request, db: Session = Depends(get_db)) -> dict:
    consent = validate_share_token(db, share_token, request, resource_type)
    return bundle(_share_resources(db, consent.user_id, resource_type))
