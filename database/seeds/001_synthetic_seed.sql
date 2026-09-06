-- =====================================================================
-- DRISHTI: Synthetic Demo Seed Data (MoSJE Schemes)
-- Notice: ALL DATA IN THIS FILE IS STRICTLY SYNTHETIC AND GENERATED FOR
-- THE SMART INDIA HACKATHON 2026 PROTOTYPE. NO REAL CITIZEN OR INSTITUTION
-- DATA IS STORED OR REFERENCED.
-- Seed File: database/seeds/001_synthetic_seed.sql
-- =====================================================================

-- 1. Insert Roles
INSERT INTO roles (id, role_name, description) VALUES
('a0000001-0000-0000-0000-000000000001', 'SUPER_ADMIN', 'Central Administrator for System Maintenance & Schema Management'),
('a0000001-0000-0000-0000-000000000002', 'MINISTRY_OFFICER', 'MoSJE Directorate Officer with inspection approval and grant review privileges'),
('a0000001-0000-0000-0000-000000000003', 'DISTRICT_MAGISTRATE', 'District Social Welfare Officer with regional inspection assignment authority'),
('a0000001-0000-0000-0000-000000000004', 'INSPECTION_SUPERVISOR', 'Senior Nodal Officer managing field inspector dispatch and reports'),
('a0000001-0000-0000-0000-000000000005', 'FIELD_INSPECTOR', 'Field Inspector equipped with offline-first mobile app and GPS evidence capture'),
('a0000001-0000-0000-0000-000000000006', 'INSTITUTION_HEAD', 'Authorised NGO / Center Manager reporting daily attendance and monitoring');

-- 2. Insert Users
INSERT INTO users (id, email, hashed_password, full_name, phone_number, badge_number) VALUES
('b0000001-0000-0000-0000-000000000001', 'officer.sharma@mosje.gov.in', '$2b$12$e8wE530Z9f7D...demo_hash_sharma', 'Dr. Rajesh Sharma', '+919811001122', 'MOSJE-DIR-042'),
('b0000001-0000-0000-0000-000000000002', 'inspector.verma@drishti.gov.in', '$2b$12$e8wE530Z9f7D...demo_hash_verma', 'Anjali Verma', '+919876543210', 'INSP-DL-2026-88'),
('b0000001-0000-0000-0000-000000000003', 'inspector.singh@drishti.gov.in', '$2b$12$e8wE530Z9f7D...demo_hash_singh', 'Vikram Singh', '+919822334455', 'INSP-UP-2026-14'),
('b0000001-0000-0000-0000-000000000004', 'ngo.director@arunodayasociety.org', '$2b$12$e8wE530Z9f7D...demo_hash_narang', 'Pooja Narang', '+919988776655', 'INST-DIR-901');

-- 3. Insert User-Role Mappings
INSERT INTO user_roles (user_id, role_id) VALUES
('b0000001-0000-0000-0000-000000000001', 'a0000001-0000-0000-0000-000000000002'),
('b0000001-0000-0000-0000-000000000002', 'a0000001-0000-0000-0000-000000000005'),
('b0000001-0000-0000-0000-000000000003', 'a0000001-0000-0000-0000-000000000005'),
('b0000001-0000-0000-0000-000000000004', 'a0000001-0000-0000-0000-000000000006');

-- 4. Insert MoSJE Flagship Schemes / Projects
INSERT INTO projects_schemes (id, code, name, category, sanctioned_budget, annual_target_beneficiaries, guidelines_url) VALUES
('c0000001-0000-0000-0000-000000000001', 'DDRS-2026', 'Deendayal Disabled Rehabilitation Scheme', 'DISABILITY_EMPOWERMENT', 185000000.00, 45000, 'https://socialjustice.gov.in/schemes/ddrs'),
('c0000001-0000-0000-0000-000000000002', 'AVYAY-2026', 'Atal Vayo Abhyuday Yojana (Senior Citizens Homes)', 'SENIOR_CITIZENS', 120000000.00, 28000, 'https://socialjustice.gov.in/schemes/avyay'),
('c0000001-0000-0000-0000-000000000003', 'NAPDDR-2026', 'National Action Plan for Drug Demand Reduction (IRCA/CPLI)', 'SUBSTANCE_REHABILITATION', 95000000.00, 15000, 'https://socialjustice.gov.in/schemes/napddr'),
('c0000001-0000-0000-0000-000000000004', 'PM-DAKSH-2026', 'Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi', 'VOCATIONAL_SKILLS', 240000000.00, 60000, 'https://pmdaksh.dosje.gov.in');

