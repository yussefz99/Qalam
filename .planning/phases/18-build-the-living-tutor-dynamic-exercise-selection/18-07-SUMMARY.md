---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 07
subsystem: ui
tags: [selection-policy, dead-wire, remediation-arc, anti-boredom, micro-drills, live-path, riverpod, drift-resume, offline-parity, non-pii]

# Dependency graph
requires:
  - phase: 18
    plan: 01
    provides: "the RED contract this plan greens — selection_rails_property (R5), offline_floor (R6), microdrill_selection (R3) turned green with ZERO test edits"
  - phase: 18
    plan: 04
    provides: "SelectionPolicy.narrow -> PolicyOutcome{candidates,nextArc,targetCriterion,whyFacts}, ArcState, ChildModelSnapshot, SessionAttempt, kArcEntryFailStreak/kArcMaxAttempts"
  - phase: 18
    plan: 06
    provides: "ChildModelRepository/childModelProvider (profile mirror), ArcStateRepository (D-12 resume), TutorFacts.profile wire field"
  - phase: 15
    provides: "CurriculumGraph.isLegalSelection rail, CurriculumGraphWalker, RouterExerciseSelector seam, GraphPosition, LetterUnitController resume/mastery"
  - phase: 17
    provides: "per-criterion LetterScore.criteria + weakestCriterion the policy targets + the CheckResult carries"
provides:
  - "The two-timescale selection brain DRIVES the live path online + offline identically — the Phase-15 dead wire is CLOSED and RENDERED (proven by widget-level live-path tests, not only unit tests)"
  - "Candidate-aware RouterExerciseSelector: accept the agent pick iff it is a policy candidate AND graph-legal, else the walker over the SAME narrowed set (R5); CurriculumGraphWalker.selectFrom + legality-hardened selectNext"
  - "D-08 micro-drill scoring in the validator (spotlighted criterion owns pass/fail) + ExerciseSpec/Exercise type+criteria wiring"
  - "LetterUnitController orchestration: SelectionPolicy.narrow once per feedback moment, candidates -> facts.legalNextExerciseIds, arc persisted (D-12), profile threaded (R2, non-blocking), session-scoped SessionAttempt store, nextReady await"
  - "exercise_presenter.presentGraphExercise — renders ANY graph node through the SAME ExerciseScaffold; the shell renders the presenter override once selection is active (selectionActive), ribbon follows, graph-exhausted -> Mastery"
  - "write_surface writtenWords wiring (base order / buildSentence is passable) + the offline authored WHY template (D-10)"
