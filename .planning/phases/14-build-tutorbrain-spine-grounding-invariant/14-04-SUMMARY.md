---
phase: 14-build-tutorbrain-spine-grounding-invariant
plan: 04
subsystem: tutor-guards
tags: [non-pii-guard, ground-02, tutor-04, tutor-02, offline-floor, import-guard, build-failing, regression-guard]
status: complete
requires:
  - "Plan 14-01: the server TutorFactsIn / AttemptFactIn DTO with extra=forbid"
  - "Plan 14-02: the analyze->plan->coach graph + curriculum guard (unchanged here)"
  - "Plan 14-03: the enlarged client TutorFacts (trajectory + strengthTags) + the tightened non-PII guard regex + AuthoredFallbackBrain"
provides:
  - "test/tutor/payload_nonpii_test.dart — build-failing GROUND-02 guard on the client payload (recursive whitelist + tightened token guard, both directions)"
  - "server/tests/test_payload_nonpii.py — build-failing GROUND-02 guard on the server request DTO (TutorFactsIn + nested AttemptFactIn reject PII; extra=forbid pinned)"
  - "test/tutor/durable_layers_no_agent_imports_test.dart — TUTOR-04 static-scan guard: lib/core, lib/features/practice, lib/models, lib/data carry zero agent/framework/network imports"
  - "test/tutor/authored_fallback_offline_test.dart — TUTOR-02 offline-floor coverage: every baa coaching moment (pass + each authored mistakeId + unknown id) yields a grounded line byte-identical to applyResult, loop never blocks"
affects:
  - "Any future change to TutorFacts.toJson / TutorFactsIn — a leaked geometry/PII field now fails the build on BOTH sides"
  - "Any future change to lib/core / lib/features/practice / lib/models / lib/data — an agent/network import now fails the build"
  - "Any future change to the baa feedback seed or the offline floor — a non-grounded/empty coaching moment now fails the build"
tech-stack:
  added: []
  patterns:
    - "Build-failing invariant as a regression test on BOTH wire sides (Dart toJson + Python request DTO) — the chokepoint is enforced, not promised"
    - "Static import-scan guard over durable-layer globs with comment-stripping so header prose naming forbidden packages cannot self-trip"
    - "Data-driven offline-floor coverage: enumerate every authored baa feedback map from the canonical seed and assert the floor mirrors applyResult byte-for-byte"
key-files:
  created:
    - test/tutor/payload_nonpii_test.dart
    - server/tests/test_payload_nonpii.py
    - test/tutor/durable_layers_no_agent_imports_test.dart
    - test/tutor/authored_fallback_offline_test.dart
  modified: []
decisions:
  - "The durable-layer import guard scans EXACTLY the plan's four globs (lib/core, lib/features/practice, lib/models, lib/data). lib/features/letter_unit (exercise_controller) is durable v1 too but the plan's acceptance criteria scope the guard to those four; honored verbatim."
  - "The offline-floor test loads assets/curriculum/exercises.json DIRECTLY off disk (the canonical bundled seed) rather than via CurriculumRepository.getExercises, to stay pure-Dart / network-free / Firebase-free (the repo getter touches FirebaseFirestore). The seed is the same source the repo reads, so coverage is identical."
  - "Correct-Arabic is asserted only as non-empty AS AUTHORED — correctness of the Arabic is the owner's-mother sign-off, not a code check (per the plan)."
metrics:
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 0
  tests: "flutter test/tutor/ → 94 passed (34 new); server pytest → 61 passed (16 new)"
  duration: "~25m"
  completed: 2026-06-22
---

# Phase 14 Plan 04: Lock the Grounding + Non-PII + Offline Invariants as Build-Failing Guards Summary

Converted the three structural invariants the whole phase rests on into automated, build-failing regression tests: the GROUND-02 non-PII guard on BOTH the client payload and the server request body, the TUTOR-04 durable-layers-no-agent-imports guard, and the TUTOR-02 offline-floor coverage across every baa coaching moment. No future change can silently leak child data, contaminate the durable spine, or break the airplane-mode floor — the build goes red first.

## What was built

**Task 1 — GROUND-02 non-PII guard on both wire sides (commit `3acb610`):**
- `test/tutor/payload_nonpii_test.dart`: constructs a FULLY-populated `TutorFacts` (every field set, a 3-record trajectory, struggle + strength tags), serializes via `toJson()`, recursively walks ALL keys (incl. the nested `AttemptFact` records), and asserts every key is in the explicit non-PII whitelist AND none matches the tightened coordinate/PII token guard. Both directions are asserted: `{x, y, strokes, offsets, childName, nickname, rawPoints, coordList}` each FAIL the guard; `{trajectory, strengthTags, struggleTags, recentMistakes, nextExerciseId, letterId, section, passed, mistakeId}` each PASS. Plus a reflection-free source check that `tutor_facts.dart` (comments stripped) declares no `Offset` / `List<Stroke>` field and the serialized surface equals the 8-field whitelist.
- `server/tests/test_payload_nonpii.py` (`code` marker): asserts `TutorFactsIn` AND the nested `AttemptFactIn` reject each of `{strokes, x, y, offsets, nickname, childName}` (top-level and inside a trajectory entry) with a `ValidationError`, accept the legit enlarged payload (populated `trajectory` + `strengthTags`), and that `extra="forbid"` is pinned on both `model_config`s as a permanent regression guard.