-- 5. Insert Institutions
INSERT INTO institutions (id, registration_code, name, institution_type, primary_scheme_id, state, district, pincode, address, latitude, longitude, geofence_radius_meters, contact_person_name, contact_phone, contact_email, sanctioned_capacity, active_beneficiary_count, current_risk_score) VALUES
('d0000001-0000-0000-0000-000000000001', 'MOSJE-DL-DDRS-019', 'Arunodaya Special School & Vocational Training Center', 'DDRS_CENTER', 'c0000001-0000-0000-0000-000000000001', 'Delhi', 'South Delhi', '110017', 'Institutional Area, Sector 4, R.K. Puram, New Delhi', 28.5672, 77.1856, 100, 'Pooja Narang', '+919988776655', 'arunodaya.ddrs@demo.org', 80, 74, 18),
('d0000001-0000-0000-0000-000000000002', 'MOSJE-UP-AVYAY-042', 'Vridhashram Shanti Sadan Senior Care Home', 'OLD_AGE_HOME_AVYAY', 'c0000001-0000-0000-0000-000000000002', 'Uttar Pradesh', 'Lucknow', '226010', 'Plot 18, Gomti Nagar Extension, Lucknow', 26.8521, 80.9984, 120, 'Rameshwar Dayal', '+919455112233', 'shantisadan.avyay@demo.org', 60, 58, 72),
('d0000001-0000-0000-0000-000000000003', 'MOSJE-HR-NAPDDR-088', 'Nai Disha Integrated Rehabilitation Center for Addicts (IRCA)', 'NASHA_MUKTI_KENDRA_NAPDDR', 'c0000001-0000-0000-0000-000000000003', 'Haryana', 'Gurugram', '122001', 'Near Civil Hospital, Old Railway Road, Gurugram', 28.4595, 77.0266, 80, 'Dr. Harpreet Chawla', '+919711445566', 'naidisha.irca@demo.org', 40, 39, 85),
('d0000001-0000-0000-0000-000000000004', 'MOSJE-MP-DAKSH-011', 'Pratibha Skill Empowerment Hub', 'SKILL_DEVELOPMENT_PM_DAKSH', 'c0000001-0000-0000-0000-000000000004', 'Madhya Pradesh', 'Bhopal', '462003', 'Industrial Area, Govindpura, Bhopal', 23.2599, 77.4126, 150, 'Suresh Kulkarni', '+919827001122', 'pratibha.daksh@demo.org', 120, 115, 34);

