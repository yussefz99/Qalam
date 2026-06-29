---
status: partial
phase: 16-build-presence-voice-eval-gate-demo-harden
source: [16-04-PLAN.md, 16-05-PLAN.md, 16-06-PLAN.md]
started: "2026-06-29T13:47:12Z"
updated: "2026-06-29T13:47:12Z"
---

## Current Test

[awaiting human / hardware / owner's-mother availability]

Phase 16 executed all autonomous code (16-01, 16-02, 16-03 fully; 16-04 Tasks 1–2 +
instrumentation; 16-06 Task 1). The remaining work is gated on things outside an
agent session — the Pixel Tablet, the deployed `qalam-tutor` service, the owner's
mother's register authority, and a one-time GCP console Enable. These six items were
explicitly **deferred to HUMAN-UAT** by the owner on 2026-06-29. The code seams they
depend on are all committed and green.

## Tests

### 1. 16-04 Task 3 — Pixel Tablet latency budget (PRES-01, D-01)
expected: Run the seeded baa flow on the Pixel Tablet against the deployed `qalam-tutor`
  (`--dart-define=TUTOR_BASE_URL=<service URL> --dart-define=LATENCY_TRACE=true`).
  Stream marks: `adb logcat | grep LATENCY` (segments: stylusUp → scorerVerdictRendered →
  coachRequestSent → coachResponseReceived → lineRendered → firstTtsStart). Record a COLD
  path (idle, min-instances=0) and a WARM path; confirm the instant ink+verdict+star
  renders WITHOUT waiting on /coach or TTS (reflex stays local, D-05). Write
  `16-LATENCY-BUDGET.md` with per-segment budget, warm+cold numbers, cold-start delta,
  first-TTS start, and whether a silent TTS warm-up at unit open is needed.
result: [pending]
resume_signal: "budget recorded" (with warm/cold first-TTS numbers)

### 2. 16-05 Task 1 — Owner's-mother gold-set sign-off (EVAL-01, D-09)
expected: Present the 11 Claude-DRAFTED (verdict → ideal-coaching) gold lines in
  `server/tests/test_eval/gold_set.jsonl` (each `"signed": false`) to the owner's mother.
  She edits any line whose register/Arabic is off, or approves as-is. Flip reviewed cases
  to `"signed": true`; write `server/tests/test_eval/GOLD-SIGNOFF.md` (signer, date, scope,
  D-10 no-training-without-consent constraint). Nothing register-shaping ships unsigned.
result: [pending]
resume_signal: "gold signed: N cases" (with the count)

### 3. 16-05 Task 2 — LLM-judge calibration ≥0.7 vs signed gold (EVAL-01)
expected: BLOCKED on #2. Once the gold is signed, run `run_judge.py` (gemini-2.5-flash,
  keyless Vertex, judge ≠ coach) over the SIGNED gold; compute per-dimension
  correlation/agreement vs the signed labels; write `server/tests/test_eval/CALIBRATION.md`
  recording ≥0.7 PASS (or tune rubric / escalate to gemini-2.5-pro until ≥0.7) and the
  register/Arabic gate threshold `make eval` uses. Autonomous once #2 is done + live Vertex
  reachable — an executor can finish this.
result: [pending]
resume_signal: (auto after #2) — re-run `/gsd-execute-phase 16` to finish 16-05 Task 2

### 4. 16-06 Task 2 — On-device demo-harden + hero moment (DEMO-01, D-12/D-13)
expected: Build on the Pixel Tablet with the demo seed (`--dart-define=DEMO=true` +
  `--dart-define=TUTOR_BASE_URL=<service URL>`). Walk Home/Journey → baa unit → trace.
  Trigger the hero moment: wobble on the seeded form → backward remediation re-surfaces an
  easier exercise → the tutor SPEAKS the specific fix → one quiet star at mastery. Confirm
  `isLanguageAvailable('ar')` on the device (record it). Fault-inject airplane mode mid-flow
  → confirm the AuthoredFallback floor takes over INVISIBLY (no dead end, no hang). Repeat to
  confirm it fires on cue repeatably. Record a short device-UAT note.
result: [pending]
resume_signal: "demo hardened" (with hero-moment + airplane-mode results)

### 5. 16-06 Task 3 — Model-Garden Enable for the Claude coach (D-03)
expected: Owner opens Vertex AI → Model Garden → Claude Haiku 4.5 card → Enable (accept
  Anthropic terms). Verify with the rawPredict 200 probe (16-RESEARCH "Code Examples") for
  `claude-haiku-4-5@20251001` at region `us-east5` or `global` (404 before → 200 after).
  Confirm Technion credits cover partner-model billing; if blocked, the demo ships
  all-Gemini-keyless (no demo impact — it is the shippable default).
result: [pending]
resume_signal: "claude enabled: 200" OR "blocked: <reason> — ship all-Gemini"

### 6. 16-06 Task 4 — Coach bake-off + ADR-016 per-node verdict (SC#4)
expected: BLOCKED on #3 (Enable) + #5/calibrated judge. Run `make eval` on
  gemini-2.5-flash; if Claude was Enabled (#5 = 200), also run
  `COACH_MODEL_PROVIDER=anthropic_vertex COACH_LOCATION=global make eval`; compare
  register/correct-Arabic + faithfulness. Write `docs/architecture/ADR-016-v2-per-node-model-verdict.md`
  (finalized analyze/plan/coach verdict, keyless-Vertex, all-Gemini shippable default,
  Claude coach only if Enabled + eval-won, Gemma-deferred-via-seam) and append a dated
  ADR-016 pointer to 14-AI-SPEC §4. Autonomous once #3+#5 resolve — an executor can finish it.
result: [pending]
resume_signal: (auto after #3/#5) — re-run `/gsd-execute-phase 16` to finish 16-06 Task 4

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps

(none — these are deferred human/hardware/authority gates, not defects in the landed code.
The autonomous code for each gated task is committed and green.)
