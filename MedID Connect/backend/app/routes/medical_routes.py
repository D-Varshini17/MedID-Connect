from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.medical_record import MedicalRecord
from app.models.user import User
from app.schemas.medical_schema import MedicalRecordCreate, MedicalRecordRead, MedicalRecordUpdate
from app.services.audit_service import write_audit_log
from app.services.encryption_service import encrypt_sensitive_payload
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/records", tags=["medical records"])


@router.get("", response_model=list[MedicalRecordRead])
def list_records(
    record_type: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MedicalRecord]:
    query = db.query(MedicalRecord).filter(MedicalRecord.user_id == current_user.id)
    if record_type:
        query = query.filter(MedicalRecord.record_type == record_type)
    return query.order_by(MedicalRecord.record_date.desc()).all()


@router.post("", response_model=MedicalRecordRead, status_code=status.HTTP_201_CREATED)
def create_record(
    payload: MedicalRecordCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MedicalRecord:
    record = MedicalRecord(
        user_id=current_user.id,
        **payload.model_dump(exclude={"fhir_payload"}),
        fhir_payload=encrypt_sensitive_payload(payload.fhir_payload),
    )
    db.add(record)
    db.flush()
    write_audit_log(db, current_user.id, "create", "medical_record", str(record.id))
    db.commit()
    db.refresh(record)
    return record


@router.get("/{record_id}", response_model=MedicalRecordRead)
def get_record(
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MedicalRecord:
    record = db.get(MedicalRecord, record_id)
    if record is None or record.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Record not found")
    return record


@router.put("/{record_id}", response_model=MedicalRecordRead)
def update_record(
    record_id: int,
    payload: MedicalRecordUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MedicalRecord:
    record = get_record(record_id, current_user, db)
    for key, value in payload.model_dump(exclude_unset=True).items():
        if key == "fhir_payload" and value is not None:
            value = encrypt_sensitive_payload(value)
        setattr(record, key, value)
    write_audit_log(db, current_user.id, "update", "medical_record", str(record.id))
    db.commit()
    db.refresh(record)
    return record


@router.delete("/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_record(
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    record = get_record(record_id, current_user, db)
    db.delete(record)
    write_audit_log(db, current_user.id, "delete", "medical_record", str(record_id))
    db.commit()
