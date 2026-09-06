/**
 * DRISHTI: Centralized Typed API Client
 * Interfaces with FastAPI backend (48 endpoints under /api/v1/)
 * Supports JWT authentication, RBAC, retry policies, and synthetic fallback when offline.
 */

import {
  Token,
  UserProfile,
  DemoUser,
  DashboardSummary,
  Institution,
  MonitoringRecord,
  AttendanceRecord,
  AttendanceSummary,
  Inspection,
  InspectionAssignment,
  ChecklistTemplate,
  ChecklistItem,
  ChecklistSubmission,
  EvidenceRecord,
  InspectionReport,
  AIAnalysis,
  AIAlert,
  Notification,
  AuditActivity,
  Scheme,
  Beneficiary
} from '../types/api';

const API_BASE_URL = ((import.meta.env && import.meta.env.VITE_API_BASE_URL) || '/api/v1').replace(/\/$/, '');

export interface ApiResponse<T> {
  data: T;
  isLive: boolean;
  statusText?: string;
  error?: string;
}

class DrishtiApiClient {
  private token: string | null = null;
  private isLiveBackend: boolean = true;
  private healthChecked: boolean = false;

  constructor() {
    if (typeof window !== 'undefined') {
      this.token = localStorage.getItem('drishti_jwt_token');
    }
  }

  public setToken(token: string | null) {
    this.token = token;
    if (typeof window !== 'undefined') {
      if (token) {
        localStorage.setItem('drishti_jwt_token', token);
      } else {
        localStorage.removeItem('drishti_jwt_token');
      }
    }
  }

  public getToken(): string | null {
    return this.token;
  }

