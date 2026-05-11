from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import Appointment
from app.models.interop import Consent
from app.models.medical_record import MedicalRecord
from app.models.medication import Allergy, Medication
from app.models.observation import Observation
from app.models.user import User
from app.services.fhir_mapper import (
    allergy_to_fhir,
    appointment_to_fhir,
    bundle,
    condition_to_fhir,
    consent_to_fhir,
    diagnostic_report_to_fhir,
    immunization_to_fhir,
    medication_to_fhir_medication_request,
    observation_to_fhir,
    user_to_fhir_patient,
)
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/fhir", tags=["fhir-r4"])


def _ensure_patient_access(patient_id: int, current_user: User) -> None:
    if patient_id != current_user.id:
        raise HTTPException(status_code=403, detail="FHIR patient access denied")


@router.get("/Patient/{patient_id}")
def fhir_patient(patient_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient_id, current_user)
    user = db.get(User, patient_id)
    if user is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    return user_to_fhir_patient(user)


@router.get("/Observation")
def fhir_observations(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(Observation).filter(Observation.user_id == patient).all()
    return bundle([observation_to_fhir(row) for row in rows])


@router.get("/Condition")
def fhir_conditions(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(MedicalRecord).filter(MedicalRecord.user_id == patient, MedicalRecord.record_type.ilike("%diagnosis%")).all()
    return bundle([condition_to_fhir(row) for row in rows])


@router.get("/MedicationRequest")
def fhir_medications(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(Medication).filter(Medication.user_id == patient).all()
    return bundle([medication_to_fhir_medication_request(row) for row in rows])


@router.get("/AllergyIntolerance")
def fhir_allergies(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(Allergy).filter(Allergy.user_id == patient).all()
    return bundle([allergy_to_fhir(row) for row in rows])


@router.get("/DiagnosticReport")
def fhir_diagnostic_reports(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(MedicalRecord).filter(MedicalRecord.user_id == patient, MedicalRecord.record_type.ilike("%lab%")).all()
    return bundle([diagnostic_report_to_fhir(row) for row in rows])


@router.get("/Immunization")
def fhir_immunizations(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(MedicalRecord).filter(MedicalRecord.user_id == patient, MedicalRecord.record_type.ilike("%vaccination%")).all()
    return bundle([immunization_to_fhir(row) for row in rows])


@router.get("/Appointment")
def fhir_appointments(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(Appointment).filter(Appointment.user_id == patient).all()
    return bundle([appointment_to_fhir(row) for row in rows])


@router.get("/Consent")
def fhir_consents(patient: int = Query(...), current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    _ensure_patient_access(patient, current_user)
    rows = db.query(Consent).filter(Consent.user_id == patient).all()
    return bundle([consent_to_fhir(row) for row in rows])
