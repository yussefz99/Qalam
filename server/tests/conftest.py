"""Shared pytest fixtures (Plan 01).

The tests never hit live Firebase or a live model:

  * `firebase_admin.auth.verify_id_token` / `app_check.verify_token` are monkeypatched
    so token verification is deterministic and offline.
  * The coach model is monkeypatched in the endpoint tests so /coach runs with no network.

A pytest-asyncio httpx ASGI client drives the FastAPI app in-process.
"""

from __future__ import annotations

import os

import pytest

# Make sure module import never tries to reach a real GCP project / ADC.
os.environ.setdefault("GCP_PROJECT_ID", "qalam-app-bd7d0")


# A sentinel valid token pair the fake verifiers accept; anything else is rejected.
VALID_ID_TOKEN = "valid-id-token"
VALID_APP_CHECK_TOKEN = "valid-app-check-token"

VALID_AUTH_HEADERS = {
    "Authorization": f"Bearer {VALID_ID_TOKEN}",
    "X-Firebase-AppCheck": VALID_APP_CHECK_TOKEN,
}


@pytest.fixture(autouse=True)
def fake_firebase(monkeypatch):
    """Monkeypatch firebase-admin verification so tests run offline + deterministically.

    A request is "authenticated" only when it carries BOTH the sentinel valid ID token
    AND the sentinel valid App Check token. Any other value raises (mimicking a real
    invalid-token rejection), which the auth layer maps to 401.
    """
    from firebase_admin import app_check as fb_app_check
    from firebase_admin import auth as fb_auth

    def fake_verify_id_token(token, *args, **kwargs):
        if token != VALID_ID_TOKEN:
            raise ValueError("invalid id token")
        return {"uid": "test-child-uid", "aud": "qalam-app-bd7d0"}

    def fake_verify_app_check(token, *args, **kwargs):
        if token != VALID_APP_CHECK_TOKEN:
            raise ValueError("invalid app check token")
        return {"app_id": "1:android:qalam", "aud": ["projects/qalam-app-bd7d0"]}

    monkeypatch.setattr(fb_auth, "verify_id_token", fake_verify_id_token)
    monkeypatch.setattr(fb_app_check, "verify_token", fake_verify_app_check)
    yield


@pytest.fixture
async def client():
    """An httpx ASGI client bound to the real FastAPI app (in-process, no socket)."""
    import httpx

    from app.main import app

    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as ac:
        yield ac
