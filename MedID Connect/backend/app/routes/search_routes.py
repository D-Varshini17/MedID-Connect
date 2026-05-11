from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.advanced_schema import NaturalSearchRequest, NaturalSearchResponse
from app.services.search_service import natural_record_search
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/search", tags=["natural-language-search"])


@router.post("/records", response_model=NaturalSearchResponse)
def search_records(
    payload: NaturalSearchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> NaturalSearchResponse:
    return NaturalSearchResponse(**natural_record_search(db, current_user.id, payload.query))
