"""Qalam tutor server application package (Phase 14, Plan 01).

The server-side LangGraph tutor: a FastAPI app on Cloud Run that verifies the caller
(Firebase ID token + App Check), runs a minimal one-node grounding graph, and returns
one grounded ACTION. See README.md for the deploy path and the resolved dependency pins.
"""
