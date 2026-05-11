from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.models.advanced import MedicationLog, WellnessLog
from app.models.observation import Observation


def calculate_wellness_score(db: Session, user_id: int) -> dict:
    now = datetime.now(UTC)
    week_start = now - timedelta(days=7)

    logs = (
        db.query(WellnessLog)
        .filter(WellnessLog.user_id == user_id, WellnessLog.log_date >= week_start)
        .order_by(WellnessLog.log_date.desc())
        .all()
    )
    med_logs = (
        db.query(MedicationLog)
        .filter(MedicationLog.user_id == user_id, MedicationLog.created_at >= week_start)
        .all()
    )
    observations = (
        db.query(Observation)
        .filter(Observation.user_id == user_id, Observation.observed_at >= week_start)
        .all()
    )

    taken = len([log for log in med_logs if log.status == "taken"])
    missed = len([log for log in med_logs if log.status == "missed"])
    adherence = round((taken / max(taken + missed, 1)) * 100)

    water_avg = sum(log.water_ml for log in logs) / max(len(logs), 1)
    water_percent = min(round((water_avg / 2500) * 100), 100)

    sleep_values = [log.sleep_hours for log in logs if log.sleep_hours is not None]
    sleep_avg = sum(sleep_values) / max(len(sleep_values), 1) if sleep_values else 7
    sleep_percent = min(round((sleep_avg / 8) * 100), 100)

    abnormal = len([obs for obs in observations if obs.status.lower() not in {"normal", "final"}])
    observations_percent = max(55, 100 - abnormal * 12)

    score = round((adherence * 0.35) + (water_percent * 0.2) + (sleep_percent * 0.2) + (observations_percent * 0.25))
    suggestions: list[str] = []
    if adherence < 85:
        suggestions.append("Confirm medicines after each dose to improve adherence.")
    if water_percent < 70:
        suggestions.append("Aim for 2.5L water today unless your doctor restricted fluids.")
    if sleep_percent < 75:
        suggestions.append("Try a consistent sleep window to support recovery.")
    if abnormal:
        suggestions.append("Review abnormal lab or vital trends with a qualified doctor.")
    if not suggestions:
        suggestions.append("Great consistency. Keep logging habits and medicines.")

    return {
        "score": max(0, min(score, 100)),
        "adherence_percent": adherence,
        "water_percent": water_percent,
        "sleep_percent": sleep_percent,
        "observations_percent": observations_percent,
        "suggestions": suggestions,
    }
