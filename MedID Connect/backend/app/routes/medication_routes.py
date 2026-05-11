from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.medication import Medication
from app.models.user import User
from app.schemas.medication_schema import (
    MedicationCreate,
    MedicationRead,
    MedicationUpdate,
    SafetyCheckResponse,
)
from app.services.audit_service import write_audit_log
from app.services.safety_checker import check_medication_safety
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/medications", tags=["medications"])


@router.get("", response_model=list[MedicationRead])
def list_medications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Medication]:
    return db.query(Medication).filter(Medication.user_id == current_user.id).order_by(Medication.created_at.desc()).all()


@router.get("/safety-check", response_model=SafetyCheckResponse)
def safety_check(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SafetyCheckResponse:
    return SafetyCheckResponse(warnings=check_medication_safety(db, current_user.id))


@router.post("", response_model=MedicationRead, status_code=status.HTTP_201_CREATED)
def create_medication(
    payload: MedicationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Medication:
    medication = Medication(user_id=current_user.id, **payload.model_dump())
    db.add(medication)
    db.flush()
    write_audit_log(db, current_user.id, "create", "medication", str(medication.id))
    db.commit()
    db.refresh(medication)
    return medication


@router.put("/{medication_id}", response_model=MedicationRead)
def update_medication(
    medication_id: int,
    payload: MedicationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Medication:
    medication = db.get(Medication, medication_id)
    if medication is None or medication.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medication not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(medication, key, value)
    write_audit_log(db, current_user.id, "update", "medication", str(medication.id))
    db.commit()
    db.refresh(medication)
    return medication


@router.delete("/{medication_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_medication(
    medication_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    medication = db.get(Medication, medication_id)
    if medication is None or medication.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medication not found")
    db.delete(medication)
    write_audit_log(db, current_user.id, "delete", "medication", str(medication_id))
    db.commit()