**Task 2 — durable-layers import guard + offline-floor coverage (commit `2968ba8`):**
- `test/tutor/durable_layers_no_agent_imports_test.dart`: enumerates every `.dart` file under `lib/core`, `lib/features/practice`, `lib/models`, `lib/data`, strips comment lines, and fails the build if any import line contains a forbidden token (`firebase_ai`, `genui`, `flutter_gemma`, `langgraph`, `package:http/`, `tutor/remote_agent_brain.dart`, `json_schema_builder`). Includes a non-vacuous self-test (the matcher fires on a real `package:http` line and passes `cloud_firestore`) and a `scanned > 0` assertion so a typo'd glob cannot pass vacuously.
- `test/tutor/authored_fallback_offline_test.dart`: loads every baa exercise's authored `feedback` map from the canonical seed and, for EACH coaching moment — the `pass` line, EVERY authored `mistakeId`, and an UNKNOWN id — constructs `AuthoredFallbackBrain` and asserts the returned line is non-empty, is byte-identical to what `ExerciseController.applyResult` would resolve for the same verdict, and that nothing throws/blocks. A separate sweep confirms the floor completes across ≥36 moments without blocking, and an import-clean check confirms the floor imports no `firebase_ai`/`genui`/`flutter_gemma`/`http`/`cloud_firestore`.

## Durable-layer file globs scanned

`lib/core` (13 files: scorer/exercise_engine/recognition/strokes), `lib/features/practice` (8: StrokeCanvas + practice widgets), `lib/models` (7: curriculum content models), `lib/data` (10: curriculum repository + drift/firestore codecs). All currently import-clean of the forbidden set. (`cloud_firestore`/`drift`/`flutter` are legit persistence/UI deps and are NOT in the forbidden list — the ban targets agent/on-device-model/network/tutor-seam deps only.)

## baa feedback source used

`assets/curriculum/exercises.json` — the canonical owner-signed bundled seed, read directly off disk (the same seed `CurriculumRepository.getExercises` reads, and the same one `server/app/curriculum_data/generate.py` transcribes for the server G4 guard). 18 baa exercises author a `feedback` map (each with a `pass` line + 1–2 `mistakeId` fix lines); the offline-floor test covers every one of them. (`baa.teachCard.meet` is the one baa exercise with no feedback — a teachCard that only teaches; correctly skipped.)

## Final tightened guard regex (the GROUND-02 token guard, from Plan 14-03)

```dart
final _forbiddenKey = RegExp(
  r'\b[xy]\b|stroke|offset|coord|point|raw|nick|name',
  caseSensitive: false,
);
```

Only the lone single letters `x`/`y` are word-boundary-anchored (the original substring trap that hit `trajectory`'s "y" and `nextExerciseId`'s "x"); the multi-char geometry/PII tokens stay substrings because no legit field name contains them. Reused verbatim in `payload_nonpii_test.dart` — NOT regressed to a substring scan.

## Deliberate-breakage proof results (verification step; NOT committed)

Both proofs were run on a temporary copy and reverted (working tree confirmed clean afterward, `git status --short lib/` empty):

1. **Client guard catches a leak:** injected `'strokes': const <double>[]` into `TutorFacts.toMap` → `flutter test test/tutor/payload_nonpii_test.dart` FAILED with both `TutorFacts leaked a non-whitelisted key: {…, strokes}` and `key "strokes" matches the forbidden stroke/PII guard` (`+1 -3`). Reverted; `grep -c "'strokes'"` → 0.
2. **Import guard catches a forbidden import:** prepended `import 'package:http/http.dart' as http;` to `lib/core/scoring/tolerances.dart` → `flutter test test/tutor/durable_layers_no_agent_imports_test.dart` FAILED with `a durable v1 layer took a forbidden agent/network/seam import` (`+1 -1`). Reverted; the file's first line is back to its original doc-comment.

## Verification

- `flutter test test/tutor/` → **94 passed** (the 34 new across the three Dart guards + the 60 pre-existing tutor tests; gen-l10n was run first per the gitignored-generated-l10n constraint).
- `cd server && uv run pytest -q` → **61 passed** (16 new in `test_payload_nonpii.py` + the 45 pre-existing server tests).
- The tightened non-PII guard asserts both directions (geometry/PII FAIL, legit enlarged fields PASS) on both wire sides.
- Both deliberate-breakage proofs confirm the guards are non-vacuous (they go red on a real leak / a real forbidden import).

## Deviations from Plan

None affecting behavior. Two scope clarifications, recorded as decisions above:
- The import guard scans exactly the plan's four globs; `lib/features/letter_unit` (also durable v1) is out of the plan's stated acceptance scope and was not added (honoring the plan verbatim rather than widening it).
- The offline-floor test reads the canonical seed directly off disk instead of through `CurriculumRepository.getExercises`, to keep the test pure-Dart / Firebase-free (the repo getter constructs `FirebaseFirestore.instance`). Same seed, identical coverage.

No Rule 1/2/3 auto-fixes were required — the guards are pure additive tests over code that was already correct at the base commit (they pass against it; they fail only when an invariant is later broken).

## Self-Check: PASSED

- All 4 created files exist on disk (`test/tutor/payload_nonpii_test.dart`, `server/tests/test_payload_nonpii.py`, `test/tutor/durable_layers_no_agent_imports_test.dart`, `test/tutor/authored_fallback_offline_test.dart`).
- Commits `3acb610` (Task 1) and `2968ba8` (Task 2) exist in git log.
- 94 Dart tutor tests + 61 server tests pass; both deliberate-breakage proofs confirmed and reverted; working tree clean.

---
*Phase: 14-build-tutorbrain-spine-grounding-invariant*
*Completed: 2026-06-22*
