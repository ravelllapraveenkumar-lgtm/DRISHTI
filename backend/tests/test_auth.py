def test_get_demo_users(client):
    response = client.get("/api/v1/auth/demo-users")
    assert response.status_code == 200
    users = response.json()
    assert len(users) >= 5
    roles = [u["roles"][0] for u in users]
    assert "SUPER_ADMIN" in roles
    assert "FIELD_INSPECTOR" in roles

def test_demo_login_success(client):
    response = client.post("/api/v1/auth/demo-login", json={"role": "FIELD_INSPECTOR"})
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert "FIELD_INSPECTOR" in data["roles"]

def test_regular_login_invalid_credentials(client):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "nonexistent@mosje.gov.in", "password": "wrongpassword"}
    )
    assert response.status_code == 401
    assert "Incorrect email or password" in response.json()["message"]

def test_get_current_user_profile(client, super_admin_headers):
    response = client.get("/api/v1/auth/me", headers=super_admin_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "admin@mosje.gov.in"
    assert "SUPER_ADMIN" in data["roles"]

def test_get_profile_unauthorized(client):
    response = client.get("/api/v1/auth/me", headers={"Authorization": "Bearer invalid_token_xyz"})
    assert response.status_code == 401

def test_rbac_forbidden_access(client, inspector_headers):
    # FIELD_INSPECTOR attempting SUPER_ADMIN/MINISTRY_OFFICIAL restricted route
    payload = {
        "institution_id": "00000000-0000-0000-0000-000000000000",
        "algorithm_used": "ISOLATION_FOREST_V1",
        "dataset_window_days": 30,
        "risk_attention_score": 50,
        "severity_level": "HIGH",
        "statistical_divergence_score": 2.0,
        "potential_anomaly_flag": True,
        "explainable_reason": "Test",
        "recommended_action": "Test",
        "requires_human_review": True
    }
    response = client.post("/api/v1/ai-analyses", json=payload, headers=inspector_headers)
    assert response.status_code == 403
    assert "Access denied" in response.json()["message"]

