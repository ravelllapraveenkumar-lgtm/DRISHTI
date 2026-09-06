import uuid
from datetime import date

def test_monitoring_records_flow(client, super_admin_headers):
    # Fetch an institution
    insts = client.get("/api/v1/institutions").json()
    inst_id = insts["items"][0]["id"]

    rec_date = str(date.today())
    payload = {
        "institution_id": inst_id,
        "record_date": rec_date,
        "reported_beneficiaries_present": 48,
        "biometric_punch_count": 47,
        "staff_present_count": 6,
        "meals_served_count": 94,
        "cctv_uptime_percentage": 98.5,
        "geofence_status": "MATCHED_GEOFENCE",
        "telemetry_payload": {"ambient_temp": 24.5}
    }
    response = client.post("/api/v1/monitoring", json=payload, headers=super_admin_headers)
    assert response.status_code == 201
    created = response.json()
    assert created["reported_beneficiaries_present"] == 48

    # Query institution history
    hist = client.get(f"/api/v1/monitoring/institution/{inst_id}")
    assert hist.status_code == 200
    assert len(hist.json()) >= 1

def test_attendance_and_summary_flow(client, super_admin_headers):
    # Fetch beneficiary and institution
    bens = client.get("/api/v1/beneficiaries").json()
    ben = bens["items"][0]
    inst_id = ben["institution_id"]
    ben_id = ben["id"]

    today = str(date.today())
    att_payload = {
        "institution_id": inst_id,
        "beneficiary_id": ben_id,
        "attendance_date": today,
        "status": "PRESENT",
        "verification_mode": "BIOMETRIC_OR_SMART_PORTAL"
    }
    response = client.post("/api/v1/attendance", json=att_payload, headers=super_admin_headers)
    assert response.status_code == 201
    assert response.json()["status"] == "PRESENT"

    # Summary
    summary_resp = client.get(f"/api/v1/attendance/summary?institution_id={inst_id}&attendance_date={today}")
    assert summary_resp.status_code == 200
    summary = summary_resp.json()
    assert summary["present_count"] >= 1
    assert summary["attendance_percentage"] > 0
