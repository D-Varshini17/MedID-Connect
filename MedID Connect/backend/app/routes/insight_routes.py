from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.insight_schema import InsightRead
from app.services.insight_service import generate_rule_based_insights
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/insights", tags=["insights"])


@router.get("", response_model=list[InsightRead])
def insights(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[InsightRead]:
    return generate_rule_based_insights(db, current_user.id)
