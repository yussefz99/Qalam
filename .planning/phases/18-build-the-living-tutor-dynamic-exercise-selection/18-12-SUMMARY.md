---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 12
subsystem: ui
tags: [flutter, riverpod, widget-key, remount, letter-unit, tts, uat-gap-closure]

# Dependency graph
requires:
  - phase: 18-build-the-living-tutor-dynamic-exercise-selection
    provides: "the live selection path (exercise_presenter + _UnitShell) that renders the selector's pick; advanceOnFix + the remediation arc"
provides:
  - "A monotonic presentation-epoch folded into the presenter key so a same-id re-present forces a fresh scaffold mount (initState resets phase/canvas/instruction-hold)"
  - "Closes UAT T3 (retry-in-place no-op) and the T6 hard-stuck (active-arc pass dead button that needed a force-quit) with ONE mechanism"
  - "An always-available 'Hear again' control that replays the spoken instruction in idle/fix/pass"
affects: [phase-19-question-presentation-overhaul]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Presentation-epoch widget key: ValueKey('graph:<id>#<epoch>') — bump a monotonic counter on every advance so a re-present of the SAME id still remounts (initState re-runs)"
    - "Epoch-tolerant graph-node test finder: match graph:<id> with OR without the #<epoch> suffix so an assertion tracks WHICH node renders, not its epoch"

key-files:
  created:
    - test/features/letter_unit/same_id_represent_test.dart
  modified:
    - lib/features/letter_unit/exercise_presenter.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - test/features/letter_unit/exercise_scaffold_test.dart
    - test/features/letter_unit/exercise_presenter_test.dart
    - test/features/letter_unit/live_fail_streak_scenario_test.dart
    - test/features/letter_unit/agent_pick_live_path_test.dart

key-decisions:
  - "One fix for both UAT gaps: T3 (fail-path retry-in-place) and T6 (active-arc pass re-present) share the same ValueKey re-key collision — a presentation epoch covers both"
  - "Increment the epoch on EVERY advance (monotonic), harmless when the next id differs (that already remounts), decisive when the id is the same"
  - "Do NOT bump the epoch when routing to Mastery (_presentedId = null) — the epoch only matters for a presented node"
  - "Hide the 'Hear again' control on teachCards / empty say-lines (where _speakInstructionThenRelease no-ops) rather than offering a dead tap"

patterns-established:
  - "Presentation-epoch remount key for selection-driven presenters"
  - "Epoch-tolerant graph-node finder in live-path widget tests"

requirements-completed: [UAT-18-T3, UAT-18-T6, SPEC-18-R1, SPEC-18-R4]

# Metrics
duration: ~30min
completed: 2026-07-17
---

# Phase 18 Plan 12: Same-id re-present fresh-mount + replay-instruction Summary

**A presentation-epoch folded into the presenter key (`graph:<id>#<epoch>`) forces a fresh scaffold mount on every advance, so a legitimate same-id re-present (first-fail retry-in-place, or an active-arc pass re-present of the floor trace) can never strand the child on a dead CTA — plus an always-available "Hear again" control.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-07-17T09:05Z
- **Completed:** 2026-07-17T09:30Z
- **Tasks:** 2 (Task 1 TDD RED→GREEN)
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments
- **UAT T3 closed:** one wrong attempt → "Try again" now visibly resets the canvas/phase to idle (a fresh mount ran initState) instead of a silent no-op.
- **UAT T6 half closed (the BLOCKER):** an active-arc pass that re-presents the same floor-trace id now remounts on the lone "Next exercise" tap — the permanent dead button that forced a force-quit is gone.
- Proven with **live-path widget tests** (project lesson: any wire-into-the-live-path change needs live-path proof) driving the real `LetterUnitScreen`/`_UnitShell` through both trigger paths.
- **Replay-instruction control:** a small, calm "Hear again" affordance re-speaks the current question's instruction in idle, fix, AND pass phases (the T3 report's secondary ask).

## Task Commits

1. **Task 1 (RED): failing same-id re-present tests (T3 + T6)** - `095c381` (test)
2. **Task 1 (GREEN): presentation epoch forces fresh mount** - `506c316` (feat)
3. **Task 2: always-available 'Hear again' replay-instruction control** - `66223eb` (feat)

_Task 1 is a TDD task (RED test commit → GREEN implementation commit)._

