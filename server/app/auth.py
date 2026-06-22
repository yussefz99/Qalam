"""Caller verification — the secure client->server boundary (Plan 01 Task 1).

The Flutter child device is untrusted; before the graph runs, every POST /coach request
must present BOTH:

  1. A valid Firebase ID token  (`Authorization: Bearer <idToken>`)        -> TUTOR-03, T-14-01
  2. A valid App Check token     (`X-Firebase-AppCheck: <appCheckToken>`)  -> T-14-02 (replay protection)

Either failure raises HTTP 401 so the request never reaches the graph.

This module reads NO provider API keys. Provider keys (ANTHROPIC_API_KEY / GOOGLE_API_KEY)
are env-only and consumed exclusively by the models (Plan 02). `firebase_admin` is initialized
once at import using Application Default Credentials (the Cloud Run runtime service account)
for project qalam-app-bd7d0 — locally, ADC comes from `gcloud auth application-default login`.
"""

from __future__ import annotations

import logging
import os

import firebase_admin
from fastapi import HTTPException, Request, status

logger = logging.getLogger("qalam.tutor.auth")

# The GCP/Firebase project the tokens are minted for and verified against.
_PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "qalam-app-bd7d0")

# App Check token header the Flutter client sets (mirrors the Firebase convention).
APP_CHECK_HEADER = "X-Firebase-AppCheck"


def _ensure_firebase_initialized() -> None:
    """Initialize the default firebase_admin app exactly once.

    Uses Application Default Credentials — on Cloud Run that is the runtime service
    account; locally it is `gcloud auth application-default login`. We pass the explicit
    projectId so App Check / ID-token audience checks resolve to qalam-app-bd7d0 even
    when ADC does not carry a default project.
    """
    if not firebase_admin._apps:  # noqa: SLF001 — documented public-enough sentinel
        try:
            firebase_admin.initialize_app(options={"projectId": _PROJECT_ID})
        except ValueError:
            # Concurrent import / double-init race: another caller won. Safe to ignore.
            logger.debug("firebase_admin already initialized; continuing.")


# Initialize at import so the first request does not pay the cold-init cost mid-handler.
_ensure_firebase_initialized()


def _verify_id_token(authorization: str | None) -> dict:
    """Verify the Firebase ID token from the Authorization header. 401 on any failure."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization: Bearer <Firebase ID token>.",
        )
    id_token = authorization[len("bearer ") :].strip()
    if not id_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empty Firebase ID token.",
        )
    # Imported lazily so tests can monkeypatch firebase_admin.auth.verify_id_token cheaply
    # and so import of this module never requires live Firebase credentials.
    from firebase_admin import auth as fb_auth

    try:
        return fb_auth.verify_id_token(id_token)
    except Exception as exc:  # firebase raises several token-error subclasses; treat all as 401
        logger.info("Firebase ID token verification failed: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase ID token.",
        ) from exc


def _verify_app_check_token(app_check_token: str | None) -> dict:
    """Verify the App Check limited-use token (replay protection). 401 on any failure."""
    if not app_check_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Missing {APP_CHECK_HEADER} App Check token.",
        )
    from firebase_admin import app_check as fb_app_check

    try:
        # options.consume requests a limited-use (single-use) verification for replay
        # protection when the client mints limited-use tokens (App Check). When the SDK
        # version does not accept the kwarg we fall back to a plain verify.
        try:
            return fb_app_check.verify_token(app_check_token, options={"consume": True})
        except TypeError:
            return fb_app_check.verify_token(app_check_token)
    except HTTPException:
        raise
    except Exception as exc:
        logger.info("App Check token verification failed: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid App Check token.",
        ) from exc


async def verify_caller(request: Request) -> dict:
    """FastAPI dependency: gate POST /coach on BOTH the ID token and the App Check token.

    Returns the decoded ID-token claims (a non-PII dict of uid + standard claims) for any
    downstream use. Raises HTTP 401 before the graph runs if either token is absent/invalid.
    """
    claims = _verify_id_token(request.headers.get("Authorization"))
    _verify_app_check_token(request.headers.get(APP_CHECK_HEADER))
    return claims
