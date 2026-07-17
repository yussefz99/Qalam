# Phase 18 — Deferred / Out-of-Scope Items

Discoveries logged during execution that are NOT in scope for the current plan.

## Pre-existing test failures (not caused by Phase 18)

- **`test/data/curriculum_repository_v2_test.dart` → `getExercises() returns the
  bundled baa+taa+alif configs`** — the `every((e) => e.signedOff == true)` leg
  is RED at HEAD (verified by stashing all 18-02 changes: fails at the original
  line 106). Cause: alif's `traceLetter.isolated` / `writeLetter.fromSound` /
  `writeLetter.writeForm` ship `signedOff:false` in `assets/curriculum/exercises.json`
  (alif's four forms were never signed at the exercise level — one of the known
  "748/8-known" baseline reds). Plan 18-02 does NOT fix this (out of scope —
  curriculum sign-off is the owner's-mother's domain). 18-02 only updated the
  count 48→51 (its own +3 microDrill additions) and carved the microDrills out of
  the signed-check, so the microDrill additions contribute NO new red — the test
  remains red for the SAME pre-existing alif reason. Resolve when alif's exercise
  forms are signed off.

## Carried forward at phase close (owner decision, 2026-07-17)

Owner declared Phase 18 done; the following open items are deferred, NOT dropped:

- **18-11 Task 2 — on-device cost/latency measurement.** Calls/session, cached-token %,
  stroke-up→feedback→next-pick wall-clock, measured on the tablet against rev
  qalam-tutor-00027-nqw. Closes the last open research question (R-cost/latency);
  results belong in `docs/architecture/COST-LATENCY-CLOSURE.md`.
- **18-11 Task 3 — mother's sign-off.** Drill set, arc-N, α/EMA thresholds, eval
  threshold + selection gold set are all provisional (`signed:false`). Per the
  curriculum-governance rule, nothing model-authored ships unsigned — flip to
  `signed:true` as the ONLY content change when she reviews.
- **Device retest of the 5 UAT gap fixes** (18-12..18-16, one per failed item in
  `18-UAT.md`, which remains `status: diagnosed`). The 5 matching sessions in
  `.planning/debug/` stay open until the retest passes:
  stimulus-picture-too-small, retry-does-nothing-after-fail,
  coach-feedback-feels-static, app-stuck-and-teacher-margin-not-understood,
  resume-position-lost-on-relaunch.
  Natural home: fold into Phase 19 device UAT — the overhaul re-exercises the
  same presentation surfaces anyway. Build WITHOUT `--dart-define=DEMO=true`.
