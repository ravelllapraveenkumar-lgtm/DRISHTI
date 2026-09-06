from typing import List, Dict, Any, Optional
from pydantic import BaseModel

class MetricCard(BaseModel):
    title: str
    value: int
    change: Optional[str] = None
    status: str = "normal"  # normal, warning, critical

class RiskDistribution(BaseModel):
    low: int = 0
    medium: int = 0
    high: int = 0
    critical: int = 0

class SchemeStats(BaseModel):
    scheme_code: str
    scheme_name: str
    category: str
    institutions_count: int
    beneficiaries_count: int
    active_inspections_count: int
    critical_alerts_count: int

class DashboardSummaryResponse(BaseModel):
    total_institutions: int
    total_beneficiaries: int
    active_inspections: int
    completed_inspections: int
    pending_ai_alerts: int
    average_daily_attendance_pct: float
    cctv_online_rate_pct: float
    risk_distribution: RiskDistribution
    schemes: List[SchemeStats]
    recent_critical_alerts: List[Dict[str, Any]]
    recent_inspections: List[Dict[str, Any]]
