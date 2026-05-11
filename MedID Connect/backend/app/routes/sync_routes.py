from datetime import datetime, UTC

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import SyncConflict, SyncEvent
from app.models.medical_record import MedicalRecord
from app.models.medication import Medication
from app.models.observation import Observation
from app.models.user import User
from app.schemas.advanced_schema import SyncPullResponse, SyncPushRequest
from app.services.audit_service import write_audit_log
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/sync", tags=["offline-sync"])


@router.post("/push")
def push_sync_events(
    payload: SyncPushRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    accepted: list[str] = []
    conflicts: list[int] = []
    for event in payload.events:
        duplicate = (
            db.query(SyncEvent)
            .filter(SyncEvent.user_id == current_user.id, SyncEvent.client_event_id == event.client_event_id)
            .first()
        )
        if duplicate:
            continue
        row = SyncEvent(user_id=current_user.id, **event.model_dump())
        db.add(row)
        accepted.append(event.client_event_id)
        if event.operation == "update" and event.payload.get("server_version_mismatch"):
            conflict = SyncConflict(
                user_id=current_user.id,
                entity_type=event.entity_type,
                entity_id=event.entity_id or "unknown",
                client_payload=event.payload,
                server_payload={"resolution_hint": "pull_latest_then_retry"},
            )
            db.add(conflict)
            db.flush()
            conflicts.append(conflict.id)
    write_audit_log(db, current_user.id, "push", "sync_events", str(len(accepted)))
    db.commit()
    return {"accepted": accepted, "conflict_ids": conflicts, "server_time": datetime.now(UTC).isoformat()}


@router.get("/pull", response_model=SyncPullResponse)
def pull_sync_snapshot(
    since: datetime | None = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SyncPullResponse:
    records = {
        "medical_records": [
            {"id": record.id, "title": record.title, "record_type": record.record_type, "updated_at": record.updated_at.isoformat()}
            for record in db.query(MedicalRecord).filter(MedicalRecord.user_id == current_user.id).all()
            if since is None or record.updated_at >= since
        ],
        "medications": [
            {"id": med.id, "medicine_name": med.medicine_name, "active": med.active, "created_at": med.created_at.isoformat()}
            for med in db.query(Medication).filter(Medication.user_id == current_user.id).all()
        ],
        "observations": [
            {
                "id": obs.id,
                "observation_type": obs.observation_type,
                "value": obs.value,
                "status": obs.status,
                "observed_at": obs.observed_at.isoformat(),
            }
            for obs in db.query(Observation).filter(Observation.user_id == current_user.id).all()
        ],
    }
    conflicts = [
        {"id": conflict.id, "entity_type": conflict.entity_type, "entity_id": conflict.entity_id, "resolution": conflict.resolution}
        for conflict in db.query(SyncConflict).filter(SyncConflict.user_id == current_user.id).all()
    ]
    return SyncPullResponse(server_time=datetime.now(UTC), records=records, conflicts=conflicts)
