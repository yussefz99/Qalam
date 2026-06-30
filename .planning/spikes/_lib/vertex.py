"""Vertex client for the spike (THROWAWAY) — keyless, but via INJECTED USER CREDS not ADC.

Production reaches Gemini-on-Vertex with the Cloud Run runtime SA's ADC. This local spike has no
ADC, so it mints the owner's already-logged-in user token (`gcloud auth print-access-token`) and
injects it as the credential. Same project, same keyless posture (no provider API key anywhere) —
only the credential SOURCE differs, and only for the throwaway harness. Tokens expire ~1h; re-mint
per run. Production auth is UNCHANGED.

`thinking_budget=0` mirrors app/models._provider_kwargs — without it Gemini 2.5 spends the token
budget on hidden thinking and returns empty content (observed on the auth probe).
"""
from __future__ import annotations

import functools
import os
import subprocess

PROJECT = os.environ.get("GCP_PROJECT_ID", "qalam-app-bd7d0")
GEMINI_LOCATION = "us-central1"


@functools.lru_cache(maxsize=1)
def _creds():
    import google.oauth2.credentials

    token = subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()
    return google.oauth2.credentials.Credentials(token=token)


def build_gemini(model: str = "gemini-2.5-flash", *, temperature: float = 0.5,
                 max_tokens: int = 256, location: str = GEMINI_LOCATION):
    """A ChatVertexAI Gemini bound to injected user creds. Used for both coach + judge."""
    from langchain_google_vertexai import ChatVertexAI

    return ChatVertexAI(
        model=model,
        project=PROJECT,
        location=location,
        temperature=temperature,
        max_tokens=max_tokens,
        thinking_budget=0,
        credentials=_creds(),
    )
