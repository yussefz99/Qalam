---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 16
subsystem: ui
tags: [teacher-margin, remediation-arc, tutor-insight, riverpod, anti-gamification, baa]

# Dependency graph
requires:
  - phase: 18
    provides: "SelectionPolicy.narrow → PolicyOutcome.arcStep/whyFacts (18-01/18-04); the LetterUnitController two-timescale selection context (18-07); the Teacher's Margin panel + TutorInsight channel (18-10); the coach rationale on the clean-pass path (18-14)"
provides:
  - "The Teacher's Margin is a single, distinct note BESIDE the writing canvas (demo Teacher's Eye strip gated out of non-demo builds)"
  - "Arc step-down narration fires from the REAL policy arcStep (micro-drills parked) — the Phase-15/dead-wire micro-drill pick dependency is gone"
  - "The WHY line varies per attempt: coach rationale verbatim → pass-appropriate line on a clean pass → authored floor only for a genuine criterion miss (no more static 'deeper bowl' skew)"
  - "A shared kDemoMode flag (lib/core/demo_flag.dart) consolidating the router + scaffold demo-gate"
affects: [18-HUMAN-UAT, phase-19-question-presentation-overhaul]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TutorInsight carries the non-PII policy signal (arcStep + whyFacts) threaded from the controller's cached PolicyOutcome — the child-facing margin narrates policy, never re-computes it"
    - "Genuine-arc guard: only a policy outcome carrying an `arcStep:` why-fact surfaces a step (a mere tracking arc / first fail returns null) — a single fail never narrates a step-down"
    - "WHY resolution as a 3-tier ladder (rationale → pass line → authored floor), the authored table demoted to a last-resort offline FLOOR"
    - "Shared compile-time DEMO flag in lib/core so demo chrome can be gated out of child-facing builds"

key-files:
  created:
    - lib/core/demo_flag.dart
  modified:
    - lib/features/letter_unit/widgets/teacher_margin_panel.dart
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/router/app_router.dart
    - test/features/letter_unit/teacher_margin_test.dart

key-decisions:
  - "Arc narration is driven by insight.arcStep guarded by an `arcStep:` why-fact (genuine arc), NOT insight.pick.contains('microDrill') — the drills are parked out of the live graph (D-03)"
  - "The targeted criterion for the WHY/header is now a certainlyWrong miss only; a fuzzy soft-band criterion no longer skews the WHY to a fixed 'shape'/'deeper bowl'"
  - "A clean pass shows a warm pass-appropriate line (_passWhy); the authored per-criterion table is the offline floor for genuine misses only"
  - "The demo Teacher's Eye strip renders only under --dart-define=DEMO=true, leaving the Teacher's Margin as the SINGLE margin surface in child-facing builds"
  - "Consolidated the duplicated kDemoMode literal into lib/core/demo_flag.dart, imported by both app_router and the scaffold (DRY)"

patterns-established:
  - "Verdict-time TutorInsight publish moved AFTER controller.beginSelection so the cached PolicyOutcome (arcStep/whyFacts) is populated before it is read; carried through the later coach-merge publish"
  - "The margin has a persistent resting presence (calm focus note before the first verdict) instead of appearing only in the verdict blast"

requirements-completed: [UAT-18-T6, UAT-18-T5, SPEC-18-R1]

# Metrics
duration: ~30min
completed: 2026-07-17
---

# Phase 18 Plan 16: The Teacher's Margin — recognizable, arc-narrating, per-attempt WHY

**The Teacher's Margin is now one distinct note beside the canvas that narrates the remediation-arc step-down from the real policy `arcStep` (micro-drills parked) and varies its WHY per attempt (coach rationale → pass line → authored floor), closing the UAT-T6 "never understood it" and UAT-T5 "feels static" gaps.**

## Performance

- **Duration:** ~30 min
- **Tasks:** 3
- **Files modified:** 6 (5 modified + 1 created)

## Accomplishments

- **UAT T6 (margin half):** The child-facing Teacher's Margin moved out of the 258px tutor column to sit BESIDE the writing canvas, and the demo-only "Teacher's Eye" diagnostic strip — its visual/content twin — is now gated behind `kDemoMode`. In a real (non-demo) build the margin is the single, recognizable margin surface, and it has a persistent resting presence (a calm focus note before the first verdict) rather than a verdict-only blast.
- **Arc step-down is no longer dead code:** `TutorInsight` now carries the real policy `arcStep` + `whyFacts` (threaded from a new controller accessor over the cached `PolicyOutcome`), and the margin fires the named step-down ("let's practice just the dot for a moment — then we'll come back") from that arc state — with NO `pick.contains('microDrill')` dependency (the drills are parked out of the live graph, D-03).
- **UAT T5 (client half):** The WHY line varies per attempt. It prefers the coach `rationale` verbatim; on a clean pass with no rationale it shows a warm pass-appropriate line; and it falls to the authored per-criterion floor only for a genuine `certainlyWrong` miss. The `_targetedCriterion` skew (a merely-`fuzzy` soft-band criterion routing to the fixed 'deeper bowl' line) is fixed.
- No points/streaks/badges/"+N"/score language anywhere on the margin or exercise screen (grep-clean; anti-gamification guard test green).

## Task Commits

Each task was committed atomically:

1. **Task 1: Thread the real arcStep/whyFacts into TutorInsight and fire arc narration from it** — `704afa9` (feat)
2. **Task 2: Give the margin a distinct, singular presence beside the canvas** — `4670137` (feat)
3. **Task 3: Vary the WHY per attempt and stop the static 'deeper bowl' skew** — `882d80f` (fix)

