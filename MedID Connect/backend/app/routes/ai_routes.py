from datetime import datetime, UTC

from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import UploadedDocument
from app.models.medication import Medication
from app.models.observation import Observation
from app.models.user import User
from app.schemas.advanced_schema import (
    LabAnalyzerResponse,
    PrescriptionOcrResponse,
    RiskScoreRead,
    VoiceAssistantRequest,
    VoiceAssistantResponse,
)
from app.services.audit_service import write_audit_log
from app.services.ocr_service import extract_prescription_entities, extract_text_from_upload, parse_lab_markers
from app.services.risk_service import calculate_risk_scores
from app.services.voice_assistant_service import answer_health_query
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/ai", tags=["advanced-ai"])


@router.post("/prescription-ocr", response_model=PrescriptionOcrResponse, status_code=status.HTTP_201_CREATED)
async def prescription_ocr(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PrescriptionOcrResponse:
    content = await file.read()
    extracted_text = extract_text_from_upload(file.filename or "prescription", content)
    entities = extract_prescription_entities(extracted_text)
    document = UploadedDocument(
        user_id=current_user.id,
        document_type="prescription",
        file_name=file.filename or "prescription",
        content_type=file.content_type,
        extracted_text=extracted_text,
        extraction_payload={
            "engine": "tesseract_easyocr_google_vision_ready",
            "entities": [med.model_dump() for med in entities["medications"]],
        },
        ai_summary="Prescription parsed and medication candidates created.",
    )
    db.add(document)
    db.flush()

    created_ids: list[int] = []
    for med in entities["medications"]:
        medication = Medication(
            user_id=current_user.id,
            medicine_name=med.medicine_name,
            dosage=med.dosage,
            frequency=med.timing,
            prescribing_doctor=entities["doctor_name"],
            active=True,
            notes=f"OCR duration: {med.duration or 'not detected'}",
        )
        db.add(medication)
        db.flush()
        created_ids.append(medication.id)

    write_audit_log(db, current_user.id, "ai_prescription_ocr", "uploaded_document", str(document.id))
    db.commit()
    return PrescriptionOcrResponse(
        document_id=document.id,
        doctor_name=entities["doctor_name"],
        hospital_name=entities["hospital_name"],
        extracted_text=extracted_text,
        medications=entities["medications"],
        created_medication_ids=created_ids,
        cleanup_notes=entities["cleanup_notes"],
    )


@router.post("/lab-report-analyze", response_model=LabAnalyzerResponse, status_code=status.HTTP_201_CREATED)
async def lab_report_analyze(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> LabAnalyzerResponse:
    content = await file.read()
    extracted_text = extract_text_from_upload(file.filename or "lab-report", content)
    markers = parse_lab_markers(extracted_text)
    warnings = [f"{marker.observation_type} is {marker.status}" for marker in markers if marker.status != "normal"]
    document = UploadedDocument(
        user_id=current_user.id,
        document_type="lab_report",
        file_name=file.filename or "lab-report",
        content_type=file.content_type,
        extracted_text=extracted_text,
        extraction_payload={"markers": [marker.model_dump() for marker in markers]},
        ai_summary="; ".join(warnings) if warnings else "All extracted markers appear within expected ranges.",
    )
    db.add(document)
    db.flush()

    created_ids: list[int] = []
    for marker in markers:
        observation = Observation(
            user_id=current_user.id,
            observation_type=marker.observation_type,
            value=marker.value,
            unit=marker.unit,
            normal_min=marker.normal_min,
            normal_max=marker.normal_max,
            status=marker.status,
            observed_at=datetime.now(UTC),
            fhir_payload={"source": "ai_lab_report_analyzer", "document_id": document.id},
        )
        db.add(observation)
        db.flush()
        created_ids.append(observation.id)

    write_audit_log(db, current_user.id, "ai_lab_report_analyze", "uploaded_document", str(document.id))
    db.commit()
    return LabAnalyzerResponse(
        document_id=document.id,
        summary=document.ai_summary or "Lab report analyzed.",
        markers=markers,
        warnings=warnings,
        created_observation_ids=created_ids,
    )


@router.post("/voice-assistant", response_model=VoiceAssistantResponse)
def voice_assistant(
    payload: VoiceAssistantRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> VoiceAssistantResponse:
    result = answer_health_query(db, current_user.id, payload.text, payload.language)
    return VoiceAssistantResponse(**result)


@router.get("/risk-scores", response_model=list[RiskScoreRead])
def risk_scores(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[RiskScoreRead]:
    scores = calculate_risk_scores(db, current_user.id)
    write_audit_log(db, current_user.id, "calculate", "risk_scores", None)
    db.commit()
    return [
        RiskScoreRead(
            risk_type=score.risk_type,
            score_percent=score.score_percent,
            band=score.band,
            factors=score.factors,
            recommendations=score.recommendations,
            calculated_at=score.calculated_at,
        )
        for score in scores
    ]
