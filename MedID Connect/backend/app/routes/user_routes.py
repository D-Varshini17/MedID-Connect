from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import EmergencyContact, User
from app.schemas.user_schema import UserRead, UserUpdate
from app.services.audit_service import write_audit_log
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/user", tags=["user"])


@router.get("/profile", response_model=UserRead)
def get_profile(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.put("/profile", response_model=UserRead)
def update_profile(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> User:
    update_data = payload.model_dump(exclude_unset=True, exclude={"emergency_contact"})
    for key, value in update_data.items():
        setattr(current_user, key, value)

    if payload.emergency_contact:
        if current_user.emergency_contacts:
            contact = current_user.emergency_contacts[0]
            for key, value in payload.emergency_contact.model_dump().items():
                setattr(contact, key, value)
        else:
            db.add(EmergencyContact(user_id=current_user.id, **payload.emergency_contact.model_dump()))

    write_audit_log(db, current_user.id, "update", "user", str(current_user.id))
    db.commit()
    db.refresh(current_user)
    return current_user


@router.delete("/delete-placeholder")
def delete_account_placeholder(current_user: User = Depends(get_current_user)) -> dict[str, str]:
    return {
        "status": "placeholder",
        "message": f"Account deletion workflow queued for user {current_user.id}. Production requires confirmation, export window, and audit retention policy.",
    }
