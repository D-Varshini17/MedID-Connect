from pydantic import BaseModel


class InsightRead(BaseModel):
    title: str
    description: str
    recommendation: str
    severity: str = "info"
    category: str
