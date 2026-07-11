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
