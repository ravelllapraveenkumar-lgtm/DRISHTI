from typing import Generic, TypeVar, List, Optional
from pydantic import BaseModel, Field

T = TypeVar("T")

class MessageResponse(BaseModel):
    message: str
    detail: Optional[str] = None

class HealthResponse(BaseModel):
    status: str = "healthy"
    app_name: str
    version: str
    environment: str

class DBHealthResponse(BaseModel):
    status: str
    database: str
    tables_count: int
    connection: str
    detail: Optional[str] = None

class PaginatedResponse(BaseModel, Generic[T]):
    total: int = Field(..., ge=0)
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    items: List[T]