_TDD tasks (1 & 3): the test additions were written first and watched fail (RED — `arcStep`/`whyFacts` missing; clean-pass showed 'deeper bowl'), then implemented to green. Each task is committed as one working unit (tests + implementation) so every commit compiles._

## Files Created/Modified

- `lib/core/demo_flag.dart` — **created.** The single shared `kDemoMode = bool.fromEnvironment('DEMO')` flag (consolidates the router + scaffold copies).
- `lib/features/letter_unit/widgets/teacher_margin_panel.dart` — arc narration driven by `insight.arcStep` (guarded, criterion named from `whyFacts`); resting-presence note before the first verdict (takes the current `Exercise`); 3-tier WHY resolution with a `_passWhy` pass line; `_targetedCriterion` narrowed to `certainlyWrong` misses.
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — `TutorInsight` gains `arcStep`/`whyFacts`; verdict-time publish moved after `beginSelection` and threads them (carried through the coach merge); the margin relocated beside the canvas; the demo Teacher's Eye strip gated behind `kDemoMode`.
- `lib/features/letter_unit/letter_unit_controller.dart` — `pendingArcStep()` (genuine-arc-guarded) + `pendingWhyFacts()` accessors over the cached `_pendingNarrow` policy outcome.
- `lib/router/app_router.dart` — imports the shared `kDemoMode` (local duplicate removed).
- `test/features/letter_unit/teacher_margin_test.dart` — Test 4 rewritten to drive off `arcStep`; new tests for null-arc, resting presence, clean-pass WHY, genuine-fail floor, and rationale-verbatim.

## Decisions Made

See `key-decisions` in the frontmatter. In short: arc narration is now sourced from the real policy `arcStep` (guarded by an `arcStep:` why-fact so a tracking arc / first fail never narrates a step-down); the WHY table is demoted to an offline floor for genuine misses; a clean pass gets its own warm line; the demo strip is gated out of child-facing builds; the DEMO flag is consolidated into `lib/core`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Generated the gitignored l10n localizations for the fresh worktree**
- **Found during:** Task 1 (running the letter_unit suite)
- **Issue:** In this fresh worktree, `lib/l10n/app_localizations*.dart` (gitignored, generated) was absent, so every test transitively importing `mastery_celebration.dart` failed to compile ("No such file or directory").
- **Fix:** Ran `flutter gen-l10n` (a standard post-checkout step; the outputs are gitignored and are NOT committed).
- **Files modified:** none tracked (generated output only).
- **Verification:** The 7 compilation failures cleared; the suite compiles.
- **Committed in:** n/a (generated, gitignored).

**2. [Good practice] Consolidated the duplicated `kDemoMode` literal into `lib/core/demo_flag.dart`**
- **Found during:** Task 2 (gating the Teacher's Eye strip)
- **Issue:** `bool.fromEnvironment('DEMO')` was defined in `app_router.dart` (public `kDemoMode`) and privately in `latency_trace.dart`; importing the router into a widget to reuse it would invert the layering (widget → router).
- **Fix:** Created a shared `lib/core/demo_flag.dart` (the plan's sanctioned "shared spot"), imported by both the router (local duplicate removed) and the scaffold.
- **Files modified:** lib/core/demo_flag.dart (new), lib/router/app_router.dart
- **Verification:** `flutter analyze` clean on all touched files; router unchanged in behavior.
- **Committed in:** 4670137 (Task 2 commit)

---

**Total deviations:** 2 (1 blocking env fix, 1 DRY consolidation)
**Impact on plan:** Both are necessary/clean; no scope creep. The l10n fix is a known fresh-checkout step; the flag consolidation is the layering-correct reading of the plan's "reuse if defined, otherwise a shared spot" instruction.

## Issues Encountered

- One pre-existing baseline test failure remains and is OUT OF SCOPE: `meet_section_test.dart Test 1` (the door image `img.door`), explicitly named as a known baseline in STATE.md. Unrelated to the Teacher's Margin.
- `flutter analyze` reports 60 pre-existing warnings, all in unrelated test files (`getting_ready_test`, `practice_screen_test`, `parent_gate_test`, `home_screen_test`, `parent_dashboard_test`, `tutor_providers_test`) — none in any file this plan touched (all my changed files are analyze-clean). Left untouched per the scope boundary.

## Verification

- `flutter test test/features/letter_unit/`: 97 passed, 1 failed (the known `meet_section` img.door baseline). `teacher_margin_test.dart` + `exercise_scaffold_test.dart` all green.
- Anti-gamification grep on the margin + exercise scaffold string literals: clean (no streak/badge/points/+N/score copy).
- `flutter analyze` on all touched files (`teacher_margin_panel`, `exercise_scaffold`, `letter_unit_controller`, `app_router`, `demo_flag`): No issues found.

## Known Stubs

None. The copy strings (`_passWhy`, `_restingLine`, the step-down phrasing, the authored floor) remain PROVISIONAL (`signed:false`) named strings for the owner-mother's sign-off at the 18-HUMAN-UAT gate (D-03) — consistent with the panel's existing provisional-copy contract, not new stubs.

## Next Phase Readiness

- The Teacher's Margin closes the UAT-T6 margin half and the UAT-T5 client half at the code level. The remaining halves are the mother's copy sign-off (18-HUMAN-UAT) and — for the coach rationale to actually populate the clean-pass WHY online — the 18-14 server deploy.
- No blockers introduced. Phase 19 (question-presentation overhaul) can build on the single, recognizable margin surface.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-17*
