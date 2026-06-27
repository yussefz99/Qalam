---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
plan: 01
subsystem: testing
tags: [curriculum, langgraph, drift, riverpod, pytest, flutter-test, grounding, nyquist]

# Dependency graph
requires:
  - phase: 14-tutor-grounded-agent-spine
    provides: "the plan node G3/G4 guards, AUTHORED_BAA_IDS membership rail, TutorFacts chokepoint, Drift LetterReps/LetterMastery tables, the 19 signed baa.* exercise ids"
provides:
  - "assets/curriculum/curriculum_graph.json — the PROVISIONAL (signedOff:false) baa curriculum graph: 19 nodes mapping each signed exercise to competency/tier/minCleanReps; recognize→positionalForms→copyWrite→fluentReading essential chain + wordBuilding/grammarTransform enrichment (70/30); the manqul/manzur/ghayrManzur إملاء ramp"
  - "docs/curriculum/baa-curriculum-graph-signoff-sheet.md — the owner-mother sign-off sheet (D-05) Plan 15-07 gates on"
  - "the Wave-0 RED contract: 5 new test files (3 Dart, 2 Python) + 1 JSONL fixture, every Phase-15 requirement (DYN-01/DYN-02/GROUND-03) has a failing automated test naming its exact behavior"
affects: [15-02, 15-03, 15-04, 15-05, 15-06, 15-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Separate signed-off graph asset (independent signedOff gate, not inlined into exercises.json) — RESEARCH A5"
    - "Wave-0 RED-by-missing-symbol contract: every test imports a not-yet-existing symbol so it fails RED before implementation (Nyquist)"

key-files:
  created:
    - assets/curriculum/curriculum_graph.json
    - docs/curriculum/baa-curriculum-graph-signoff-sheet.md
    - server/tests/test_plan_graph.py
    - server/tests/test_faithfulness.py
    - server/tests/fixtures/faithfulness_set.jsonl
    - test/curriculum/curriculum_graph_test.dart
    - test/curriculum/curriculum_graph_walker_test.dart
    - test/curriculum/mastery_condition_test.dart
    - test/data/graph_position_repository_test.dart
    - test/features/letter_unit/dynamic_selection_test.dart
  modified: []

key-decisions:
  - "The graph is a SEPARATE asset from exercises.json so its signedOff gate is independent — signed exercises are never re-touched (RESEARCH A5)"
  - "Graph node id set is byte-identical to the 19 signed baa.* ids in baa_authored_ids.json (verified) — the graph only adds competency/tier/prerequisite/minCleanReps metadata, invents no exercises"
  - "tier is non-null ONLY for the إملاء writing ramp (connectWord/completeWord/writeWord/buildSentence); recognize/trace/recall/morphology nodes carry tier:null"
  - "DRAFT competency mapping: recognize(1) + positionalForms(6: 3 trace + 3 recall) + copyWrite(6 إملاء) + fluentReading(2) essential; wordBuilding(1) + grammarTransform(3) enrichment — provisional until owner-mother signs (D-05)"
  - "Server RED tests reference app.curriculum.{reachable_tiers,prerequisites_met,tier_of} (15-02) and app.faithfulness (15-06); Dart RED tests reference lib/curriculum/* (15-03), the LetterGraphPosition repo (15-04), and the exerciseSelectorProvider (15-05) — all fail by missing symbol"

patterns-established:
  - "Provisional curriculum-data gate mirrored: signedOff:false + a clean human-readable sign-off sheet, exactly like the AUTHORED_BAA_IDS gate"
  - "Faithfulness fixture carries BOTH constructed-faithful gold cases AND adversarial cases (a fail with 'Great job!'; a fail naming the dot when the curve failed) so the flag tests have something to flag"

requirements-completed: [DYN-01, DYN-02, GROUND-03]

# Metrics
duration: 8min
completed: 2026-06-27
---

# Phase 15 Plan 01: Nyquist RED Contract + Provisional baa Curriculum Graph Summary

**The provisional baa curriculum-graph asset (19 nodes, competency/tier/minCleanReps, signedOff:false) + its owner-mother sign-off sheet, plus a failing automated test for every Phase-15 requirement (DYN-01/DYN-02/GROUND-03) before any implementation begins.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-27T14:29:59Z
- **Completed:** 2026-06-27T14:37:39Z
- **Tasks:** 3
- **Files modified:** 10 created

## Accomplishments

- **The one shared data artifact every Wave-1/2 slice reads is authored once here** — `assets/curriculum/curriculum_graph.json`, mapping each of baa's 19 signed exercises to a competency, a difficulty tier (إملاء ramp, non-null only for writing), and DRAFT clean-reps, with `signedOff:false` (PROVISIONAL, D-05). Its node id set is byte-identical to the signed `baa_authored_ids.json` set (verified), so the graph adds only metadata — it invents no pedagogy.
- **The owner-mother sign-off sheet** (`docs/curriculum/baa-curriculum-graph-signoff-sheet.md`) lays out every node as a reviewable row plus the three tier-level sign-off questions (competency mapping, the 70/30 essential/enrichment split, the per-skill clean-reps) that Plan 15-07 gates on.
- **A complete Wave-0 RED contract** — 5 new test files + 1 fixture, with every Phase-15 requirement carrying at least one failing automated test that names its exact observable behavior from 15-VALIDATION.md. None are accidentally green.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the provisional baa curriculum graph asset + sign-off sheet** - `f64b577` (feat)
2. **Task 2: RED server tests — graph rail (DYN-01) + faithfulness check (GROUND-03)** - `bec0232` (test)
3. **Task 3: RED Dart tests — graph/walker/mastery + Drift resume + dynamic flow (DYN-01/DYN-02)** - `24be19f` (test)

## Files Created/Modified

- `assets/curriculum/curriculum_graph.json` - The provisional baa graph: `_meta` (source/regenerate/sign-off), `letterId:"baa"`, `signedOff:false`, 6 competencies (4 essential chain + 2 enrichment), the 3-tier إملاء ramp, 19 baa-only nodes each with exerciseId/competency/tier/minCleanReps.
- `docs/curriculum/baa-curriculum-graph-signoff-sheet.md` - One reviewable row per node + the three tier-level sign-off questions for the owner-mother.
- `server/tests/test_plan_graph.py` - `pytest.mark.code`, monkeypatches the plan model like `test_grounding.py`; the 4 verbatim DYN-01 cases (within-tier choice, G5 unreached-tier rejected, G6 prereq-unmet rejected, backward remediation allowed). RED — imports `reachable_tiers`/`prerequisites_met`/`tier_of` from `app.curriculum` (don't exist yet).
- `server/tests/test_faithfulness.py` - `pytest.mark.code`; `test_flags_praise_on_fail`, `test_flags_wrong_fix`, `test_faithfulness_rate_reported`. RED — imports `app.faithfulness` (15-06 writes it).
- `server/tests/fixtures/faithfulness_set.jsonl` - 13 labeled cases (9 faithful gold + 4 adversarial, incl. the two required adversarial entries).
- `test/curriculum/curriculum_graph_test.dart` - CurriculumGraph parse contract (essentialNodes 70/30 filter, tierOf/nextForward/remediateOneTier, signedOff). RED — `lib/curriculum/curriculum_graph.dart` absent.
- `test/curriculum/curriculum_graph_walker_test.dart` - The deterministic walker as an ExerciseSelector: pass→nextForward, fail→one tier down, manqul floor re-presents in place (Pitfall 5). RED.
- `test/curriculum/mastery_condition_test.dart` - `isMasteryMet` true only at mom's reps on essential nodes; enrichment never gates; false on click-through (Pitfall 2). RED.
- `test/data/graph_position_repository_test.dart` - Temp-file simulated-restart shape (D-08): cleared tiers/competencies + currentExerciseId persist. RED — `DriftGraphPositionRepository` absent.
- `test/features/letter_unit/dynamic_selection_test.dart` - A fail re-surfaces a remediation, not the next linear section (DYN-02 end-to-end). RED — the `exerciseSelectorProvider` seam absent.

## Decisions Made

- Authored the graph as a **separate** asset (not inlined into `exercises.json`) for an independent `signedOff` gate (RESEARCH A5) — the signed exercise content is never re-touched.
- Mapped the إملاء **tier** non-null only for the writing exercises (connect/complete/writeWord/buildSentence); recognition, trace, single-letter recall, and morphology nodes carry `tier:null`. Backward remediation walks `ghayrManzur → manzur → manqul` within a competency.
- DRAFT clean-reps follow A2: trace 3, single-letter/word writes 2, teach/sentence/blank/transform 1 — all owner-mother's to confirm (D-07).
- Kept all RED tests **failing by missing project symbol** (not incidental missing imports): added the `package:drift/drift.dart` import to the resume test so its only failures are the intended `DriftGraphPositionRepository`/`GraphPosition` symbols.

## Deviations from Plan

None - plan executed exactly as written.

The plan is a pure RED-contract + data-asset authoring slice; no implementation logic was written (by design — Waves 1/2 turn these tests green), so no auto-fix rules (1–3) or architectural decisions (Rule 4) were triggered.

## Issues Encountered

- The resume test initially flagged `DatabaseConnection` as undefined (a real missing import unrelated to the RED contract). Resolved by importing `package:drift/drift.dart` (hiding the `isNull`/`isNotNull` matcher collision, the same idiom as `app_database_test.dart`) so the test now fails ONLY on the intended missing graph-position symbols. Verified via `flutter test` (`+0 -5`, RED by the right symbols).

## Known Stubs

None. The two non-test artifacts (the graph asset + the sign-off sheet) are intentionally PROVISIONAL — `signedOff:false` is the designed gate (D-05/Pitfall 4), not a stub: it is the explicit human-review marker that Plan 15-07 flips behind a human-verify checkpoint. It does not block this plan's goal (establishing the RED contract + the shared graph artifact); downstream tests read the provisional graph by design.

## Threat Surface

No new security-relevant surface beyond the plan's `<threat_model>`. T-15-01-S (the drafted graph must not reach a child as if signed) is mitigated as designed: the asset ships `signedOff:false`; no code path consumes it as signed in this plan. T-15-01-D11 (baa-only, no ت/ث) is satisfied — the node id set is exactly the 19 `baa.*` ids (verified). T-15-SC (no package installs) holds — zero dependencies added.

## Verification

- Task 1: `python3 -c` graph-shape assertion PASSES (parses, `signedOff:false`, 3-tier ramp, essential+enrichment split, every node has exerciseId/competency/minCleanReps); node set == the 19 signed baa.* ids (verified).
- Task 2: `cd server && uv run pytest tests/test_plan_graph.py tests/test_faithfulness.py -q` → 2 collection ERRORS (ImportError / ModuleNotFoundError) — RED by missing symbol.
- Task 3: `flutter test test/curriculum/ test/data/graph_position_repository_test.dart test/features/letter_unit/dynamic_selection_test.dart` → `+0 -5` compile/missing-symbol failures — RED by design.
- No test is green (Wave-0 contract: a green Wave-0 test means the contract is too weak).

## Next Phase Readiness

- **15-02** (server graph rail) reads the graph asset and turns `test_plan_graph.py` green by adding `reachable_tiers`/`prerequisites_met`/`tier_of` to `curriculum.py` + the G5/G6 guards in `plan.py`, and extending `generate.py` to derive the server copy.
- **15-03** (pure-Dart graph/walker/mastery) turns the 3 `test/curriculum/` files green by building `lib/curriculum/{curriculum_graph,curriculum_graph_walker,mastery_condition}.dart`.
- **15-04** (Drift resume) turns `graph_position_repository_test.dart` green via the `LetterGraphPosition` table (schema v4→v5) + `DriftGraphPositionRepository`.
- **15-05** (selection seam) turns `dynamic_selection_test.dart` green via the `exerciseSelectorProvider` router + the unit-level config-presenter.
- **15-06** (faithfulness check) turns `test_faithfulness.py` green via `app.faithfulness`.
- **15-07** (sign-off checkpoint) is the ONLY place that flips `signedOff:true` after the owner-mother signs the sheet — do not flip it before.

## Self-Check: PASSED

All 11 created files verified on disk; all 3 task commits (`f64b577`, `bec0232`, `24be19f`) verified in git history.

---
*Phase: 15-build-dynamic-grounded-exercise-selection-on-baa*
*Completed: 2026-06-27*
