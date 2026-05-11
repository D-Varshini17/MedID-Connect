from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import MedicationLog, WellnessLog
from app.models.observation import Observation
from app.models.user import User
from app.schemas.productivity_schema import AnalyticsSummary
from app.services.health_score_service import calculate_wellness_score
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/product-analytics", tags=["health-analytics"])


@router.get("/summary", response_model=AnalyticsSummary)
def analytics_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AnalyticsSummary:
    now = datetime.now(UTC)
    week_start = now - timedelta(days=7)
    wellness = db.query(WellnessLog).filter(WellnessLog.user_id == current_user.id, WellnessLog.log_date >= week_start).all()
    med_logs = db.query(MedicationLog).filter(MedicationLog.user_id == current_user.id, MedicationLog.created_at >= week_start).all()
    observations = db.query(Observation).filter(Observation.user_id == current_user.id).order_by(Observation.observed_at.desc()).limit(30).all()
    score = calculate_wellness_score(db, current_user.id)

    taken = len([log for log in med_logs if log.status == "taken"])
    missed = len([log for log in med_logs if log.status == "missed"])
    adherence = round((taken / max(taken + missed, 1)) * 100)
    water_average = round(sum(log.water_ml for log in wellness) / max(len(wellness), 1))
    sleep_values = [log.sleep_hours for log in wellness if log.sleep_hours is not None]
    sleep_average = round(sum(sleep_values) / max(len(sleep_values), 1), 1) if sleep_values else 7.0
    abnormal = len([obs for obs in observations if obs.status.lower() not in {"normal", "final"}])

    return AnalyticsSummary(
        weekly_health_score=score["score"],
        medication_adherence=adherence,
        water_average_ml=water_average,
        sleep_average_hours=sleep_average,
        abnormal_observations=abnormal,
        most_common_symptoms=["Headache", "Fatigue", "Stress"],
        progress_timeline=[
            {"label": "Medicines", "value": adherence},
            {"label": "Water", "value": score["water_percent"]},
            {"label": "Sleep", "value": score["sleep_percent"]},
            {"label": "Vitals", "value": score["observations_percent"]},
        ],
        trend_cards=[
            {"title": obs.observation_type, "value": obs.value, "unit": obs.unit, "status": obs.status}
            for obs in observations[:6]
        ],
    )
