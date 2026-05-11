from datetime import datetime, UTC

from sqlalchemy.orm import Session

from app.models.advanced import LifestyleProfile, RiskScore
from app.models.observation import Observation


def _latest_value(db: Session, user_id: int, marker: str) -> float | None:
    observation = (
        db.query(Observation)
        .filter(Observation.user_id == user_id, Observation.observation_type.ilike(f"%{marker}%"))
        .order_by(Observation.observed_at.desc())
        .first()
    )
    return observation.value if observation else None


def calculate_risk_scores(db: Session, user_id: int) -> list[RiskScore]:
    lifestyle = db.query(LifestyleProfile).filter(LifestyleProfile.user_id == user_id).first()
    glucose = _latest_value(db, user_id, "glucose")
    bp = _latest_value(db, user_id, "blood")
    cholesterol = _latest_value(db, user_id, "cholesterol")

    risks: list[tuple[str, float, list[dict[str, object]], list[str]]] = []

    diabetes = 18.0
    diabetes_factors: list[dict[str, object]] = []
    if glucose and glucose > 140:
        diabetes += 28
        diabetes_factors.append({"factor": "Recent glucose above range", "value": glucose})
    if lifestyle and lifestyle.family_history.get("diabetes"):
        diabetes += 16
        diabetes_factors.append({"factor": "Family history of diabetes", "value": True})
    risks.append(("Diabetes", min(diabetes, 92), diabetes_factors, ["Repeat fasting glucose or HbA1c", "Walk 30 minutes daily"]))

    hypertension = 16.0
    hypertension_factors: list[dict[str, object]] = []
    if bp and bp > 140:
        hypertension += 34
        hypertension_factors.append({"factor": "Blood pressure above range", "value": bp})
    if lifestyle and lifestyle.smoker:
        hypertension += 12
        hypertension_factors.append({"factor": "Smoking history", "value": True})
    risks.append(("Hypertension", min(hypertension, 90), hypertension_factors, ["Track BP twice weekly", "Reduce sodium intake"]))

    heart = 14.0
    heart_factors: list[dict[str, object]] = []
    if cholesterol and cholesterol > 200:
        heart += 26
        heart_factors.append({"factor": "Cholesterol above range", "value": cholesterol})
    if lifestyle and lifestyle.family_history.get("heart_disease"):
        heart += 18
        heart_factors.append({"factor": "Family history of heart disease", "value": True})
    risks.append(("Heart Disease", min(heart, 88), heart_factors, ["Discuss lipid profile with doctor", "Prioritize sleep and activity"]))

    rows: list[RiskScore] = []
    for risk_type, score, factors, recommendations in risks:
        band = "high" if score >= 65 else "moderate" if score >= 35 else "low"
        row = RiskScore(
            user_id=user_id,
            risk_type=risk_type,
            score_percent=round(score, 1),
            band=band,
            factors=factors,
            recommendations=recommendations,
            calculated_at=datetime.now(UTC),
        )
        db.add(row)
        rows.append(row)
    db.flush()
    return rows
