-- =====================================================================
-- DRISHTI: Smart Real-Time Monitoring & Inspection Platform
-- Target: PostgreSQL 16+
-- Schema: Normalized Relational Architecture with UUID v4 & Temporal Tracking
-- Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026 Problem ID 26095
-- Master Schema: database/schema.sql
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================
-- CLEAN TEARDOWN (For pristine migrations & testing)
-- =====================================================================

DROP VIEW IF EXISTS reports CASCADE;
DROP VIEW IF EXISTS evidence_metadata CASCADE;
DROP VIEW IF EXISTS checklist_submissions CASCADE;
DROP VIEW IF EXISTS schemes CASCADE;

DROP TABLE IF EXISTS audit_activity CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS inspection_reports CASCADE;
DROP TABLE IF EXISTS evidence CASCADE;
DROP TABLE IF EXISTS inspection_checklists CASCADE;
DROP TABLE IF EXISTS checklist_items CASCADE;
DROP TABLE IF EXISTS checklist_templates CASCADE;
DROP TABLE IF EXISTS inspection_assignments CASCADE;
DROP TABLE IF EXISTS inspections CASCADE;
DROP TABLE IF EXISTS ai_alerts CASCADE;
DROP TABLE IF EXISTS ai_analyses CASCADE;
DROP TABLE IF EXISTS attendance_records CASCADE;
DROP TABLE IF EXISTS monitoring_records CASCADE;
DROP TABLE IF EXISTS beneficiaries CASCADE;
DROP TABLE IF EXISTS institutions CASCADE;
DROP TABLE IF EXISTS projects_schemes CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop Enums if existing
DROP TYPE IF EXISTS user_role_enum CASCADE;
DROP TYPE IF EXISTS institution_type_enum CASCADE;
DROP TYPE IF EXISTS scheme_category_enum CASCADE;
DROP TYPE IF EXISTS inspection_status_enum CASCADE;
DROP TYPE IF EXISTS priority_level_enum CASCADE;
DROP TYPE IF EXISTS anomaly_severity_enum CASCADE;
DROP TYPE IF EXISTS evidence_type_enum CASCADE;
DROP TYPE IF EXISTS sync_status_enum CASCADE;
DROP TYPE IF EXISTS report_verdict_enum CASCADE;

-- =====================================================================
-- ENUM TYPES
-- =====================================================================

CREATE TYPE user_role_enum AS ENUM (
    'SUPER_ADMIN',
    'MINISTRY_OFFICER',
    'DISTRICT_MAGISTRATE',
    'INSPECTION_SUPERVISOR',
    'FIELD_INSPECTOR',
    'INSTITUTION_HEAD'
);

CREATE TYPE institution_type_enum AS ENUM (
    'DDRS_CENTER',                -- Deendayal Disabled Rehabilitation Scheme
    'OLD_AGE_HOME_AVYAY',        -- Atal Vayo Abhyuday Yojana
    'NASHA_MUKTI_KENDRA_NAPDDR',  -- National Action Plan for Drug Demand Reduction
    'SKILL_DEVELOPMENT_PM_DAKSH', -- PM Young Achievers / DAKSH
    'SPECIAL_SCHOOL',            -- Residential schools for disabled youth
    'HALFWAY_HOME'               -- Post-care psychiatric/social rehabilitation
);

CREATE TYPE scheme_category_enum AS ENUM (
    'DISABILITY_EMPOWERMENT',
    'SENIOR_CITIZENS',
    'SUBSTANCE_REHABILITATION',
    'SC_OBC_DEVELOPMENT',
    'VOCATIONAL_SKILLS'
);

CREATE TYPE inspection_status_enum AS ENUM (
    'PENDING_DISPATCH',
    'ASSIGNED',
    'INSPECTOR_EN_ROUTE',
    'ON_SITE_ACTIVE',
    'COMPLETED_OFFLINE',
    'SYNCED',
    'UNDER_MINISTRY_REVIEW',
    'CLOSED_ACTION_TAKEN',
    'IN_PROGRESS',
    'SUBMITTED',
    'APPROVED',
    'CLOSED'
);

CREATE TYPE priority_level_enum AS ENUM (
    'ROUTINE',
    'MEDIUM',
    'HIGH',
    'URGENT'
);

CREATE TYPE anomaly_severity_enum AS ENUM (
    'LOW',       -- 0-29: Normal statistical variance
    'MEDIUM',    -- 30-59: Moderate telemetry drift
    'HIGH',      -- 60-79: Significant divergence; verification recommended
    'CRITICAL'   -- 80-100: Severe irregularity; urgent physical inspection required
);

CREATE TYPE evidence_type_enum AS ENUM (
    'GEO_TAGGED_PHOTO',
    'GEO_TAGGED_VIDEO',
    'BENEFICIARY_VOICE_NOTE',
    'INFRASTRUCTURE_AUDIT_IMAGE',
    'REGISTER_SCAN'
);