-- 6. Insert Beneficiaries
INSERT INTO beneficiaries (id, institution_id, scheme_id, masked_aadhaar_ref, full_name, gender, date_of_birth, disability_category, admission_date, is_active) VALUES
('bb000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'XXXX-XXXX-4192', 'Rohan Mehra', 'MALE', '2010-04-15', 'LOCOMOTOR_DISABILITY', '2024-07-01', TRUE),
('bb000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'XXXX-XXXX-8821', 'Priyanka Sen', 'FEMALE', '2012-08-20', 'HEARING_IMPAIRMENT', '2024-08-10', TRUE),
('bb000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000002', 'XXXX-XXXX-1034', 'Ram Prasad Sharma', 'MALE', '1948-03-12', 'GERIATRIC_CARE', '2023-11-05', TRUE),
('bb000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000002', 'c0000001-0000-0000-0000-000000000002', 'XXXX-XXXX-6672', 'Kalyani Devi', 'FEMALE', '1952-11-09', 'GERIATRIC_CARE', '2024-01-15', TRUE),
('bb000001-0000-0000-0000-000000000005', 'd0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', 'XXXX-XXXX-9901', 'Manish Tanwar', 'MALE', '1995-06-22', 'SUBSTANCE_DE_ADDICTION', '2026-06-01', TRUE),
('bb000001-0000-0000-0000-000000000006', 'd0000001-0000-0000-0000-000000000003', 'c0000001-0000-0000-0000-000000000003', 'XXXX-XXXX-5543', 'Sandeep Yadav', 'MALE', '1998-02-14', 'SUBSTANCE_DE_ADDICTION', '2026-07-12', TRUE),
('bb000001-0000-0000-0000-000000000007', 'd0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 'XXXX-XXXX-3312', 'Sunita Ahirwar', 'FEMALE', '2001-09-30', 'SKILL_TRAINEE_TAILORING', '2026-05-10', TRUE),
('bb000001-0000-0000-0000-000000000008', 'd0000001-0000-0000-0000-000000000004', 'c0000001-0000-0000-0000-000000000004', 'XXXX-XXXX-7729', 'Deepak Shakya', 'MALE', '2000-12-05', 'SKILL_TRAINEE_IT', '2026-05-10', TRUE);

-- 7. Insert Monitoring Records (Daily Telemetry)
INSERT INTO monitoring_records (id, institution_id, record_date, total_enrolled, present_beneficiaries, present_staff, meals_served_count, cctv_uptime_percentage, gps_ping_status, telemetry_metadata) VALUES
('9a000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', '2026-09-04', 74, 69, 12, 138, 99.40, 'MATCHED_GEOFENCE', '{"smart_meter_kwh": 48.2, "water_liters": 1250}'::jsonb),
('9a000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000002', '2026-09-04', 58, 58, 8, 72, 84.10, 'MATCHED_GEOFENCE', '{"diet_log_discrepancy_ratio": 0.38, "power_outage_hrs": 1.2}'::jsonb),
('9a000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000003', '2026-09-04', 39, 39, 6, 78, 42.50, 'OUTSIDE_GEOFENCE_DRIFT', '{"avg_geofence_offset_meters": 1820, "cctv_heartbeat_loss_hrs": 4.5}'::jsonb),
('9a000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000004', '2026-09-04', 115, 108, 14, 216, 98.80, 'MATCHED_GEOFENCE', '{"biometric_sync_latency_sec": 1.2}'::jsonb);

-- 8. Insert Attendance Records
INSERT INTO attendance_records (id, institution_id, beneficiary_id, attendance_date, check_in_time, check_out_time, status, verification_mode, is_synthetic) VALUES
('aa000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'bb000001-0000-0000-0000-000000000001', '2026-09-04', '2026-09-04 09:12:00+00', '2026-09-04 16:30:00+00', 'PRESENT', 'BIOMETRIC_OR_SMART_PORTAL', TRUE),
('aa000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000001', 'bb000001-0000-0000-0000-000000000002', '2026-09-04', '2026-09-04 09:15:30+00', '2026-09-04 16:35:00+00', 'PRESENT', 'BIOMETRIC_OR_SMART_PORTAL', TRUE),
('aa000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000002', 'bb000001-0000-0000-0000-000000000003', '2026-09-04', '2026-09-04 08:30:00+00', '2026-09-04 20:00:00+00', 'PRESENT', 'RESIDENTIAL_HEADCOUNT', TRUE),
('aa000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000002', 'bb000001-0000-0000-0000-000000000004', '2026-09-04', '2026-09-04 08:30:00+00', '2026-09-04 20:00:00+00', 'PRESENT', 'RESIDENTIAL_HEADCOUNT', TRUE),
('aa000001-0000-0000-0000-000000000005', 'd0000001-0000-0000-0000-000000000003', 'bb000001-0000-0000-0000-000000000005', '2026-09-04', '2026-09-04 09:00:00+00', '2026-09-04 18:00:00+00', 'PRESENT', 'BIOMETRIC_PORTAL', TRUE),
('aa000001-0000-0000-0000-000000000006', 'd0000001-0000-0000-0000-000000000003', 'bb000001-0000-0000-0000-000000000006', '2026-09-04', '2026-09-04 09:00:00+00', '2026-09-04 18:00:00+00', 'PRESENT', 'BIOMETRIC_PORTAL', TRUE);

-- 9. Insert AI Analyses & Responsible AI Alerts
INSERT INTO ai_analyses (id, institution_id, risk_attention_score, severity_level, statistical_divergence_score, potential_anomaly_flag, explainable_reason, recommended_action, requires_human_review, reviewed_by_user_id, reviewed_at, review_notes) VALUES
('e0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000002', 72, 'HIGH', 0.7640, TRUE, 'Consecutive 14-day flatlined biometric attendance with zero natural absenteeism variance, combined with a 38% drop in reported meal consumption logs.', 'Verification recommended. Human review required. Recommend dispatching field inspector for unannounced on-site headcount.', TRUE, 'b0000001-0000-0000-0000-000000000001', '2026-09-04 14:20:00+00', 'Reviewed telemetry discrepancy. Dispatched field inspection.'),
('e0000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000003', 85, 'CRITICAL', 0.8820, TRUE, 'Discrepancy detected: Repeated high attendance pings outside registered geofence perimeter (average offset 1.8km), accompanied by CCTV heartbeat dropout during peak daytime hours.', 'Verification recommended. Human review required. Urgent physical inspection and GPS geofence re-audit advised.', TRUE, 'b0000001-0000-0000-0000-000000000001', '2026-09-04 14:25:00+00', 'Urgent inspection ordered for IRCA center.');

INSERT INTO ai_alerts (id, ai_analysis_id, institution_id, severity, title, alert_summary, suggested_inspection_scope, is_acknowledged, acknowledged_by, acknowledged_at) VALUES
('f0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000002', 'HIGH', 'Potential anomaly detected: Attendance vs Ration Log Variance', 'Potential anomaly detected. Verification recommended. Discrepancy observed between claimed senior resident roster (58 residents) and dietary intake logs over the last 14 days.', 'Verify physical resident presence, inspect kitchen inventory, check medicine administration registers.', TRUE, 'b0000001-0000-0000-0000-000000000001', '2026-09-04 14:30:00+00'),
('f0000001-0000-0000-0000-000000000002', 'e0000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000003', 'CRITICAL', 'Potential anomaly detected: Geofence Offset & Telemetry Gap', 'Potential anomaly detected. Verification recommended. IRCA center telemetry reflects consistent coordinate mismatch and missing afternoon counselor session logs.', 'Immediate physical audit of in-patient wards, attendance biometric machine location, and counselor staff rosters.', TRUE, 'b0000001-0000-0000-0000-000000000001', '2026-09-04 14:35:00+00');

-- 10. Insert Inspections
INSERT INTO inspections (id, inspection_code, institution_id, origin_ai_alert_id, priority, status, mandated_date, due_date, inspection_reason, special_instructions, assigned_by_user_id) VALUES
('10000001-0000-0000-0000-000000000001', 'INSP-2026-LKO-001', 'd0000001-0000-0000-0000-000000000002', 'f0000001-0000-0000-0000-000000000001', 'HIGH', 'ASSIGNED', '2026-09-05', '2026-09-07', 'Physical verification of resident census following AI divergence alert on dietary log ratios.', 'Inspect dormitories, food storage registers, and resident identity badges.', 'b0000001-0000-0000-0000-000000000001'),
('10000001-0000-0000-0000-000000000002', 'INSP-2026-GGM-002', 'd0000001-0000-0000-0000-000000000003', 'f0000001-0000-0000-0000-000000000002', 'URGENT', 'ON_SITE_ACTIVE', '2026-09-05', '2026-09-06', 'Surprise on-site inspection for geofence verification and patient bed verification.', 'Capture live geotagged images inside the center boundary. Minimum 3 photos.', 'b0000001-0000-0000-0000-000000000001');

-- 11. Insert Inspection Assignments
INSERT INTO inspection_assignments (id, inspection_id, inspector_user_id, assigned_at, accepted_at, assigned_by_id, notes) VALUES
('20000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000003', '2026-09-04 15:00:00+00', '2026-09-04 15:15:00+00', 'b0000001-0000-0000-0000-000000000001', 'Verify actual resident beds in person. Capture minimum 3 geotagged photos.'),
('20000001-0000-0000-0000-000000000002', '10000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', '2026-09-04 15:00:00+00', '2026-09-04 15:10:00+00', 'b0000001-0000-0000-0000-000000000001', 'Capture on-site live GPS coordinates and cross-reference with center boundaries.');

-- 12. Insert Checklist Templates & Items
INSERT INTO checklist_templates (id, name, scheme_category, version) VALUES
('30000001-0000-0000-0000-000000000001', 'Standard MoSJE Institutional Inspection Checklist v2.1', 'DISABILITY_EMPOWERMENT', 2);

INSERT INTO checklist_items (id, template_id, section_name, item_question, field_type, is_mandatory, guidance_notes, order_index) VALUES
('40000001-0000-0000-0000-000000000001', '30000001-0000-0000-0000-000000000001', 'Geographic & Boundary Verification', 'Does the physical site match the registered geo-coordinates within the 100m geofence perimeter?', 'BOOLEAN_PASS_FAIL', TRUE, 'Take reading at main gate entrance.', 1),
('40000001-0000-0000-0000-000000000002', '30000001-0000-0000-0000-000000000001', 'Physical Headcount', 'Count of beneficiaries physically present during the inspection match the daily portal submission?', 'BOOLEAN_PASS_FAIL', TRUE, 'Physical roll call in assembly hall.', 2),
('40000001-0000-0000-0000-000000000003', '30000001-0000-0000-0000-000000000001', 'Infrastructure & Safety', 'Are barrier-free accessible ramps, disability-friendly toilets, and fire safety systems operational?', 'BOOLEAN_PASS_FAIL', TRUE, 'Test ramp slope and fire extinguisher tags.', 3),
('40000001-0000-0000-0000-000000000004', '30000001-0000-0000-0000-000000000001', 'Nutrition & Medicine Register', 'Are dietary and medication distribution registers up to date with batch details and doctor visits?', 'BOOLEAN_PASS_FAIL', TRUE, 'Inspect register for last 14 calendar days.', 4);

-- 13. Insert Inspection Checklist Responses
INSERT INTO inspection_checklists (id, inspection_id, checklist_item_id, response_boolean, response_value, inspector_comment, gps_latitude, gps_longitude) VALUES
('45000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000002', '40000001-0000-0000-0000-000000000001', TRUE, 'PASS', 'Main entrance verified within 12m of coordinates.', 28.45952, 77.02663),
('45000001-0000-0000-0000-000000000002', '10000001-0000-0000-0000-000000000002', '40000001-0000-0000-0000-000000000002', FALSE, 'FAIL', 'Found 22 in-patients physically present vs 39 claimed on portal.', 28.45951, 77.02661),
('45000001-0000-0000-0000-000000000003', '10000001-0000-0000-0000-000000000002', '40000001-0000-0000-0000-000000000003', TRUE, 'PASS', 'Basic fire buckets and first aid kit available.', 28.45950, 77.02660),
('45000001-0000-0000-0000-000000000004', '10000001-0000-0000-0000-000000000002', '40000001-0000-0000-0000-000000000004', FALSE, 'FAIL', 'Dietary register missing entries for 4 days this week.', 28.45952, 77.02662);

-- 14. Insert Evidence (Tamper-Resistant Geotagged Records)
INSERT INTO evidence (id, inspection_id, evidence_type, file_name, file_path_or_url, sha256_checksum, description, timestamp_captured, gps_latitude, gps_longitude, gps_accuracy_meters, geofence_verified, sync_status, captured_by_user_id) VALUES
('50000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000002', 'GEO_TAGGED_PHOTO', 'evidence_front_gate_001.jpg', 'https://storage.demo.drishti.gov.in/evidence/insp2/front_gate.jpg', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'Physical main gate signage showing Nai Disha IRCA license board.', '2026-09-05 10:14:22+00', 28.45952, 77.02663, 4.20, TRUE, 'SYNCED_SUCCESS', 'b0000001-0000-0000-0000-000000000002'),
('50000001-0000-0000-0000-000000000002', '10000001-0000-0000-0000-000000000002', 'GEO_TAGGED_PHOTO', 'evidence_dormitory_beds_002.jpg', 'https://storage.demo.drishti.gov.in/evidence/insp2/dormitory.jpg', 'f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2', 'In-patient dormitory showing 22 occupied beds out of 40 reported.', '2026-09-05 10:28:45+00', 28.45951, 77.02661, 3.80, TRUE, 'SYNCED_SUCCESS', 'b0000001-0000-0000-0000-000000000002');

-- 15. Insert Inspection Reports
INSERT INTO inspection_reports (id, inspection_id, inspector_id, submission_timestamp, physical_beneficiary_count, roster_discrepancy_count, cleanliness_score, food_nutrition_score, infrastructure_condition_score, inspector_summary, overall_verdict, official_review_status, reviewed_by_official_id, official_decision_notes, action_taken_type, action_taken_at) VALUES
('60000001-0000-0000-0000-000000000001', '10000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', '2026-09-05 12:30:00+00', 22, 17, 6, 5, 7, 'Conducted unannounced inspection at Nai Disha IRCA. Found only 22 patients physically present against 39 claimed on the national portal. 17 resident beds unoccupied with missing attendance entries.', 'PHYSICAL_DISCREPANCY_CONFIRMED', 'REVIEWED_ACTION_TAKEN', 'b0000001-0000-0000-0000-000000000001', 'Discrepancy confirmed by geotagged evidence. Next installment of grant suspended pending show-cause notice response.', 'GRANT_TRANCHE_PAUSED', '2026-09-05 16:00:00+00');

-- 16. Insert Notifications
INSERT INTO notifications (id, recipient_user_id, title, message, category, entity_reference_id, is_read) VALUES
('70000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'High Severity Anomaly Detected', 'AI Engine flagged divergence in Nai Disha IRCA telemetry.', 'AI_ALERT', 'f0000001-0000-0000-0000-000000000002', TRUE),
('70000001-0000-0000-0000-000000000002', 'b0000001-0000-0000-0000-000000000002', 'Urgent Inspection Assigned', 'You have been assigned to inspect Nai Disha IRCA (INSP-2026-GGM-002).', 'ASSIGNMENT', '10000001-0000-0000-0000-000000000002', TRUE),
('70000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', 'Inspection Report Submitted', 'Inspector Anjali Verma submitted report for INSP-2026-GGM-002.', 'REPORT_SUBMITTED', '60000001-0000-0000-0000-000000000001', FALSE);

-- 17. Insert Audit Activity (Immutable System Trail)
INSERT INTO audit_activity (id, actor_user_id, action, target_entity, entity_id, ip_address, user_agent, details) VALUES
('80000001-0000-0000-0000-000000000001', 'b0000001-0000-0000-0000-000000000001', 'USER_LOGIN', 'users', 'b0000001-0000-0000-0000-000000000001', '10.0.4.12', 'Mozilla/5.0 (MoSJE-Intranet)', '{"auth_type": "CERTIFICATE_2FA"}'::jsonb),
('80000001-0000-0000-0000-000000000002', NULL, 'AI_ANOMALY_EVALUATION', 'institutions', 'd0000001-0000-0000-0000-000000000003', '127.0.0.1', 'DRISHTI-AI-Worker/1.0', '{"risk_score": 85, "model": "IsolationForest_v1"}'::jsonb),
('80000001-0000-0000-0000-000000000003', 'b0000001-0000-0000-0000-000000000001', 'CREATE_INSPECTION_MANDATE', 'inspections', '10000001-0000-0000-0000-000000000002', '10.0.4.12', 'Mozilla/5.0 (MoSJE-Intranet)', '{"priority": "URGENT", "assigned_inspector": "Anjali Verma"}'::jsonb),
('80000001-0000-0000-0000-000000000004', 'b0000001-0000-0000-0000-000000000002', 'SUBMIT_EVIDENCE', 'evidence', '50000001-0000-0000-0000-000000000001', '172.24.1.88', 'DRISHTI-Mobile-App/1.0 (Android 14; Pixel 8)', '{"geofence_verified": true, "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}'::jsonb);
