---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 04
subsystem: curriculum
tags: [selection-policy, remediation-arc, anti-boredom, micro-drills, two-timescale, pure-dart, offline-floor, non-pii]

# Dependency graph
requires:
  - phase: 18
    plan: 01
    provides: "the RED contract this plan greens — SelectionPolicy.narrow -> PolicyOutcome{candidates, nextArc, targetCriterion, whyFacts}, ArcState, ChildModelSnapshot, kArcEntryFailStreak/kArcMaxAttempts (zero test edits)"
  - phase: 18
    plan: 02
    provides: "the criterion-tagged microDrill nodes (baa.microDrill.{dot,bowl,start}, criterion dot/shape/strokeOrder) the drill injection reads"
  - phase: 15
    provides: "CurriculumGraph.isLegalSelection rail (G4/G5/G6), CurriculumGraphWalker reachable-forward + remediateOneTier, GraphPosition"
  - phase: 17
    provides: "the five scorer criteria + TutorFacts.weakestCriterion the policy targets"
provides:
  - "SelectionPolicy — the pure-Dart deterministic selection brain: narrow(facts, position, {arc, profile, sessionHistory}) -> PolicyOutcome{candidates, nextArc, targetCriterion, whyFacts}, consumed identically online + offline (D-09/D-11)"
  - "ONE fail-streak counter (kArcEntryFailStreak same-criterion fails) driving BOTH anti-boredom exclusion (R1) AND arc entry (R4) — D-02"
  - "The confidence-rebuilding remediation arc SM: entry -> stepDown -> rebuild -> retryOriginal, clean-win-on-original exit + kArcMaxAttempts floor-guard trace (R4/D-04, never loops)"
  - "Micro-drill injection off graph.drillForCriterion(letter, criterion) for a dominant failing criterion (R3, enrichment — never gates the star)"
  - "Pure value types: ArcState (+ ArcStep + provisional signed:false constants), ChildModelSnapshot (fixed-vocab across-session profile + toMap wire mirror), SessionAttempt (criterion-tagged client-only fail-streak source)"
  - "GraphNode.criterion parse + CurriculumGraph.drillForCriterion(letterId, criterion) lookup (additive; zero rail-semantics change)"
