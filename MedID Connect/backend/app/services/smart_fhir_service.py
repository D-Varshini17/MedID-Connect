from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy.orm import Session

from app.models.interop import FhirImportLog, ProviderConnection
from app.models.medical_record import MedicalRecord
from app.models.medication import Allergy, Medication
from app.models.observation import Observation
from app.models.user import User


PROVIDERS = [
    {
        "id": "hapi",
        "provider_name": "HAPI FHIR Test Server",
        "provider_type": "FHIR_R4",
        "provider_base_url": "https://hapi.fhir.org/baseR4",
        "notes": "Public FHIR R4 test server. Demo sync imports sample data locally.",
    },
    {
        "id": "epic",
        "provider_name": "Epic Sandbox",
        "provider_type": "SMART_ON_FHIR",
        "provider_base_url": None,
        "notes": "Placeholder. Requires Epic developer app credentials.",
    },
    {
        "id": "cerner",
        "provider_name": "Oracle Cerner Sandbox",
        "provider_type": "SMART_ON_FHIR",
        "provider_base_url": None,
        "notes": "Placeholder. Requires Oracle Health developer credentials.",
    },
    {
        "id": "abdm",
        "provider_name": "ABDM/ABHA Sandbox",
        "provider_type": "ABDM",
        "provider_base_url": None,
        "notes": "Placeholder. Requires ABDM sandbox registration and gateway approval.",
    },
]


def provider_by_id(provider_id: str) -> dict[str, Any]:
    return next((provider for provider in PROVIDERS if provider["id"] == provider_id), PROVIDERS[0])


def get_authorization_url(provider_id: str, user_id: int) -> str:
    provider = provider_by_id(provider_id)
    if provider_id == "hapi":
        return f"{provider['provider_base_url']}/metadata?user={user_id}"
    return f"https://sandbox.medidconnect.com/oauth/{provider_id}/authorize?state=medid-{user_id}"


def exchange_code_for_token(auth_code: str, provider_id: str) -> dict[str, Any]:
    return {
        "access_token": f"demo-access-token-{provider_id}",
        "refresh_token": f"demo-refresh-token-{provider_id}",
        "expires_at": datetime.now(UTC) + timedelta(hours=1),
        "scopes": ["patient/*.read", "openid", "fhirUser"],
        "auth_code_used": auth_code[:4] + "***",
    }


def fetch_patient_bundle(provider_connection: ProviderConnection) -> dict[str, Any]:
    return {
        "resourceType": "Bundle",
        "type": "searchset",
        "entry": [
            {
                "resource": {
                    "resourceType": "Observation",
                    "code": {"text": "Glucose"},
                    "valueQuantity": {"value": 108, "unit": "mg/dL"},
                    "effectiveDateTime": datetime.now(UTC).isoformat(),
                }
            },
            {
                "resource": {
                    "resourceType": "Condition",
                    "code": {"text": "Seasonal allergic rhinitis"},
                    "clinicalStatus": {"text": "active"},
                }
            },
            {
                "resource": {
                    "resourceType": "MedicationRequest",
                    "medicationCodeableConcept": {"text": "Montelukast 10 mg"},
                    "dosageInstruction": [{"text": "Once at night"}],
                    "status": "active",
                }
            },
            {
                "resource": {
                    "resourceType": "AllergyIntolerance",
                    "code": {"text": "Dust mites"},
                    "criticality": "low",
                }
            },
        ],
    }


def fetch_observations(provider_connection: ProviderConnection) -> list[dict[str, Any]]:
    return [entry["resource"] for entry in fetch_patient_bundle(provider_connection)["entry"] if entry["resource"]["resourceType"] == "Observation"]


def fetch_conditions(provider_connection: ProviderConnection) -> list[dict[str, Any]]:
    return [entry["resource"] for entry in fetch_patient_bundle(provider_connection)["entry"] if entry["resource"]["resourceType"] == "Condition"]


def fetch_medications(provider_connection: ProviderConnection) -> list[dict[str, Any]]:
    return [entry["resource"] for entry in fetch_patient_bundle(provider_connection)["entry"] if entry["resource"]["resourceType"] == "MedicationRequest"]


def fetch_allergies(provider_connection: ProviderConnection) -> list[dict[str, Any]]:
    return [entry["resource"] for entry in fetch_patient_bundle(provider_connection)["entry"] if entry["resource"]["resourceType"] == "AllergyIntolerance"]


def normalize_and_store_bundle(db: Session, bundle: dict[str, Any], user: User, connection: ProviderConnection | None = None) -> dict[str, int]:
    counts = {"observations": 0, "conditions": 0, "medications": 0, "allergies": 0}
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        resource_type = resource.get("resourceType")
        if resource_type == "Observation":
            value = resource.get("valueQuantity", {}).get("value", 0)
            db.add(
                Observation(
                    user_id=user.id,
                    observation_type=resource.get("code", {}).get("text", "Observation"),
                    value=float(value),
                    unit=resource.get("valueQuantity", {}).get("unit"),
                    normal_min=None,
                    normal_max=None,
                    status="normal",
                    observed_at=datetime.now(UTC),
                    fhir_payload=resource,
                )
            )
            counts["observations"] += 1
        elif resource_type == "Condition":
            db.add(
                MedicalRecord(
                    user_id=user.id,
                    record_type="Diagnosis",
                    title=resource.get("code", {}).get("text", "Imported condition"),
                    description="Imported from FHIR sandbox",
                    provider_name=connection.provider_name if connection else "FHIR Sandbox",
                    doctor_name=None,
                    record_date=datetime.now(UTC),
                    fhir_resource_type="Condition",
                    fhir_payload=resource,
                )
            )
            counts["conditions"] += 1
        elif resource_type == "MedicationRequest":
            db.add(
                Medication(
                    user_id=user.id,
                    medicine_name=resource.get("medicationCodeableConcept", {}).get("text", "Imported medication"),
                    dosage=resource.get("dosageInstruction", [{}])[0].get("text"),
                    frequency=None,
                    active=resource.get("status") == "active",
                    notes="Imported from FHIR sandbox",
                )
            )
            counts["medications"] += 1
        elif resource_type == "AllergyIntolerance":
            db.add(
                Allergy(
                    user_id=user.id,
                    allergen=resource.get("code", {}).get("text", "Imported allergy"),
                    severity=resource.get("criticality"),
                    reaction="Imported from FHIR sandbox",
                )
            )
            counts["allergies"] += 1
    db.add(
        FhirImportLog(
            user_id=user.id,
            provider_connection_id=connection.id if connection else None,
            source=connection.provider_name if connection else "FHIR Sandbox",
            imported_counts=counts,
            raw_bundle=bundle,
        )
    )
    return counts


def refresh_token_if_needed(provider_connection: ProviderConnection) -> ProviderConnection:
    # TODO: call provider token endpoint when token_expires_at is close.
    return provider_connection
