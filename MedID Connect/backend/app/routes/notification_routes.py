from datetime import datetime, UTC

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import Notification, NotificationDevice
from app.models.user import User
from app.schemas.advanced_schema import NotificationDeviceCreate, NotificationRead
from app.services.audit_service import write_audit_log
from app.services.notification_service import create_notification
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.post("/devices", status_code=status.HTTP_201_CREATED)
def register_device(
    payload: NotificationDeviceCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    existing = (
        db.query(NotificationDevice)
        .filter(NotificationDevice.user_id == current_user.id, NotificationDevice.fcm_token == payload.fcm_token)
        .first()
    )
    if existing:
        existing.last_seen_at = datetime.now(UTC)
        existing.enabled = True
    else:
        db.add(NotificationDevice(user_id=current_user.id, **payload.model_dump(), last_seen_at=datetime.now(UTC)))
    write_audit_log(db, current_user.id, "register", "notification_device", payload.device_id)
    db.commit()
    return {"status": "registered"}


@router.get("", response_model=list[NotificationRead])
def list_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Notification]:
    return db.query(Notification).filter(Notification.user_id == current_user.id).order_by(Notification.created_at.desc()).limit(50).all()


@router.post("/demo-alert", response_model=NotificationRead, status_code=status.HTTP_201_CREATED)
def create_demo_alert(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Notification:
    notification = create_notification(
        db,
        current_user.id,
        "Medication reminder",
        "It is time for your evening dose.",
        "medication_reminder",
        "high",
        {"fcm_placeholder": True},
    )
    write_audit_log(db, current_user.id, "create", "notification", str(notification.id))
    db.commit()
    db.refresh(notification)
    return notification


@router.put("/{notification_id}/read", response_model=NotificationRead)
def mark_read(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Notification:
    notification = db.get(Notification, notification_id)
    if notification is None or notification.user_id != current_user.id:
        from fastapi import HTTPException

        raise HTTPException(status_code=404, detail="Notification not found")
    notification.read_at = datetime.now(UTC)
    db.commit()
    db.refresh(notification)
    return notification
