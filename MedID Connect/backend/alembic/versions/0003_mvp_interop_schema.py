"""mvp interop schema

Revision ID: 0003_mvp_interop_schema
Revises: 0002_advanced_platform_schema
Create Date: 2026-05-10
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "0003_mvp_interop_schema"
down_revision = "0002_advanced_platform_schema"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("emergency_tokens", sa.Column("token_hash", sa.String(length=255), nullable=True))
    op.create_index("ix_emergency_tokens_token_hash", "emergency_tokens", ["token_hash"], unique=True)
    op.create_table(
        "provider_connections",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("provider_name", sa.String(length=160), nullable=False),
        sa.Column("provider_type", sa.String(length=80), nullable=False),
        sa.Column("provider_base_url", sa.String(length=500), nullable=True),
        sa.Column("access_token_encrypted", sa.Text(), nullable=True),
        sa.Column("refresh_token_encrypted", sa.Text(), nullable=True),
        sa.Column("scopes", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'[]'::jsonb"), nullable=False),
        sa.Column("token_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_sync_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=40), server_default="connected", nullable=False),
    )
    op.create_table(
        "consents",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("grantee_name", sa.String(length=160), nullable=False),
        sa.Column("grantee_type", sa.String(length=80), server_default="doctor", nullable=False),
        sa.Column("hospital_name", sa.String(length=160), nullable=True),
        sa.Column("doctor_name", sa.String(length=160), nullable=True),
        sa.Column("purpose", sa.Text(), nullable=True),
        sa.Column("allowed_resources", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'[]'::jsonb"), nullable=False),
        sa.Column("access_token_hash", sa.String(length=255), nullable=False, unique=True, index=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False, index=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "consent_access_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("consent_id", sa.Integer(), sa.ForeignKey("consents.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("accessed_by", sa.String(length=160), nullable=True),
        sa.Column("ip_address", sa.String(length=80), nullable=True),
        sa.Column("user_agent", sa.Text(), nullable=True),
        sa.Column("resource_accessed", sa.String(length=120), nullable=False),
        sa.Column("accessed_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "fhir_import_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("provider_connection_id", sa.Integer(), sa.ForeignKey("provider_connections.id", ondelete="SET NULL"), nullable=True),
        sa.Column("source", sa.String(length=160), nullable=False),
        sa.Column("imported_counts", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("raw_bundle", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("fhir_import_logs")
    op.drop_table("consent_access_logs")
    op.drop_table("consents")
    op.drop_table("provider_connections")
    op.drop_index("ix_emergency_tokens_token_hash", table_name="emergency_tokens")
    op.drop_column("emergency_tokens", "token_hash")
