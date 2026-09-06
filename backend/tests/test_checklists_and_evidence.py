import hashlib
from datetime import datetime

def test_get_checklist_templates(client):
    response = client.get("/api/v1/inspection-checklists/templates")
    assert response.status_code == 200
    templates = response.json()
    assert len(templates) >= 1
    assert len(templates[0]["items"]) >= 4

def test_submit_checklist_batch(client, inspector_headers):
    # Fetch an inspection
    inspections = client.get("/api/v1/inspections").json()
    insp_id = inspections["items"][0]["id"]

    # Fetch checklist items
    templates = client.get("/api/v1/inspection-checklists/templates").json()
    item_id = templates[0]["items"][0]["id"]

    payload = {
        "inspection_id": insp_id,
        "items": [
            {
                "checklist_item_id": item_id,
                "response_boolean": True,
                "response_value": "Coordinates verified with on-site GPS reading.",
                "inspector_comment": "Entrance gate clear and accessible.",
                "gps_latitude": 26.8856,
                "gps_longitude": 80.9462
            }
        ]
    }
    response = client.post("/api/v1/inspection-checklists", json=payload, headers=inspector_headers)
    assert response.status_code == 201
    results = response.json()
    assert len(results) == 1
    assert results[0]["response_boolean"] is True

def test_upload_geotagged_evidence(client, inspector_headers):
    # Fetch an inspection
    inspections = client.get("/api/v1/inspections").json()
    insp_id = inspections["items"][0]["id"]

    fake_file_content = b"SIMULATED_TAMPER_PROOF_GEOTAGGED_INSPECTION_PHOTO_DATA"
    sha256_hash = hashlib.sha256(fake_file_content).hexdigest()

    payload = {
        "inspection_id": insp_id,
        "evidence_type": "GEO_TAGGED_PHOTO",
        "file_name": "entrance_geofence_verification.jpg",
        "file_path_or_url": "https://storage.drishti.gov.in/evidence/insp-001-photo.jpg",
        "sha256_checksum": sha256_hash,
        "description": "Inspector entrance geotagged timestamped photo.",
        "timestamp_captured": datetime.utcnow().isoformat(),
        "gps_latitude": 26.8856,
        "gps_longitude": 80.9462,
        "gps_accuracy_meters": 4.5
    }
    response = client.post("/api/v1/evidence", json=payload, headers=inspector_headers)
    assert response.status_code == 201
    evidence = response.json()
    assert evidence["sha256_checksum"] == sha256_hash
    assert evidence["sync_status"] == "SYNCED_SUCCESS"
    assert "geofence_verified" in evidence
