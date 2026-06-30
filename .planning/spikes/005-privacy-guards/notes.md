# Spike 005 — raw recon (2026-06-30)

## Cloud Run service env (no request-body logging; only non-PII config)
```
qalam-tutor  https://qalam-tutor-ogtudswkjq-uc.a.run.app   (us-central1, qalam-app-bd7d0)
env: GCP_PROJECT_ID=qalam-app-bd7d0; GOOGLE_CLOUD_LOCATION=us-central1; COACH_TIMEOUT_SECONDS=12
```

## Logging sinks — no prediction request/response capture
```
_Required  -> _Required bucket   (cloud audit only)
_Default   -> _Default bucket    (everything NOT audit)
```
No custom sink routing Vertex prediction request/response bodies anywhere. Vertex request-response
logging is opt-in (a per-model / per-request setting) and is NOT enabled.

## Server already forbids stroke/PII keys (the guard the build must deliberately reverse)
`app/schema.py`: `model_config = ConfigDict(extra="forbid")` on `TutorFactsIn`, `AttemptFactIn`,
and `CoachOut`. Any `strokes`/`x`/`y`/`childName` key today => 422. The build replaces this with an
explicit `strokes`/`reference` whitelist (the §2 reversal), keeping every other key a 422.

## Image hygiene
`server/.dockerignore` excludes `tests/` — the eval gold set / fixtures never ship in the image.
