from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import Notification, SupportTicket, UploadedDocument
from app.models.audit_log import AuditLog
from app.models.emergency import EmergencyAccessLog
from app.models.medical_record import MedicalRecord
from app.models.user import User
from app.schemas.advanced_schema import AdminAnalyticsResponse, SupportTicketCreate
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/admin", tags=["admin"])


def _admin_ready(current_user: User) -> bool:
    # Replace with enterprise RBAC/SSO. For now every authenticated user can
    # see demo admin aggregates in local hackathon builds.
    return bool(current_user.id)


@router.get("/analytics", response_model=AdminAnalyticsResponse)
def analytics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AdminAnalyticsResponse:
    _admin_ready(current_user)
    return AdminAnalyticsResponse(
        total_users=db.query(User).count(),
        total_records=db.query(MedicalRecord).count(),
        total_emergency_accesses=db.query(EmergencyAccessLog).count(),
        total_notifications=db.query(Notification).count(),
        open_support_tickets=db.query(SupportTicket).filter(SupportTicket.status == "open").count(),
        ai_documents_processed=db.query(UploadedDocument).count(),
    )


@router.get("/audit-logs")
def audit_logs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[dict[str, object]]:
    _admin_ready(current_user)
    rows = db.query(AuditLog).order_by(AuditLog.timestamp.desc()).limit(100).all()
    return [
        {
            "id": row.id,
            "user_id": row.user_id,
            "action": row.action,
            "resource_type": row.resource_type,
            "resource_id": row.resource_id,
            "timestamp": row.timestamp,
        }
        for row in rows
    ]


@router.post("/support-tickets", status_code=status.HTTP_201_CREATED)
def create_support_ticket(
    payload: SupportTicketCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, int]:
    ticket = SupportTicket(user_id=current_user.id, **payload.model_dump())
    db.add(ticket)
    db.commit()
    return {"ticket_id": ticket.id}
