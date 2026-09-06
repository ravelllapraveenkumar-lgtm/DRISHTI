from typing import Optional
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field, ConfigDict

class BeneficiaryBase(BaseModel):
    institution_id: UUID
    scheme_id: UUID
    identifier_masked: str = Field(..., min_length=4, max_length=50)
    full_name: str = Field(..., min_length=2, max_length=255)
    gender: str = Field(..., min_length=1, max_length=20)
    date_of_birth: date
    disability_type: Optional[str] = None
    admission_date: date

class BeneficiaryCreate(BeneficiaryBase):
    pass

class BeneficiaryResponse(BeneficiaryBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    is_active: bool
    created_at: datetime
