from datetime import datetime, timedelta, UTC
from secrets import token_urlsafe

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import AccessRole, FamilyInvitation, FamilyMember
from app.models.user import User
from app.schemas.advanced_schema import (
    FamilyInvitationCreate,
    FamilyInvitationRead,
    FamilyMemberCreate,
    FamilyMemberRead,
)
from app.services.audit_service import write_audit_log
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/family", tags=["family-vault"])


@router.get("/members", response_model=list[FamilyMemberRead])
def list_family_members(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[FamilyMember]:
    return db.query(FamilyMember).filter(FamilyMember.owner_user_id == current_user.id).order_by(FamilyMember.created_at.desc()).all()


@router.post("/members", response_model=FamilyMemberRead, status_code=status.HTTP_201_CREATED)
def create_family_member(
    payload: FamilyMemberCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FamilyMember:
    member = FamilyMember(owner_user_id=current_user.id, **payload.model_dump())
    db.add(member)
    db.flush()
    db.add(
        AccessRole(
            family_member_id=member.id,
            user_id=current_user.id,
            role="owner",
            permissions=["read", "write", "share", "emergency"],
        )
    )
    write_audit_log(db, current_user.id, "create", "family_member", str(member.id))
    db.commit()
    db.refresh(member)
    return member


@router.put("/members/{member_id}", response_model=FamilyMemberRead)
def update_family_member(
    member_id: int,
    payload: FamilyMemberCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FamilyMember:
    member = db.get(FamilyMember, member_id)
    if member is None or member.owner_user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Family member not found")
    for key, value in payload.model_dump().items():
        setattr(member, key, value)
    write_audit_log(db, current_user.id, "update", "family_member", str(member.id))
    db.commit()
    db.refresh(member)
    return member


@router.delete("/members/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_family_member(
    member_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    member = db.get(FamilyMember, member_id)
    if member is None or member.owner_user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Family member not found")
    db.delete(member)
    write_audit_log(db, current_user.id, "delete", "family_member", str(member_id))
    db.commit()


@router.post("/invitations", response_model=FamilyInvitationRead, status_code=status.HTTP_201_CREATED)
def invite_family_caregiver(
    payload: FamilyInvitationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FamilyInvitation:
    invitation = FamilyInvitation(
        owner_user_id=current_user.id,
        invitee_email=str(payload.invitee_email),
        relationship=payload.relationship,
        role=payload.role,
        token=token_urlsafe(32),
        expires_at=datetime.now(UTC) + timedelta(days=7),
    )
    db.add(invitation)
    write_audit_log(db, current_user.id, "invite", "family_invitation", payload.invitee_email)
    db.commit()
    db.refresh(invitation)
    return invitation


@router.get("/invitations", response_model=list[FamilyInvitationRead])
def list_invitations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[FamilyInvitation]:
    return db.query(FamilyInvitation).filter(FamilyInvitation.owner_user_id == current_user.id).order_by(FamilyInvitation.created_at.desc()).all()
