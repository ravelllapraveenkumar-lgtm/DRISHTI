from backend.app.schemas.common import MessageResponse, HealthResponse, DBHealthResponse, PaginatedResponse
from backend.app.schemas.auth import Token, LoginRequest, DemoLoginRequest, RoleResponse, UserProfileResponse
from backend.app.schemas.institution import InstitutionCreate, InstitutionUpdate, InstitutionResponse, InstitutionDetailResponse
from backend.app.schemas.scheme import SchemeResponse
from backend.app.schemas.beneficiary import BeneficiaryCreate, BeneficiaryResponse
from backend.app.schemas.monitoring import MonitoringRecordCreate, MonitoringRecordResponse
from backend.app.schemas.attendance import AttendanceRecordCreate, AttendanceRecordResponse, AttendanceSummaryResponse
from backend.app.schemas.inspection import InspectionCreate, InspectionUpdate, InspectionStatusUpdate, InspectionResponse
from backend.app.schemas.assignment import AssignmentCreate, AssignmentUpdate, AssignmentResponse
from backend.app.schemas.checklist import (
    ChecklistItemResponse,
    ChecklistTemplateResponse,
    ChecklistSubmissionCreate,
    ChecklistBatchSubmission,
    ChecklistSubmissionResponse,
)
from backend.app.schemas.evidence import EvidenceCreate, EvidenceResponse
from backend.app.schemas.report import InspectionReportCreate, InspectionReportReview, InspectionReportResponse
from backend.app.schemas.ai import AIAnalysisCreate, AIAnalysisResponse, AIAlertResponse, AlertAcknowledgeRequest
from backend.app.schemas.notification import NotificationCreate, NotificationResponse
from backend.app.schemas.audit import AuditActivityCreate, AuditActivityResponse
from backend.app.schemas.dashboard import DashboardSummaryResponse, RiskDistribution, SchemeStats

__all__ = [
    "MessageResponse",
    "HealthResponse",
    "DBHealthResponse",
    "PaginatedResponse",
    "Token",
    "LoginRequest",
    "DemoLoginRequest",
    "RoleResponse",
    "UserProfileResponse",
    "InstitutionCreate",
    "InstitutionUpdate",
    "InstitutionResponse",
    "InstitutionDetailResponse",
    "SchemeResponse",
    "BeneficiaryCreate",
    "BeneficiaryResponse",
    "MonitoringRecordCreate",
    "MonitoringRecordResponse",
    "AttendanceRecordCreate",
    "AttendanceRecordResponse",
    "AttendanceSummaryResponse",
    "InspectionCreate",
    "InspectionUpdate",
    "InspectionStatusUpdate",
    "InspectionResponse",
    "AssignmentCreate",
    "AssignmentUpdate",
    "AssignmentResponse",
    "ChecklistItemResponse",
    "ChecklistTemplateResponse",
    "ChecklistSubmissionCreate",
    "ChecklistBatchSubmission",
    "ChecklistSubmissionResponse",
    "EvidenceCreate",
    "EvidenceResponse",
    "InspectionReportCreate",
    "InspectionReportReview",
    "InspectionReportResponse",
    "AIAnalysisCreate",
    "AIAnalysisResponse",
    "AIAlertResponse",
    "AlertAcknowledgeRequest",
    "NotificationCreate",
    "NotificationResponse",
    "AuditActivityCreate",
    "AuditActivityResponse",
    "DashboardSummaryResponse",
    "RiskDistribution",
    "SchemeStats",
]
