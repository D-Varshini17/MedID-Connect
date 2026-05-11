"""practical mvp feature tables

Revision ID: 0004_practical_mvp_features
Revises: 0003_mvp_interop_schema
Create Date: 2026-05-11
"""

from alembic import op
import sqlalchemy as sa

revision = "0004_practical_mvp_features"
down_revision = "0003_mvp_interop_schema"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "wellness_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("log_date", sa.DateTime(timezone=True), nullable=False, index=True),
        sa.Column("water_ml", sa.Integer(), server_default="0", nullable=False),
        sa.Column("sleep_hours", sa.Float(), nullable=True),
        sa.Column("steps", sa.Integer(), nullable=True),
        sa.Column("mood", sa.String(length=40), nullable=True),
        sa.Column("exercise_minutes", sa.Integer(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "sos_alerts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("emergency_contact_name", sa.String(length=160), nullable=True),
        sa.Column("emergency_contact_phone", sa.String(length=40), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("status", sa.String(length=40), server_default="mock_sent", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "document_flags",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("medical_record_id", sa.Integer(), sa.ForeignKey("medical_records.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("favorite", sa.Boolean(), server_default=sa.false(), nullable=False),
        sa.Column("pinned", sa.Boolean(), server_default=sa.false(), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("document_flags")
    op.drop_table("sos_alerts")
    op.drop_table("wellness_logs")
