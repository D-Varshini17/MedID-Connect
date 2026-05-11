from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class ProviderConnection(Base):
    __tablename__ = "provider_connections"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    provider_name: Mapped[str] = mapped_column(String(160), nullable=False)
    provider_type: Mapped[str] = mapped_column(String(80), nullable=False)
    provider_base_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    access_token_encrypted: Mapped[str | None] = mapped_column(Text, nullable=True)
    refresh_token_encrypted: Mapped[str | None] = mapped_column(Text, nullable=True)
    scopes: Mapped[list[str]] = mapped_column(JSONB, default=list)
    token_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_sync_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(40), default="connected")


class Consent(Base):
    __tablename__ = "consents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    grantee_name: Mapped[str] = mapped_column(String(160), nullable=False)
    grantee_type: Mapped[str] = mapped_column(String(80), default="doctor")
    hospital_name: Mapped[str | None] = mapped_column(String(160), nullable=True)
    doctor_name: Mapped[str | None] = mapped_column(String(160), nullable=True)
    purpose: Mapped[str | None] = mapped_column(Text, nullable=True)
    allowed_resources: Mapped[list[str]] = mapped_column(JSONB, default=list)
    access_token_hash: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class ConsentAccessLog(Base):
    __tablename__ = "consent_access_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    consent_id: Mapped[int] = mapped_column(ForeignKey("consents.id", ondelete="CASCADE"), index=True)
    accessed_by: Mapped[str | None] = mapped_column(String(160), nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(80), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(Text, nullable=True)
    resource_accessed: Mapped[str] = mapped_column(String(120))
    accessed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class FhirImportLog(Base):
    __tablename__ = "fhir_import_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    provider_connection_id: Mapped[int | None] = mapped_column(ForeignKey("provider_connections.id", ondelete="SET NULL"))
    source: Mapped[str] = mapped_column(String(160), nullable=False)
    imported_counts: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    raw_bundle: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
