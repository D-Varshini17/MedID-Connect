from datetime import datetime, UTC

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import MedicationLog, MedicationSchedule
from app.models.medication import Medication
from app.models.user import User
from app.schemas.advanced_schema import (
    DailyMedicationChecklist,
    MedicationLogCreate,
    MedicationLogRead,
    MedicationScheduleCreate,
    MedicationScheduleRead,
)
from app.services.audit_service import write_audit_log
from app.services.safety_checker import check_medication_safety
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/medication-engine", tags=["smart-medication-engine"])


def _ensure_owned_medication(db: Session, user_id: int, medication_id: int) -> Medication:
    medication = db.get(Medication, medication_id)
    if medication is None or medication.user_id != user_id:
        raise HTTPException(status_code=404, detail="Medication not found")
    return medication


@router.get("/schedules", response_model=list[MedicationScheduleRead])
def list_schedules(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MedicationSchedule]:
    return db.query(MedicationSchedule).filter(MedicationSchedule.user_id == current_user.id).order_by(MedicationSchedule.schedule_time.asc()).all()


@router.post("/schedules", response_model=MedicationScheduleRead, status_code=status.HTTP_201_CREATED)
def create_schedule(
    payload: MedicationScheduleCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MedicationSchedule:
    _ensure_owned_medication(db, current_user.id, payload.medication_id)
    schedule = MedicationSchedule(user_id=current_user.id, **payload.model_dump())
    db.add(schedule)
    write_audit_log(db, current_user.id, "create", "medication_schedule", str(payload.medication_id))
    db.commit()
    db.refresh(schedule)
    return schedule


@router.post("/logs", response_model=MedicationLogRead, status_code=status.HTTP_201_CREATED)
def create_log(
    payload: MedicationLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MedicationLog:
    _ensure_owned_medication(db, current_user.id, payload.medication_id)
    log = MedicationLog(user_id=current_user.id, taken_at=payload.taken_at or datetime.now(UTC), **payload.model_dump(exclude={"taken_at"}))
    db.add(log)
    write_audit_log(db, current_user.id, payload.status, "medication_log", str(payload.medication_id))
    db.commit()
    db.refresh(log)
    return log


@router.get("/daily-checklist", response_model=DailyMedicationChecklist)
def daily_checklist(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> DailyMedicationChecklist:
    medications = db.query(Medication).filter(Medication.user_id == current_user.id, Medication.active.is_(True)).all()
    schedules = {schedule.medication_id: schedule for schedule in list_schedules(current_user, db)}
    logs = db.query(MedicationLog).filter(MedicationLog.user_id == current_user.id).all()
    logged_medication_ids = {log.medication_id for log in logs if log.status == "taken"}
    items = [
        {
            "medication_id": medication.id,
            "medicine_name": medication.medicine_name,
            "dosage": medication.dosage,
            "schedule_time": schedules.get(medication.id).schedule_time if medication.id in schedules else "Not scheduled",
            "status": "taken" if medication.id in logged_medication_ids else "pending",
        }
        for medication in medications
    ]
    return DailyMedicationChecklist(
        date=datetime.now(UTC),
        items=items,
        safety_warnings=[warning.model_dump() for warning in check_medication_safety(db, current_user.id)],
    )
