---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 15
subsystem: ui
tags: [flutter, riverpod, drift, resume, letter-unit, dynamic-selection, cold-boot]

# Dependency graph
requires:
  - phase: 18-build-the-living-tutor-dynamic-exercise-selection
    provides: "18-07 selection-mode render path (selectionActive + shell-local _presentedId); 18-12 presentEpoch (fresh-mount on same-id re-present); 15-04 durable LetterGraphPosition cursor"
provides:
  - "start() restores selectionActive:true when the durable currentExerciseId is a real authored graph node (cold-boot resume into presenter mode)"
  - "the shell re-enters the presenter on the saved node after a force-quit + relaunch (UAT T7 closed), not the legacy _section walk"
  - "resume_cold_boot_test.dart — the missing LIVE-PATH tear-down + re-mount proof"
affects: [phase-19 question-presentation-overhaul, per-child-position-keying]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cold-boot resume: derive session render-state (selectionActive) from the already-persisted durable cursor via isAuthored() — no new Drift column"
    - "Seed the shell-local _presentedId at boot (post-frame, after start()) to keep it authoritative, so verdict-time cursor advances never swap the view (18-07 swap-on-Continue timing preserved)"

key-files:
  created:
    - test/features/letter_unit/letter_unit_controller_resume_test.dart
    - test/features/letter_unit/resume_cold_boot_test.dart
  modified:
    - lib/features/letter_unit/letter_unit_controller.dart
    - lib/features/letter_unit/letter_unit_screen.dart
    - test/features/letter_unit/live_selection_shell_test.dart
    - test/features/letter_unit/same_id_represent_test.dart
    - test/features/letter_unit/live_fail_streak_scenario_test.dart
    - test/features/letter_unit/agent_pick_live_path_test.dart

key-decisions:
  - "Restore selectionActive from the durable cursor via a guarded isAuthored() check — a null/stale/unauthored id or a graph that will not load degrades to false (no false resume, no crash, T-18-15-01). No Drift schema bump."
  - "Deviated from the plan's `_presentedId ?? state.currentExerciseId` render mechanism: it would leak a verdict-time cursor advance into the render (breaking the 18-07 swap-on-Continue-not-verdict timing AND the fresh-session legacy-walk gate). Instead SEED _presentedId at boot and keep the render gate unchanged."

patterns-established:
  - "Resume render-state is DERIVED from the durable cursor, never separately persisted (selectionActive/_presentedId stay session-scoped)."
  - "A seeded real-node position now boots straight into the presenter — the legacy Watch&Trace 'I'll try' gate is a fresh-child-only step."

requirements-completed: [UAT-18-T7, SPEC-18-R6]

# Metrics
duration: ~34min
completed: 2026-07-17
---

# Phase 18 Plan 15: Resume-in-place after a cold boot Summary

**A force-quit + relaunch mid-unit now re-enters the presenter on the exact graph node the child left off — start() restores selectionActive from the durable cursor and the shell seeds _presentedId from it, bypassing the legacy section-0 walk (UAT T7 closed).**

## Performance

- **Duration:** ~34 min
- **Started:** 2026-07-17T12:34:38Z (worktree base)
- **Completed:** 2026-07-17T13:08:22Z
- **Tasks:** 2
- **Files modified:** 6 (2 lib, 4 existing tests) + 2 tests created

## Accomplishments
- Closed the resume-lost-on-relaunch regression (18-07 root cause): the durable `LetterGraphPosition.currentExerciseId` was read back correctly but never re-seeded the session-scoped render state, so every cold boot fell back to the legacy `_section` walk (commonly section 0 = "Meet").
- `LetterUnitController.start()` now restores `selectionActive: true` iff the saved cursor is a real authored graph node (best-effort, guarded graph read; degrades to false on null/stale/unauthored ids or a graph-load failure — never a crash, never a false resume).
- `_UnitShellState` seeds the shell-local `_presentedId` from the restored cursor at boot, so the presenter re-enters on the exact node without waiting for a "Next" tap.
- Added the LIVE-PATH tear-down + re-mount proof the debug flagged as missing (`resume_cold_boot_test.dart`) — drives a scored session over a shared in-memory Drift store, force-quits (unmounts), relaunches a fresh screen over the SAME db, and asserts the presenter resumes on the saved node; a fresh install still starts at Meet.

## Task Commits

Each task was committed atomically (both are `fix` — this plan closes a regression):

