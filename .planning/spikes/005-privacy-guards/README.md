---
spike: 005
name: privacy-guards
type: desk-check
validates: "Given the brief's §4 mandatory guards (geometry-only/no-PII, no-training, minimal retention, parental consent), when checked against the Vertex/Cloud Run reality, then the technical guards are achievable — and what remains is named as build-phase gates."
verdict: PARTIAL
related: [002]
tags: [stroke-aware, privacy, GROUND-02, vertex, cloud-run, consent, no-training]
---

# Spike 005: Privacy Guards Achievable on Vertex / Cloud Run

## What This Validates

Stroke-aware coaching **reverses GROUND-02** (raw strokes never leave the device) and the child-data
minimization stance (§2). The brief's §4 makes four guards mandatory as the "cost of admission." H5
asks: are they achievable on our actual stack? This is a config + documentation desk-check, not a
live experiment — hence verdict PARTIAL (technically clear; consent/legal + the contract reversal are
explicitly build-phase work, not provable in a spike).

## Method / Evidence gathered

Read-only recon of the live project (`qalam-app-bd7d0`) + the deployed `qalam-tutor` Cloud Run
service, plus Google's Vertex data-governance posture. See `notes.md` for the raw command output.

## Results — guard by guard

| §4 guard | status | evidence |
|----------|--------|----------|
| **Geometry only, no identifiers** | ✅ achievable by construction | The spike sends only normalized points / diff / image — no name, nickname, device id. The build extends the existing GROUND-02 whitelist discipline: the server's `extra="forbid"` (`app/schema.py`) is *replaced* with an explicit `strokes`/`reference` whitelist (the §2 reversal), keeping every other PII key a 422. |
| **No training use** | ✅ achievable / already the posture | Vertex AI does not use Gemini API prompts/responses to train Google's models; request-response logging is **opt-in and OFF** — recon found **no logging sink** capturing prediction bodies on the project (only the default audit/`_Default` buckets). The existing D-10 no-training constraint extends to live stroke payloads. |
| **Minimal retention** | ✅ achievable (confirm at deploy) | With request-response logging off, Vertex does not retain request bodies beyond serving; Cloud Run does not log request bodies (the service env carries only `GCP_PROJECT_ID` / location / timeout — no body logging). Confirm the runtime-SA posture at build. |
| **Parental consent covers it** | ⚠️ build/legal gate | The onboarding/consent copy must state that handwriting attempts are processed by an AI service. Out of spike scope — product + owner/legal review. |
| **Owner sign-off that stroke geometry is acceptable** | ⚠️ owner decision | Letter tracings are not faces/voices, but the project treats child data as sensitive by default. The §2 reversal is the owner's recorded call; this guard is the explicit re-confirmation at build. |

## Conclusion

**PARTIAL — the technical guards are achievable and, for no-training/retention/no-PII, already the
project's posture.** Two items are genuine **build-phase preconditions**, not spike deliverables:

1. **Consent/onboarding copy + any legal review** (handwriting → AI service).
2. **The contract reversal lands client + server in lockstep** — replace `extra="forbid"` with an
   explicit `strokes`/`reference` whitelist; deploy the server only after the Dart mirror ships (the
   422 trap the brief and the team have already hit once).

No technical blocker to the privacy design was found. The reversal is bounded, auditable, and rests
on guards the stack can already enforce.
