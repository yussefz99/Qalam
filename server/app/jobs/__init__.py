"""Batch job entrypoints run as Cloud Run Jobs on the existing server image (Phase 18).

Each module here is a stand-alone ``python -m app.jobs.<name>`` entrypoint that reuses the
deployed server image + ``firebase_admin`` ADC — it is NOT wired into the FastAPI /coach
service. ``compile_profiles`` is the nightly across-session child-model compiler (D-15 / Req 8).
"""