affects: [18-05, 18-06, 18-07, 18-09, 18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure durable-layer selection brain in lib/curriculum — narrows, never widens, the isLegalSelection rail (every candidate re-checked; defense in depth, T-18-04-01)"
    - "SessionAttempt (criterion-tagged, client-only) replaces facts.trajectory as the fail-streak source — AttemptFact lacks a criterion + is per-widget-instance; zero 422 exposure"
    - "Provisional signed:false named constants (kArcEntryFailStreak/kArcMaxAttempts) — never magic numbers; mother-signed at 18-11"
    - "Arc state threaded through narro()'s nextArc so a stateful fail-streak simulation drives entry->stepDown->rebuild->retryOriginal without a separate advance API"

key-files:
  created:
    - lib/curriculum/arc_state.dart
    - lib/curriculum/child_model_snapshot.dart
    - lib/curriculum/session_attempt.dart
    - lib/curriculum/selection_policy.dart
  modified:
    - lib/curriculum/curriculum_graph.dart

key-decisions:
  - "narrow() signature = narrow(TutorFacts, GraphPosition, {ArcState? arc, ChildModelSnapshot? profile, List<SessionAttempt>? sessionHistory}) — all extra params OPTIONAL/named so the RED contract's narrow(facts, position) and narrow(facts, position, arc:) both compile (the plan's positional-param sketch reconciled to the test's actual call shapes, zero test edits)"
  - "ArcState.step is a String GETTER over an internal ArcStep enum field (stepValue) — the RED contract compares arc.step == 'retryOriginal' and adds it to a List<String>, so step must be a String; ArcStep is still defined + used (in transitions), satisfying Task 1's acceptance"
  - "The fail-streak counter reads a threaded tracking-arc + criterion-tagged sessionHistory + (single-call fallback) the dominant recent-mistake count — NEVER facts.trajectory (per-widget-instance, criterion-less); the must_have honored literally"
  - "ChildModelSnapshot ships schemaVersion + toMap() NOW (beyond the plan's {strengths,struggles,perCriterion} sketch) so across_session_memory_test greens with ZERO edits once 18-05/06 add TutorFacts.profile — the 18-01 executable contract requires them"
  - "PolicyOutcome exposes arcStep as a getter over nextArc?.step (the documented 18-01 field) rather than a stored field — no test reads it, but the contract is honored"

patterns-established:
  - "Two-timescale selection: within-session SessionAttempt streak + across-session ChildModelSnapshot struggles, both feeding whyFacts (criterion:/struggle:/arcStep:/reason: non-PII facts for the D-10 WHY line)"
  - "Arc floor guard: a floor-fail at retryOriginal OR the kArcMaxAttempts ceiling lands the first legal traceLetter node and ends the arc warm — bounded remediation by construction (T-18-04-03)"

requirements-completed: []

# Metrics
duration: 18min
completed: 2026-07-11
---

# Phase 18 Plan 04: The Selection Brain — SelectionPolicy Summary

**The deterministic, rail-bounded selection intelligence now exists as a pure-Dart `SelectionPolicy.narrow` (lib/curriculum): ONE same-criterion fail-streak counter drives BOTH anti-boredom exclusion (R1) and entry into a confidence-rebuilding remediation arc (entry→stepDown→rebuild→retryOriginal with a floor-guard trace, R4/D-04), a dominant failing criterion injects its micro-drill (R3), every candidate is re-checked against `isLegalSelection` — all consumed identically online and offline (D-11), all provisional-value gated, with ZERO curriculum-ban guard change and ZERO wire/422 exposure.**

## Performance

- **Duration:** ~18 min
- **Completed:** 2026-07-11
- **Tasks:** 2
- **Files modified:** 5 (4 created, 1 modified)

## Accomplishments

- **Pure value types (Task 1):** `ArcState` {active, step, targetCriterion, exerciseToRetry, failStreak, attempts} + `ArcStep` enum + stepDown/rebuild/retry transition helpers + provisional `signed:false` constants `kArcEntryFailStreak`(2)/`kArcMaxAttempts`(5); `ChildModelSnapshot` {strengths, struggles, perCriterion, schemaVersion} + `empty()` + `toMap()` wire mirror; `GraphNode.criterion` parse + `CurriculumGraph.drillForCriterion(letterId, criterion)`. Additive — zero change to `essentialNodes`/`isLegalSelection` semantics; the strict `lib/curriculum` durable-layer ban stays green with **zero guard change**.
- **The selection brain (Task 2):** `SelectionPolicy.narrow` composes the graph-legal forward+remediation set with the two-timescale signal. **ONE counter (D-02):** `kArcEntryFailStreak` same-criterion fails EXCLUDE the identical exercise (R1) AND enter the arc targeting that criterion (R4). **Arc SM (R4/D-04):** entry→stepDown(micro-drill)→rebuild→retryOriginal; a clean win on the ORIGINAL exits, a floor-fail lands the first legal `traceLetter` and ends warm within `kArcMaxAttempts` — never a loop. **Drill injection (R3):** a dominant failing criterion adds `graph.drillForCriterion` (enrichment). **Defense in depth (T-18-04-01):** every emitted candidate re-checked with `isLegalSelection`.
- **The AttemptFact criterion-gap fix:** `SessionAttempt` (criterion-tagged, CLIENT-ONLY) is the fail-streak source instead of `facts.trajectory` (per-widget-instance, criterion-less). It never crosses the wire — `AttemptFactIn`/422 `extra=forbid` lockstep untouched, **zero 422 exposure**.

## Task Commits

Each task was committed atomically (GREEN leg — the RED phase was authored in 18-01):

1. **Task 1: pure ArcState + ChildModelSnapshot value types + graph criterion-tag parse** — `13ff819` (feat)
2. **Task 2: SelectionPolicy.narrow — anti-boredom + drill injection + remediation arc** — `61dcd04` (feat)

## Files Created/Modified

- `lib/curriculum/arc_state.dart` — pure `ArcState` + `ArcStep` enum + transition helpers + `kArcEntryFailStreak`/`kArcMaxAttempts` (signed:false); no forbidden import
- `lib/curriculum/child_model_snapshot.dart` — fixed-vocab non-PII `ChildModelSnapshot` + `empty()` + `toMap()` (mirrors the wire `TutorFacts.profile` field 18-05 adds)
- `lib/curriculum/session_attempt.dart` — criterion-tagged, client-only `SessionAttempt` fail-streak source (never wire-bound)
- `lib/curriculum/selection_policy.dart` — `SelectionPolicy.narrow` + `PolicyOutcome`; re-exports the three value types so one import satisfies the RED contract
- `lib/curriculum/curriculum_graph.dart` — `GraphNode.criterion` (nullable) parse + `drillForCriterion(letterId, criterion)`; additive, rail-semantics unchanged

## Decisions Made

- **`narrow()` extra params are OPTIONAL/named.** The plan sketched a positional `narrow(facts, position, profile, arc, sessionHistory)`; the RED contract actually calls `narrow(facts, position)` and `narrow(facts, position, arc: arc)`. Reconciled to `{ArcState? arc, ChildModelSnapshot? profile, List<SessionAttempt>? sessionHistory}` so both compile with zero test edits.
- **`ArcState.step` is a `String` getter over an `ArcStep` enum field.** The RED contract does `arc.step == 'retryOriginal'` and `List<String>[arc.step]`, so `step` must be a String; `ArcStep` is still declared + used in transitions (Task 1 acceptance: "defines ArcStep with entry/stepDown/rebuild/retryOriginal").
- **Fail-streak source is `SessionAttempt` + the threaded tracking-arc, NEVER `facts.trajectory`.** The single-call unit contract (no session store threaded) falls back to the dominant recent-mistake COUNT (`recentMistakes`, the derived struggle signal) — deliberately not `facts.trajectory`, honoring the must_have literally.
- **`ChildModelSnapshot` ships `schemaVersion` + `toMap()` now.** Beyond the plan's `{strengths,struggles,perCriterion}` sketch, because `across_session_memory_test` (greened by 18-05/06 with zero test edits) constructs `const ChildModelSnapshot(... schemaVersion: 1)` and calls `.toMap()`. The 18-01 executable contract requires them, so they land here (the file's home plan).

