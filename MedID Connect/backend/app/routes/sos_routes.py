from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import SosAlert
from app.models.user import User
from app.schemas.productivity_schema import SosAlertCreate, SosAlertRead
from app.services.audit_service import write_audit_log
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/sos", tags=["sos"])


@router.post("/alert", response_model=SosAlertRead, status_code=status.HTTP_201_CREATED)
def create_sos_alert(
    payload: SosAlertCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SosAlert:
    contact = current_user.emergency_contacts[0] if current_user.emergency_contacts else None
    alert = SosAlert(
        user_id=current_user.id,
        message=payload.message,
        latitude=payload.latitude,
        longitude=payload.longitude,
        emergency_contact_name=contact.name if contact else None,
        emergency_contact_phone=contact.phone if contact else None,
        status="mock_sent",
    )
    db.add(alert)
    write_audit_log(db, current_user.id, "mock_send", "sos_alert", None)
    db.commit()
    db.refresh(alert)
    return alert


@router.get("/alerts", response_model=list[SosAlertRead])
def list_sos_alerts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[SosAlert]:
    return db.query(SosAlert).filter(SosAlert.user_id == current_user.id).order_by(SosAlert.created_at.desc()).limit(20).all()
