from datetime import UTC, datetime

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import WellnessLog
from app.models.user import User
from app.schemas.productivity_schema import HealthScoreResponse, WellnessLogCreate, WellnessLogRead
from app.services.audit_service import write_audit_log
from app.services.health_score_service import calculate_wellness_score
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/wellness", tags=["wellness"])


@router.get("/logs", response_model=list[WellnessLogRead])
def list_logs(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[WellnessLog]:
    return db.query(WellnessLog).filter(WellnessLog.user_id == current_user.id).order_by(WellnessLog.log_date.desc()).limit(30).all()


@router.post("/logs", response_model=WellnessLogRead, status_code=status.HTTP_201_CREATED)
def create_log(
    payload: WellnessLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WellnessLog:
    log = WellnessLog(
        user_id=current_user.id,
        log_date=payload.log_date or datetime.now(UTC),
        **payload.model_dump(exclude={"log_date"}),
    )
    db.add(log)
    write_audit_log(db, current_user.id, "create", "wellness_log", None)
    db.commit()
    db.refresh(log)
    return log


@router.get("/score", response_model=HealthScoreResponse)
def health_score(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    return calculate_wellness_score(db, current_user.id)
