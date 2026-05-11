from sqlalchemy.orm import Session

from app.models.advanced import Appointment
from app.models.medication import Medication
from app.models.observation import Observation
from app.services.safety_checker import check_medication_safety


def answer_health_query(db: Session, user_id: int, text: str, language: str) -> dict[str, object]:
    query = text.lower()
    if any(word in query for word in ("medicine", "medication", "tablet", "dose")):
        medications = (
            db.query(Medication)
            .filter(Medication.user_id == user_id, Medication.active.is_(True))
            .order_by(Medication.created_at.desc())
            .limit(5)
            .all()
        )
        names = ", ".join(m.medicine_name for m in medications) or "no active medicines"
        return {
            "intent": "today_medications",
            "spoken_reply": f"Your active medicines are {names}. Please follow your doctor schedule.",
            "display_cards": [{"title": m.medicine_name, "subtitle": m.dosage or "Dosage not set"} for m in medications],
            "language": language,
        }
    if any(word in query for word in ("sugar", "glucose", "lab", "report")):
        observation = (
            db.query(Observation)
            .filter(Observation.user_id == user_id, Observation.observation_type.ilike("%glucose%"))
            .order_by(Observation.observed_at.desc())
            .first()
        )
        if observation:
            reply = f"Your latest glucose value is {observation.value:g} {observation.unit or ''}, marked {observation.status}."
            cards = [{"title": "Latest glucose", "value": observation.value, "status": observation.status}]
        else:
            reply = "I could not find a glucose report yet."
            cards = []
        return {"intent": "latest_lab", "spoken_reply": reply, "display_cards": cards, "language": language}
    if "interaction" in query or "allergy" in query:
        warnings = check_medication_safety(db, user_id)
        return {
            "intent": "safety_check",
            "spoken_reply": f"I found {len(warnings)} medication safety item or allergy warning.",
            "display_cards": [warning.model_dump() for warning in warnings],
            "language": language,
        }
    if "appointment" in query:
        appointment = (
            db.query(Appointment)
            .filter(Appointment.user_id == user_id, Appointment.status == "scheduled")
            .order_by(Appointment.scheduled_at.asc())
            .first()
        )
        reply = (
            f"Your next appointment is on {appointment.scheduled_at:%d %b %Y at %I:%M %p}."
            if appointment
            else "You have no scheduled appointments."
        )
        return {"intent": "next_appointment", "spoken_reply": reply, "display_cards": [], "language": language}
    return {
        "intent": "general_health_help",
        "spoken_reply": "I can help with medicines, lab reports, interactions, and appointments.",
        "display_cards": [
            {"title": "Try asking", "subtitle": "What medicines today?"},
            {"title": "Try asking", "subtitle": "Any medicine interactions?"},
        ],
        "language": language,
    }