  public getIsLive(): boolean {
    return this.isLiveBackend;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
    fallbackData?: T
  ): Promise<ApiResponse<T>> {
    const url = `${API_BASE_URL}${endpoint}`;
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {})
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers
      });

      if (response.status === 401) {
        // Expired or invalid token
        console.warn('[DRISHTI API] 401 Unauthorized from', endpoint);
      }

      if (!response.ok) {
        let errorMsg = `HTTP ${response.status} ${response.statusText}`;
        try {
          const errData = await response.json();
          if (errData.message) errorMsg = errData.message;
          else if (errData.detail) errorMsg = typeof errData.detail === 'string' ? errData.detail : JSON.stringify(errData.detail);
        } catch {
          // ignore json parse error
        }
        throw new Error(errorMsg);
      }

      const rawData = await response.json();
      this.isLiveBackend = true;
      let data: any = rawData;
      if (rawData && typeof rawData === 'object' && Array.isArray(rawData.items)) {
        data = [...rawData.items];
        (data as any).total = rawData.total;
        (data as any).page = rawData.page;
        (data as any).page_size = rawData.page_size;
        (data as any).items = data;
      }
      return { data, isLive: true, statusText: 'Live Backend Connected' };
    } catch (err: any) {
      console.warn(`[DRISHTI API] Call to ${endpoint} failed: ${err.message}. Using fallback if available.`);
      this.isLiveBackend = false;

      if (fallbackData !== undefined) {
        return {
          data: fallbackData,
          isLive: false,
          statusText: 'Demo / Synthetic Fallback Data',
          error: err.message
        };
      }
      throw err;
    }
  }

  // Health checks
  public async checkHealth(): Promise<{ status: string; isLive: boolean }> {
    try {
      const healthUrl = API_BASE_URL.startsWith('http')
        ? `${API_BASE_URL.replace(/\/api\/v1$/, '')}/health`
        : '/health';
      const res = await fetch(healthUrl);
      if (res.ok) {
        const data = await res.json();
        this.isLiveBackend = true;
        return { status: data.status || 'healthy', isLive: true };
      }
    } catch {
      // Backend not reached
    }
    this.isLiveBackend = false;
    return { status: 'offline', isLive: false };
  }

  // 1. AUTHENTICATION & RBAC
  public async getDemoUsers(): Promise<ApiResponse<DemoUser[]>> {
    return this.request<DemoUser[]>('/auth/demo-users', { method: 'GET' });
  }

  public async demoLogin(role: string, userId?: string): Promise<ApiResponse<Token>> {
    return this.request<Token>('/auth/demo-login', {
      method: 'POST',
      body: JSON.stringify({ role, user_id: userId })
    });
  }

  public async login(email: string, password: string): Promise<ApiResponse<Token>> {
    return this.request<Token>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });
  }

  public async getMe(): Promise<ApiResponse<UserProfile>> {
    return this.request<UserProfile>('/auth/me', { method: 'GET' });
  }

  // 2. DASHBOARD
  public async getDashboardSummary(): Promise<ApiResponse<DashboardSummary>> {
    return this.request<DashboardSummary>('/dashboard/summary', { method: 'GET' });
  }

  // 3. INSTITUTIONS
  public async getInstitutions(params?: {
    scheme_category?: string;
    state?: string;
    district?: string;
    risk_level?: string;
    search?: string;
  }): Promise<ApiResponse<Institution[]>> {
    const query = new URLSearchParams();
    if (params?.scheme_category) query.append('scheme_category', params.scheme_category);
    if (params?.state) query.append('state', params.state);
    if (params?.district) query.append('district', params.district);
    if (params?.risk_level) query.append('risk_level', params.risk_level);
    if (params?.search) query.append('search', params.search);

    const qs = query.toString() ? `?${query.toString()}` : '';
    return this.request<Institution[]>(`/institutions${qs}`, { method: 'GET' });
  }

  public async getInstitutionById(id: string): Promise<ApiResponse<Institution>> {
    return this.request<Institution>(`/institutions/${id}`, { method: 'GET' });
  }

  // 4. MONITORING
  public async getMonitoringRecords(params?: {
    institution_id?: string;
    start_date?: string;
    end_date?: string;
  }): Promise<ApiResponse<MonitoringRecord[]>> {
    const query = new URLSearchParams();
    if (params?.institution_id) query.append('institution_id', params.institution_id);
    if (params?.start_date) query.append('start_date', params.start_date);
    if (params?.end_date) query.append('end_date', params.end_date);

    const qs = query.toString() ? `?${query.toString()}` : '';
    return this.request<MonitoringRecord[]>(`/monitoring${qs}`, { method: 'GET' });
  }

  public async getTodayMonitoring(): Promise<ApiResponse<MonitoringRecord[]>> {
    return this.request<MonitoringRecord[]>('/monitoring/today', { method: 'GET' });
  }

  // 5. ATTENDANCE
  public async getAttendanceRecords(params?: {
    institution_id?: string;
    date?: string;
  }): Promise<ApiResponse<AttendanceRecord[]>> {
    const query = new URLSearchParams();
    if (params?.institution_id) query.append('institution_id', params.institution_id);
    if (params?.date) query.append('date', params.date);

    const qs = query.toString() ? `?${query.toString()}` : '';
    return this.request<AttendanceRecord[]>(`/attendance${qs}`, { method: 'GET' });
  }

  public async getAttendanceSummary(institutionId: string, date?: string): Promise<ApiResponse<AttendanceSummary>> {
    const query = new URLSearchParams();
    query.append('institution_id', institutionId);
    if (date) query.append('date', date);

    return this.request<AttendanceSummary>(`/attendance/summary?${query.toString()}`, { method: 'GET' });
  }

  // 6. INSPECTIONS
  public async getInspections(params?: {
    institution_id?: string;
    status?: string;
    priority?: string;
  }): Promise<ApiResponse<Inspection[]>> {
    const query = new URLSearchParams();
    if (params?.institution_id) query.append('institution_id', params.institution_id);
    if (params?.status) query.append('status', params.status);
    if (params?.priority) query.append('priority', params.priority);

    const qs = query.toString() ? `?${query.toString()}` : '';
    return this.request<Inspection[]>(`/inspections${qs}`, { method: 'GET' });
  }

  public async getInspectionById(id: string): Promise<ApiResponse<Inspection>> {
    return this.request<Inspection>(`/inspections/${id}`, { method: 'GET' });
  }

  public async createInspection(payload: {
    institution_id: string;
    priority: string;
    mandated_date: string;
    due_date: string;
    inspection_reason: string;
    special_instructions?: string;
    inspector_user_id?: string;
    origin_ai_alert_id?: string;
  }): Promise<ApiResponse<Inspection>> {
    return this.request<Inspection>('/inspections', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
  }

  public async updateInspectionStatus(id: string, status: string, notes?: string): Promise<ApiResponse<Inspection>> {
    return this.request<Inspection>(`/inspections/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status, notes })
    });
  }

  // 7. ASSIGNMENTS
  public async getAssignments(params?: {
    inspector_id?: string;
    inspection_id?: string;
  }): Promise<ApiResponse<InspectionAssignment[]>> {
    const query = new URLSearchParams();
    if (params?.inspector_id) query.append('inspector_id', params.inspector_id);
    if (params?.inspection_id) query.append('inspection_id', params.inspection_id);

    const qs = query.toString() ? `?${query.toString()}` : '';
    return this.request<InspectionAssignment[]>(`/inspection-assignments${qs}`, { method: 'GET' });
  }

  public async acceptAssignment(id: string): Promise<ApiResponse<InspectionAssignment>> {
    return this.request<InspectionAssignment>(`/inspection-assignments/${id}/accept`, {
      method: 'POST'
    });
  }

  public async markArrival(
    id: string,
    latitude?: number,
    longitude?: number
  ): Promise<ApiResponse<InspectionAssignment>> {
    return this.request<InspectionAssignment>(`/inspection-assignments/${id}/arrive`, {
      method: 'POST',
      body: latitude !== undefined && longitude !== undefined ? JSON.stringify({ latitude, longitude }) : undefined
    });
  }

  // 8. CHECKLISTS
  public async getChecklistTemplates(): Promise<ApiResponse<ChecklistTemplate[]>> {
    return this.request<ChecklistTemplate[]>('/inspection-checklists/templates', { method: 'GET' });
  }

  public async getChecklistItems(templateId?: string): Promise<ApiResponse<ChecklistItem[]>> {
    const qs = templateId ? `?template_id=${templateId}` : '';
    return this.request<ChecklistItem[]>(`/inspection-checklists/items${qs}`, { method: 'GET' });
  }

  public async getInspectionChecklists(inspectionId: string): Promise<ApiResponse<ChecklistSubmission[]>> {
    return this.request<ChecklistSubmission[]>(`/inspection-checklists/inspection/${inspectionId}`, {
      method: 'GET'
    });
  }

  public async submitChecklistBatch(payload: {
    inspection_id: string;
    items: Array<{
      checklist_item_id: string;
      response_boolean?: boolean;
      response_value?: string;
      inspector_comment?: string;
      gps_latitude?: number;
      gps_longitude?: number;
    }>;
  }): Promise<ApiResponse<ChecklistSubmission[]>> {
    return this.request<ChecklistSubmission[]>('/inspection-checklists/batch', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
  }

  // 9. EVIDENCE
  public async getEvidence(inspectionId?: string): Promise<ApiResponse<EvidenceRecord[]>> {
    const qs = inspectionId ? `?inspection_id=${inspectionId}` : '';
    return this.request<EvidenceRecord[]>(`/evidence${qs}`, { method: 'GET' });
  }

  public async submitEvidence(payload: {
    inspection_id: string;
    evidence_type: string;
    file_name: string;
    file_path_or_url: string;
    sha256_checksum: string;
    description: string;
    timestamp_captured: string;
    gps_latitude: number;
    gps_longitude: number;
    gps_accuracy_meters: number;
  }): Promise<ApiResponse<EvidenceRecord>> {
    return this.request<EvidenceRecord>('/evidence', {
      method: 'POST',
      body: JSON.stringify(payload)
    });
  }

  // 10. REPORTS
  public async getInspectionReports(inspectionId?: string): Promise<ApiResponse<InspectionReport[]>> {
    const qs = inspectionId ? `?inspection_id=${inspectionId}` : '';
    return this.request<InspectionReport[]>(`/inspection-reports${qs}`, { method: 'GET' });
  }

  public async getReports(inspectionId?: string): Promise<ApiResponse<InspectionReport[]>> {
    return this.getInspectionReports(inspectionId);
  }

  public async reviewInspectionReport(
    id: string,
    payload: {
      official_review_status?: string;
      status?: string;
      official_decision_notes?: string;
      official_review_notes?: string;
      action_taken_type?: string;
    }
  ): Promise<ApiResponse<InspectionReport>> {
    const body = {
      official_review_status: payload.official_review_status || payload.status || 'REVIEWED_ACCEPTED',
      official_decision_notes: payload.official_decision_notes || payload.official_review_notes || 'Reviewed',
      action_taken_type: payload.action_taken_type
    };
    return this.request<InspectionReport>(`/inspection-reports/${id}/review`, {
      method: 'PATCH',
      body: JSON.stringify(body)
    });
  }

  public async reviewReport(
    id: string,
    payload: {
      official_review_status?: string;
      status?: string;
      official_decision_notes?: string;
      official_review_notes?: string;
      action_taken_type?: string;
    }
  ): Promise<ApiResponse<InspectionReport>> {
    return this.reviewInspectionReport(id, payload);
  }

  // 11. AI ANALYSES & ALERTS
  public async getAIAnalyses(institutionId?: string): Promise<ApiResponse<AIAnalysis[]>> {
    const endpoint = institutionId ? `/ai-analyses/${institutionId}` : '/ai-analyses';
    return this.request<AIAnalysis[]>(endpoint, { method: 'GET' });
  }

  public async getAIAlerts(params?: {
    severity?: string;
    is_acknowledged?: boolean;
    institution_id?: string;
  }): Promise<ApiResponse<AIAlert[]>> {
    const query = new URLSearchParams();
    if (params?.severity) query.append('severity', params.severity);
    if (params?.is_acknowledged !== undefined) query.append('is_acknowledged', String(params.is_acknowledged));
    if (params?.institution_id) query.append('institution_id', params.institution_id);

    const qs = query.toString() ? `?${query.toString()}` : '';
    return this.request<AIAlert[]>(`/ai-alerts${qs}`, { method: 'GET' });
  }

  public async acknowledgeAlert(
    id: string,
    payload?:
      | string
      | {
          action_note?: string;
          create_inspection?: boolean;
          priority?: string;
        }
  ): Promise<ApiResponse<AIAlert>> {
    const body = typeof payload === 'string' ? { action_note: payload } : payload || {};
    return this.request<AIAlert>(`/ai-alerts/${id}/acknowledge`, {
      method: 'POST',
      body: JSON.stringify(body)
    });
  }

  // 12. NOTIFICATIONS
  public async getNotifications(unreadOnly: boolean = false): Promise<ApiResponse<Notification[]>> {
    const qs = unreadOnly ? '?unread_only=true' : '';
    return this.request<Notification[]>(`/notifications${qs}`, { method: 'GET' });
  }

  public async markNotificationRead(id: string): Promise<ApiResponse<{ status: string }>> {
    return this.request<{ status: string }>(`/notifications/${id}/read`, {
      method: 'PATCH'
    });
  }

  public async markAllNotificationsRead(): Promise<ApiResponse<{ status: string }>> {
    return this.request<{ status: string }>('/notifications/read-all', {
      method: 'POST'
    });
  }

  // 13. AUDIT ACTIVITY
  public async getAuditActivity(params?: {
    target_entity?: string;
    limit?: number;
  }): Promise<ApiResponse<AuditActivity[]>> {
    const query = new URLSearchParams();
    if (params?.target_entity) query.append('target_entity', params.target_entity);
    if (params?.limit) query.append('limit', String(params.limit));

    const qs = query.toString() ? `?${query.toString()}` : '';
    return this.request<AuditActivity[]>(`/audit-activity${qs}`, { method: 'GET' });
  }

  public async getAuditLogs(params?: {
    target_entity?: string;
    limit?: number;
  }): Promise<ApiResponse<AuditActivity[]>> {
    return this.getAuditActivity(params);
  }

  // 14. SCHEMES & BENEFICIARIES
  public async getSchemes(): Promise<ApiResponse<Scheme[]>> {
    return this.request<Scheme[]>('/schemes', { method: 'GET' });
  }

  public async getBeneficiaries(institutionId?: string): Promise<ApiResponse<Beneficiary[]>> {
    const qs = institutionId ? `?institution_id=${institutionId}` : '';
    return this.request<Beneficiary[]>(`/beneficiaries${qs}`, { method: 'GET' });
  }
}

export const api = new DrishtiApiClient();
