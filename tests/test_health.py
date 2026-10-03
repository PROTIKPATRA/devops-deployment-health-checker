import os
import pytest
from app.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.get_json()["service"] == "deployment-health-checker"


def test_health_ok(client, monkeypatch):
    monkeypatch.setenv("HEALTHY", "true")
    import importlib
    import app.app as a
    importlib.reload(a)
    r = a.app.test_client().get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "healthy"


def test_health_fail(monkeypatch):
    monkeypatch.setenv("HEALTHY", "false")
    import importlib
    import app.app as a
    importlib.reload(a)
    r = a.app.test_client().get("/health")
    assert r.status_code == 503
    assert r.get_json()["status"] == "unhealthy"