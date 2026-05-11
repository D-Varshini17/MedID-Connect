from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.emergency import EmergencyAccessLog
from app.models.user import User
from app.schemas.emergency_schema import (
    EmergencyAccessLogRead,
    EmergencyTokenRequest,
    EmergencyTokenResponse,
    EmergencyViewResponse,
)
from app.services.audit_service import write_audit_log
from app.services.emergency_service import (
    create_emergency_token,
    emergency_url,
    get_emergency_view,
    revoke_emergency_token,
)
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/emergency", tags=["emergency"])


@router.post("/token", response_model=EmergencyTokenResponse)
def issue_emergency_token(
    payload: EmergencyTokenRequest | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> EmergencyTokenResponse:
    expires = payload.expires_in_minutes if payload else None
    token_row, raw_token = create_emergency_token(db, current_user, expires)
    write_audit_log(db, current_user.id, "create", "emergency_token", str(token_row.id))
    db.commit()
    return EmergencyTokenResponse(
        token=raw_token,
        emergency_url=emergency_url(raw_token),
        expires_at=token_row.expires_at,
    )


@router.get("/view/{token}", response_model=EmergencyViewResponse)
def view_emergency(token: str, request: Request, db: Session = Depends(get_db)) -> dict:
    return get_emergency_view(db, token, request)


@router.post("/revoke/{token}", status_code=status.HTTP_204_NO_CONTENT)
def revoke_token(
    token: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    revoke_emergency_token(db, token, current_user.id)
    write_audit_log(db, current_user.id, "revoke", "emergency_token", None)
    db.commit()


@router.get("/logs", response_model=list[EmergencyAccessLogRead])
def emergency_logs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[EmergencyAccessLog]:
    return (
        db.query(EmergencyAccessLog)
        .filter(EmergencyAccessLog.user_id == current_user.id)
        .order_by(EmergencyAccessLog.accessed_at.desc())
        .all()
    )
