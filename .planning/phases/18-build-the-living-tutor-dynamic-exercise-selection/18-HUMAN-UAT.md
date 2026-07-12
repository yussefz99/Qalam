---
status: partial
phase: 18-build-the-living-tutor-dynamic-exercise-selection
source: [18-11-PLAN.md, 18-VALIDATION.md, 18-05-SUMMARY.md, 18-09-SUMMARY.md, ADR-017]
human_verify_mode: end-of-phase
started: "2026-07-12T00:00:00Z"
updated: "2026-07-12T00:00:00Z"
---

## Current Test

Task 2 — cost/latency device measurement session (item 4 below). Task 1's three ordered
deploy gates are DONE (user-authorized, orchestrator-executed, 2026-07-12) and recorded
below with every command outcome, two runbook deviations, and one pending re-verify item.
Tasks 2 and 3 (device measurement; the mother's sign-off) remain human-gated per
`autonomous: false` (the 17-10 pattern).

**Deploy order honored: server FIRST (the 422 lockstep) — the new `TutorFactsIn.profile`
+ `evidenceDigest` wire fields went live before any client build sends them.**

## Tests

### 1. GATE 1 — /coach server re-deploy carrying the new wire fields  *(PASSED 2026-07-12 — rev qalam-tutor-00025-hd8)*
result: PASSED. `gcloud run deploy qalam-tutor --source server --project qalam-app-bd7d0
  --region us-central1` → revision **qalam-tutor-00025-hd8** serving 100% traffic (2026-07-12).
  Image: `us-central1-docker.pkg.dev/qalam-app-bd7d0/cloud-run-source-deploy/qalam-tutor@sha256:3efaaf841c39f27ca31280fb23cc1c187fa8c685ee69e381aad941abc9196890`.
  `GET /health` → **200**.
  NUANCE (recorded honestly): a live `POST /coach` with a `profile`/`evidenceDigest` payload and
  no auth → **401** — `verify_caller` rejects BEFORE schema validation, so an unauthenticated
  422-probe is not possible from outside. Schema acceptance of the new fields is pinned by the
  deployed commit's `test_schema_forbid.py` 3/3; the live AUTHENTICATED 200-not-422 proof lands
  in Task 2's device session (item 4).
expected: Server re-deploys FIRST (422 lockstep, T-18-11-01); `/health` 200; a live /coach
  with the new fields returns 200 (not 422).
why_human: production `gcloud run deploy` is auto-mode-classifier-blocked (17-10 precedent);
  user explicitly authorized, orchestrator executed.
resume_signal: (received — "deployed")

### 2. GATE 2 — firestore.rules child_models owner-read block  *(PASSED 2026-07-12 — ruleset 8cdd41b4)*
result: PASSED. firebase CLI credentials were expired (needs interactive `--reauth`), so the
  deploy went through the **Firebase Rules REST API with gcloud user credentials** (same action,
  same effect). Created ruleset `projects/qalam-app-bd7d0/rulesets/8cdd41b4-2b88-4f5c-a81a-72b3400090bc`
  and pointed the `cloud.firestore` release at it. Verified the SERVED ruleset content contains
  `match /child_models/{uid} { allow read: if request.auth != null && request.auth.uid == uid; allow write: if false; }`
  — byte-match with the local `firestore.rules`.
  NOTE: the Rules Playground cross-account check (A cannot read B) was NOT run — it is
  console-only; the served-content verification above covers the rule text (T-18-11-02 rule is
  live; the interactive Playground walk remains an optional console follow-up).
expected: Owner-only `child_models/{uid}` read; all client writes denied; rule live before the
  client's D-16 `.get()` ships.
why_human: `firebase deploy` needed interactive reauth; REST-API path executed by the
  orchestrator under user authorization.
resume_signal: (received — "deployed")

### 3. GATE 3 — nightly Cloud Run Job + Cloud Scheduler cron  *(PASSED 2026-07-12 — with 2 runbook deviations + 1 pending re-verify)*
result: PASSED. Created SA `qalam-compile-profiles@qalam-app-bd7d0.iam.gserviceaccount.com`;
  bound **roles/datastore.user only** at project level (least privilege, T-18-11-03).
  - **Deviation A:** the Job was created on the REAL deployed image digest
    (`cloud-run-source-deploy/qalam-tutor@sha256:3efaaf84…`) — the runbook's
    `qalam/qalam-tutor:latest` path does not exist in this project.
  - **Deviation B:** added **roles/run.invoker on the job** for the same SA — required for the
    Scheduler OAuth call to execute the job; the runbook omitted it.
  Enabled `cloudscheduler.googleapis.com` (was disabled), then created scheduler job
  `qalam-compile-profiles-nightly`, schedule `"0 3 * * *"` (Etc/UTC), OAuth SA as above.
  Manual execution `qalam-compile-profiles-9pb7d` → **SUCCEEDED**, container exit(0).
  PENDING RE-VERIFY (not a failure): the `child_models` collection is EMPTY after the run —
  expected and honest: zero `children/{uid}/evidence` rows exist yet because the evidence-append
  path only went live with revision 00025-hd8 and no /coach call has hit it. The "manual run
  writes a child_models doc" acceptance is deferred to after Task 2's device session generates
  the first evidence rows (re-run the Job once, then confirm a `child_models/{uid}` doc).
expected: Job created on the qalam-tutor image with the `python -m app.jobs.compile_profiles`
  command; SA = roles/datastore.user only; nightly cron live; one manual run writes a
  `child_models/{uid}` doc.
why_human: `gcloud run jobs create` / `gcloud scheduler jobs create` are production infra
  commands (classifier-blocked in auto-mode); user authorized, orchestrator executed.
resume_signal: (received — "deployed")

### 4. Task 2 — CLOSE the cost/latency research question (measured device numbers)  *(PENDING)*
expected: On a Pixel Tablet / iPad against rev 00025-hd8, run a FULL baa session and MEASURE:
  (1) **calls/session** — count `POST /coach` in the run; (2) **cached-token %** — from the
  /coach logs / Vertex token accounting (input tokens served from the implicit cache vs total);
  (3) **stroke-up → feedback → next-pick wall-clock** — the perceived latency for a scored
  attempt. Write the numbers (with device + build + date) into
  `docs/architecture/COST-LATENCY-CLOSURE.md` and state the question CLOSED. Confirm selection
  adds no perceptible latency (the pick rides the SAME /coach round-trip the feedback moment
  masks, Pitfall 5). Side effects to bank: the first authenticated /coach calls prove the live
  200-not-422 (item 1 nuance) and write the first evidence rows (unblocks item 3's re-verify).
why_human: device rendering, stylus capture, real network latency, and Vertex token accounting
  are not reproducible in a headless session.
resume_signal: "measured" with the three numbers (or describe what blocked, e.g. no device)

### 5. Task 3 — mother sign-off of provisional values + content → flip signed:false → true  *(PENDING)*
expected: Present each provisional item with its one-sentence rationale; she approves or gives
  her numbers/edits: the baa micro-drill set (dot/bowl/start), the step-down/arc framing copy
  (D-03 register), arc-N (`kArcEntryFailStreak`/`kArcMaxAttempts`, D-02/D-04), the EMA α +
  thresholds (`kEmaAlpha`/`kEmaStrengthHi`/`kEmaStruggleLo`/`kEmaMinAttempts`, D-15), and the
  selection eval threshold + gold scenarios (`SELECTION_THRESHOLD` + `selection_gold_set.jsonl`,
  Req 9). Then: flip `signedOff:false → true` on the signed exercises/nodes and
  `"signed": false → true` on the gold scenarios as the ONLY content change (15-07/17-10
  pattern); re-run `python -m app.curriculum_data.generate`; `cd server && make eval` (Vertex
  judge / ADC) passes ≥ the signed threshold on the signed gold set; re-deploy the server so the
  signed graph + threshold go live. Record who/when/what here.
why_human: curriculum content and pedagogy parameters are the owner's-mother's authority —
  never autonomous (15-07 precedent).
resume_signal: "approve-as-drafted" OR "mother-adjusts" (with her values); then confirm the
  flip + generate.py + make eval + re-deploy are done

## Summary

total: 5
passed: 3
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps

- **Item 1 nuance:** the live authenticated /coach 200-not-422 proof for the new wire fields is
  deferred to Task 2's device session (unauthenticated probes 401 before schema validation —
  by design). Not a defect: schema acceptance is test-pinned on the deployed commit.
- **Item 3 pending re-verify:** `child_models/{uid}` doc write is unproven until the first
  evidence rows exist (device session), then one manual Job run confirms it. The Job itself
  SUCCEEDED (exit 0).
- **Rules Playground cross-account walk** (item 2) was not run — console-only; the served
  ruleset byte-matches the repo rule. Optional console follow-up.
