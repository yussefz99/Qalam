---
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
plan: 03
subsystem: curriculum
tags: [curriculum, tutor, offline, dart, graph-walk, mastery, riverpod-seam]

# Dependency graph
requires:
  - phase: 15-01
    provides: "the provisional baa curriculum_graph.json asset (19 baa.* nodes, competency/tier/minCleanReps, signedOff:false) + the RED Dart contract (curriculum_graph_test / curriculum_graph_walker_test / mastery_condition_test) this plan turns GREEN"
  - phase: 14-tutor-grounded-agent-spine
    provides: "TutorFacts (the non-PII FACTS chokepoint the walker reads), the TutorBrain/AuthoredFallbackBrain seam shapes mirrored here, the durable_layers_no_agent_imports guard extended here"
provides:
  - "lib/curriculum/curriculum_graph.dart — pure-Dart CurriculumGraph.fromJson parser: essentialNodes (70/30), tierOf, signedOff, nextForward, remediateOneTier; GraphNode/GraphCompetency value types + kTierOrder"
  - "lib/curriculum/curriculum_graph_walker.dart — the ExerciseSelector selection seam + GraphPosition cursor + CurriculumGraphWalker (deterministic offline walk: advance on pass, remediate one tier down on fail, drill in place at the manqul floor)"
  - "lib/curriculum/mastery_condition.dart — isMasteryMet, the on-device deterministic star condition over essential nodes only (D-06, ADR-014 trust boundary)"
  - "the no-agent-imports guard extended to cover lib/curriculum/ with a STRICTER cloud/Firebase/network/render/persistence ban"