CREATE TYPE sync_status_enum AS ENUM (
    'LOCAL_PENDING',
    'SYNCING',
    'SYNCED_SUCCESS',
    'SYNC_FAILED',
    'RETRY_QUEUED'
);

CREATE TYPE report_verdict_enum AS ENUM (
    'SATISFACTORY',
    'MINOR_NON_COMPLIANCE',
    'MAJOR_DEFICIENCIES_DETECTED',
    'PHYSICAL_DISCREPANCY_CONFIRMED',
    'RECOMMENDED_GRANT_PAUSE'
);

-- =====================================================================
-- 1. USERS & ROLES
-- =====================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    badge_number VARCHAR(100),
    designation VARCHAR(100),
    department VARCHAR(150),
    state VARCHAR(100),
    district VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    is_demo BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name user_role_enum UNIQUE NOT NULL,
    display_name VARCHAR(100),
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

-- =====================================================================
-- 2. SCHEMES/PROJECTS & INSTITUTIONS
-- =====================================================================

CREATE TABLE projects_schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    category scheme_category_enum NOT NULL,
    description TEXT,
    launch_date DATE,
    nodal_ministry VARCHAR(255) NOT NULL DEFAULT 'Ministry of Social Justice and Empowerment',
    sanctioned_budget NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (sanctioned_budget >= 0),
    annual_target_beneficiaries INT NOT NULL DEFAULT 0 CHECK (annual_target_beneficiaries >= 0),
    guidelines_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE institutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    institution_type institution_type_enum NOT NULL,
    primary_scheme_id UUID NOT NULL REFERENCES projects_schemes(id) ON DELETE RESTRICT,
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    sub_division VARCHAR(100),
    pincode VARCHAR(10) NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90.0 AND 90.0),
    longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180.0 AND 180.0),
    geofence_radius_meters INT NOT NULL DEFAULT 100 CHECK (geofence_radius_meters > 0),
    contact_person_name VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    sanctioned_capacity INT NOT NULL DEFAULT 50 CHECK (sanctioned_capacity >= 0),
    active_beneficiary_count INT NOT NULL DEFAULT 0 CHECK (active_beneficiary_count >= 0),
    cctv_streams_count INT NOT NULL DEFAULT 0 CHECK (cctv_streams_count >= 0),
    cctv_status VARCHAR(50) NOT NULL DEFAULT 'OPERATIONAL',
    verification_status VARCHAR(50) NOT NULL DEFAULT 'VERIFIED_REGISTERED',
    current_risk_score INT NOT NULL DEFAULT 0 CHECK (current_risk_score BETWEEN 0 AND 100),
    risk_level VARCHAR(20) NOT NULL DEFAULT 'LOW',
    last_inspected_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- 3. BENEFICIARIES
-- =====================================================================

CREATE TABLE beneficiaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES projects_schemes(id) ON DELETE RESTRICT,
    masked_aadhaar_ref VARCHAR(20) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    date_of_birth DATE NOT NULL,
    disability_category VARCHAR(100),
    admission_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- 4. MONITORING RECORDS & ATTENDANCE
-- =====================================================================

CREATE TABLE monitoring_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    record_date DATE NOT NULL,
    total_enrolled INT NOT NULL CHECK (total_enrolled >= 0),
    present_beneficiaries INT NOT NULL CHECK (present_beneficiaries >= 0),
    biometric_punch_count INT NOT NULL DEFAULT 0 CHECK (biometric_punch_count >= 0),
    present_staff INT NOT NULL CHECK (present_staff >= 0),
    meals_served_count INT NOT NULL DEFAULT 0 CHECK (meals_served_count >= 0),
    cctv_uptime_percentage NUMERIC(5, 2) NOT NULL DEFAULT 100.00 CHECK (cctv_uptime_percentage BETWEEN 0.00 AND 100.00),
    gps_ping_status VARCHAR(50) NOT NULL DEFAULT 'MATCHED_GEOFENCE',
    telemetry_metadata JSONB,
    is_synthetic BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_inst_daily_monitoring UNIQUE (institution_id, record_date)
);

CREATE TABLE attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    beneficiary_id UUID REFERENCES beneficiaries(id) ON DELETE SET NULL,
    attendance_date DATE NOT NULL,
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'PRESENT',
    verification_mode VARCHAR(50) NOT NULL DEFAULT 'BIOMETRIC_OR_SMART_PORTAL',
    is_synthetic BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- 5. AI ANALYSES & AI ALERTS (RESPONSIBLE AI CONSTRAINTS)
-- =====================================================================

