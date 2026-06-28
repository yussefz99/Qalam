---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
plan: 08
type: gap_closure
gap_closure: true
status: complete
requirements: [DYN-01, DYN-02]
sources: [15-REVIEW.md, 15-VERIFICATION.md]
key_files:
  modified:
    - lib/curriculum/curriculum_graph_walker.dart
    - lib/curriculum/mastery_condition.dart
    - lib/data/app_database.dart
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - lib/features/letter_unit/sections/forms_section.dart
    - lib/features/letter_unit/sections/listen_write_section.dart
    - lib/features/letter_unit/sections/meet_section.dart
    - lib/features/letter_unit/sections/watch_trace_section.dart
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - test/curriculum/curriculum_graph_walker_test.dart
    - test/curriculum/mastery_condition_test.dart
---

# 15-08 — Gap closure: wire dynamic selection + the mastery star into the baa unit

Closes the two BLOCKER gaps that `15-REVIEW.md` and `15-VERIFICATION.md` found: the
graph/selection machinery built in 15-02..15-05 was never invoked by the running unit
screen, and the quiet star could never fire (nothing wrote per-exercise clean-reps).
Approach chosen by the owner (2026-06-28): **keep the bespoke 6-section UI** and plumb
selection in — NOT a flat one-exercise-at-a-time rewrite.

## What changed

- **T1 — cleared-state now grows (`letter_unit_controller.dart`).** `markNodeCleared(exerciseId)`
  reads the graph + the child's Drift rep count; once a node meets its `minCleanReps` it
  dedup-adds the node's competency to `clearedCompetencies` and its (non-null) tier to
  `clearedTiers`, then persists. The reachability rail (G5/G6 mirror) and durable resume now
  advance with real progress (fixes review WR-01).
- **T2 — clean-reps are recorded at the single scoring chokepoint
  (`exercise_scaffold._onResult` + `app_database.incrementExerciseCleanReps`).** On a passing
  attempt the scaffold fires `onGraphNodePassed(graphExerciseId)`; the unit shell increments the
  Drift clean-rep count for that **graph node id**. Each section passes the canonical `baa.*`
  graph id (not the synthetic per-word ids). This is what makes the star reachable at all.
- **T3 — selection drives "what comes next" (`letter_unit_screen._onNodePassed` → controller
  `selectNext`).** On each pass the durable cursor advances reachability-aware via the selector
  (online plan if graph-legal, else the offline walker). On a fail the child stays on the
  current exercise in its fix/remediation state rather than blindly advancing — the Pitfall-5
  behaviour (a fail is a remediation, not the next linear step). **Bounded by the owner's
  keep-sections choice:** the 6-section macro-order is preserved; per-exercise remediation is
  handled within the scaffold seam, and cross-section redirect-on-fail is intentionally NOT done
  (that would require the flat rewrite the owner declined).
- **T4 — walker forward-advance is now reachability-aware (`curriculum_graph_walker.dart`).** A
  PASS advances to the next node that passes `graph.isLegalSelection` (tier reachable +
  prerequisites met), never crossing into an unreached tier or skipping a prerequisite. Backward
  remediation is unchanged (always legal — Pitfall 3). +4 walker tests.
- **T5 — the quiet star fires, scoped to what the unit teaches
  (`mastery_condition.isMasteryMetForPresented`).** See the interim flag below. +4 mastery tests.

## ⚠ Interim flag (owner/mother decision for a later phase) — content coverage

The signed curriculum graph has **15 essential nodes**, but the 6-section baa unit currently
**presents and records reps on only 7** of them: `baa.teachCard.meet`, `baa.traceLetter.isolated`,
`baa.traceLetter.initial`, `baa.traceLetter.medial`, `baa.connectWord.baab`,
`baa.writeWord.dictation`, `baa.writeLetter.fromSound`. The other 8 essential exercises
(`writeLetter.fromPicture`/`writeForm`, `connectWord.kitaab`, `completeWord.middle`,
`writeWord.copy`/`picture`, `buildSentence.hear`/`picture`) are not surfaced by the current UI.

So `isMasteryMet` over ALL 15 essential nodes can never be satisfied by this UI. The star is
therefore gated on `isMasteryMetForPresented(graph, reps, presentedIds)` — mastery of the
essential exercises the unit actually teaches. The signed `curriculum_graph.json` and the
original `isMasteryMet` are unchanged. **Surfacing the remaining 8 essential exercises is a
content-coverage task for the owner-mother + a later phase** (it grows the unit, not the graph).
When those exercises are added, they record reps through the same chokepoint and the star
condition tightens automatically.

## Verification

- `flutter analyze`: **0 errors** (56 pre-existing warnings/infos untouched).
- `flutter test test/features/letter_unit/ test/curriculum/ test/tutor/`: **231 passed, 4 failed**.
  All 4 failures are pre-existing drift, independently confirmed (no new failures):
  `alif_reference_test` ×2 (geometry drift), `reference_overlay_golden_test` (golden font drift),
  `meet_section_test` Test 1 (door-image `Image.asset` render in the test env).
- Star fires only on real clean-reps (mastery test drives the scoring path); click-through with
  unmet reps records NO star.

## Deviations

- **T3 bounded to the per-section seam** by the owner's keep-sections decision (documented in
  `_onNodePassed`). Full per-exercise agent-driven navigation would be the flat rewrite that was
  explicitly declined.
- **T5 scoped star** is an interim (flagged above) — required because the UI under-covers the
  signed essential set; it does not modify signed pedagogy.

## Self-Check: PASSED

All 12 files changed as described; analyze clean; 231 tests pass with only the 4 documented
pre-existing failures; no iOS tooling noise committed (Android-only).
