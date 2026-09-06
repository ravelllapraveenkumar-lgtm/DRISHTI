import os
import pytest
from backend.app.config import Settings
from backend.app.main import app
from fastapi.testclient import TestClient

def test_cors_origins_default(monkeypatch):
    monkeypatch.delenv("CORS_ORIGINS", raising=False)
    monkeypatch.delenv("BACKEND_CORS_ORIGINS", raising=False)
    s = Settings()
    assert isinstance(s.CORS_ORIGINS, list)
    assert "*" in s.CORS_ORIGINS or "http://localhost:3000" in s.CORS_ORIGINS

def test_cors_origins_star_string(monkeypatch):
    """Test the exact Render scenario where CORS_ORIGINS is set to '*'."""
    monkeypatch.setenv("CORS_ORIGINS", "*")
    s = Settings()
    assert s.CORS_ORIGINS == ["*"]

def test_cors_origins_single_url(monkeypatch):
    """Test setting a single production dashboard URL."""
    url = "https://drishti-dashboard.onrender.com"
    monkeypatch.setenv("CORS_ORIGINS", url)
    s = Settings()
    assert s.CORS_ORIGINS == [url]

def test_cors_origins_comma_separated(monkeypatch):
    """Test setting multiple comma-separated URLs."""
    raw = "https://drishti-dashboard.onrender.com, http://localhost:5173, http://localhost:3000"
    monkeypatch.setenv("CORS_ORIGINS", raw)
    s = Settings()
    assert s.CORS_ORIGINS == [
        "https://drishti-dashboard.onrender.com",
        "http://localhost:5173",
        "http://localhost:3000"
    ]

def test_cors_origins_json_array_string(monkeypatch):
    """Test setting a JSON-encoded array string."""
    raw = '["https://drishti-dashboard.onrender.com", "http://localhost:5173"]'
    monkeypatch.setenv("CORS_ORIGINS", raw)
    s = Settings()
    assert s.CORS_ORIGINS == [
        "https://drishti-dashboard.onrender.com",
        "http://localhost:5173"
    ]

def test_app_health_with_star_cors(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
