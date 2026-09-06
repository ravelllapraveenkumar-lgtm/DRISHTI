from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from backend.app.config import settings
from backend.app.database import get_db, engine
from backend.app.schemas.common import HealthResponse, DBHealthResponse

router = APIRouter(tags=["Health & Diagnostics"])

@router.get("/health", response_model=HealthResponse)
def get_health():
    """Standard system health status."""
    return HealthResponse(
        status="healthy",
        app_name=settings.PROJECT_NAME,
        version=settings.VERSION,
        environment=settings.ENVIRONMENT
    )

@router.get("/health/db", response_model=DBHealthResponse)
def get_db_health(db: Session = Depends(get_db)):
    """Comprehensive database connectivity and schema verification."""
    try:
        # Check active connection
        db.execute(text("SELECT 1")).fetchone()
        
        # Determine database dialect from the active session
        dialect_name = db.get_bind().dialect.name
        
        # Count available tables
        if dialect_name == "postgresql":
            res = db.execute(text("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'")).fetchone()
            tables_count = res[0] if res else 0
        else:
            res = db.execute(text("SELECT COUNT(*) FROM sqlite_master WHERE type='table'")).fetchone()
            tables_count = res[0] if res else 0

        return DBHealthResponse(
            status="healthy",
            database=dialect_name,
            tables_count=tables_count,
            connection="connected",
            detail=f"Successfully queried database. Active tables: {tables_count}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Database health check failed: {str(e)}"
        )
