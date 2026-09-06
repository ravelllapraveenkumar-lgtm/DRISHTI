"""
Database Seeder for DRISHTI Platform.
Populates standard demonstration records when starting in fresh environments.
"""
import uuid
import logging
from datetime import datetime, date, timedelta
from sqlalchemy.orm import Session
from backend.app.models import (
    Role, User, UserRole, ProjectScheme, Institution, Beneficiary,
    MonitoringRecord, AttendanceRecord, AIAnalysis, AIAlert,
    Inspection, InspectionAssignment, ChecklistTemplate, ChecklistItem,
    InspectionChecklist, Evidence, InspectionReport, Notification, AuditActivity
)

logger = logging.getLogger("drishti.seed")

def seed_database_if_empty(db: Session) -> None:
    """Idempotently populates standard demonstration records when starting in fresh or existing environments."""
    logger.info("Verifying and synchronizing authoritative demo database foundation...")

    # 1. ROLES
    roles_data = [
        ("a0000001-0000-0000-0000-000000000001", "SUPER_ADMIN", "National Super Administrator", "Full system privileges"),
        ("a0000001-0000-0000-0000-000000000002", "MINISTRY_OFFICIAL", "Ministry Official (MoSJE)", "National and State level monitoring"),
        ("a0000001-0000-0000-0000-000000000003", "DISTRICT_OFFICER", "District Social Welfare Officer", "District-level oversight and dispatch"),
        ("a0000001-0000-0000-0000-000000000004", "FIELD_INSPECTOR", "Empaneled Field Inspector", "Mobile app user for field inspections"),
        ("a0000001-0000-0000-0000-000000000005", "INSTITUTION_ADMIN", "Institution Representative", "NGO/Institution manager"),
    ]
    roles = {}
    for r_id, r_name, d_name, desc in roles_data:
        r_uuid = uuid.UUID(r_id)
        role = db.query(Role).filter(Role.id == r_uuid).first()
        if not role:
            role = Role(id=r_uuid, role_name=r_name, display_name=d_name, description=desc)
            db.add(role)
            db.flush()
        roles[r_name] = role

    # 2. USERS
    users_data = [
        ("b0000001-0000-0000-0000-000000000001", "admin@mosje.gov.in", "+919876543210", "$2b$12$e8F0l1KzP62K6n3.x4k5eO9tE2wE9sB2qY8uK6sP3eO8wE1qY4uK6", "Dr. Rajeshwar Sharma", "Joint Secretary", "Department of Social Justice", "Delhi", "Central Delhi", "SUPER_ADMIN"),
        ("b0000001-0000-0000-0000-000000000002", "official.delhi@mosje.gov.in", "+919876543211", "$2b$12$e8F0l1KzP62K6n3.x4k5eO9tE2wE9sB2qY8uK6sP3eO8wE1qY4uK6", "Sunita Verma, IAS", "Director (Monitoring)", "MoSJE National Cell", "Delhi", "New Delhi", "MINISTRY_OFFICIAL"),
        ("b0000001-0000-0000-0000-000000000003", "dswo.lucknow@up.gov.in", "+919876543212", "$2b$12$e8F0l1KzP62K6n3.x4k5eO9tE2wE9sB2qY8uK6sP3eO8wE1qY4uK6", "Anurag Tripathi, PCS", "District Social Welfare Officer", "DSWO Lucknow", "Uttar Pradesh", "Lucknow", "DISTRICT_OFFICER"),
        ("b0000001-0000-0000-0000-000000000004", "inspector.sharma@mosje.gov.in", "+919876543213", "$2b$12$e8F0l1KzP62K6n3.x4k5eO9tE2wE9sB2qY8uK6sP3eO8wE1qY4uK6", "Vikramaditya Sharma", "Senior Empaneled Inspector", "Field Inspection Cadre", "Uttar Pradesh", "Lucknow", "FIELD_INSPECTOR"),
        ("b0000001-0000-0000-0000-000000000005", "ngo.prerna@drishti.org", "+919876543214", "$2b$12$e8F0l1KzP62K6n3.x4k5eO9tE2wE9sB2qY8uK6sP3eO8wE1qY4uK6", "Meenakshi Sundaram", "Director & Secretary", "Prerna Rehabilitation Society", "Uttar Pradesh", "Lucknow", "INSTITUTION_ADMIN"),
    ]
    users = {}
    for u_id, email, phone, p_hash, name, desig, dept, state, district, r_name in users_data:
        u_uuid = uuid.UUID(u_id)
        user = db.query(User).filter(User.id == u_uuid).first()
        if not user:
            user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                id=u_uuid,
                email=email,
                phone_number=phone,
                password_hash=p_hash,
                full_name=name,
                designation=desig,
                department=dept,
                state=state,
                district=district,
                is_active=True,
                is_demo=True
            )
            db.add(user)
            db.flush()
            user_role = UserRole(user_id=user.id, role_id=roles[r_name].id)
            db.add(user_role)
            db.flush()
        users[email] = user

    # 3. SCHEMES
    schemes_data = [
        ("c0000001-0000-0000-0000-000000000001", "SCH-DDRS-01", "Deendayal Disabled Rehabilitation Scheme (DDRS)", "DDRS", "Financial assistance to voluntary organizations running special schools and vocational training centers for Persons with Disabilities.", date(2003, 4, 1), 125000000.00, "https://socialjustice.gov.in/schemes/ddrs"),
        ("c0000001-0000-0000-0000-000000000002", "SCH-AVYAY-02", "Atal Vayo Abhyuday Yojana (AVYAY)", "SENIOR_CITIZENS_AVYAY", "Integrated scheme for providing shelter, healthcare, and nutrition to indigent senior citizens in old-age care facilities.", date(2021, 10, 1), 98000000.00, "https://socialjustice.gov.in/schemes/avyay"),
        ("c0000001-0000-0000-0000-000000000003", "SCH-NAPDDR-03", "National Action Plan for Drug Demand Reduction (NAPDDR)", "NAPDDR", "Multi-pronged strategy to address drug and substance abuse through Integrated Rehabilitation Centres for Addicts (IRCAs).", date(2018, 6, 26), 110000000.00, "https://socialjustice.gov.in/schemes/napddr"),
        ("c0000001-0000-0000-0000-000000000004", "SCH-PMDAKSH-04", "PM-DAKSH Skill Development Scheme", "PM_DAKSH", "National Action Plan for skilling marginalized youth, SCs, OBCs, and sanitation workers.", date(2020, 11, 1), 150000000.00, "https://pmdaksh.dosje.gov.in"),
    ]
    schemes = {}
    for s_id, code, name, cat, desc, l_date, budget, url in schemes_data:
        s_uuid = uuid.UUID(s_id)
        scheme = db.query(ProjectScheme).filter(ProjectScheme.id == s_uuid).first()
        if not scheme:
            scheme = ProjectScheme(
                id=s_uuid,
                code=code,
                name=name,
                category=cat,
                description=desc,
                launch_date=l_date,
                nodal_ministry="Ministry of Social Justice and Empowerment",
                sanctioned_budget=budget,
                guidelines_url=url,
                is_active=True
            )
            db.add(scheme)
            db.flush()
        schemes[code] = scheme

    # 4. INSTITUTIONS
    institutions_data = [
        ("d0000001-0000-0000-0000-000000000001", "NGO-UP-LKO-2024-001", "Prerna Special School & Rehabilitation Centre", "NGO_AIDED", "SCH-DDRS-01", "Uttar Pradesh", "Lucknow", "Aliganj", "Plot 42, Sector B, Aliganj, Lucknow", "226024", 26.8856, 80.9462, 120, "Meenakshi Sundaram", "+919876543214", "ngo.prerna@drishti.org", 65, 58, 4, "OPERATIONAL", 18, "LOW"),
        ("d0000001-0000-0000-0000-000000000002", "NGO-UP-LKO-2024-002", "Sanjeevani IRCA Drug De-addiction Centre", "REHABILITATION_CENTER", "SCH-NAPDDR-03", "Uttar Pradesh", "Lucknow", "Chinhat", "Khasra 108, Near Malhaur Railway Crossing, Chinhat, Lucknow", "226028", 26.8921, 81.0145, 150, "Dr. Arvind Pathak", "+919876543221", "sanjeevani.irca@drishti.org", 40, 24, 2, "DEGRADED", 72, "HIGH"),
        ("d0000001-0000-0000-0000-000000000003", "NGO-DL-SWD-2024-003", "Vridh Seva Ashram Senior Living", "OLD_AGE_HOME", "SCH-AVYAY-02", "Delhi", "South West Delhi", "Najafgarh", "Village Dhansa Road, Najafgarh, New Delhi", "110043", 28.6139, 76.9827, 200, "Col. Balbir Singh (Retd)", "+919876543222", "vridh.seva@drishti.org", 80, 76, 6, "OFFLINE", 85, "CRITICAL"),
    ]
    institutions = {}
    for i_id, code, name, i_type, s_code, state, district, sub_div, addr, pin, lat, lon, geo_r, c_name, c_phone, c_email, cap, occ, cctv_c, cctv_s, risk_s, risk_l in institutions_data:
        i_uuid = uuid.UUID(i_id)
        inst = db.query(Institution).filter(Institution.id == i_uuid).first()
        if not inst:
            inst = Institution(
                id=i_uuid,
                registration_code=code,
                name=name,
                institution_type=i_type,
                primary_scheme_id=schemes[s_code].id,
                state=state,
                district=district,
                sub_division=sub_div,
                address=addr,
                pincode=pin,
                latitude=lat,
                longitude=lon,
                geofence_radius_meters=geo_r,
                contact_person_name=c_name,
                contact_phone=c_phone,
                contact_email=c_email,
                registered_capacity=cap,
                current_occupancy=occ,
                cctv_streams_count=cctv_c,
                cctv_status=cctv_s,
                current_risk_score=risk_s,
                risk_level=risk_l,
                is_active=True,
                verification_status="VERIFIED_REGISTERED"
            )
            db.add(inst)
            db.flush()
        institutions[code] = inst

    # 5. BENEFICIARIES
    beneficiaries_data = [
        ("b1000001-0000-0000-0000-000000000001", "NGO-UP-LKO-2024-001", "SCH-DDRS-01", "XXXX-XXXX-4812", "Aarav Kumar", "MALE", date(2012, 5, 14), "HEARING_IMPAIRMENT", date(2023, 7, 10)),
        ("b1000001-0000-0000-0000-000000000002", "NGO-UP-LKO-2024-001", "SCH-DDRS-01", "XXXX-XXXX-9321", "Pooja Kumari", "FEMALE", date(2014, 9, 22), "LOCOMOTOR_DISABILITY", date(2023, 8, 1)),
    ]
    for b_id, i_code, s_code, a_mask, name, gender, dob, d_type, a_date in beneficiaries_data:
        b_uuid = uuid.UUID(b_id)
        ben = db.query(Beneficiary).filter(Beneficiary.id == b_uuid).first()
        if not ben:
            ben = Beneficiary(
                id=b_uuid,
                institution_id=institutions[i_code].id,
                scheme_id=schemes[s_code].id,
                identifier_masked=a_mask,
                full_name=name,
                gender=gender,
                date_of_birth=dob,
                disability_type=d_type,
                admission_date=a_date,
                is_active=True
            )
            db.add(ben)
            db.flush()

    # 6. MONITORING RECORDS
    if db.query(MonitoringRecord).count() == 0:
        for d_offset in range(3):
            rec_date = date.today() - timedelta(days=d_offset)
            mon = MonitoringRecord(
                id=uuid.uuid4(),
                institution_id=institutions["NGO-UP-LKO-2024-001"].id,
                record_date=rec_date,
                reported_beneficiaries_present=55 - d_offset,
                biometric_punch_count=54 - d_offset,
                staff_present_count=8,
                meals_served_count=110,
                cctv_uptime_percentage=99.2,
                geofence_status="MATCHED_GEOFENCE",
                telemetry_payload={"daily_variance": 0.02},
                is_synthetic=True
            )
            db.add(mon)
        db.flush()

    # 7. AI ANALYSES & ALERTS
    # AI 1
    ai1_id = uuid.UUID("e0000001-0000-0000-0000-000000000001")
    ai1 = db.query(AIAnalysis).filter(AIAnalysis.id == ai1_id).first()
    if not ai1:
        ai1 = AIAnalysis(
            id=ai1_id,
            institution_id=institutions["NGO-UP-LKO-2024-002"].id,
            risk_attention_score=72,
            severity_level="HIGH",
            statistical_divergence_score=0.764,
            potential_anomaly_flag=True,
            explainable_reason="Consecutive 14-day flatlined biometric attendance with zero natural variance, combined with 38% drop in reported meal logs.",
            recommended_action="Dispatch field inspector for unannounced on-site headcount.",
            requires_human_review=True,
            reviewed_by_user_id=users["admin@mosje.gov.in"].id,
            reviewed_at=datetime.utcnow() - timedelta(hours=4),
            review_notes="Reviewed telemetry divergence. Dispatched field inspection."
        )
        db.add(ai1)
        db.flush()

    alert1_id = uuid.UUID("f0000001-0000-0000-0000-000000000001")
    alert1 = db.query(AIAlert).filter(AIAlert.id == alert1_id).first()
    if not alert1:
        alert1 = AIAlert(
            id=alert1_id,
            ai_analysis_id=ai1.id,
            institution_id=institutions["NGO-UP-LKO-2024-002"].id,
            severity="HIGH",
            title="High Anomaly Alert: Attendance & Nutrition Discrepancy",
            alert_summary="Reported roster occupancy deviates from physical biometric log patterns by >30%.",
            suggested_inspection_scope="Physical roll-call headcount, review of pantry grocery receipts, biometric kiosk inspection.",
            is_acknowledged=True,
            acknowledged_by=users["admin@mosje.gov.in"].id,
            acknowledged_at=datetime.utcnow() - timedelta(hours=3)
        )
        db.add(alert1)
        db.flush()

    # AI 2
    ai2_id = uuid.UUID("e0000001-0000-0000-0000-000000000002")
    ai2 = db.query(AIAnalysis).filter(AIAnalysis.id == ai2_id).first()
    if not ai2:
        ai2 = AIAnalysis(
            id=ai2_id,
            institution_id=institutions["NGO-DL-SWD-2024-003"].id,
            risk_attention_score=85,
            severity_level="CRITICAL",
            statistical_divergence_score=0.882,
            potential_anomaly_flag=True,
            explainable_reason="Repeated high attendance pings outside registered geofence perimeter (average offset 1.8km), accompanied by CCTV heartbeat dropout.",
            recommended_action="Urgent physical inspection and GPS geofence re-audit advised.",
            requires_human_review=True,
            reviewed_by_user_id=users["admin@mosje.gov.in"].id,
            reviewed_at=datetime.utcnow() - timedelta(hours=4),
            review_notes="Urgent inspection ordered for IRCA / facility center."
        )
        db.add(ai2)
        db.flush()

    alert2_id = uuid.UUID("f0000001-0000-0000-0000-000000000002")
    alert2 = db.query(AIAlert).filter(AIAlert.id == alert2_id).first()
    if not alert2:
        alert2 = AIAlert(
            id=alert2_id,
            ai_analysis_id=ai2.id,
            institution_id=institutions["NGO-DL-SWD-2024-003"].id,
            severity="CRITICAL",
            title="Critical Anomaly Alert: Geofence Offset & Telemetry Gap",
            alert_summary="Facility telemetry reflects consistent coordinate mismatch and missing afternoon counselor session logs.",
            suggested_inspection_scope="Immediate physical audit of in-patient wards, attendance biometric machine location, and counselor staff rosters.",
            is_acknowledged=True,
            acknowledged_by=users["admin@mosje.gov.in"].id,
            acknowledged_at=datetime.utcnow() - timedelta(hours=3)
        )
        db.add(alert2)
        db.flush()

    # 8. INSPECTIONS & ASSIGNMENTS (Seed BOTH INSP-2026-UP-0001 and INSP-2026-GGM-002)
    # Inspection 1 (INSP-2026-UP-0001)
    insp1_id = uuid.UUID("10000001-0000-0000-0000-000000000001")
    insp1 = db.query(Inspection).filter(Inspection.id == insp1_id).first()
    if not insp1:
        insp1 = Inspection(
            id=insp1_id,
            inspection_code="INSP-2026-UP-0001",
            institution_id=institutions["NGO-UP-LKO-2024-002"].id,
            origin_ai_alert_id=alert1.id,
            priority="URGENT",
            status="ASSIGNED",
            mandated_date=date.today(),
            due_date=date.today() + timedelta(days=2),
            inspection_reason="Triggered by AI Anomaly #e0000001. Cross-verify physical presence against portal roster.",
            special_instructions="Verify geofenced coordinates before starting. Take GPS-tagged photos of all wards.",
            assigned_by_user_id=users["dswo.lucknow@up.gov.in"].id
        )
        db.add(insp1)
        db.flush()

    assign1_id = uuid.UUID("20000001-0000-0000-0000-000000000001")
    assign1 = db.query(InspectionAssignment).filter(InspectionAssignment.id == assign1_id).first()
    if not assign1:
        assign1 = InspectionAssignment(
            id=assign1_id,
            inspection_id=insp1.id,
            inspector_user_id=users["inspector.sharma@mosje.gov.in"].id,
            assigned_at=datetime.utcnow() - timedelta(hours=2),
            accepted_at=datetime.utcnow() - timedelta(hours=1),
            assigned_by_id=users["dswo.lucknow@up.gov.in"].id,
            notes="Please prioritize unannounced headcount before lunch."
        )
        db.add(assign1)
        db.flush()

    # Inspection 2 (INSP-2026-GGM-002)
    insp2_id = uuid.UUID("10000001-0000-0000-0000-000000000002")
    insp2 = db.query(Inspection).filter(Inspection.id == insp2_id).first()
    if not insp2:
        insp2 = Inspection(
            id=insp2_id,
            inspection_code="INSP-2026-GGM-002",
            institution_id=institutions["NGO-DL-SWD-2024-003"].id,
            origin_ai_alert_id=alert2.id,
            priority="URGENT",
            status="ASSIGNED",
            mandated_date=date.today(),
            due_date=date.today() + timedelta(days=2),
            inspection_reason="Surprise on-site inspection for geofence verification and patient bed verification.",
            special_instructions="Capture live geotagged images inside the center boundary. Minimum 3 photos.",
            assigned_by_user_id=users["admin@mosje.gov.in"].id
        )
        db.add(insp2)
        db.flush()

    assign2_id = uuid.UUID("20000001-0000-0000-0000-000000000002")
    assign2 = db.query(InspectionAssignment).filter(InspectionAssignment.id == assign2_id).first()
    if not assign2:
        assign2 = InspectionAssignment(
            id=assign2_id,
            inspection_id=insp2.id,
            inspector_user_id=users["inspector.sharma@mosje.gov.in"].id,
            assigned_at=datetime.utcnow() - timedelta(hours=2),
            accepted_at=datetime.utcnow() - timedelta(hours=1),
            assigned_by_id=users["admin@mosje.gov.in"].id,
            notes="Capture on-site live GPS coordinates and cross-reference with center boundaries."
        )
        db.add(assign2)
        db.flush()

    # 9. CHECKLIST TEMPLATE & ITEMS
    tmpl1_id = uuid.UUID("30000001-0000-0000-0000-000000000001")
    tmpl1 = db.query(ChecklistTemplate).filter(ChecklistTemplate.id == tmpl1_id).first()
    if not tmpl1:
        tmpl1 = ChecklistTemplate(
            id=tmpl1_id,
            name="Standard MoSJE Institutional Inspection Checklist v1",
            scheme_category="UNIVERSAL_INSTITUTIONAL",
            version=1,
            is_active=True
        )
        db.add(tmpl1)
        db.flush()

    items = [
        (uuid.UUID("40000001-0000-0000-0000-000000000001"), tmpl1.id, "Geofencing & Physical Verification", "Is inspector physically within verified perimeter of institution?", "BOOLEAN_PASS_FAIL", True, "Take GPS reading at main entrance gate.", 1),
        (uuid.UUID("40000001-0000-0000-0000-000000000002"), tmpl1.id, "Beneficiary Headcount", "Physical headcount matches active attendance register?", "BOOLEAN_PASS_FAIL", True, "Physical roll call in assembly hall.", 2),
        (uuid.UUID("40000001-0000-0000-0000-000000000003"), tmpl1.id, "Safety & Accessibility", "Divyangjan accessible ramps, tactile paths, and fire exits operational?", "BOOLEAN_PASS_FAIL", True, "Test ramp slope and fire extinguisher inspection tags.", 3),
        (uuid.UUID("40000001-0000-0000-0000-000000000004"), tmpl1.id, "Nutrition & Meal Log", "Kitchen hygiene and food stock meet prescribed nutritional standards?", "BOOLEAN_PASS_FAIL", True, "Inspect ration storage and meal register.", 4),
    ]
    for it_id, t_id, sec, quest, f_type, mand, notes, ord_idx in items:
        item_rec = db.query(ChecklistItem).filter(ChecklistItem.id == it_id).first()
        if not item_rec:
            db.add(ChecklistItem(
                id=it_id,
                template_id=t_id,
                section_name=sec,
                item_question=quest,
                field_type=f_type,
                is_mandatory=mand,
                guidance_notes=notes,
                order_index=ord_idx
            ))
    db.flush()

    # 10. NOTIFICATIONS
    notif1_id = uuid.UUID("80000001-0000-0000-0000-000000000001")
    notif1 = db.query(Notification).filter(Notification.id == notif1_id).first()
    if not notif1:
        notif1 = Notification(
            id=notif1_id,
            recipient_user_id=users["inspector.sharma@mosje.gov.in"].id,
            title="Urgent Inspection Assigned: Sanjeevani IRCA",
            message="You have been assigned unannounced inspection INSP-2026-UP-0001 for Sanjeevani IRCA Chinhat.",
            category="ASSIGNMENT",
            entity_reference_id=insp1.id,
            is_read=False
        )
        db.add(notif1)

    # 11. AUDIT
    audit1_id = uuid.UUID("90000001-0000-0000-0000-000000000001")
    audit1 = db.query(AuditActivity).filter(AuditActivity.id == audit1_id).first()
    if not audit1:
        audit1 = AuditActivity(
            id=audit1_id,
            actor_user_id=users["admin@mosje.gov.in"].id,
            action="INSPECTION_ASSIGNED",
            target_entity="inspections",
            entity_id=insp1.id,
            ip_address="10.0.0.1",
            user_agent="DRISHTI-Command-Console/1.0",
            details={"assigned_to": "Vikramaditya Sharma", "priority": "URGENT"}
        )
        db.add(audit1)

    db.commit()
    logger.info("Successfully completed database verification and idempotent demo synchronization.")
