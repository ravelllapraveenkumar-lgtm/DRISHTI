import uuid

def test_list_institutions(client):
    response = client.get("/api/v1/institutions")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 3
    assert len(data["items"]) >= 3
    first = data["items"][0]
    assert "registration_code" in first
    assert "current_risk_score" in first

def test_get_institution_detail(client):
    # Fetch first institution
    list_resp = client.get("/api/v1/institutions")
    inst_id = list_resp.json()["items"][0]["id"]

    response = client.get(f"/api/v1/institutions/{inst_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == inst_id
    assert "total_beneficiaries_count" in data
    assert "active_inspections_count" in data

def test_create_institution_success(client, super_admin_headers):
    # Fetch a scheme id
    schemes = client.get("/api/v1/schemes").json()
    scheme_id = schemes[0]["id"]

    payload = {
        "registration_code": f"TEST-INST-{uuid.uuid4().hex[:6]}",
        "name": "Divyangjan Upliftment Centre",
        "institution_type": "NGO_AIDED",
        "primary_scheme_id": scheme_id,
        "state": "Uttar Pradesh",
        "district": "Varanasi",
        "sub_division": "Sadar",
        "address": "B-12, Lanka Road, Varanasi",
        "pincode": "221005",
        "latitude": 25.3176,
        "longitude": 82.9739,
        "geofence_radius_meters": 150,
        "contact_person_name": "Ramesh Chandra",
        "contact_phone": "+919876543299",
        "contact_email": "ramesh.varanasi@ngo.org",
        "registered_capacity": 60
    }
    response = client.post("/api/v1/institutions", json=payload, headers=super_admin_headers)
    assert response.status_code == 201
    created = response.json()
    assert created["registration_code"] == payload["registration_code"]
    assert created["risk_level"] == "LOW"

def test_create_institution_validation_error_422(client, super_admin_headers):
    # Invalid latitude > 90 and invalid email format
    payload = {
        "registration_code": "TEST-BAD",
        "name": "Bad Inst",
        "institution_type": "NGO_AIDED",
        "primary_scheme_id": str(uuid.uuid4()),
        "state": "UP",
        "district": "Lucknow",
        "address": "Too short",
        "pincode": "123456",
        "latitude": 125.0,  # Invalid
        "longitude": 80.0,
        "geofence_radius_meters": 100,
        "contact_person_name": "Test",
        "contact_phone": "123456",
        "contact_email": "not-an-email",  # Invalid
        "registered_capacity": 50
    }
    response = client.post("/api/v1/institutions", json=payload, headers=super_admin_headers)
    assert response.status_code == 422
    err = response.json()
    assert err["error_code"] == "UNPROCESSABLE_ENTITY"
    assert len(err["details"]) >= 1
