from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.medication import Allergy
from app.models.user import User
from app.schemas.medication_schema import AllergyRead
from app.services.audit_service import write_audit_log
from app.utils.dependencies import get_current_user
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/allergies", tags=["allergies"])


class AllergyCreate(BaseModel):
    allergen: str = Field(min_length=2, max_length=160)
    severity: str | None = None
    reaction: str | None = None


@router.get("", response_model=list[AllergyRead])
def list_allergies(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[Allergy]:
    return db.query(Allergy).filter(Allergy.user_id == current_user.id).order_by(Allergy.created_at.desc()).all()


@router.post("", response_model=AllergyRead, status_code=status.HTTP_201_CREATED)
def create_allergy(
    payload: AllergyCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Allergy:
    allergy = Allergy(user_id=current_user.id, **payload.model_dump())
    db.add(allergy)
    write_audit_log(db, current_user.id, "create", "allergy", payload.allergen)
    db.commit()
    db.refresh(allergy)
    return allergy


@router.put("/{allergy_id}", response_model=AllergyRead)
def update_allergy(
    allergy_id: int,
    payload: AllergyCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Allergy:
    allergy = db.get(Allergy, allergy_id)
    if allergy is None or allergy.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Allergy not found")
    for key, value in payload.model_dump().items():
        setattr(allergy, key, value)
    write_audit_log(db, current_user.id, "update", "allergy", str(allergy.id))
    db.commit()
    db.refresh(allergy)
    return allergy


@router.delete("/{allergy_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_allergy(
    allergy_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    allergy = db.get(Allergy, allergy_id)
    if allergy is None or allergy.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Allergy not found")
    db.delete(allergy)
    write_audit_log(db, current_user.id, "delete", "allergy", str(allergy_id))
    db.commit()
