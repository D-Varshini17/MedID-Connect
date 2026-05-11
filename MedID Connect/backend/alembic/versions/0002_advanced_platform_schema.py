"""advanced platform schema

Revision ID: 0002_advanced_platform_schema
Revises: 0001_initial
Create Date: 2026-05-10
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "0002_advanced_platform_schema"
down_revision = "0001_initial"
branch_labels = None
depends_on = None

json_empty_object = sa.text("'{}'::jsonb")
json_empty_array = sa.text("'[]'::jsonb")


def upgrade() -> None:
    op.create_table(
        "family_members",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("owner_user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("linked_user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("full_name", sa.String(length=160), nullable=False),
        sa.Column("relationship", sa.String(length=80), nullable=False),
        sa.Column("age", sa.Integer(), nullable=True),
        sa.Column("gender", sa.String(length=40), nullable=True),
        sa.Column("blood_group", sa.String(length=8), nullable=True),
        sa.Column("emergency_enabled", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("profile_payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "access_roles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("family_member_id", sa.Integer(), sa.ForeignKey("family_members.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("role", sa.String(length=40), server_default="viewer", nullable=False),
        sa.Column("permissions", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_array, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "family_invitations",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("owner_user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("invitee_email", sa.String(length=255), nullable=False, index=True),
        sa.Column("relationship", sa.String(length=80), nullable=True),
        sa.Column("role", sa.String(length=40), server_default="caregiver", nullable=False),
        sa.Column("token", sa.String(length=255), nullable=False, unique=True, index=True),
        sa.Column("status", sa.String(length=40), server_default="pending", nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "uploaded_documents",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("document_type", sa.String(length=80), nullable=False, index=True),
        sa.Column("file_name", sa.String(length=255), nullable=False),
        sa.Column("content_type", sa.String(length=120), nullable=True),
        sa.Column("storage_uri", sa.String(length=500), nullable=True),
        sa.Column("extracted_text", sa.Text(), nullable=True),
        sa.Column("extraction_payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("ai_summary", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=40), server_default="processed", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "medication_schedules",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("medication_id", sa.Integer(), sa.ForeignKey("medications.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("schedule_time", sa.String(length=20), nullable=False),
        sa.Column("timezone", sa.String(length=80), server_default="Asia/Kolkata", nullable=False),
        sa.Column("days_of_week", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_array, nullable=False),
        sa.Column("refill_due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reminder_enabled", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "medication_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("medication_id", sa.Integer(), sa.ForeignKey("medications.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("schedule_id", sa.Integer(), sa.ForeignKey("medication_schedules.id", ondelete="SET NULL"), nullable=True),
        sa.Column("status", sa.String(length=40), server_default="taken", nullable=False),
        sa.Column("taken_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "notification_devices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("platform", sa.String(length=40), server_default="android", nullable=False),
        sa.Column("fcm_token", sa.Text(), nullable=False),
        sa.Column("device_id", sa.String(length=160), nullable=True),
        sa.Column("enabled", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_table(
        "notifications",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("title", sa.String(length=180), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("category", sa.String(length=80), nullable=False, index=True),
        sa.Column("priority", sa.String(length=40), server_default="normal", nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "sync_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("client_event_id", sa.String(length=120), nullable=False, index=True),
        sa.Column("entity_type", sa.String(length=80), nullable=False, index=True),
        sa.Column("entity_id", sa.String(length=120), nullable=True),
        sa.Column("operation", sa.String(length=40), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("status", sa.String(length=40), server_default="accepted", nullable=False),
        sa.Column("client_updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("server_received_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "sync_conflicts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("entity_type", sa.String(length=80), nullable=False),
        sa.Column("entity_id", sa.String(length=120), nullable=False),
        sa.Column("client_payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("server_payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("resolution", sa.String(length=40), server_default="server_wins", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "doctor_profiles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("full_name", sa.String(length=160), nullable=False),
        sa.Column("specialty", sa.String(length=120), nullable=False),
        sa.Column("hospital_name", sa.String(length=160), nullable=True),
        sa.Column("city", sa.String(length=120), nullable=True),
        sa.Column("rating", sa.Float(), nullable=True),
        sa.Column("languages", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_array, nullable=False),
        sa.Column("telemedicine_enabled", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("profile_payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "appointments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("doctor_id", sa.Integer(), sa.ForeignKey("doctor_profiles.id", ondelete="SET NULL"), nullable=True),
        sa.Column("appointment_type", sa.String(length=80), server_default="telemedicine", nullable=False),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=False, index=True),
        sa.Column("status", sa.String(length=40), server_default="scheduled", nullable=False),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("meeting_url", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "consultation_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("appointment_id", sa.Integer(), sa.ForeignKey("appointments.id", ondelete="SET NULL"), nullable=True),
        sa.Column("doctor_id", sa.Integer(), sa.ForeignKey("doctor_profiles.id", ondelete="SET NULL"), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("transcript_uri", sa.String(length=500), nullable=True),
        sa.Column("prescription_payload", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "lifestyle_profiles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True),
        sa.Column("activity_level", sa.String(length=80), nullable=True),
        sa.Column("smoker", sa.Boolean(), server_default=sa.false(), nullable=False),
        sa.Column("alcohol_use", sa.String(length=80), nullable=True),
        sa.Column("sleep_hours", sa.Float(), nullable=True),
        sa.Column("family_history", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "risk_scores",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("risk_type", sa.String(length=80), nullable=False, index=True),
        sa.Column("score_percent", sa.Float(), nullable=False),
        sa.Column("band", sa.String(length=40), nullable=False),
        sa.Column("factors", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_array, nullable=False),
        sa.Column("recommendations", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_array, nullable=False),
        sa.Column("calculated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "consent_grants",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("grantee_name", sa.String(length=160), nullable=False),
        sa.Column("grantee_type", sa.String(length=80), server_default="provider", nullable=False),
        sa.Column("scopes", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_array, nullable=False),
        sa.Column("purpose", sa.Text(), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "user_devices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("device_id", sa.String(length=160), nullable=False, index=True),
        sa.Column("device_name", sa.String(length=160), nullable=True),
        sa.Column("platform", sa.String(length=40), server_default="android", nullable=False),
        sa.Column("trusted", sa.Boolean(), server_default=sa.false(), nullable=False),
        sa.Column("last_ip_address", sa.String(length=80), nullable=True),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "user_sessions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("token_id", sa.String(length=160), nullable=True, index=True),
        sa.Column("device_id", sa.String(length=160), nullable=True),
        sa.Column("ip_address", sa.String(length=80), nullable=True),
        sa.Column("user_agent", sa.Text(), nullable=True),
        sa.Column("active", sa.Boolean(), server_default=sa.true(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_table(
        "security_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True),
        sa.Column("event_type", sa.String(length=100), nullable=False, index=True),
        sa.Column("severity", sa.String(length=40), server_default="info", nullable=False),
        sa.Column("ip_address", sa.String(length=80), nullable=True),
        sa.Column("user_agent", sa.Text(), nullable=True),
        sa.Column("details", postgresql.JSONB(astext_type=sa.Text()), server_default=json_empty_object, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "support_tickets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True),
        sa.Column("subject", sa.String(length=180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=40), server_default="open", nullable=False),
        sa.Column("priority", sa.String(length=40), server_default="normal", nullable=False),
        sa.Column("assigned_to", sa.String(length=160), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    for table in [
        "support_tickets",
        "security_events",
        "user_sessions",
        "user_devices",
        "consent_grants",
        "risk_scores",
        "lifestyle_profiles",
        "consultation_logs",
        "appointments",
        "doctor_profiles",
        "sync_conflicts",
        "sync_events",
        "notifications",
        "notification_devices",
        "medication_logs",
        "medication_schedules",
        "uploaded_documents",
        "family_invitations",
        "access_roles",
        "family_members",
    ]:
        op.drop_table(table)
