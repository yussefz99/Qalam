"""Auth-gate tests (Plan 01 Task 1) — the client->server boundary.

T-14-01 (spoofing): no/invalid Firebase ID token -> 401 before the graph.
T-14-02 (replay):     valid ID token but missing/invalid App Check token -> 401.

These are model-free deterministic checks -> marked `code` (14-AI-SPEC §5 CI leg 1).
"""

from __future__ import annotations

import pytest

from tests.conftest import VALID_APP_CHECK_TOKEN, VALID_ID_TOKEN

pytestmark = pytest.mark.code


# A minimal valid enlarged body so a 401 cannot be confused with a 422 body-validation error.
SAMPLE_BODY = {
    "letterId": "baa",
    "section": "traceLetter",
    "passed": False,
    "mistakeId": "shallowBowl",
    "struggleTags": ["boat-curvature"],
    "recentMistakes": ["shallowBowl"],
    "trajectory": [{"passed": False, "mistakeId": "shallowBowl", "section": "traceLetter"}],
    "strengthTags": [],
}


async def test_no_authorization_header_is_401(client):
    resp = await client.post(
        "/coach",
        json=SAMPLE_BODY,
        headers={"X-Firebase-AppCheck": VALID_APP_CHECK_TOKEN},  # App Check present, ID token absent
    )
    assert resp.status_code == 401


async def test_malformed_authorization_header_is_401(client):
    resp = await client.post(
        "/coach",
        json=SAMPLE_BODY,
        headers={
            "Authorization": "Token something",  # not "Bearer ..."
            "X-Firebase-AppCheck": VALID_APP_CHECK_TOKEN,
        },
    )
    assert resp.status_code == 401


async def test_invalid_id_token_is_401(client):
    resp = await client.post(
        "/coach",
        json=SAMPLE_BODY,
        headers={
            "Authorization": "Bearer not-the-valid-token",
            "X-Firebase-AppCheck": VALID_APP_CHECK_TOKEN,
        },
    )
    assert resp.status_code == 401


async def test_valid_id_token_but_missing_app_check_is_401(client):
    resp = await client.post(
        "/coach",
        json=SAMPLE_BODY,
        headers={"Authorization": f"Bearer {VALID_ID_TOKEN}"},  # App Check header absent
    )
    assert resp.status_code == 401


async def test_valid_id_token_but_invalid_app_check_is_401(client):
    resp = await client.post(
        "/coach",
        json=SAMPLE_BODY,
        headers={
            "Authorization": f"Bearer {VALID_ID_TOKEN}",
            "X-Firebase-AppCheck": "not-the-valid-app-check-token",
        },
    )
    assert resp.status_code == 401


async def test_healthz_requires_no_auth(client):
    """The warm-up ping must answer 200 with no tokens (AI-SPEC §3 Cloud Run)."""
    resp = await client.get("/healthz")
    assert resp.status_code == 200