1. **Task 1: Restore selection mode from the durable cursor on start()** — `1faa617` (fix; controller + `letter_unit_controller_resume_test.dart`, RED→GREEN)
2. **Task 2: Render the restored cursor after a cold boot (relaunch resumes in place)** — `1ed9634` (fix; screen + `resume_cold_boot_test.dart` + 4 existing-test updates, RED→GREEN)

_Task 1's controller resume test was written RED first (selectionActive stayed false), then greened by the start() change. Task 2's cold-boot test was written RED first (remount fell to the legacy section), then greened by the _presentedId seed._

## Files Created/Modified
- `lib/features/letter_unit/letter_unit_controller.dart` — `start()` validates the saved cursor via a guarded `curriculumGraphProvider.future` + `graph.isAuthored(...)` and constructs the initial `LetterUnitState` with `selectionActive: restoreSelection`.
- `lib/features/letter_unit/letter_unit_screen.dart` — `initState` post-frame now awaits `start()` then seeds `_presentedId` from the restored `currentExerciseId` when `selectionActive` is true and `_presentedId` is null.
- `test/features/letter_unit/letter_unit_controller_resume_test.dart` (new) — 5 controller cases: real-node → restore; null / stale-unauthored / no-position → no resume; graph-load failure → no crash.
- `test/features/letter_unit/resume_cold_boot_test.dart` (new) — 2 live-path cases: drive → force-quit → relaunch resumes on the saved node; fresh install starts at Meet.
- `test/features/letter_unit/{live_selection_shell,same_id_represent,live_fail_streak_scenario,agent_pick_live_path}_test.dart` — the "I'll try" watch-gate tap made conditional (a seeded real-node cursor now boots straight into the presenter).

## Decisions Made
- **No Drift schema change.** The debug confirmed `selectionActive` is derivable from the already-persisted `currentExerciseId`; the fix re-seeds render state, it does not persist new state.
- **Guarded `isAuthored()` gate (T-18-15-01).** A corrupt/stale id in Drift is rejected → `selectionActive` stays false → legacy walk. No crash, no presenter dead-end.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the Task 2 render mechanism to preserve the 18-07 swap-on-Continue timing**
- **Found during:** Task 2 (Render the restored cursor after a cold boot)
- **Issue:** The plan prescribed rendering `_presentedId ?? state.currentExerciseId` and gating on `state.selectionActive && presentedOrRestored != null`. That fallback leaks the verdict-time cursor advance into the render: on the first scored moment `selectNext` advances `currentExerciseId` while `_presentedId` is still null, so the `??` swaps the view to the next exercise AT VERDICT — replacing the pass feedback before "Next exercise" is tapped. It also breaks the fresh-session legacy-walk gate (selectionActive flips true at the first verdict with `_presentedId` null → the presenter would take over mid-feedback). Both violate the 18-07 "swap on Continue, never at verdict" invariant.
- **Fix:** Kept the render condition unchanged (`state.selectionActive && _presentedId != null`) and instead SEED `_presentedId` from the restored `currentExerciseId` at boot (post-frame, after `start()`), so `_presentedId` is authoritative before any verdict — a later cursor advance never swaps the view, and a truly-fresh child (selectionActive false) never seeds and keeps the legacy walk.
- **Files modified:** `lib/features/letter_unit/letter_unit_screen.dart`
- **Verification:** `resume_cold_boot_test.dart` (resume renders the saved node; fresh install → Meet) + full `test/features/letter_unit/` green; the same-id-represent / live-fail-streak / agent-pick verdict-timing tests still pass (they would break under the `??` mechanism).
- **Committed in:** `1ed9634` (Task 2 commit)

**2. [Rule 3 - Blocking] Generated the gitignored l10n sources in the fresh worktree**
- **Found during:** Task 1 (first full-suite run)
- **Issue:** `lib/l10n/app_localizations*.dart` is gitignored (known project fact) and absent in a fresh worktree checkout — every widget test that touches `mastery_celebration.dart` failed to COMPILE ("No such file or directory").
- **Fix:** Ran `flutter gen-l10n` (no source edit; the files stay gitignored and uncommitted).
- **Files modified:** none tracked (generated, gitignored)
- **Verification:** the "loading [E]" compile failures cleared; suite ran.
- **Committed in:** n/a (generated artifact, not committed)