CREATE TABLE ai_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    analysis_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    algorithm_used VARCHAR(100) NOT NULL DEFAULT 'ISOLATION_FOREST_V1',
    dataset_window_days INT NOT NULL DEFAULT 30 CHECK (dataset_window_days > 0),
    risk_attention_score INT NOT NULL CHECK (risk_attention_score BETWEEN 0 AND 100),
    severity_level anomaly_severity_enum NOT NULL,
    statistical_divergence_score NUMERIC(6, 4) NOT NULL,
    -- Strictly Responsible AI: neutral verification language enforced
    potential_anomaly_flag BOOLEAN NOT NULL DEFAULT FALSE,
    explainable_reason TEXT NOT NULL,
    recommended_action TEXT NOT NULL,
    requires_human_review BOOLEAN NOT NULL DEFAULT TRUE,
    reviewed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ai_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ai_analysis_id UUID NOT NULL REFERENCES ai_analyses(id) ON DELETE CASCADE,
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    severity anomaly_severity_enum NOT NULL,
    title VARCHAR(255) NOT NULL,
    alert_summary TEXT NOT NULL,
    suggested_inspection_scope TEXT,
    is_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_by UUID REFERENCES users(id) ON DELETE SET NULL,
    acknowledged_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- 6. INSPECTIONS & ASSIGNMENTS
-- =====================================================================

CREATE TABLE inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_code VARCHAR(100) UNIQUE NOT NULL,
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    origin_ai_alert_id UUID REFERENCES ai_alerts(id) ON DELETE SET NULL,
    priority priority_level_enum NOT NULL DEFAULT 'ROUTINE',
    status inspection_status_enum NOT NULL DEFAULT 'PENDING_DISPATCH',
    mandated_date DATE NOT NULL,
    due_date DATE NOT NULL,
    inspection_reason TEXT NOT NULL,
    special_instructions TEXT,
    assigned_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inspection_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id UUID NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    inspector_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMPTZ,
    arrived_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    assigned_by_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_inspection_assignment UNIQUE (inspection_id, inspector_user_id)
);

-- =====================================================================
-- 7. CHECKLIST TEMPLATES, ITEMS & INSPECTION CHECKLISTS
-- =====================================================================

CREATE TABLE checklist_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    scheme_category scheme_category_enum NOT NULL,
    version INT NOT NULL DEFAULT 1 CHECK (version > 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE checklist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES checklist_templates(id) ON DELETE CASCADE,
    section_name VARCHAR(100) NOT NULL,
    item_question TEXT NOT NULL,
    field_type VARCHAR(50) NOT NULL DEFAULT 'BOOLEAN_PASS_FAIL',
    is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    guidance_notes TEXT,
    order_index INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inspection_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id UUID NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    checklist_item_id UUID NOT NULL REFERENCES checklist_items(id) ON DELETE RESTRICT,
    response_boolean BOOLEAN,
    response_value TEXT,
    inspector_comment TEXT,
    gps_latitude DOUBLE PRECISION CHECK (gps_latitude IS NULL OR (gps_latitude BETWEEN -90.0 AND 90.0)),
    gps_longitude DOUBLE PRECISION CHECK (gps_longitude IS NULL OR (gps_longitude BETWEEN -180.0 AND 180.0)),
    captured_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_inspection_checklist_item UNIQUE (inspection_id, checklist_item_id)
);

-- =====================================================================
-- 8. EVIDENCE (TAMPER-RESISTANT CHAIN OF CUSTODY)
-- =====================================================================

CREATE TABLE evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id UUID NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    evidence_type evidence_type_enum NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path_or_url TEXT NOT NULL,
    sha256_checksum VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    timestamp_captured TIMESTAMPTZ NOT NULL,
    gps_latitude DOUBLE PRECISION NOT NULL CHECK (gps_latitude BETWEEN -90.0 AND 90.0),
    gps_longitude DOUBLE PRECISION NOT NULL CHECK (gps_longitude BETWEEN -180.0 AND 180.0),
    gps_accuracy_meters NUMERIC(6, 2) NOT NULL CHECK (gps_accuracy_meters >= 0),
    geofence_verified BOOLEAN NOT NULL DEFAULT FALSE,
    sync_status sync_status_enum NOT NULL DEFAULT 'SYNCED_SUCCESS',
    sync_attempts INT NOT NULL DEFAULT 1 CHECK (sync_attempts >= 0),
    local_sqlite_id VARCHAR(100),
    captured_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- 9. INSPECTION REPORTS & ADMINISTRATIVE ACTIONS
-- =====================================================================

