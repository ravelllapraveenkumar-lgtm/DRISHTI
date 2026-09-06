import hashlib
import datetime
import uuid

def test_full_system_integration_lifecycle(client, inspector_headers, district_officer_headers, super_admin_headers):
    """
    DRISHTI Phase 6 Full System Integration Lifecycle Test
    1. Authenticate as Field Inspector
    2. Retrieve assignment
    3. Open inspection
    4. Submit checklist
    5. Submit evidence metadata
    6. Submit report
    7. Verify persistence
    8. Verify dashboard can retrieve updated inspection/report state
    9. Trigger/analyze supported AI data
    10. Verify AI analysis
    11. Verify High/Critical alert behavior
    12. Verify human-review status
    """
    # -------------------------------------------------------------
    # Step 1: Authenticate as Field Inspector
    # -------------------------------------------------------------
    auth_resp = client.post("/api/v1/auth/demo-login", json={"role": "FIELD_INSPECTOR"})
    assert auth_resp.status_code == 200
    auth_data = auth_resp.json()
    assert "access_token" in auth_data
    assert "FIELD_INSPECTOR" in auth_data["roles"]

    # Retrieve inspector user id from demo-users
    demo_users = client.get("/api/v1/auth/demo-users").json()
    inspector_id = next(u["id"] for u in demo_users if "FIELD_INSPECTOR" in u["roles"])

    # -------------------------------------------------------------
    # Step 2: Retrieve assigned inspections
    # -------------------------------------------------------------
    # Ensure there is an assigned inspection for this inspector
    insts_resp = client.get("/api/v1/institutions")
    assert insts_resp.status_code == 200
    inst_id = insts_resp.json()["items"][0]["id"]

    today = str(datetime.date.today())
    due = str(datetime.date.today() + datetime.timedelta(days=3))
    create_insp_payload = {
        "institution_id": inst_id,
        "priority": "URGENT",
        "mandated_date": today,
        "due_date": due,
        "inspection_reason": "Automated Phase 6 System Integration Flow",
        "special_instructions": "Verify all biometric kiosks and ration storage facilities.",
        "inspector_user_id": inspector_id
    }
    insp_create_resp = client.post("/api/v1/inspections", json=create_insp_payload, headers=district_officer_headers)
    assert insp_create_resp.status_code == 201
    server_inspection_uuid = insp_create_resp.json()["id"]

    # Retrieve assignments
    assignments_resp = client.get("/api/v1/inspection-assignments")
    assert assignments_resp.status_code == 200
    assignments = assignments_resp.json()
    assert any(a["inspection_id"] == server_inspection_uuid for a in assignments)

    # -------------------------------------------------------------
    # Step 3: Open inspection and acknowledge arrival
    # -------------------------------------------------------------
    insp_detail_resp = client.get(f"/api/v1/inspections/{server_inspection_uuid}")
    assert insp_detail_resp.status_code == 200
    assert insp_detail_resp.json()["id"] == server_inspection_uuid

    # Transition inspection status to IN_PROGRESS
    status_update_resp = client.patch(
        f"/api/v1/inspections/{server_inspection_uuid}/status",
        json={"status": "IN_PROGRESS"},
        headers=district_officer_headers
    )
    assert status_update_resp.status_code == 200
    assert status_update_resp.json()["status"] == "IN_PROGRESS"

    # -------------------------------------------------------------
    # Step 4: Submit checklist batch
    # -------------------------------------------------------------
    templates_resp = client.get("/api/v1/inspection-checklists/templates")
    assert templates_resp.status_code == 200
    templates = templates_resp.json()
    assert len(templates) >= 1
    chk_item_id = templates[0]["items"][0]["id"]

    checklist_payload = {
        "inspection_id": server_inspection_uuid,
        "items": [
            {
                "checklist_item_id": chk_item_id,
                "response_boolean": True,
                "response_value": "Perimeter physical security fencing verified intact.",
                "inspector_comment": "Clear unobstructed view across all perimeters.",
                "gps_latitude": 26.8467,
                "gps_longitude": 80.9462
            }
        ]
    }
    chk_resp = client.post("/api/v1/inspection-checklists", json=checklist_payload, headers=inspector_headers)
    assert chk_resp.status_code == 201
    submitted_chk = chk_resp.json()
    assert len(submitted_chk) == 1
    assert submitted_chk[0]["inspection_id"] == server_inspection_uuid

    # -------------------------------------------------------------
    # Step 5: Submit evidence metadata
    # -------------------------------------------------------------
    evidence_content = b"DRISHTI_INTEGRATION_TEST_EVIDENCE_PHOTO"
    sha256_hash = hashlib.sha256(evidence_content).hexdigest()

    evidence_payload = {
        "inspection_id": server_inspection_uuid,
        "evidence_type": "GEO_TAGGED_PHOTO",
        "file_name": "gate_entrance_verification.jpg",
        "file_path_or_url": "local:///storage/emulated/0/gate_entrance_verification.jpg",
        "sha256_checksum": sha256_hash,
        "description": "Geotagged entrance photo with on-site GPS verification.",
        "timestamp_captured": datetime.datetime.utcnow().isoformat(),
        "gps_latitude": 26.8467,
        "gps_longitude": 80.9462,
        "gps_accuracy_meters": 3.8
    }
    ev_resp = client.post("/api/v1/evidence", json=evidence_payload, headers=inspector_headers)
    assert ev_resp.status_code == 201
    created_evidence = ev_resp.json()
    assert created_evidence["inspection_id"] == server_inspection_uuid
    assert created_evidence["sha256_checksum"] == sha256_hash

    # -------------------------------------------------------------
    # Step 6: Submit report
    # -------------------------------------------------------------
    report_payload = {
        "inspection_id": server_inspection_uuid,
        "physical_beneficiary_count": 58,
        "roster_discrepancy_count": 0,
        "cleanliness_score": 9,
        "food_nutrition_score": 9,
        "infrastructure_condition_score": 9,
        "inspector_summary": "Facility operating in full compliance with MoSJE quality guidelines.",
        "overall_verdict": "COMPLIANT"
    }
    rep_resp = client.post("/api/v1/inspection-reports", json=report_payload, headers=inspector_headers)
    assert rep_resp.status_code == 201
    created_report = rep_resp.json()
    assert created_report["inspection_id"] == server_inspection_uuid
    assert created_report["overall_verdict"] == "COMPLIANT"
    assert created_report["official_review_status"] == "PENDING_OFFICIAL_REVIEW"

    # -------------------------------------------------------------
    # Step 7: Verify persistence
    # -------------------------------------------------------------
    db_insp = client.get(f"/api/v1/inspections/{server_inspection_uuid}").json()
    assert db_insp["id"] == server_inspection_uuid

    db_ev = client.get(f"/api/v1/evidence?inspection_id={server_inspection_uuid}").json()
    assert db_ev["total"] >= 1
    assert any(e["sha256_checksum"] == sha256_hash for e in db_ev["items"])

    # -------------------------------------------------------------
    # Step 8: Verify dashboard can retrieve updated state
    # -------------------------------------------------------------
    dash_resp = client.get("/api/v1/dashboard/summary")
    assert dash_resp.status_code == 200
    dash_data = dash_resp.json()
    assert dash_data["total_institutions"] >= 1
    assert "risk_distribution" in dash_data

    # -------------------------------------------------------------
    # Step 9 & 10: Trigger/analyze supported AI data & verify AI analysis
    # -------------------------------------------------------------
    ai_payload = {
        "institution_id": inst_id,
        "algorithm_used": "ISOLATION_FOREST_V1",
        "dataset_window_days": 30,
        "risk_attention_score": 85,
        "severity_level": "CRITICAL",
        "statistical_divergence_score": 4.12,
        "potential_anomaly_flag": True,
        "explainable_reason": "Sustained flatline in biometric punch timestamps over 21 days indicates synthetic log entry.",
        "recommended_action": "Mandate immediate unannounced on-site headcount inspection.",
        "requires_human_review": True
    }
    ai_resp = client.post("/api/v1/ai-analyses", json=ai_payload, headers=super_admin_headers)
    assert ai_resp.status_code == 201
    ai_data = ai_resp.json()
    assert ai_data["risk_attention_score"] == 85
    assert ai_data["severity_level"] == "CRITICAL"
    assert ai_data["potential_anomaly_flag"] is True
    assert ai_data["requires_human_review"] is True

    # -------------------------------------------------------------
    # Step 11: Verify High/Critical alert behavior
    # -------------------------------------------------------------
    alerts_resp = client.get(f"/api/v1/ai-alerts?institution_id={inst_id}&severity=CRITICAL")
    assert alerts_resp.status_code == 200
    alerts_data = alerts_resp.json()
    assert alerts_data["total"] >= 1
    alert_item = alerts_data["items"][0]
    assert alert_item["severity"] == "CRITICAL"
    assert alert_item["is_acknowledged"] is False

    # -------------------------------------------------------------
    # Step 12: Verify human-review status requirement
    # -------------------------------------------------------------
    assert ai_data["requires_human_review"] is True
    assert alert_item["is_acknowledged"] is False

    # Perform official human review / acknowledgement
    ack_resp = client.post(
        f"/api/v1/ai-alerts/{alert_item['id']}/acknowledge",
        json={
            "action_note": "Senior MoSJE Officer reviewed statistical divergence. Inspection team dispatched.",
            "create_inspection": False
        },
        headers=super_admin_headers
    )
    assert ack_resp.status_code == 200
    assert ack_resp.json()["is_acknowledged"] is True