affects: [18-10, 18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Candidate-aware selection: the policy NARROWS, the rail decides legality — accept-if-candidate-AND-legal, else the walker over the SAME set (defense in depth, offline parity by construction D-11)"
    - "Two-step feedback moment: beginSelection (narrow once + record the attempt) BEFORE the coach facts, selectNext (thread the decision + persist the arc) AFTER — one narrow per moment, cached"
    - "Render swap on the CONTINUE CTA, never at verdict time: a shell-local _presentedId (changes only on onNext) keyed graph:<id> keeps the feedback moment intact"
    - "advanceOnFix: in selection mode the fix CTA advances to the SELECTED node so the arc / anti-boredom actually change what renders after a same-criterion streak"

key-files:
  created:
    - lib/features/letter_unit/exercise_presenter.dart
    - test/core/exercise_engine/microdrill_validator_test.dart
    - test/tutor/offline_why_template_test.dart
    - test/features/letter_unit/agent_pick_live_path_test.dart
    - test/features/letter_unit/fail_path_selection_test.dart
    - test/features/letter_unit/exercise_presenter_test.dart
    - test/features/letter_unit/live_fail_streak_scenario_test.dart
    - test/features/letter_unit/live_selection_shell_test.dart
  modified:
    - lib/tutor/exercise_selector_provider.dart
    - lib/curriculum/curriculum_graph_walker.dart
    - lib/core/exercise_engine/exercise_validator.dart
    - lib/core/exercise_engine/exercise_check.dart
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - lib/features/letter_unit/widgets/write_surface.dart
    - lib/features/letter_unit/exercise_spec_adapter.dart
    - lib/models/exercise.dart
    - test/tutor/tutor_facts_builder_test.dart

key-decisions:
  - "RouterExerciseSelector keeps the single-arg RouterExerciseSelector(graph) constructor (the RED contract calls it) + OPTIONAL named arc/profile/sessionHistory so the controller threads the live context; it narrows internally and degrades to walker.selectFrom(candidates)"
  - "The walker's fail path is legality-hardened (rem-if-legal else current-if-legal else forward) — the old `remediateOneTier ?? current` could hand back an ILLEGAL node; the rails property (200 seeded cases) demands legal-only. All 3 pinned walker fail-tests use legal targets, so no regression"
  - "selectNext narrows ONCE (beginSelection) and caches PolicyOutcome; the pick routes through the candidate-aware selector; both narrows use the SAME arc/profile/session context so candidates + nextArc are identical"
  - "The render swap uses a shell-local _presentedId (not state.currentExerciseId) so the swap happens on the CONTINUE CTA (awaits nextReady), never at verdict time — the feedback moment survives"
  - "D-08 reads the spotlighted CRITERION from ExerciseSpec.criteria.first (the scorer criterion), not the display-only spotlightZone label (dot/bowl/start)"
  - "requirements-completed left [] following the phase precedent (18-01/04/06 all left []): the provisional kArcEntryFailStreak/kArcMaxAttempts are signed:false (mother sign-off at 18-11) and the Cloud Run re-deploy is pending; the verifier / 18-11 flips R1/R4/R5/R6"

patterns-established:
  - "Live-path widget proof is MANDATORY for any 'wire into the live path' plan (the phase15-dynamic-selection dead-wire lesson): a test that pumps the real screen and asserts the policy's pick is what RENDERS, not only selector/controller unit tests"
  - "The offline walker + the online router choose from the SAME SelectionPolicy candidate set — offline parity by construction (D-11)"

requirements-completed: []

# Metrics
duration: 67min
completed: 2026-07-11
---

# Phase 18 Plan 07: Wire the Living Tutor into the Live Selection Path Summary

**The two-timescale selection brain now DRIVES what the child sees next — online and offline identically: the coach's `TutorDecision` reaches the selector on the live path (the Phase-15 dead wire is closed AND rendered), selection runs on every feedback moment (pass and fail), the rails hold under a 200-case property test, remediation arcs persist to Drift, and micro-drills score by their target criterion — all proven by widget-level live-path tests.**

## Performance

- **Duration:** ~67 min
- **Started:** 2026-07-11T14:20:19Z
- **Completed:** 2026-07-11T15:27:34Z
- **Tasks:** 3 (all `tdd="true"`)
- **Files modified:** 19 (8 created, 11 modified)

## Accomplishments

- **Task 1 — candidate-aware selector + walker + D-08 + offline WHY:** `RouterExerciseSelector` now narrows to the pure `SelectionPolicy` candidate set and accepts an agent pick ONLY when it is a policy candidate AND graph-legal, else degrades to `walker.selectFrom(candidates)` — the offline floor is identical to the online degrade by construction (D-11). The walker's fail path is legality-hardened (never presents an illegal remediation). `validateExercise` scores a `type=='microDrill'` by its spotlighted criterion only (D-08). `authoredWhyLine` is the offline D-10 WHY template. Greened `selection_rails_property` (R5, 200 seeded cases: 0 illegal picks accepted) with zero test edits; `offline_floor`/`microdrill_selection`/`durable_layers` stay green.
- **Task 2 — CLOSE the Phase-15 dead wire:** the coach's `TutorDecision` is handed to `controller.selectNext(facts, decision:)` in the scaffold's `brain.next().then()` (was displayed-only in the demo strip). Selection runs on pass AND fail. The controller invokes `SelectionPolicy.narrow` ONCE per moment, feeds the candidates to `facts.legalNextExerciseIds`, populates `clearedTiers`/`clearedCompetencies` (were dead `const []`), persists `nextArc` via `ArcStateRepository` (D-12), threads the profile mirror (R2, non-blocking), holds a session-scoped `SessionAttempt` store (survives scaffold key swaps), and exposes `Future<String?> nextReady`. Proven by `agent_pick_live_path` (agent legal pick ≠ walker → that is the cursor; illegal → walker) and `fail_path_selection`.
- **Task 3 — RENDER the selection:** `exercise_presenter.presentGraphExercise` renders ANY of the graph's nodes through the SAME `ExerciseScaffold` (keyed `graph:<id>`); the shell renders the presenter override INSTEAD of `_section(index)` once `selectionActive`, with the swap on the CONTINUE CTA (awaits `nextReady`) so the feedback moment survives; the ribbon FOLLOWS the presented node (competency→section) and is display-only in selection mode; graph exhausted → Mastery (star reachable). `write_surface` wires `writtenWords` for `base=='order'` (buildSentence is now passable — the dead end is removed). Proven end-to-end by the `agent_pick` RENDER group, the `live_fail_streak` composition proof, presenter render coverage, ribbon display-only, and graph-exhausted→Mastery.

## Task Commits

Each task committed atomically (GREEN leg — the RED contract was authored in 18-01):

1. **Task 1: candidate-aware selector + walker + D-08 drill scoring + offline WHY** — `3b37fb9` (feat)
2. **Task 2: CLOSE the Phase-15 dead wire — thread the coach decision through the live screen, select on pass AND fail, arc persistence** — `88443d1` (feat)
3. **Task 3: RENDER the selection — exercise presenter + shell override + ribbon follow** — `9103710` (feat)

## Files Created/Modified

- `lib/curriculum/curriculum_graph_walker.dart` — `selectFrom(candidates,...)` + legality-hardened `selectNext` fail path (Rule-1 correctness)
- `lib/tutor/exercise_selector_provider.dart` — candidate-aware `RouterExerciseSelector` (accept-if-candidate-AND-legal, else `selectFrom`) + optional arc/profile/sessionHistory + `authoredWhyLine` (offline D-10)
- `lib/core/exercise_engine/exercise_validator.dart` — `_validateMicroDrill` (D-08 spotlight-owns-verdict)
- `lib/core/exercise_engine/exercise_check.dart` — `ExerciseSpec` gains `type` + `criteria` + `spotlightCriterion`
- `lib/features/letter_unit/letter_unit_controller.dart` — `beginSelection` (narrow once + record attempt), async decision-threaded `selectNext` (router + arc persist + `nextReady`), `_sessionHistory`/`_sessionArc`/`_profileSnapshot`, `selectionActive`
- `lib/features/letter_unit/letter_unit_screen.dart` — presenter override render, `_advanceSelection`, `_followRibbon`, ribbon display-only gate; `_onNodePassed` drops the decision-less T3
- `lib/features/letter_unit/exercise_presenter.dart` (NEW) — `presentGraphExercise` + fallbacks
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — thread the decision into `selectNext`, candidates+cleared+profile into the facts, `advanceOnFix`
- `lib/features/letter_unit/widgets/write_surface.dart` — `writtenWords` for `base=='order'`
- `lib/features/letter_unit/exercise_spec_adapter.dart` + `lib/models/exercise.dart` — carry `type`+`criteria` for live D-08

## Decisions Made

- **The walker's fail path is legality-hardened.** The property test proved `remediateOneTier ?? current` could return an ILLEGAL node (e.g. `connectWord.baab` when `positionalForms` uncleared). Now it returns the legal remediation, else the legal drill-in-place, else the nearest legal forward — never a dead-end illegal id. All three pinned walker fail-tests use legal targets, so no regression.
- **One narrow per moment, two touchpoints.** `beginSelection` narrows + caches BEFORE the coach facts (so `legalNextExerciseIds` = candidates); `selectNext` routes the decision + persists the arc AFTER. Both use the same arc/profile/session context → identical candidates.
- **Render swaps on the CONTINUE CTA, never at verdict.** A shell-local `_presentedId` (distinct from the cursor) changes only on `_advanceSelection`, so a fresh `graph:<id>` scaffold mounts on Next — the pass star / coach line / TTS are never destroyed at verdict time.
- **`requirements-completed: []`** — phase precedent (18-01/04/06). R1/R4/R5/R6 are functionally delivered on the client live path, but the provisional constants are `signed:false` (mother sign-off at 18-11) and the Cloud Run re-deploy is pending; the verifier / 18-11 flips the boxes.

## Deviations from Plan

### Auto-fixed / reconciled

**1. [Rule 1 - Bug] Legality-hardened the walker's fail path**
- **Found during:** Task 1
- **Issue:** `CurriculumGraphWalker.selectNext`'s `remediateOneTier(current) ?? current` could return an illegal node given a random cleared state — the rails property (R5) requires legal-only, and presenting an unreachable/unmet-prereq exercise is a correctness bug.
- **Fix:** Return the legal remediation, else the legal drill-in-place, else the nearest legal forward (`_isLegal` gate added).
- **Files modified:** lib/curriculum/curriculum_graph_walker.dart
- **Verification:** `selection_rails_property` (200 cases) green; all `curriculum_graph_walker_test` fail-cases green.
- **Committed in:** `3b37fb9`

**2. [Rule 2 - Missing critical] Added `advanceOnFix` so the arc RENDERS**
- **Found during:** Task 3
- **Issue:** The plan's render swap fires on the pass CTA, but a FAIL keeps the fix-state "Try again" = clear-in-place — so the anti-boredom / remediation arc would NEVER change what the child sees after a same-criterion streak (the arc's whole point).
- **Fix:** Added `advanceOnFix` to `ExerciseScaffold` (presenter sets it true) so the fix CTA advances to the SELECTED node; Clear still retries in place. Legacy sections keep clear-in-place (default false).
- **Files modified:** lib/features/letter_unit/widgets/exercise_scaffold.dart, lib/features/letter_unit/exercise_presenter.dart
- **Verification:** `live_fail_streak_scenario` proves the third render ≠ the identical failed exercise.
- **Committed in:** `9103710`

