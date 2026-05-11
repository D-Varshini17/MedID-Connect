from datetime import UTC, datetime

from fastapi import HTTPException, Request, status
from sqlalchemy.orm import Session

from app.config import settings
from app.models.interop import Consent, ConsentAccessLog
from app.utils.security import generate_opaque_token, hash_opaque_token


def create_share_consent(db: Session, user_id: int, payload) -> tuple[Consent, str]:
    raw_token = generate_opaque_token()
    consent = Consent(user_id=user_id, access_token_hash=hash_opaque_token(raw_token), **payload.model_dump())
    db.add(consent)
    db.flush()
    return consent, raw_token


def share_url(raw_token: str) -> str:
    return f"{settings.backend_public_url.rstrip('/')}/api/share/{raw_token}/summary"


def validate_share_token(db: Session, raw_token: str, request: Request, resource: str) -> Consent:
    consent = db.query(Consent).filter(Consent.access_token_hash == hash_opaque_token(raw_token)).first()
    if consent is None or consent.revoked_at is not None or consent.expires_at < datetime.now(UTC):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share link expired or revoked")
    if resource != "summary" and resource not in consent.allowed_resources:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"{resource} not allowed by consent")
    db.add(
        ConsentAccessLog(
            consent_id=consent.id,
            accessed_by=consent.grantee_name,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
            resource_accessed=resource,
        )
    )
    db.commit()
    return consent