**3. [Rule 1 - Bug] Updated four existing full-screen tests for the corrected boot behavior**
- **Found during:** Task 2
- **Issue:** With the durable cursor now driving selection at boot, four full-screen tests that seed a real-node position (`baa.traceLetter.isolated`) resume straight into the presenter — the legacy Watch&Trace "I'll try" gate no longer appears, so their `tap(find.text("I'll try"))` failed.
- **Fix:** Made the "I'll try" tap conditional (`if (find.text("I'll try").evaluate().isNotEmpty) ...`) — it fires for a legacy watch-first setup and is skipped when the cursor resumes directly into the presenter. This reflects the new correct resume behavior; the tests' actual intent (ribbon display-only, graph-exhausted→Mastery, same-id remount, agent-pick render, fail-streak anti-boredom) is unchanged and still asserted.
- **Files modified:** `test/features/letter_unit/{live_selection_shell,same_id_represent,live_fail_streak_scenario,agent_pick_live_path}_test.dart`
- **Verification:** full `test/features/letter_unit/` at +92 / -1 (the -1 is the documented `meet_section` `img.door` baseline).
- **Committed in:** `1ed9634` (Task 2 commit)

**4. [Rule 3 - Blocking] Matched the clean ProviderScope-override structure in the new cold-boot test**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** Building the `ProviderScope` in an arrow-body helper (`Widget _app(...) => ProviderScope(...)`) tripped `scoped_providers_should_specify_dependencies` on the keepAlive-provider overrides (the sibling live tests, which inline the scope in `pumpWidget`, analyze clean).
- **Fix:** Restructured to a `_mount(tester, db, graph)` helper that builds the `ProviderScope` inline in the `pumpWidget` call (matching the clean sibling pattern) + overrode `graphPositionRepositoryProvider` explicitly with a real `DriftGraphPositionRepository(db)`.
- **Files modified:** `test/features/letter_unit/resume_cold_boot_test.dart`
- **Verification:** `flutter analyze test/features/letter_unit/resume_cold_boot_test.dart` → No issues found.
- **Committed in:** `1ed9634` (Task 2 commit)

---

**Total deviations:** 4 (2 Rule-1 bug corrections, 2 Rule-3 blocking). 
**Impact on plan:** The Task 1 outcome is exactly as specified. The Task 2 render mechanism was corrected to a semantically-equivalent-but-safe form (seed `_presentedId` vs `??` fallback) that preserves the 18-07 verdict timing — the plan's `must_haves` (resume on the exact node; fresh child → Meet; `presentGraphExercise(` on the cold-boot path) all hold. No scope creep.

## Issues Encountered
- The plan's prescribed `??` render fallback conflicted with the 18-07 "swap on Continue, never at verdict" timing (see Deviation 1). Resolved by seeding `_presentedId` at boot instead of a build-time fallback, keeping the render gate unchanged.

## Verification
- `flutter test test/features/letter_unit/letter_unit_controller_resume_test.dart` — 5/5 pass.
- `flutter test test/features/letter_unit/resume_cold_boot_test.dart` — 2/2 pass.
- `flutter test test/features/letter_unit/` — +92 / -1 (only the documented `meet_section` `img.door` baseline).
- `flutter test test/spike_genui/durable_layers_unchanged_test.dart` — SC-4 passes (no working-tree drift over sacred paths once committed).
- No Drift `schemaVersion` bump.
- `flutter analyze` on the changed lib + test files: clean for the new files; the only remaining items are pre-existing (`unnecessary_brace_in_string_interps` infos + an `unused_import` warning in `agent_pick_live_path_test.dart` — both present at HEAD, out of scope).
- Full-suite failures outside `letter_unit` (glyph_audit / reference_overlay / mastery_celebration goldens, alif_reference, all_letters_validation, curriculum_repository_v2) are pre-existing baselines and do not import the changed files.

## Self-Check: PASSED
- Created files exist: `letter_unit_controller_resume_test.dart`, `resume_cold_boot_test.dart` — FOUND.
- Modified files exist: `letter_unit_controller.dart`, `letter_unit_screen.dart` — FOUND.
- Commits exist: `1faa617` (Task 1), `1ed9634` (Task 2) — FOUND.

## Next Phase Readiness
- UAT T7 (resume-lost-on-relaunch) closed for the single-profile case.
- Note (out of scope): the separate per-child position-keying gap (`LetterGraphPosition` keyed by `letterId` only, shared across profiles) remains — folded into Phase 19 per the roadmap; this plan does not address cross-profile collisions.

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-17*
