from datetime import UTC, datetime, timedelta

from sqlalchemy.orm import Session

from app.models.medical_record import MedicalRecord
from app.models.observation import Observation
from app.schemas.insight_schema import InsightRead
from app.services.safety_checker import check_medication_safety


def generate_rule_based_insights(db: Session, user_id: int) -> list[InsightRead]:
    insights: list[InsightRead] = []
    observations = (
        db.query(Observation)
        .filter(Observation.user_id == user_id)
        .order_by(Observation.observed_at.desc())
        .all()
    )

    latest_by_type: dict[str, Observation] = {}
    for observation in observations:
        latest_by_type.setdefault(observation.observation_type, observation)

    bp = latest_by_type.get("blood_pressure")
    if bp and bp.value >= 130:
        insights.append(
            InsightRead(
                title="Blood pressure high warning",
                description=f"Latest systolic blood pressure is {bp.value:g} {bp.unit or ''}.",
                recommendation="Recheck after rest and contact your clinician if high readings continue.",
                severity="warning",
                category="Cardio",
            )
        )
    elif bp:
        insights.append(
            InsightRead(
                title="Blood pressure improving",
                description="Your latest blood pressure is within the target demo range.",
                recommendation="Keep logging readings regularly.",
                severity="success",
                category="Cardio",
            )
        )

    glucose = latest_by_type.get("glucose")
    if glucose and glucose.value > (glucose.normal_max or 99):
        insights.append(
            InsightRead(
                title="Glucose high warning",
                description=f"Latest glucose value is {glucose.value:g} {glucose.unit or ''}.",
                recommendation="Review diet, hydration, and follow your clinician's lab plan.",
                severity="warning",
                category="Labs",
            )
        )

    for warning in check_medication_safety(db, user_id):
        insights.append(
            InsightRead(
                title="Medication allergy warning",
                description=warning.warning,
                recommendation="Confirm medication safety with a qualified clinician.",
                severity=warning.severity,
                category="Medication",
            )
        )

    recent_record = (
        db.query(MedicalRecord)
        .filter(
            MedicalRecord.user_id == user_id,
            MedicalRecord.record_type.in_(["Lab Report", "lab_report"]),
        )
        .order_by(MedicalRecord.record_date.desc())
        .first()
    )
    if not recent_record or recent_record.record_date < datetime.now(UTC) - timedelta(days=180):
        insights.append(
            InsightRead(
                title="Missing recent lab report",
                description="No lab report was found in the last six months.",
                recommendation="Schedule routine labs if your care plan recommends them.",
                severity="info",
                category="Preventive",
            )
        )

    if not insights:
        insights.append(
            InsightRead(
                title="Health profile looks stable",
                description="No urgent rule-based warnings were detected from current demo data.",
                recommendation="Keep records updated for better future insights.",
                severity="success",
                category="General",
            )
        )
    return insights
