def test_dashboard_summary(client):
    response = client.get("/api/v1/dashboard/summary")
    assert response.status_code == 200
    data = response.json()
    assert data["total_institutions"] >= 3
    assert data["total_beneficiaries"] >= 2
    assert "risk_distribution" in data
    assert len(data["schemes"]) >= 4

def test_ai_alerts_and_acknowledgement(client, super_admin_headers):
    # Fetch alerts
    alerts_resp = client.get("/api/v1/ai-alerts")
    assert alerts_resp.status_code == 200
    alerts = alerts_resp.json()
    assert len(alerts["items"]) >= 1

    alert_id = alerts["items"][0]["id"]

    # Acknowledge and dispatch inspection
    ack_payload = {
        "action_note": "Immediate investigation team dispatched to cross-check biometric kiosk logs.",
        "create_inspection": True,
        "priority": "URGENT"
    }
    ack_resp = client.post(f"/api/v1/ai-alerts/{alert_id}/acknowledge", json=ack_payload, headers=super_admin_headers)
    assert ack_resp.status_code == 200
    acknowledged = ack_resp.json()
    assert acknowledged["is_acknowledged"] is True

def test_audit_activity_trail(client, super_admin_headers):
    response = client.get("/api/v1/audit-activity", headers=super_admin_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert len(data["items"]) >= 1
    first = data["items"][0]
    assert "action" in first
    assert "target_entity" in first

def test_ai_alert_idempotency_no_duplicate_open_alerts(client, super_admin_headers):
    # 1. Fetch an institution
    insts_resp = client.get("/api/v1/institutions")
    assert insts_resp.status_code == 200
    inst_id = insts_resp.json()["items"][0]["id"]

    # 2. Ingest initial HIGH AI analysis
    payload_1 = {
        "institution_id": inst_id,
        "algorithm_used": "ISOLATION_FOREST_V1",
        "dataset_window_days": 30,
        "risk_attention_score": 65,
        "severity_level": "HIGH",
        "statistical_divergence_score": 2.5,
        "potential_anomaly_flag": True,
        "explainable_reason": "Biometric verification discrepancy detected.",
        "recommended_action": "Conduct spot check on biometric terminals.",
        "requires_human_review": True
    }
    res_1 = client.post("/api/v1/ai-analyses", json=payload_1, headers=super_admin_headers)
    assert res_1.status_code == 201
    analysis_1_id = res_1.json()["id"]

    # Check OPEN alerts count for this institution
    alerts_1 = client.get(f"/api/v1/ai-alerts?institution_id={inst_id}&is_acknowledged=false").json()
    open_alerts_count_1 = alerts_1["total"]
    assert open_alerts_count_1 >= 1
    alert_1 = alerts_1["items"][0]
    initial_alert_id = alert_1["id"]
    assert alert_1["ai_analysis_id"] == analysis_1_id

    # 3. Ingest second CRITICAL AI analysis for SAME institution while alert is still OPEN
    payload_2 = {
        "institution_id": inst_id,
        "algorithm_used": "ISOLATION_FOREST_V1",
        "dataset_window_days": 30,
        "risk_attention_score": 88,
        "severity_level": "CRITICAL",
        "statistical_divergence_score": 4.8,
        "potential_anomaly_flag": True,
        "explainable_reason": "Escalated: Biometric flatline and CCTV offline simultaneously.",
        "recommended_action": "Prioritize physical inspection immediately.",
        "requires_human_review": True
    }
    res_2 = client.post("/api/v1/ai-analyses", json=payload_2, headers=super_admin_headers)
    assert res_2.status_code == 201
    analysis_2_id = res_2.json()["id"]

    # Check OPEN alerts count: Must STILL be equal to open_alerts_count_1 (NO duplicate created)
    alerts_2 = client.get(f"/api/v1/ai-alerts?institution_id={inst_id}&is_acknowledged=false").json()
    assert alerts_2["total"] == open_alerts_count_1
    updated_alert = alerts_2["items"][0]
    # Alert ID preserved, but updated with new analysis info and CRITICAL severity
    assert updated_alert["id"] == initial_alert_id
    assert updated_alert["ai_analysis_id"] == analysis_2_id
    assert updated_alert["severity"] == "CRITICAL"
    assert "Escalated" in updated_alert["alert_summary"]

    # 4. Acknowledge existing alert
    ack_resp = client.post(
        f"/api/v1/ai-alerts/{initial_alert_id}/acknowledge",
        json={"action_note": "Reviewed by official"},
        headers=super_admin_headers
    )
    assert ack_resp.status_code == 200

    # 5. Ingest third CRITICAL AI analysis after acknowledgement
    res_3 = client.post("/api/v1/ai-analyses", json=payload_2, headers=super_admin_headers)
    assert res_3.status_code == 201

    # Verify a new OPEN alert is now spawned because previous one was acknowledged
    alerts_3 = client.get(f"/api/v1/ai-alerts?institution_id={inst_id}&is_acknowledged=false").json()
    assert alerts_3["total"] == 1
    new_alert = alerts_3["items"][0]
    assert new_alert["id"] != initial_alert_id

