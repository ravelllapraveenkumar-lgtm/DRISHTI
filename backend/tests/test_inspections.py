from datetime import date, timedelta

def test_list_inspections(client):
    response = client.get("/api/v1/inspections")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    assert len(data["items"]) >= 1
    insp = data["items"][0]
    assert "inspection_code" in insp
    assert "priority" in insp

def test_create_and_dispatch_inspection(client, district_officer_headers):
    # Fetch an institution
    inst_resp = client.get("/api/v1/institutions")
    inst_id = inst_resp.json()["items"][0]["id"]

    # Fetch inspector
    demo_users = client.get("/api/v1/auth/demo-users").json()
    inspector_id = next(u["id"] for u in demo_users if "FIELD_INSPECTOR" in u["roles"])

    today = str(date.today())
    due = str(date.today() + timedelta(days=2))

    payload = {
        "institution_id": inst_id,
        "priority": "URGENT",
        "mandated_date": today,
        "due_date": due,
        "inspection_reason": "Unannounced verification following statistical divergence in attendance logs.",
        "special_instructions": "Check biometric logs at main entrance gate.",
        "inspector_user_id": inspector_id
    }
    response = client.post("/api/v1/inspections", json=payload, headers=district_officer_headers)
    assert response.status_code == 201
    created = response.json()
    assert created["status"] == "ASSIGNED"
    assert created["assigned_inspector_id"] == inspector_id
    assert created["inspection_code"].startswith("INSP-")

def test_update_inspection_status_validation_422(client, district_officer_headers):
    insp_list = client.get("/api/v1/inspections").json()
    insp_id = insp_list["items"][0]["id"]

    response = client.patch(
        f"/api/v1/inspections/{insp_id}/status",
        json={"status": "INVALID_STATE_XYZ"},
        headers=district_officer_headers
    )
    assert response.status_code == 422
    data = response.json()
    assert "Invalid status" in data["message"]