## Deviations from Plan

### Auto-fixed / reconciled (all necessary to honor the 18-01 zero-test-edit contract)

**1. [Rule 3 - Blocking] `narrow()` signature reconciled to the RED test's actual call shapes**
- **Found during:** Task 2
- **Issue:** The plan's positional-param signature would not compile against the RED tests' `narrow(facts, position)` / `narrow(facts, position, arc:)` calls.
- **Fix:** Made `arc`/`profile`/`sessionHistory` optional named params.
- **Files modified:** lib/curriculum/selection_policy.dart
- **Verification:** all three RED selection tests green with zero edits.
- **Committed in:** `61dcd04`

**2. [Rule 2 - Missing critical functionality] `ChildModelSnapshot` gained `schemaVersion` + `toMap()`**
- **Found during:** Task 1
- **Issue:** The plan sketched only `{strengths,struggles,perCriterion}`, but the 18-01 `across_session_memory_test` (a zero-test-edit downstream contract) needs `schemaVersion:` + `.toMap()`.
- **Fix:** Added both (pure, additive) so 18-05/06 green that test with no edits once they add `TutorFacts.profile`.
- **Files modified:** lib/curriculum/child_model_snapshot.dart
- **Verification:** `across_session_memory_test` now RED for the SINGLE intended reason (missing `TutorFacts.profile`), not for `ChildModelSnapshot` shape.
- **Committed in:** `13ff819`

**Total deviations:** 2 reconciliations (1 Rule 3, 1 Rule 2). No scope creep — no new packages, no wire/schema change, all inside lib/curriculum.

## Issues Encountered

