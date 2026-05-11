from datetime import datetime, UTC

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import SecurityEvent, UserDevice, UserSession
from app.models.user import User
from app.schemas.advanced_schema import DeviceRegisterRequest, SecurityEventRead
from app.services.audit_service import write_audit_log
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/security", tags=["security"])


@router.post("/devices")
def register_device(
    payload: DeviceRegisterRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    device = (
        db.query(UserDevice)
        .filter(UserDevice.user_id == current_user.id, UserDevice.device_id == payload.device_id)
        .first()
    )
    ip_address = request.client.host if request.client else None
    if device:
        device.last_seen_at = datetime.now(UTC)
        device.last_ip_address = ip_address
    else:
        db.add(UserDevice(user_id=current_user.id, **payload.model_dump(), last_seen_at=datetime.now(UTC), last_ip_address=ip_address))
    db.add(
        SecurityEvent(
            user_id=current_user.id,
            event_type="device_seen",
            severity="info",
            ip_address=ip_address,
            user_agent=request.headers.get("user-agent"),
            details={"device_id": payload.device_id, "biometric_ready": True},
        )
    )
    write_audit_log(db, current_user.id, "register", "device", payload.device_id)
    db.commit()
    return {"status": "device_registered"}


@router.get("/sessions")
def sessions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[dict[str, object]]:
    rows = db.query(UserSession).filter(UserSession.user_id == current_user.id).order_by(UserSession.created_at.desc()).all()
    return [
        {
            "id": row.id,
            "device_id": row.device_id,
            "ip_address": row.ip_address,
            "active": row.active,
            "created_at": row.created_at,
        }
        for row in rows
    ]


@router.get("/events", response_model=list[SecurityEventRead])
def security_events(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[SecurityEvent]:
    return db.query(SecurityEvent).filter(SecurityEvent.user_id == current_user.id).order_by(SecurityEvent.created_at.desc()).limit(50).all()


@router.post("/biometric/verify-placeholder")
def biometric_placeholder(current_user: User = Depends(get_current_user)) -> dict[str, object]:
    return {
        "enabled": True,
        "message": "Client-side biometric verification should use local_auth and never send biometric material to this API.",
        "user_id": current_user.id,
    }
