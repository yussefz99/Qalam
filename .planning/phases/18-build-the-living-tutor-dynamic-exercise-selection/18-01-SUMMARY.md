---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 01
subsystem: testing
tags: [nyquist, red-contract, selection-policy, ema, knowledge-tracing, evidence, eval, flutter_test, pytest, non-pii]

# Dependency graph
requires:
  - phase: 15
    provides: CurriculumGraph / isLegalSelection rails, CurriculumGraphWalker, RouterExerciseSelector accept-if-legal seam, GraphPosition
  - phase: 17
    provides: per-criterion LetterScore.criteria + weakestCriterion, TutorFacts additive/extra=forbid wire discipline, run_eval.py + gold_set.jsonl eval harness
provides:
  - "Wave-0 RED contract for all 9 Phase-18 requirements (R1..R9) — one failing automated test per requirement, RED by MISSING SYMBOL"
  - "EMA Dart<->Python parity contract pinned by two tests reading byte-identical fixtures"
  - "Extended non-PII whitelist guard + server extra=forbid guard for the new profile/evidenceDigest wire fields (D-14, 422 lockstep, server-first)"
  - "signed:false selection gold set (fail-streak / returning-child / boredom-trap) for the new selection_policy eval dimension"
  - "The executable API contract downstream plans implement with ZERO test edits: SelectionPolicy.narrow -> PolicyOutcome{candidates, arcStep, targetCriterion, whyFacts, nextArc}, ChildModelSnapshot, ArcState, kArcEntryFailStreak/kArcMaxAttempts, updateEma/update_ema, evidence_rows_from_facts/append_evidence, compile_child, SELECTION_THRESHOLD"