affects: [15-04, 15-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Selection seam on a SEPARATE axis from coaching — ExerciseSelector (next-exercise) parallels TutorBrain (coach-the-current); the two degrade independently (selection→CurriculumGraphWalker, coaching→AuthoredFallbackBrain)"
    - "Pure-Dart parser hermetic from a Map (fromJson(Map), no rootBundle inside) so it stays unit-testable; the production loader hands decoded bytes in"
    - "Tighter import-purity sub-guard scoped to a single dir (lib/curriculum) layered over the existing global durable-layer scan — lets lib/data keep its legit Firebase/drift while lib/curriculum stays render/cloud-free"

key-files:
  created:
    - lib/curriculum/curriculum_graph.dart
    - lib/curriculum/curriculum_graph_walker.dart
    - lib/curriculum/mastery_condition.dart
  modified:
    - test/tutor/durable_layers_no_agent_imports_test.dart

key-decisions:
  - "nextForward(id) walks the canonical declaration order of nodes (the graph IS the order); remediateOneTier(id) takes the exerciseId (single arg) and steps to the FIRST same-competency node at the next-lower tier (ghayrManzur→manzur→manqul), null at the manqul floor — both the graph test and a clean walker share that signature"
  - "GraphNode.essential is DERIVED at parse from its competency's essential flag (built once into an essentialByCompetency map) — the asset carries essential on competencies only, never duplicated per node"
  - "GraphPosition (letterId, currentExerciseId, clearedCompetencies, clearedTiers) lives in curriculum_graph_walker.dart as the durable non-PII cursor 15-04 persists in Drift and 15-05 reads"
  - "lib/curriculum gets a SEPARATE, stricter ban list (cloud_firestore/firebase/flutter-render/drift/riverpod on top of the shared agent/network/seam set) rather than tightening the global _forbidden — lib/data legitimately needs Firebase/drift, lib/curriculum must not"

patterns-established:
  - "ExerciseSelector seam: String? selectNext(TutorFacts, GraphPosition) — the offline impl mirrors AuthoredFallbackBrain's pure-deterministic shape"
  - "On-device star: isMasteryMet iterates essential nodes only; a missing clean-rep key counts as 0 so a clicked-through unit never earns the star (Pitfall 2)"

requirements-completed: [DYN-01, DYN-02]

# Metrics
duration: 5min
completed: 2026-06-27
---

# Phase 15 Plan 03: Offline-Parity Graph Walker + On-Device Mastery Condition Summary

**A pure-Dart CurriculumGraph + a deterministic CurriculumGraphWalker that drive the SAME single-source graph offline (advance on pass, remediate one tier down on fail, drill in place at the manqul floor — never the old linear order), plus isMasteryMet gating the star on the essential 70/30 core on-device — turning all 11 of 15-01's RED Dart tests GREEN with zero cloud/Firebase/network/render imports.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-27T14:55:04Z
- **Completed:** 2026-06-27T15:00:23Z
- **Tasks:** 2
- **Files created:** 3 (+ 1 modified)

## Accomplishments

- **The offline-parity slice (D-09) is real:** a baa fail re-surfaces an EASIER same-competency exercise via the walker — backward remediation working end-to-end OFFLINE with zero model. The walker reads the SAME `assets/curriculum/curriculum_graph.json` the online server rail (15-02) reads, so airplane-mode selection is as adaptive as online; on a fail it NEVER reverts to the old fixed 6-section linear sequence (Pitfall 5).
- **The star is now computable ON-DEVICE from real mastery, not navigation:** `isMasteryMet` returns true only when every essential node meets the owner-mother's clean-reps; a clicked-through (zero-rep) unit can never earn it (Pitfall 2), and enrichment (`wordBuilding`/`grammarTransform`) never gates it (the 70/30 split, D-06). The agent's `intent:"advance"` stays a suggestion — the predicate never reads a server response (ADR-014 trust boundary).
- **lib/curriculum/ is import-pure and guarded:** the existing `durable_layers_no_agent_imports_test.dart` now scans `lib/curriculum/` with a STRICTER ban (cloud-AI/Firebase/network/Flutter-render/drift/riverpod), with a non-vacuous self-test proving the matcher fires.

## Task Commits

Each task was committed atomically (the RED gate commits live in 15-01's `24be19f`; these are the GREEN-phase commits):

1. **Task 1: Pure-Dart CurriculumGraph parser + the ExerciseSelector/CurriculumGraphWalker seam** - `bbb3b73` (feat)
2. **Task 2: On-device mastery condition (D-06) + extend the no-agent-imports guard** - `0251326` (feat)

_Note: This is the GREEN side of a plan-level TDD cycle whose RED commit (`24be19f`, 15-01) authored the failing tests first. See TDD Gate Compliance below._

## Files Created/Modified

- `lib/curriculum/curriculum_graph.dart` (created, 217 lines) - Pure-Dart `CurriculumGraph.fromJson(Map)` parser. `GraphCompetency`/`GraphNode` value types + `kTierOrder = [manqul, manzur, ghayrManzur]`. Exposes `letterId`, `signedOff`, `nodes`, `competencies`, `essentialNodes` (essential==true via the competency flag), `tierOf(id)`, `competencyOf(id)`, `nextForward(id)` (next node in declaration order), `remediateOneTier(id)` (first same-competency node one tier down; null at floor/off-ramp). Defensive whitelisted parse, no rootBundle inside.
- `lib/curriculum/curriculum_graph_walker.dart` (created, 81 lines) - `GraphPosition` (the durable non-PII cursor), `abstract class ExerciseSelector { String? selectNext(TutorFacts, GraphPosition); }`, and `class CurriculumGraphWalker implements ExerciseSelector`: pass → `graph.nextForward(current)`, fail → `graph.remediateOneTier(current) ?? current`. Pure deterministic, no LLM/network.
- `lib/curriculum/mastery_condition.dart` (created, 35 lines) - `bool isMasteryMet(CurriculumGraph, Map<String,int>)` iterating essential nodes only; false the moment any essential node is below its `minCleanReps` (missing key = 0 reps). Pure, no PII, no server-response read.
- `test/tutor/durable_layers_no_agent_imports_test.dart` (modified) - Added `lib/curriculum` to `_durableDirs`, plus a new `D-06` group with a curriculum-only stricter ban list (cloud_firestore/firebase/flutter-render/drift/riverpod on top of the shared set) and a non-vacuous self-test.

## Decisions Made

- `remediateOneTier(id)` takes the **exerciseId** (single arg), matching both the graph test (`graph.remediateOneTier('baa.writeWord.dictation')`) and a clean walker call (`graph.remediateOneTier(position.currentExerciseId)`). It returns the FIRST same-competency node at the next-lower tier in declaration order — so a `ghayrManzur` dictation fail remediates to the `manzur` `writeWord.copy`, and a `manqul`-floor fail returns null → the walker drills in place.
- `nextForward(id)` walks the **canonical declaration order** of `nodes` — the graph asset's node order IS the forward order (recognize → positionalForms → copyWrite manqul→manzur→ghayrManzur → fluentReading → enrichment). No separate topological recompute needed; the asset is already authored in chain order.
- `GraphNode.essential` is **derived at parse** from the node's competency (built once into an `essentialByCompetency` map), keeping the asset's essential flag on competencies only (no per-node duplication, no drift risk).
- `lib/curriculum` got a **separate, stricter sub-guard** rather than tightening the global `_forbidden` list, because `lib/data` legitimately persists via `cloud_firestore`/`drift`/`flutter` while `lib/curriculum` must stay render/cloud/persistence-free (the on-device star/selection purity invariant, D-06).

## Deviations from Plan

None - plan executed exactly as written. All deviation rules (1-4) untriggered: the RED contract was authored in 15-01, the seam/impl shapes were fully specified in 15-PATTERNS.md, the asset already existed, and no packages were installed (T-15-SC holds).

## TDD Gate Compliance

This plan is the GREEN/REFACTOR side of a plan-level TDD cycle split across waves:
- **RED gate:** `24be19f` (15-01) — `test(15-01): RED Dart contract — graph/walker/mastery` authored all 11 failing tests first (verified RED at execution start: compile failure by missing `CurriculumGraph`/`isMasteryMet` symbols).
- **GREEN gate:** `bbb3b73` + `0251326` (this plan) — `feat(...)` commits make every RED test pass.
- **REFACTOR gate:** none needed — the implementations were minimal and clean on first pass (analyzer clean, no duplication to extract).

The RED→GREEN feat sequence is present in git history. No warning needed.

## Issues Encountered

- Running the full `test/curriculum/` directory surfaced 3 pre-existing failures (`reference_overlay_golden_test.dart` x1 — golden font drift; `alif_reference_test.dart` x2 — alif-reference shipped data). These are OUT OF SCOPE: they pre-date this plan (present on parent commit `e30e097`), live in files this plan never touched, and match the known issues in MEMORY ("golden-tests-font-drift") and the 06.1-04 SUMMARY ("4 known pre-existing out-of-scope failures: alif-reference + mastery golden"). Logged to `deferred-items.md`, not fixed (executor scope boundary). All 11 of this plan's target tests are GREEN.

## Known Stubs

None. The `assets/curriculum/curriculum_graph.json` asset ships `signedOff:false` — that is the DESIGNED owner-mother review gate from 15-01 (D-05), not a stub; Plan 15-07 owns the flip behind a human-verify checkpoint. This plan's code reads it as provisional by design and does not gate any child-facing star write on it (15-05 wires the `recordMastery` gate to `isMasteryMet`, computed from real Drift reps).

## Threat Surface

No new security-relevant surface beyond the plan's `<threat_model>`. All three mitigations are satisfied:
- **T-15-03-E** (mastery off a server CoachOut): `isMasteryMet` is pure on-device over a `Map<String,int>` of clean-reps on essential nodes only; it imports no Firebase/network and reads no server response (guarded by the extended import test).
- **T-15-03-T** (offline fallback silently linear): the walker test asserts a `ghayrManzur` fail produces a `manzur` remediation and a `manqul` fail drills in place — never the next linear section (Pitfall 5).
- **T-15-03-ID** (curriculum layer leaks PII): `lib/curriculum/` carries only tier/competency/exercise ids; the no-agent-imports guard now scans it with a stricter ban.
- **T-15-SC** (pub installs): zero packages installed.

## Next Phase Readiness

- **15-04** (Drift resume) can now persist/read `GraphPosition` (the cursor type is defined here) via the `LetterGraphPosition` table; it supplies the per-exercise clean-rep counts `isMasteryMet` consumes.
- **15-05** (selection seam wiring) can now build the `exerciseSelectorProvider` router picking the online `RemoteAgentBrain` `plan.nextExerciseId` (when graph-legal) vs. this offline `CurriculumGraphWalker`, and wire the unit-level `recordMastery` gate strictly to `isMasteryMet` (replacing `LetterUnitController._onEnterSection`'s `cleanReps:0` auto-write).
- No blockers. The graph asset stays PROVISIONAL (`signedOff:false`) until 15-07's owner-mother checkpoint.

## Self-Check: PASSED

All 3 created files + 1 modified file verified on disk; both task commits (`bbb3b73`, `0251326`) verified in git history; all 11 target tests GREEN.

---
*Phase: 15-build-dynamic-grounded-exercise-selection-on-baa*
*Completed: 2026-06-27*
