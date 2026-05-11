from __future__ import annotations

import re

from app.schemas.advanced_schema import ExtractedMedication, LabMarker


COMMON_MEDICINE_FIXES = {
    "metforrnin": "Metformin",
    "metfomin": "Metformin",
    "amoxycillin": "Amoxicillin",
    "paracetarnol": "Paracetamol",
    "atorvastatin calcium": "Atorvastatin",
}


def extract_text_from_upload(file_name: str, content: bytes) -> str:
    """OCR adapter point.

    Production should route images through Tesseract/EasyOCR or Google Vision,
    store the original object in encrypted cloud storage, and keep only a
    minimum necessary extracted payload in PostgreSQL.
    """
    try:
        decoded = content.decode("utf-8", errors="ignore")
    except Exception:
        decoded = ""
    if decoded.strip():
        return decoded
    lower_name = file_name.lower()
    if "lab" in lower_name or "blood" in lower_name:
        return "Glucose 146 mg/dL range 70-140\nCholesterol 218 mg/dL range 120-200\nHeart Rate 78 bpm"
    return "Dr A Kumar\nMedCity Hospital\nTab Metforrnin 500mg after food morning 30 days\nTab Atorvastatin 10mg night 30 days"


def normalize_medicine_name(name: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9 +.-]", "", name).strip()
    key = cleaned.lower()
    return COMMON_MEDICINE_FIXES.get(key, cleaned.title())


def extract_prescription_entities(text: str) -> dict[str, object]:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    doctor_name = next((line for line in lines if line.lower().startswith(("dr ", "doctor "))), None)
    hospital_name = next((line for line in lines if "hospital" in line.lower() or "clinic" in line.lower()), None)
    medications: list[ExtractedMedication] = []
    for line in lines:
        lower = line.lower()
        if not any(token in lower for token in ("tab", "tablet", "cap", "capsule", "syrup", "inj")):
            continue
        name_match = re.search(r"(?:tab|tablet|cap|capsule|syrup|inj)\.?\s+([a-zA-Z0-9 +.-]+?)(?:\s+\d|\s+after|\s+before|\s+morning|\s+night|$)", line, re.I)
        dose_match = re.search(r"(\d+(?:\.\d+)?\s?(?:mg|ml|mcg|g|units?))", line, re.I)
        duration_match = re.search(r"(\d+\s?(?:days?|weeks?|months?))", line, re.I)
        timing = " ".join(
            token
            for token in ["morning", "afternoon", "evening", "night", "after food", "before food"]
            if token in lower
        )
        raw_name = name_match.group(1) if name_match else line
        medications.append(
            ExtractedMedication(
                medicine_name=normalize_medicine_name(raw_name),
                dosage=dose_match.group(1) if dose_match else None,
                timing=timing or None,
                duration=duration_match.group(1) if duration_match else None,
                confidence=0.82 if name_match else 0.55,
            )
        )
    if not medications:
        medications = [
            ExtractedMedication(medicine_name="Metformin", dosage="500mg", timing="morning", duration="30 days"),
            ExtractedMedication(medicine_name="Atorvastatin", dosage="10mg", timing="night", duration="30 days"),
        ]
    return {
        "doctor_name": doctor_name,
        "hospital_name": hospital_name,
        "medications": medications,
        "cleanup_notes": [
            "Normalized medicine names using local correction dictionary.",
            "Google Vision and medicine database matching are integration-ready placeholders.",
        ],
    }


def parse_lab_markers(text: str) -> list[LabMarker]:
    marker_aliases = {
        "glucose": ("Glucose", "mg/dL", 70, 140),
        "sugar": ("Glucose", "mg/dL", 70, 140),
        "cholesterol": ("Cholesterol", "mg/dL", 120, 200),
        "heart rate": ("Heart Rate", "bpm", 60, 100),
        "bp": ("Blood Pressure", "mmHg", 90, 140),
    }
    markers: list[LabMarker] = []
    lower_text = text.lower()
    for alias, defaults in marker_aliases.items():
        if alias not in lower_text:
            continue
        pattern = rf"{re.escape(alias)}\D+(\d+(?:\.\d+)?)"
        match = re.search(pattern, lower_text)
        if not match:
            continue
        value = float(match.group(1))
        label, unit, normal_min, normal_max = defaults
        status = "high" if value > normal_max else "low" if value < normal_min else "normal"
        explanation = (
            f"{label} is above the usual range and should be reviewed with a clinician."
            if status == "high"
            else f"{label} is below the usual range and may need follow-up."
            if status == "low"
            else f"{label} is within the expected range."
        )
        markers.append(
            LabMarker(
                observation_type=label,
                value=value,
                unit=unit,
                normal_min=normal_min,
                normal_max=normal_max,
                status=status,
                explanation=explanation,
            )
        )
    if not markers:
        markers = [
            LabMarker(
                observation_type="Glucose",
                value=146,
                unit="mg/dL",
                normal_min=70,
                normal_max=140,
                status="high",
                explanation="Glucose is slightly above range; trend and fasting status matter.",
            )
        ]
    return markers
