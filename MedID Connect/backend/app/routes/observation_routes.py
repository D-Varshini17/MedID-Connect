from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.observation import Observation
from app.models.user import User
from app.schemas.observation_schema import ObservationCreate, ObservationRead, ObservationTrend
from app.services.audit_service import write_audit_log
from app.services.encryption_service import encrypt_sensitive_payload
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/observations", tags=["observations"])


@router.get("", response_model=list[ObservationRead])
def list_observations(
    observation_type: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Observation]:
    query = db.query(Observation).filter(Observation.user_id == current_user.id)
    if observation_type:
        query = query.filter(Observation.observation_type == observation_type)
    return query.order_by(Observation.observed_at.asc()).all()


@router.post("", response_model=ObservationRead, status_code=status.HTTP_201_CREATED)
def create_observation(
    payload: ObservationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Observation:
    observation = Observation(
        user_id=current_user.id,
        **payload.model_dump(exclude={"fhir_payload"}),
        fhir_payload=encrypt_sensitive_payload(payload.fhir_payload),
    )
    db.add(observation)
    db.flush()
    write_audit_log(db, current_user.id, "create", "observation", str(observation.id))
    db.commit()
    db.refresh(observation)
    return observation


@router.get("/trends", response_model=list[ObservationTrend])
def trends(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ObservationTrend]:
    observations = list_observations(None, current_user, db)
    grouped: dict[str, list[Observation]] = {}
    for observation in observations:
        grouped.setdefault(observation.observation_type, []).append(observation)
    return [
        ObservationTrend(observation_type=key, points=value)
        for key, value in sorted(grouped.items())
    ]