**3. [Rule 3 - Reconciliation] Kept the screen's `_section` fallback builders + `_presentedExerciseIds()` scoped**
- **Found during:** Task 3
- **Issue:** Plan action (f)/(a) suggested moving the screen's fallback builders into the presenter and extending `_presentedExerciseIds()`.
- **Fix:** The presenter carries its OWN fallback resolution (the screen keeps its `_section` fallbacks, unchanged) to reduce blast radius on the working shell; `_presentedExerciseIds()` is left scoped so the star CONDITION is unchanged (matching the plan's "star condition unchanged" clause + the existing T5 INTERIM note). Expanding the presented set is a future content-coverage task.
- **Files modified:** (none beyond the presenter)
- **Verification:** `letter_unit_screen_test` (mastery gate) green; graph-exhausted→Mastery test green.
- **Committed in:** `9103710`

**4. [Rule 3 - Reconciliation] Controller accessors are methods, not getters**
- **Found during:** Task 2
- **Issue:** `nextReady`/`sessionHistory`/`profileFacts` as getters trip the un-suppressible `avoid_public_notifier_properties` riverpod_lint (3.1.3 honors no ignore form), and `flutter analyze` exits 1 on info lints in this project.
- **Fix:** Exposed them as zero-arg methods (matching the controller's existing public-method style).
- **Files modified:** lib/features/letter_unit/letter_unit_controller.dart (+ callers)
- **Verification:** `flutter analyze` clean on the changed files.
- **Committed in:** `88443d1`

---

**Total deviations:** 4 (1 Rule 1 correctness, 1 Rule 2 missing-critical, 2 Rule 3 reconciliations). No scope creep — no new packages, no wire/schema change beyond `Exercise.criteria` (additive, non-PII).

## Issues Encountered

- **2 pre-existing baseline failures in `test/features/` (NOT caused by this plan):** `meet_section_test` (`img.door` image-caption assertion in the teachCard section) and `mastery_celebration_golden_test` (the documented font-drift golden). Both fail identically at the pre-Task-2 state (verified by stashing the Task-2 changes and re-running) — part of the phase's known baseline. Left untouched per the SCOPE BOUNDARY rule. `test/features/` = +147 / -2 (was +138 / -2; +9 new tests, zero new failures).

## Known Stubs

None new. The baa micro-drill nodes (`assets/curriculum/exercises.json`) and the provisional `kArcEntryFailStreak`/`kArcMaxAttempts` remain `signed:false` — the tracked mother-sign-off pedagogy gates at 18-11 (D-02/D-04), not stubs that block this plan's goal. `_presentedExerciseIds()` stays the scoped T5 set (the star condition is deliberately unchanged — see Deviation 3).

## Threat Flags

None — no security-relevant surface beyond the plan's `<threat_model>`. The agent pick is re-checked against `isLegalSelection` before honoring it (T-18-07-01, the 200-case property proves 100% legal); the D-08 drill rule lives in the scorer/validator, never an agent call (T-18-07-02); the profile refresh is fire-and-forget and never blocks the pick (T-18-07-03); the offline walker consumes the SAME candidates (T-18-07-04). `Exercise.criteria` is a fixed-vocabulary non-PII curriculum field.

## Next Phase Readiness

- **18-10 (micro-drill Spotlight chrome):** the micro-drill renders through the presenter's default scaffold branch today; 18-10 layers the Spotlight UI on top. The D-08 verdict is already scorer-owned.
- **18-11 (HUMAN-UAT + deploy):** the mother signs the provisional `kArcEntryFailStreak`/`kArcMaxAttempts` + the micro-drill copy + the selection gold set; the single Cloud Run re-deploy carries the wire fields live; the verifier flips R1/R4/R5/R6.
- No blockers. No new packages.

## Self-Check: PASSED

- All 8 created files present on disk (verified).
- All 3 task commits present in git history: `3b37fb9`, `88443d1`, `9103710`.
- Verification suite green: `selection_rails_property` + `offline_floor` + `across_session_memory` + `microdrill_selection` + `durable_layers_no_agent_imports` + `microdrill_validator` + `exercise_validator` + `tutor_facts_builder` (45 passed). Live-path proofs green: `agent_pick_live_path` (cursor + RENDER), `fail_path_selection`, `live_fail_streak_scenario`, `exercise_presenter`, `live_selection_shell`. `test/features/` = +147 / -2 (the 2 are the known baseline, unchanged). `flutter analyze` clean on all changed lib files (only pre-existing brace/null-aware infos remain).

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