CREATE TABLE inspection_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_id UUID UNIQUE NOT NULL REFERENCES inspections(id) ON DELETE CASCADE,
    inspector_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    submission_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    physical_beneficiary_count INT NOT NULL CHECK (physical_beneficiary_count >= 0),
    roster_discrepancy_count INT NOT NULL DEFAULT 0 CHECK (roster_discrepancy_count >= 0),
    cleanliness_score INT CHECK (cleanliness_score BETWEEN 1 AND 10),
    food_nutrition_score INT CHECK (food_nutrition_score BETWEEN 1 AND 10),
    infrastructure_condition_score INT CHECK (infrastructure_condition_score BETWEEN 1 AND 10),
    inspector_summary TEXT NOT NULL,
    overall_verdict report_verdict_enum NOT NULL,
    official_review_status VARCHAR(50) NOT NULL DEFAULT 'PENDING_OFFICIAL_REVIEW',
    reviewed_by_official_id UUID REFERENCES users(id) ON DELETE SET NULL,
    official_decision_notes TEXT,
    action_taken_type VARCHAR(100),
    action_taken_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- 10. NOTIFICATIONS & AUDIT ACTIVITY
-- =====================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'ALERT',
    entity_reference_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    target_entity VARCHAR(100) NOT NULL,
    entity_id UUID,
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- COMPATIBILITY VIEWS (Supports both logical entity nomenclature)
-- =====================================================================

CREATE OR REPLACE VIEW reports AS SELECT * FROM inspection_reports;
CREATE OR REPLACE VIEW evidence_metadata AS SELECT * FROM evidence;
CREATE OR REPLACE VIEW checklist_submissions AS SELECT * FROM inspection_checklists;
CREATE OR REPLACE VIEW schemes AS SELECT * FROM projects_schemes;

-- =====================================================================
-- INDEXES FOR HIGH-THROUGHPUT QUERIES & REFERENTIAL INTEGRITY
-- =====================================================================

-- Foreign Key Lookup Indexes
CREATE INDEX idx_user_roles_user ON user_roles (user_id);
CREATE INDEX idx_user_roles_role ON user_roles (role_id);
CREATE INDEX idx_institutions_scheme ON institutions (primary_scheme_id);
CREATE INDEX idx_beneficiaries_institution ON beneficiaries (institution_id);
CREATE INDEX idx_beneficiaries_scheme ON beneficiaries (scheme_id);
CREATE INDEX idx_monitoring_institution_date ON monitoring_records (institution_id, record_date DESC);
CREATE INDEX idx_attendance_inst_date ON attendance_records (institution_id, attendance_date DESC);
CREATE INDEX idx_attendance_beneficiary ON attendance_records (beneficiary_id);
CREATE INDEX idx_ai_analyses_inst ON ai_analyses (institution_id, analysis_timestamp DESC);
CREATE INDEX idx_ai_alerts_analysis ON ai_alerts (ai_analysis_id);
CREATE INDEX idx_ai_alerts_inst ON ai_alerts (institution_id);
CREATE INDEX idx_inspections_inst ON inspections (institution_id);
CREATE INDEX idx_inspections_alert ON inspections (origin_ai_alert_id);
CREATE INDEX idx_inspections_assigned_by ON inspections (assigned_by_user_id);
CREATE INDEX idx_inspection_assignments_insp ON inspection_assignments (inspection_id);
CREATE INDEX idx_inspection_assignments_user ON inspection_assignments (inspector_user_id);
CREATE INDEX idx_checklist_items_tmpl ON checklist_items (template_id);
CREATE INDEX idx_inspection_checklists_insp ON inspection_checklists (inspection_id);
CREATE INDEX idx_inspection_checklists_item ON inspection_checklists (checklist_item_id);
CREATE INDEX idx_evidence_inspection ON evidence (inspection_id);
CREATE INDEX idx_evidence_captured_by ON evidence (captured_by_user_id);
CREATE INDEX idx_inspection_reports_inspector ON inspection_reports (inspector_id);
CREATE INDEX idx_inspection_reports_reviewed_by ON inspection_reports (reviewed_by_official_id);
CREATE INDEX idx_notifications_recipient ON notifications (recipient_user_id, is_read);
CREATE INDEX idx_audit_actor ON audit_activity (actor_user_id);

-- Filter, Range & Search Indexes
CREATE INDEX idx_institutions_risk ON institutions (current_risk_score DESC);
CREATE INDEX idx_institutions_type ON institutions (institution_type);
CREATE INDEX idx_institutions_location ON institutions (state, district);
CREATE INDEX idx_inspections_status ON inspections (status);
CREATE INDEX idx_inspections_priority ON inspections (priority);
CREATE INDEX idx_ai_alerts_severity ON ai_alerts (severity);
CREATE INDEX idx_ai_alerts_acknowledged ON ai_alerts (is_acknowledged);
CREATE INDEX idx_evidence_checksum ON evidence (sha256_checksum);
CREATE INDEX idx_evidence_sync_status ON evidence (sync_status);
CREATE INDEX idx_audit_created ON audit_activity (created_at DESC);
