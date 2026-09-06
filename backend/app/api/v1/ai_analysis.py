import uuid
from typing import List, Optional
from datetime import datetime, date, timedelta
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import (
    AIAnalysis, AIAlert, Institution, MonitoringRecord, User
)
from backend.app.schemas.ai import AIAnalysisCreate, AIAnalysisResponse
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(prefix="/ai-analyses", tags=["AI Analysis & Anomaly Detection"])

def format_analysis(a: AIAnalysis) -> AIAnalysisResponse:
    return AIAnalysisResponse(
        id=a.id,
        institution_id=a.institution_id,
        analysis_timestamp=a.analysis_timestamp,
        algorithm_used=a.algorithm_used,
        dataset_window_days=a.dataset_window_days,
        risk_attention_score=a.risk_attention_score,
        severity_level=a.severity_level,
        statistical_divergence_score=a.statistical_divergence_score,
        potential_anomaly_flag=a.potential_anomaly_flag,
        explainable_reason=a.explainable_reason,
        recommended_action=a.recommended_action,
        requires_human_review=a.requires_human_review,
        reviewed_by_user_id=a.reviewed_by_user_id,
        reviewed_at=a.reviewed_at,
        review_notes=a.review_notes,
        created_at=a.created_at,
        institution_name=a.institution.name if a.institution else None,
        institution_state=a.institution.state if a.institution else None,
        institution_district=a.institution.district if a.institution else None
    )

@router.get("", response_model=PaginatedResponse[AIAnalysisResponse])
def list_analyses(
    institution_id: Optional[uuid.UUID] = None,
    severity: Optional[str] = None,
    potential_anomaly_only: bool = False,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Lists statistical anomaly analysis evaluations."""
    query = db.query(AIAnalysis)

    if institution_id:
        query = query.filter(AIAnalysis.institution_id == institution_id)
    if severity:
        query = query.filter(AIAnalysis.severity_level == severity.upper())
    if potential_anomaly_only:
        query = query.filter(AIAnalysis.potential_anomaly_flag == True)

    total = query.count()
    offset = (page - 1) * page_size
    items = query.order_by(AIAnalysis.analysis_timestamp.desc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[format_analysis(i) for i in items]
    )

@router.post("", response_model=AIAnalysisResponse, status_code=status.HTTP_201_CREATED)
def create_ai_analysis(
    data: AIAnalysisCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL"]))
):
    """Ingests AI anomaly analysis result and automatically spawns AIAlert if critical."""
    inst = db.query(Institution).filter(Institution.id == data.institution_id).first()
    if not inst:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")

    analysis = AIAnalysis(
        id=uuid.uuid4(),
        **data.dict(),
        analysis_timestamp=datetime.utcnow()
    )
    db.add(analysis)
    db.flush()

    # Update institution risk score
    inst.current_risk_score = data.risk_attention_score
    inst.risk_level = data.severity_level.upper()
    inst.updated_at = datetime.utcnow()

    # If high or critical, auto-generate or update existing OPEN alert
    if data.severity_level.upper() in ("HIGH", "CRITICAL") and data.potential_anomaly_flag:
        existing_alert = db.query(AIAlert).filter(
            AIAlert.institution_id == inst.id,
            AIAlert.is_acknowledged == False
        ).first()

        if existing_alert:
            existing_alert.ai_analysis_id = analysis.id
            existing_alert.severity = data.severity_level.upper()
            existing_alert.title = f"{data.severity_level.upper()} Anomaly Alert: {inst.name}"
            existing_alert.alert_summary = data.explainable_reason
            existing_alert.suggested_inspection_scope = data.recommended_action
            existing_alert.updated_at = datetime.utcnow()
        else:
            alert = AIAlert(
                id=uuid.uuid4(),
                ai_analysis_id=analysis.id,
                institution_id=inst.id,
                severity=data.severity_level.upper(),
                title=f"{data.severity_level.upper()} Anomaly Alert: {inst.name}",
                alert_summary=data.explainable_reason,
                suggested_inspection_scope=data.recommended_action,
                is_acknowledged=False
            )
            db.add(alert)

    db.commit()
    db.refresh(analysis)

    record_audit_log(
        db, current_user, "AI_ANALYSIS_RECORDED", "ai_analyses", analysis.id,
        {"risk_score": data.risk_attention_score, "severity": data.severity_level}, request
    )

    return format_analysis(analysis)

@router.get("/{id}", response_model=AIAnalysisResponse)
def get_ai_analysis(id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves specific AI analysis record."""
    item = db.query(AIAnalysis).filter(AIAnalysis.id == id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="AI Analysis not found")
    return format_analysis(item)
