---
status: partial
phase: 14-build-tutorbrain-spine-grounding-invariant
source: [14-VERIFICATION.md]
started: 2026-06-22T00:00:00Z
updated: 2026-06-22T00:00:00Z
---

## Current Test

[awaiting human testing — 3 gates]

## Tests

### 1. On-device online coaching + offline floor (14-03 gate)
expected: >-
  Run the app pointed at the live server:
  `flutter run --dart-define=TUTOR_BASE_URL=https://qalam-tutor-718707208086.us-central1.run.app`
  (requires a REAL Anthropic key in Secret Manager — see deploy gate note below — and the
  app's appCheckTokenGetterProvider wired at the composition root). Confirm: (a) an online
  coaching line appears for a trace attempt; (b) a present_activity line shows real text, NOT
  the authored floor (proves the camelCase seam fix, commit 5fecd3b); (c) a grounded-fail never
  says "advance"; (d) airplane mode falls back to the authored Arabic floor and the loop never blocks.
result: [pending]

### 2. Firebase App Check console registration
expected: >-
  In the Firebase console, the Android app is registered under App Check with the Play
  Integrity provider, so the server's App Check verification accepts real device tokens.
result: [pending]

### 3. Curriculum sign-off — AUTHORED_BAA_IDS
expected: >-
  The owner's mother confirms the 26-id set in
  server/app/curriculum_data/baa_authored_ids.json (6 sections + 19 baa.* exercises + the
  baa family) against the signed curriculum — the curriculum-membership guard (G4) rails the
  agent's present_activity choices to exactly this set.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps

## Notes

Deploy gate (14-01) is VERIFIED live by the orchestrator: GET /health → 200, unauthenticated
POST /coach → 401, both keys are Secret Manager references, no plaintext key in config
(revision qalam-tutor-00003-7gv, project qalam-app-bd7d0). Provider keys are PLACEHOLDERS —
add the real Anthropic key before test 1:
  printf '%s' 'sk-ant-REAL' | gcloud secrets versions add ANTHROPIC_API_KEY --data-file=- --project=qalam-app-bd7d0
  gcloud run services update qalam-tutor --region=us-central1 --project=qalam-app-bd7d0 --update-secrets=ANTHROPIC_API_KEY=ANTHROPIC_API_KEY:latest
