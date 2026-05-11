from datetime import datetime, UTC

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.interop import ProviderConnection
from app.models.user import User
from app.schemas.interop_schema import (
    ProviderConnectCallback,
    ProviderConnectStart,
    ProviderConnectionRead,
    ProviderRead,
    ProviderSyncResponse,
)
from app.services.abdm_sandbox_service import AbdmSandboxService
from app.services.audit_service import write_audit_log
from app.services.encryption_service import encrypt_sensitive_payload
from app.services.smart_fhir_service import (
    PROVIDERS,
    exchange_code_for_token,
    fetch_patient_bundle,
    get_authorization_url,
    normalize_and_store_bundle,
    provider_by_id,
)
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/providers", tags=["provider-sandbox"])


@router.get("", response_model=list[ProviderRead])
def providers() -> list[ProviderRead]:
    return [ProviderRead(**provider, status="available") for provider in PROVIDERS]


@router.post("/connect/start")
def connect_start(
    payload: ProviderConnectStart,
    current_user: User = Depends(get_current_user),
) -> dict[str, str]:
    return {
        "authorization_url": get_authorization_url(payload.provider_id, current_user.id),
        "provider_id": payload.provider_id,
        "mode": "mock_smart_on_fhir",
    }


@router.post("/connect/callback", response_model=ProviderConnectionRead, status_code=status.HTTP_201_CREATED)
def connect_callback(
    payload: ProviderConnectCallback,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProviderConnection:
    provider = provider_by_id(payload.provider_id)
    token_payload = exchange_code_for_token(payload.auth_code, payload.provider_id)
    connection = ProviderConnection(
        user_id=current_user.id,
        provider_name=provider["provider_name"],
        provider_type=provider["provider_type"],
        provider_base_url=provider["provider_base_url"],
        access_token_encrypted=str(encrypt_sensitive_payload({"token": token_payload["access_token"]})),
        refresh_token_encrypted=str(encrypt_sensitive_payload({"token": token_payload["refresh_token"]})),
        scopes=token_payload["scopes"],
        token_expires_at=token_payload["expires_at"],
        status="connected",
    )
    db.add(connection)
    write_audit_log(db, current_user.id, "connect", "provider_connection", payload.provider_id)
    db.commit()
    db.refresh(connection)
    return connection


@router.get("/connected", response_model=list[ProviderConnectionRead])
def connected_providers(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ProviderConnection]:
    return db.query(ProviderConnection).filter(ProviderConnection.user_id == current_user.id).order_by(ProviderConnection.id.desc()).all()


@router.post("/{provider_id}/sync", response_model=ProviderSyncResponse)
def sync_provider(
    provider_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProviderSyncResponse:
    connection = db.get(ProviderConnection, provider_id)
    if connection is None or connection.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Provider connection not found")
    bundle = fetch_patient_bundle(connection)
    counts = normalize_and_store_bundle(db, bundle, current_user, connection)
    connection.last_sync_at = datetime.now(UTC)
    write_audit_log(db, current_user.id, "sync", "provider_connection", str(connection.id))
    db.commit()
    return ProviderSyncResponse(
        provider_connection_id=connection.id,
        imported_counts=counts,
        message="Sample FHIR bundle imported into MedID Connect.",
    )


@router.delete("/{provider_id}", status_code=status.HTTP_204_NO_CONTENT)
def disconnect_provider(
    provider_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    connection = db.get(ProviderConnection, provider_id)
    if connection is None or connection.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Provider connection not found")
    db.delete(connection)
    write_audit_log(db, current_user.id, "disconnect", "provider_connection", str(provider_id))
    db.commit()


@router.post("/abdm/create-abha-placeholder")
def abdm_create_abha_placeholder(
    mobile: str,
    current_user: User = Depends(get_current_user),
) -> dict[str, str]:
    _ = current_user
    return AbdmSandboxService().create_abha_address_placeholder(mobile)
