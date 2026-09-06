def test_list_assignments(client):
    response = client.get("/api/v1/inspection-assignments")
    assert response.status_code == 200
    assignments = response.json()
    assert len(assignments) >= 1
    first = assignments[0]
    assert "inspector_name" in first
    assert "inspection_code" in first

def test_accept_and_arrive_workflow(client, inspector_headers):
    # Fetch first assignment
    assignments = client.get("/api/v1/inspection-assignments").json()
    assign_id = assignments[0]["id"]

    # 1. Accept
    accept_resp = client.patch(f"/api/v1/inspection-assignments/{assign_id}/accept", headers=inspector_headers)
    assert accept_resp.status_code == 200
    assert accept_resp.json()["accepted_at"] is not None

    # 2. Mark arrival
    arrive_resp = client.patch(f"/api/v1/inspection-assignments/{assign_id}/arrive", headers=inspector_headers)
    assert arrive_resp.status_code == 200
    assert arrive_resp.json()["arrived_at"] is not None
