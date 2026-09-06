import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Ensure test settings
os.environ["ENVIRONMENT"] = "testing"
os.environ["DEBUG"] = "true"

from backend.app.config import settings
from backend.app.database import Base, get_db
from backend.app.main import app
from backend.app.seed import seed_database_if_empty

# In-memory SQLite for isolated high-speed testing
TEST_DATABASE_URL = "sqlite:///:memory:"
test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    """Initializes schema and seeds baseline demo data in test database."""
    Base.metadata.create_all(bind=test_engine)
    with TestingSessionLocal() as session:
        seed_database_if_empty(session)
    yield
    Base.metadata.drop_all(bind=test_engine)

@pytest.fixture
def db_session():
    """Provides a transactional database session for a test."""
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()

@pytest.fixture
def client(db_session):
    """FastAPI TestClient with overridden database session."""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()

@pytest.fixture
def super_admin_headers(client):
    """Login as SUPER_ADMIN and return Authorization bearer headers."""
    resp = client.post("/api/v1/auth/demo-login", json={"role": "SUPER_ADMIN"})
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def inspector_headers(client):
    """Login as FIELD_INSPECTOR and return Authorization bearer headers."""
    resp = client.post("/api/v1/auth/demo-login", json={"role": "FIELD_INSPECTOR"})
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def district_officer_headers(client):
    """Login as DISTRICT_OFFICER and return Authorization bearer headers."""
    resp = client.post("/api/v1/auth/demo-login", json={"role": "DISTRICT_OFFICER"})
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
