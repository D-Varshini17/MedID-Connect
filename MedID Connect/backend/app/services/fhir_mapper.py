from __future__ import annotations

from datetime import datetime
from typing import Any

from app.models.advanced import Appointment
from app.models.interop import Consent
from app.models.medical_record import MedicalRecord
from app.models.medication import Allergy, Medication
from app.models.observation import Observation
from app.models.user import User


def _iso(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def user_to_fhir_patient(user: User) -> dict[str, Any]:
    return {
        "resourceType": "Patient",
        "id": str(user.id),
        "identifier": [{"system": "https://medidconnect.com/patient-id", "value": f"medid-{user.id}"}],
        "name": [{"text": user.full_name}],
        "telecom": [{"system": "phone", "value": user.phone}] if user.phone else [],
        "gender": user.gender.lower() if user.gender else "unknown",
        "extension": [
            {"url": "https://medidconnect.com/fhir/StructureDefinition/blood-group", "valueString": user.blood_group}
        ]
        if user.blood_group
        else [],
    }


def observation_to_fhir(observation: Observation) -> dict[str, Any]:
    return {
        "resourceType": "Observation",
        "id": str(observation.id),
        "status": "final",
        "code": {"text": observation.observation_type},
        "subject": {"reference": f"Patient/{observation.user_id}"},
        "effectiveDateTime": _iso(observation.observed_at),
        "valueQuantity": {"value": observation.value, "unit": observation.unit},
        "interpretation": [{"text": observation.status}],
        "referenceRange": [
            {
                "low": {"value": observation.normal_min, "unit": observation.unit},
                "high": {"value": observation.normal_max, "unit": observation.unit},
            }
        ],
    }


def condition_to_fhir(record: MedicalRecord) -> dict[str, Any]:
    return {
        "resourceType": "Condition",
        "id": str(record.id),
        "clinicalStatus": {"text": "active"},
        "code": {"text": record.title},
        "subject": {"reference": f"Patient/{record.user_id}"},
        "recordedDate": _iso(record.record_date),
        "note": [{"text": record.description or ""}],
    }


def medication_to_fhir_medication_request(medication: Medication) -> dict[str, Any]:
    return {
        "resourceType": "MedicationRequest",
        "id": str(medication.id),
        "status": "active" if medication.active else "stopped",
        "intent": "order",
        "subject": {"reference": f"Patient/{medication.user_id}"},
        "medicationCodeableConcept": {"text": medication.medicine_name},
        "dosageInstruction": [{"text": " ".join(filter(None, [medication.dosage, medication.frequency]))}],
        "authoredOn": _iso(medication.created_at),
        "requester": {"display": medication.prescribing_doctor},
        "note": [{"text": medication.notes or ""}],
    }


def allergy_to_fhir(allergy: Allergy) -> dict[str, Any]:
    return {
        "resourceType": "AllergyIntolerance",
        "id": str(allergy.id),
        "clinicalStatus": {"text": "active"},
        "criticality": allergy.severity or "unable-to-assess",
        "code": {"text": allergy.allergen},
        "patient": {"reference": f"Patient/{allergy.user_id}"},
        "reaction": [{"manifestation": [{"text": allergy.reaction or "Reaction not specified"}]}],
    }


def diagnostic_report_to_fhir(record: MedicalRecord) -> dict[str, Any]:
    return {
        "resourceType": "DiagnosticReport",
        "id": str(record.id),
        "status": "final",
        "code": {"text": record.title},
        "subject": {"reference": f"Patient/{record.user_id}"},
        "effectiveDateTime": _iso(record.record_date),
        "performer": [{"display": record.provider_name}],
        "conclusion": record.description,
    }


def immunization_to_fhir(record: MedicalRecord) -> dict[str, Any]:
    return {
        "resourceType": "Immunization",
        "id": str(record.id),
        "status": "completed",
        "vaccineCode": {"text": record.title},
        "patient": {"reference": f"Patient/{record.user_id}"},
        "occurrenceDateTime": _iso(record.record_date),
        "performer": [{"actor": {"display": record.provider_name}}],
    }


def appointment_to_fhir(appointment: Appointment) -> dict[str, Any]:
    return {
        "resourceType": "Appointment",
        "id": str(appointment.id),
        "status": appointment.status,
        "serviceType": [{"text": appointment.appointment_type}],
        "start": _iso(appointment.scheduled_at),
        "participant": [{"actor": {"reference": f"Patient/{appointment.user_id}"}, "status": "accepted"}],
        "description": appointment.reason,
    }


def consent_to_fhir(consent: Consent) -> dict[str, Any]:
    return {
        "resourceType": "Consent",
        "id": str(consent.id),
        "status": "inactive" if consent.revoked_at else "active",
        "scope": {"text": "patient-privacy"},
        "category": [{"text": "MedID Connect sharing consent"}],
        "patient": {"reference": f"Patient/{consent.user_id}"},
        "dateTime": _iso(consent.created_at),
        "provision": {
            "period": {"end": _iso(consent.expires_at)},
            "actor": [{"role": {"text": consent.grantee_type}, "reference": {"display": consent.grantee_name}}],
            "type": "permit",
            "class": [{"code": resource} for resource in consent.allowed_resources],
        },
    }


def bundle(resources: list[dict[str, Any]]) -> dict[str, Any]:
    return {"resourceType": "Bundle", "type": "searchset", "entry": [{"resource": resource} for resource in resources]}