## Files Created/Modified
- `test/features/letter_unit/same_id_represent_test.dart` - **(created)** two live-path tests: T3 fail-path retry-in-place and T6 active-arc pass re-present both assert the presenter key changes (epoch) + phase returns to idle.
- `lib/features/letter_unit/exercise_presenter.dart` - `presentGraphExercise` gains `int presentEpoch = 0`; both ValueKeys become `ValueKey('graph:$exerciseId#$presentEpoch')` (teachCard MeetSection branch + ExerciseScaffold branch).
- `lib/features/letter_unit/letter_unit_screen.dart` - `_UnitShellState` gains `int _presentEpoch`; `_advanceSelection` increments it in the same `setState` as the id swap (not when routing to Mastery); threaded into `presentGraphExercise`.
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` - `_HearAgainCta` (compact ghost pill, volume glyph) + a `hearAgain` string; gated on a new `_hasInstruction` getter; `onTap` reuses `_speakInstructionThenRelease` verbatim.
- `test/features/letter_unit/exercise_scaffold_test.dart` - Test 5 (control present + re-speaks in idle/fix/pass via a recording `CoachSpeaker`) + Test 6 (teachCard shows no control); a `_pumpWith` speaker-injecting helper.
- `test/features/letter_unit/exercise_presenter_test.dart` - direct presenter calls default `presentEpoch` to 0, so exact keys pinned to `graph:<id>#0`.
- `test/features/letter_unit/live_fail_streak_scenario_test.dart` - exact-key lookups replaced with an epoch-tolerant `_graphNode(id)` finder.
- `test/features/letter_unit/agent_pick_live_path_test.dart` - same epoch-tolerant `_graphNode(id)` finder for the render-proof assertions.

## Decisions Made
- **One mechanism for both gaps.** The two debug sessions (`retry-does-nothing-after-fail.md`, `app-stuck-and-teacher-margin-not-understood.md`) confirmed the identical `ValueKey('graph:$id')` re-key collision; the epoch covers the first-fail retry-in-place AND the active-arc pass re-present in one change.
- **Monotonic increment on every advance.** Simpler and safer than a same-id guard — a differing next id already remounts (epoch harmless there); a same id now remounts too.
- **Gate "Hear again" on a real instruction.** Hidden on teachCards / empty say-lines where the speak no-ops, so the control is never a dead tap.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated three existing live/presenter tests to the new key format**
- **Found during:** Task 1 (GREEN)
- **Issue:** The deliberate key-format change (`graph:<id>` → `graph:<id>#<epoch>`) broke tests that hard-coded the exact old key (`exercise_presenter_test.dart`, `live_fail_streak_scenario_test.dart`, `agent_pick_live_path_test.dart`) — expected fallout of the change, not a behavior regression.
- **Fix:** `exercise_presenter_test` pins epoch 0 (`#0`, direct presenter calls); the two live-screen tests match by an epoch-tolerant `_graphNode(id)` finder that asserts WHICH node renders, preserving each assertion's original intent.
- **Files modified:** the three test files above.
- **Verification:** `flutter test test/features/letter_unit/` — 81 pass / 1 known-baseline fail (see Issues).
- **Committed in:** `506c316` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The test updates are a mechanical consequence of the intended key-format change; the assertions verify the same behavior. No scope creep.

## Issues Encountered
- **Fresh worktree missing generated l10n.** `lib/l10n/app_localizations*.dart` is gitignored (known project quirk), so tests could not compile until `flutter gen-l10n` was run in the worktree. This is an environment step — no committed source change.
- **Known baseline failure (out of scope):** `meet_section_test.dart` Test 1 (`img.door`) fails at base `5fc6baf` (recorded in STATE as a known baseline). Untouched by this plan.
- **Pre-existing lints (out of scope, not introduced here):** `unnecessary_brace_in_string_interps` in `letter_unit_screen.dart`'s untouched `_fallback*` builders, and an `unused_import` (`models/word.dart`) in `agent_pick_live_path_test.dart` — both present at base. `flutter analyze` on the newly-authored `exercise_scaffold.dart` + its test reports "No issues found!".

## Verification
- `flutter test test/features/letter_unit/same_id_represent_test.dart` — 2/2 pass (RED→GREEN).
- `flutter test test/features/letter_unit/exercise_scaffold_test.dart` — 6/6 pass (incl. the two new "Hear again" tests).
- `flutter test test/features/letter_unit/` — 81 pass / 1 known-baseline fail (`meet_section` img.door).
- `flutter test test/tutor/coach_speak_hook_test.dart` — 6/6 pass (the one other ExerciseScaffold consumer, unaffected by "Hear again").
- `flutter analyze` on the touched lib/test files introduces no new issues.

## Next Phase Readiness
- The presentation-epoch remount pattern is now the durable fix for any selection-driven same-id re-present; Phase 19 (question-presentation overhaul + per-child position keying + micro-drill return) inherits it.
- Remaining T6 UAT thread NOT in scope here: the "Teacher's Margin never understood" identity/redundancy gap (debug cause 2) — a separate presentation-clarity fix.

## Self-Check: PASSED
- All 8 created/modified files verified present on disk.
- All 3 commits (`095c381`, `506c316`, `66223eb`) verified in git history.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-17*
