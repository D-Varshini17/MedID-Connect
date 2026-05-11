from datetime import UTC, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.medical_record import MedicalRecord
from app.models.medication import Allergy, Medication
from app.models.observation import Observation
from app.models.user import EmergencyContact, User
from app.schemas.auth_schema import SignupRequest
from app.utils.security import create_access_token, hash_password, verify_password


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    user = db.query(User).filter(User.email == email.lower()).first()
    if not user or not verify_password(password, user.password_hash):
        return None
    return user


def register_user(db: Session, payload: SignupRequest) -> User:
    existing = db.query(User).filter(User.email == payload.email.lower()).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    user = User(
        full_name=payload.full_name,
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        age=payload.age,
        gender=payload.gender,
        blood_group=payload.blood_group,
        phone=payload.phone,
    )
    db.add(user)
    db.flush()
    seed_demo_data(db, user)
    db.commit()
    db.refresh(user)
    return user


def issue_token(user: User) -> str:
    return create_access_token(str(user.id), timedelta(days=1))


def seed_demo_data(db: Session, user: User) -> None:
    db.add(
        EmergencyContact(
            user_id=user.id,
            name="Nisha Mehta",
            relationship="Spouse",
            phone="+91 99887 77665",
            email="nisha.mehta@example.com",
        )
    )
    db.add_all(
        [
            Allergy(user_id=user.id, allergen="Penicillin", severity="high", reaction="Hives and facial swelling"),
            Allergy(user_id=user.id, allergen="Peanuts", severity="moderate", reaction="Throat irritation"),
        ]
    )
    db.add_all(
        [
            Medication(
                user_id=user.id,
                medicine_name="Amlodipine 5 mg",
                dosage="1 tablet",
                frequency="Daily after breakfast",
                start_date=datetime(2023, 3, 12, tzinfo=UTC),
                prescribing_doctor="Dr. Kavya Rao",
                active=True,
            ),
            Medication(
                user_id=user.id,
                medicine_name="Cetirizine 10 mg",
                dosage="1 tablet",
                frequency="As needed at night",
                start_date=datetime(2024, 6, 5, tzinfo=UTC),
                prescribing_doctor="Dr. Anil Shah",
                active=True,
            ),
            Medication(
                user_id=user.id,
                medicine_name="Vitamin D3 1000 IU",
                dosage="1 capsule",
                frequency="Daily with lunch",
                start_date=datetime(2025, 1, 10, tzinfo=UTC),
                prescribing_doctor="Dr. Kavya Rao",
                active=True,
            ),
        ]
    )
    db.add_all(
        [
            Observation(user_id=user.id, observation_type="blood_pressure", value=124, unit="mmHg", normal_min=90, normal_max=120, status="high", observed_at=datetime(2026, 4, 1, tzinfo=UTC), fhir_payload={}),
            Observation(user_id=user.id, observation_type="blood_pressure", value=116, unit="mmHg", normal_min=90, normal_max=120, status="normal", observed_at=datetime(2026, 4, 22, tzinfo=UTC), fhir_payload={}),
            Observation(user_id=user.id, observation_type="cholesterol", value=184, unit="mg/dL", normal_min=120, normal_max=200, status="normal", observed_at=datetime(2026, 4, 20, tzinfo=UTC), fhir_payload={}),
            Observation(user_id=user.id, observation_type="glucose", value=92, unit="mg/dL", normal_min=70, normal_max=99, status="normal", observed_at=datetime(2026, 4, 20, tzinfo=UTC), fhir_payload={}),
            Observation(user_id=user.id, observation_type="heart_rate", value=72, unit="bpm", normal_min=60, normal_max=100, status="normal", observed_at=datetime(2026, 4, 22, tzinfo=UTC), fhir_payload={}),
        ]
    )
    db.add_all(
        [
            MedicalRecord(user_id=user.id, record_type="Lab Report", title="Annual wellness panel", description="Metabolic markers are stable.", provider_name="Apollo Diagnostics", doctor_name="Dr. Kavya Rao", record_date=datetime(2026, 4, 20, tzinfo=UTC), fhir_resource_type="DiagnosticReport", fhir_payload={}),
            MedicalRecord(user_id=user.id, record_type="Prescription", title="Hypertension prescription", description="Amlodipine continued.", provider_name="Apollo Heart Center", doctor_name="Dr. Kavya Rao", record_date=datetime(2026, 3, 28, tzinfo=UTC), fhir_resource_type="MedicationRequest", fhir_payload={}),
            MedicalRecord(user_id=user.id, record_type="Vaccination", title="Influenza vaccination", description="Influenza quadrivalent completed.", provider_name="City Care Clinic", doctor_name="Nurse Practitioner", record_date=datetime(2025, 11, 8, tzinfo=UTC), fhir_resource_type="Immunization", fhir_payload={}),
        ]
    )
