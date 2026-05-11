from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import Appointment, ConsultationLog, DoctorProfile
from app.models.user import User
from app.schemas.advanced_schema import AppointmentCreate, AppointmentRead, DoctorProfileRead
from app.services.audit_service import write_audit_log
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/telemedicine", tags=["telemedicine"])


@router.get("/doctors", response_model=list[DoctorProfileRead])
def list_doctors(db: Session = Depends(get_db)) -> list[DoctorProfile]:
    doctors = db.query(DoctorProfile).order_by(DoctorProfile.rating.desc().nullslast()).all()
    if doctors:
        return doctors
    demo_doctors = [
        DoctorProfile(
            full_name="Dr. Ananya Rao",
            specialty="Internal Medicine",
            hospital_name="MedID Virtual Care",
            city="Chennai",
            rating=4.8,
            languages=["English", "Tamil", "Hindi"],
        ),
        DoctorProfile(
            full_name="Dr. Kiran Mehta",
            specialty="Cardiology",
            hospital_name="MedID Heart Clinic",
            city="Bengaluru",
            rating=4.7,
            languages=["English", "Hindi", "Telugu"],
        ),
    ]
    db.add_all(demo_doctors)
    db.commit()
    return demo_doctors


@router.get("/appointments", response_model=list[AppointmentRead])
def list_appointments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Appointment]:
    return db.query(Appointment).filter(Appointment.user_id == current_user.id).order_by(Appointment.scheduled_at.asc()).all()


@router.post("/appointments", response_model=AppointmentRead, status_code=status.HTTP_201_CREATED)
def book_appointment(
    payload: AppointmentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Appointment:
    appointment = Appointment(
        user_id=current_user.id,
        meeting_url="https://meet.medidconnect.com/demo-room",
        **payload.model_dump(),
    )
    db.add(appointment)
    write_audit_log(db, current_user.id, "book", "appointment", str(payload.doctor_id))
    db.commit()
    db.refresh(appointment)
    return appointment


@router.post("/appointments/{appointment_id}/consultation-log")
def create_consultation_log(
    appointment_id: int,
    notes: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, int]:
    appointment = db.get(Appointment, appointment_id)
    if appointment is None or appointment.user_id != current_user.id:
        from fastapi import HTTPException

        raise HTTPException(status_code=404, detail="Appointment not found")
    log = ConsultationLog(user_id=current_user.id, appointment_id=appointment.id, doctor_id=appointment.doctor_id, notes=notes)
    db.add(log)
    write_audit_log(db, current_user.id, "create", "consultation_log", str(appointment.id))
    db.commit()
    return {"consultation_log_id": log.id}
