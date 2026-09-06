from backend.app.models.user import User, Role, UserRole
from backend.app.models.scheme import ProjectScheme
from backend.app.models.institution import Institution
from backend.app.models.beneficiary import Beneficiary
from backend.app.models.monitoring import MonitoringRecord, AttendanceRecord
from backend.app.models.ai import AIAnalysis, AIAlert
from backend.app.models.inspection import Inspection, InspectionAssignment
from backend.app.models.checklist import ChecklistTemplate, ChecklistItem, InspectionChecklist
from backend.app.models.evidence import Evidence
from backend.app.models.report import InspectionReport
from backend.app.models.notification import Notification
from backend.app.models.audit import AuditActivity

__all__ = [
    "User",
    "Role",
    "UserRole",
    "ProjectScheme",
    "Institution",
    "Beneficiary",
    "MonitoringRecord",
    "AttendanceRecord",
    "AIAnalysis",
    "AIAlert",
    "Inspection",
    "InspectionAssignment",
    "ChecklistTemplate",
    "ChecklistItem",
    "InspectionChecklist",
    "Evidence",
    "InspectionReport",
    "Notification",
    "AuditActivity",
]