affects: [18-02, 18-03, 18-04, 18-05, 18-06, 18-07, 18-08, 18-09, 18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave-0 RED-by-missing-symbol contract (Nyquist) — 15-01/17-01 discipline"
    - "Seeded-random property test in plain flutter_test (NO glados — analyzer-9 conflict)"
    - "Cross-language fixture-parity test (Dart + Python read the SAME EMA rows)"

key-files:
  created:
    - test/tutor/selection_policy_test.dart
    - test/tutor/remediation_arc_test.dart
    - test/tutor/microdrill_selection_test.dart
    - test/tutor/selection_rails_property_test.dart
    - test/tutor/offline_floor_test.dart
    - test/tutor/across_session_memory_test.dart
    - test/core/scoring/criterion_ema_test.dart
    - server/tests/test_criterion_ema.py
    - server/tests/test_schema_forbid.py
    - server/tests/test_evidence.py
    - server/tests/test_compile_profiles.py
    - server/tests/test_eval/test_selection_dimension.py
    - server/tests/test_eval/selection_gold_set.jsonl
  modified:
    - test/tutor/payload_nonpii_test.dart

key-decisions:
  - "SelectionPolicy lives at lib/curriculum/selection_policy.dart (per plan Task 1) — the pure durable-layer citizen; narrow() returns a PolicyOutcome class {candidates, arcStep, targetCriterion, whyFacts, nextArc}"
  - "Arc advancement flows through narrow(facts, position, {arc}) -> PolicyOutcome.nextArc so a stateful fail-streak simulation drives entry->stepDown->rebuild->retryOriginal without a separate advance API"
  - "TutorFacts.profile is a Map (strengths/struggles/perCriterion/schemaVersion); perCriterion is an EMA map keyed by <letter>/<criterion> ids — the payload guard allows those dynamic id keys and format-checks them, the token scan proves them non-PII"
  - "EMA fixture rows are byte-identical literals in criterion_ema_test.dart and test_criterion_ema.py (prior/passed/alpha->expected) so a drift on either side goes red"
  - "micro-drill ids are baa.microDrill.{dot,bowl,start} (D-07 dot/bowl/start), mapped from criteria dot->dot, shape->bowl, strokeOrder->start"

patterns-established:
  - "Every R1..R9 requirement has a falsifiable failing test BEFORE any implementation (Dimension 8 — no 3 consecutive tasks without an automated verify)"
  - "Wire-field guards ship as RED extensions (payload_nonpii + test_schema_forbid) so the new profile/evidenceDigest fields cannot ship without passing the 422 + non-PII lockstep"

requirements-completed: []

# Metrics
duration: 22min
completed: 2026-07-11
---

# Phase 18 Plan 01: The Living Tutor — Wave-0 RED Contract Summary

**13 new failing automated tests + 1 signed:false selection gold set that pin every Phase-18 requirement (R1..R9), the EMA Dart↔Python parity, and the D-14 non-PII/422 guards — all RED by MISSING SYMBOL, giving the downstream 18-02..18-11 plans an executable target to turn GREEN with zero test edits.**

## Performance

- **Duration:** ~22 min
- **Completed:** 2026-07-11
- **Tasks:** 3
- **Files modified:** 14 (13 created, 1 extended)

## Accomplishments

- **Client selection RED contract (R1,3,4,5,6):** six flutter_test files pinning anti-boredom + WHY line (R1), the remediation arc entry→stepDown→rebuild→retryOriginal win-within-N + floor guard (R4), calibration-harness-style micro-drill injection (R3), a 200-iteration seeded-random rails property (R5, no glados), airplane-mode walker coherence (R6), and across-session profile memory (R2).
- **EMA parity + guard RED (D-14, R8):** `updateEma`/`update_ema` pinned by byte-identical fixture rows on both sides; `payload_nonpii_test.dart` extended with the `profile`/`evidenceDigest` whitelist + nested key sets; `test_schema_forbid.py` asserts the DTO accepts the fixed-vocabulary shape and 422s a nested coordinate key.
- **Server evidence/compiler/eval RED (R7,R8,R9):** word-attempt→per-letter×criterion evidence (source `word` vs `letter`), the letter-agnostic nightly `compile_child` (second-letter zero-schema-change + PII guard), and the `selection_policy` eval dimension + a 3-scenario signed:false gold set.

## Task Commits

1. **Task 1: Client selection RED tests (Req 1,3,4,5,6)** — `9a07417` (test)
2. **Task 2: EMA parity + non-PII / 422 guard RED tests (D-14, R8)** — `5898361` (test)
3. **Task 3: Server evidence/compiler/eval RED tests + gold-set fixture (R7,R8,R9)** — `c47a7a7` (test)

## Files Created/Modified

- `test/tutor/selection_policy_test.dart` — R1 anti-boredom exclusion + criterion target + WHY line
- `test/tutor/remediation_arc_test.dart` — R4 arc state machine (ordered steps, win-within-`kArcMaxAttempts`, D-04 floor guard)
- `test/tutor/microdrill_selection_test.dart` — R3 calibration-harness dominant-criterion → micro-drill id
- `test/tutor/selection_rails_property_test.dart` — R5 200-iter `Random(seed)` rails property, illegal→walker
- `test/tutor/offline_floor_test.dart` — R6 airplane-mode session coherence, synchronous selection
- `test/tutor/across_session_memory_test.dart` — R2 `ChildModelSnapshot` → `TutorFacts.profile` + whyFacts references a stored struggle
- `test/core/scoring/criterion_ema_test.dart` — EMA fixture table (Dart side of the parity)
- `server/tests/test_criterion_ema.py` — EMA fixture table (Python mirror, byte-identical rows)
- `test/tutor/payload_nonpii_test.dart` — extended: `profile`/`evidenceDigest` whitelist + `_profileKeys`/`_evidenceDigestKeys` + perCriterion id-key format check
- `server/tests/test_schema_forbid.py` — TutorFactsIn accepts fixed-vocab profile+digest, rejects nested coordinate keys
- `server/tests/test_evidence.py` — word→per-letter×criterion evidence (source word/letter), one-batch off-network append
- `server/tests/test_compile_profiles.py` — `compile_child` derived-only shape, second-letter zero-schema-change, PII guard
- `server/tests/test_eval/test_selection_dimension.py` — `selection_policy` dimension + `SELECTION_THRESHOLD`
- `server/tests/test_eval/selection_gold_set.jsonl` — 3 signed:false scenarios (fail-streak / returning-child / boredom-trap)

## Decisions Made

- **Requirements NOT marked complete.** This is a Wave-0 RED contract — R1..R9 gain FAILING tests, not implementations. Following the 15-01 / 17-01 precedent (STATE: "STRK-01 deliberately NOT checkbox-marked at the Wave-0 contract plan"), `requirements-completed: []`; the downstream plan that lands each requirement (or the phase verifier) flips it.
- **`SelectionPolicy` placement = `lib/curriculum/`** (per plan Task 1 action) — the pure durable-layer citizen, no Riverpod/Firebase/render import. The PATTERNS doc left this as a planner call; the plan resolved it to `lib/curriculum/selection_policy.dart`.
- **`narrow()` returns a `PolicyOutcome` class** (`candidates`, `arcStep`, `targetCriterion`, `whyFacts`, `nextArc`) rather than a bare record — clearer for the four downstream consumers and lets the arc simulation thread `nextArc` for stateful advancement.
- **EMA fixture rows are literal + byte-identical** across `criterion_ema_test.dart` and `test_criterion_ema.py` (0.5·pass·0.4→0.7, 0.5·fail·0.4→0.3, a 0.7→0.82→0.492 chain, and two α=0.5 saturation rows). Verified both files carry the same values.

## Deviations from Plan

None — plan executed exactly as written. All three tasks authored the specified RED tests; every per-task `<automated>` verify returned `RED-OK`.

## Issues Encountered

None. The four missing-module server tests (`test_criterion_ema`, `test_evidence`, `test_compile_profiles`, `test_selection_dimension`) interrupt a bare `uv run pytest -m code` at collection time — the established Wave-0 RED behavior (16-01's `test_eval_harness.py` did the same). Confirmed no regression by re-running the suite with the four RED modules deselected: **116 passed, 1 skipped** (pre-existing suite unchanged).

## Known Intended-RED Guards (do NOT flag as regression)

The following were GREEN before this plan and are now intentionally RED as part of the Wave-0 contract; 18-05/18-06 re-green them by SHIPPING the guarded fields (no test edits):

- `test/tutor/payload_nonpii_test.dart` — RED by missing `TutorFacts.profile` / `TutorFacts.evidenceDigest` constructor params.
- `server/tests/test_schema_forbid.py::test_accepts_fixed_vocabulary_profile_and_digest` — RED by missing `TutorFactsIn.profile` / `evidenceDigest` fields (the reject legs already pass under `extra=forbid`).

## Known Stubs

- `server/tests/test_eval/selection_gold_set.jsonl` — every scenario is `"signed": false` (PROVISIONAL). This is INTENTIONAL: gold-set content and the selection threshold are the mother's pedagogy call, signed off in **18-11** (HUMAN-UAT, the 15-07/17-10 sign-off pattern). The fixture ships now so the eval dimension has a target; the flip to `signed:true` is the only content change.

## Next Phase Readiness

- Every downstream Phase-18 plan now has a falsifiable RED target:
  - **18-02** authors the micro-drill nodes + exercise `letters`/`criteria` labels → `microdrill_selection_test` + `test_evidence` letter resolution.
  - **18-03** writes `criterion_ema.dart` + `criterion_ema.py` → the two parity tests.
  - **18-04 / 18-07** write `SelectionPolicy` (+ router wiring) → the five client selection tests.
  - **18-05** adds `TutorFactsIn.profile`/`evidenceDigest` + `evidence.py` (server-first, 422 lockstep) → `test_schema_forbid`, `payload_nonpii`, `test_evidence`.
  - **18-06** adds the Drift child-model mirror + `TutorFacts.profile` → `across_session_memory`.
  - **18-08 / 18-11** register the `selection_policy` eval dimension + sign the gold set/threshold → `test_selection_dimension`.
- No blockers. No new packages (Phase-18 adds none; glados rejected on analyzer-9 grounds).

## Self-Check: PASSED

- All 13 created files present on disk (verified).
- All 3 task commits present in git history: `9a07417`, `5898361`, `c47a7a7`.
- Every per-task `<automated>` verify returned `RED-OK`; pre-existing server suite unchanged (116 passed / 1 skipped with the RED modules deselected).

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