- **4 pre-existing curriculum baseline reds (out of scope, NOT fixed).** `test/curriculum/` runs `+87 / -4`: `reference_overlay_golden_test` (alif golden font-drift — the documented golden-drift baseline), `alif_reference_test` ×2 (alif centerline geometry), and `all_letters_validation_test` (alif-unsigned `signedOff`). Verified NONE reference the symbols I added (`criterion`/`drillForCriterion`); my change to `curriculum_graph.dart` is additive metadata and is behaviorally inert for them. These are part of the phase's "748/8-known" baseline (17-10 STATE) + the golden-font-drift + alif-unsigned reds logged in 18-02/18-03. Left untouched per the SCOPE BOUNDARY rule.
- **`curriculum_graph_test` (the test that DOES exercise my change) passes** (22 nodes / 3 microDrill, essentialNodes 70/30, tierOf, nextForward/remediateOneTier all green).

## Downstream RED contract (intended state — do NOT flag as regression)

The other three `selection_policy.dart`-importing tests remain in their intended Wave state; each greens in a LATER plan with zero test edits:

- `across_session_memory_test.dart` — RED by missing `TutorFacts.profile` param (18-05 adds the wire field, 18-06 the Drift mirror). `ChildModelSnapshot` is already contract-complete.
- `selection_rails_property_test.dart` — RED by the router not yet narrowing to policy candidates (18-07 wires `RouterExerciseSelector` to `SelectionPolicy`).
- `offline_floor_test.dart` — **greened early (bonus)**: both tests pass now (`narrow`/`selectNext` are synchronous, candidates non-null); the plan attributed it to 18-06/18-07, but no wire change was needed — greening it early is not a regression.

## Known Stubs

None. `SelectionPolicy` is fully implemented. `kArcEntryFailStreak`/`kArcMaxAttempts` are PROVISIONAL (`signed:false`) by design — a tracked mother-sign-off pedagogy gate at 18-11 (D-02/D-04), not a stub that blocks the plan's goal. The arc/anti-boredom/drill behaviour is complete and rail-bounded regardless of the final numbers.

## Threat Flags

None — no new security-relevant surface beyond the plan's `<threat_model>`. `selection_policy.dart` is a pure `lib/curriculum` citizen (T-18-04-02: the strict durable-layer ban is non-vacuous + green with zero guard change); every candidate is re-checked with `isLegalSelection` (T-18-04-01); the arc is bounded by `kArcMaxAttempts` + the floor guard (T-18-04-03). No wire field added — the 422/`extra=forbid` lockstep is untouched.

## Next Phase Readiness

- **18-05 (server evidence deriver + wire field):** adds `TutorFacts.profile` (mirroring `ChildModelSnapshot.toMap()`) → greens `across_session_memory` test 1 + `payload_nonpii` + server `test_schema_forbid`.
- **18-06 (Drift child-model mirror):** decodes `ChildProfileMirror`/`ArcStateRows` into `ChildModelSnapshot`/`ArcState` and threads them into `narrow` → greens `across_session_memory` test 2 + `offline_floor` (already green).
- **18-07 (router wiring):** wires `RouterExerciseSelector` to consume `SelectionPolicy.narrow` candidates + persists `nextArc`/`SessionAttempt` → greens `selection_rails_property`; live-path widget proof mandatory (phase15-dynamic-selection dead-wire lesson).
- **18-11 (HUMAN-UAT):** the mother signs `kArcEntryFailStreak`/`kArcMaxAttempts` + the micro-drill copy + the selection gold set.
- No blockers. No new packages. No lib/ code outside `lib/curriculum/` changed.

## Self-Check: PASSED

- All 5 files present on disk (verified): `arc_state.dart`, `child_model_snapshot.dart`, `session_attempt.dart`, `selection_policy.dart`, `curriculum_graph.dart`.
- Both task commits present in git history: `13ff819`, `61dcd04`.
- Task 1 verify: `durable_layers_no_agent_imports_test` green (4/4) + `flutter analyze` on the 3 files "No issues found"; `curriculum_graph_test` green.
- Task 2 verify: `selection_policy_test` (3) + `microdrill_selection_test` (3) + `remediation_arc_test` (3) + `durable_layers` (4) = **13/13 green** with zero test edits; `flutter analyze lib/curriculum/` "No issues found"; `isLegalSelection` present (4×); `kArcEntryFailStreak`/`kArcMaxAttempts` referenced by name (no bare literals).

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
