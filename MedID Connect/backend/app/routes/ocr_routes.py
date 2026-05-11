from datetime import datetime, UTC

from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.advanced import UploadedDocument
from app.models.medication import Medication
from app.models.observation import Observation
from app.models.user import User
from app.schemas.advanced_schema import LabAnalyzerResponse, PrescriptionOcrResponse
from app.services.audit_service import write_audit_log
from app.services.ocr_service import extract_prescription_entities, extract_text_from_upload, parse_lab_markers
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/ocr", tags=["ocr"])


@router.post("/prescription", response_model=PrescriptionOcrResponse, status_code=status.HTTP_201_CREATED)
async def prescription_ocr(
    file: UploadFile = File(...),
    confirm_save: bool = True,
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
            "engines": ["mock", "tesseract_ready", "google_vision_ready", "aws_textract_ready"],
            "todo": "Add medical NLP and human confirmation workflow before production auto-save.",
        },
        ai_summary="Prescription OCR placeholder completed.",
    )
    db.add(document)
    db.flush()
    created_ids: list[int] = []
    if confirm_save:
        for med in entities["medications"]:
            medication = Medication(
                user_id=current_user.id,
                medicine_name=med.medicine_name,
                dosage=med.dosage,
                frequency=med.timing,
                prescribing_doctor=entities["doctor_name"],
                active=True,
                notes=f"Created from OCR placeholder. Duration: {med.duration or 'not detected'}",
            )
            db.add(medication)
            db.flush()
            created_ids.append(medication.id)
    write_audit_log(db, current_user.id, "ocr_prescription", "uploaded_document", str(document.id))
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


@router.post("/lab-report", response_model=LabAnalyzerResponse, status_code=status.HTTP_201_CREATED)
async def lab_report_ocr(
    file: UploadFile = File(...),
    confirm_save: bool = True,
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
    if confirm_save:
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
                fhir_payload={"source": "ocr_lab_report_placeholder", "document_id": document.id},
            )
            db.add(observation)
            db.flush()
            created_ids.append(observation.id)
    write_audit_log(db, current_user.id, "ocr_lab_report", "uploaded_document", str(document.id))
    db.commit()
    return LabAnalyzerResponse(
        document_id=document.id,
        summary=document.ai_summary or "Lab report analyzed.",
        markers=markers,
        warnings=warnings,
        created_observation_ids=created_ids,
    )
