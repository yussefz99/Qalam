---
status: diagnosed
trigger: "Owner UAT 2026-07-17: 'when i closed the app and reopend it did start from scrathc in unit baa , i dont think so and i think we should chage that nightly job' — Fully closing and reopening the app while in the baa Letter Unit restarted from the very first exercise instead of resuming."
created: "2026-07-17T00:00:00.000Z"
updated: "2026-07-17T00:12:00.000Z"
---

## Current Focus

hypothesis: CONFIRMED — see Resolution.root_cause
test: complete
expecting: n/a
next_action: none — diagnose-only mode, return ROOT CAUSE FOUND to caller

## Symptoms

expected: Closing and reopening the app should resume the child's position within the CURRENT letter unit (the on-device resume cursor, LetterGraphPosition, Phase 15) — independent of and NOT confused with the separate nightly across-session "struggles/strengths" compile job (which only affects which exercise gets picked NEXT based on past performance, not whether you resume mid-unit at all).
actual: Owner force-closed the app while in baa Letter Unit (after several exercises via Phase 18's live dynamic-selection path) and relaunched — landed at the first exercise instead of resuming. Owner's own hypothesis blames "the nightly job" but that's unconfirmed — architecturally the nightly batch compiler is unrelated to the resume cursor.
errors: None reported
reproduction: Start baa Letter Unit session, complete a few exercises (through Phase 18 live selection path — pass/fail cycles, possibly step-down arc), fully force-quit the app, reopen, navigate back into baa Letter Unit. Check whether it resumes near last-reached exercise or restarts at first.
started: Discovered during Phase 18 UAT on 2026-07-17 (Test 7 in 18-UAT.md)

## Eliminated

- hypothesis: "The already-filed per-child position-keying gap (LetterGraphPosition keyed by letterId only, shared across profiles) explains this report."
  evidence: Owner's reproduction is single-profile (same device, same session flow, force-quit and reopen) — no profile switch occurred. The keying gap only explains resuming at the WRONG profile's cursor when a SECOND profile exists; it does not predict "zero prior position" for the SAME profile. Confirmed a separate mechanism entirely accounts for the symptom (see root_cause) — the keying gap remains real but is not this bug's cause.
  timestamp: "2026-07-17T00:10:00.000Z"

- hypothesis: "The nightly across-session profile-compile job caused the reset (owner's own stated theory)."
  evidence: The nightly job (18-09) only writes ChildModelSnapshot strengths/struggles used to bias exercise SELECTION; it has no read/write path to LetterGraphPosition, selectionActive, or _presentedId. Confirmed unrelated by code inspection (child_model_providers.dart / graph_position_repository.dart have no shared writer). Root cause is a rendering-layer bug in the Phase-18 live-selection UI, not the nightly compiler.
  timestamp: "2026-07-17T00:10:00.000Z"

## Evidence

- timestamp: "2026-07-17T00:05:00.000Z"
  checked: lib/features/letter_unit/letter_unit_controller.dart — LetterUnitState + LetterUnitController.start()
  found: |
    `LetterUnitState` has a `selectionActive` field (default `false`, doc comment: "flips on the first scored feedback moment of the session... sticky for the session"). `start()` (called on every fresh screen mount) DOES correctly read the durable Drift `GraphPosition` and sets `currentExerciseId: saved?.currentExerciseId` — but the new `state = LetterUnitState(...)` construction in `start()` never passes `selectionActive`, so it always defaults back to `false` on every fresh start(), regardless of what it was before the app closed.
  implication: The durable graph-position cursor (currentExerciseId/clearedCompetencies/clearedTiers) is correctly restored from Drift, but the flag that tells the SCREEN to use it for rendering (`selectionActive`) is not — and is not persisted anywhere.

- timestamp: "2026-07-17T00:06:00.000Z"
  checked: lib/data/app_database.dart — LetterGraphPosition Drift table definition, and graph_position_repository.dart getPosition/setPosition
  found: The `LetterGraphPosition` table has exactly 3 data columns besides letterId/timestamps — `currentExerciseId`, `clearedCompetencies`, `clearedTiers`. There is no `selectionActive` (or equivalent) column, and `DriftGraphPositionRepository.setPosition`/`_persist()` in the controller never write one.
  implication: `selectionActive` is by design NEVER persisted to Drift — it is pure in-memory/session state on the Riverpod notifier, which itself is torn down and rebuilt fresh on every app process restart.

- timestamp: "2026-07-17T00:08:00.000Z"
  checked: lib/features/letter_unit/letter_unit_screen.dart — _UnitShellState (_presentedId field, initState, build() render branch, _advanceSelection)
  found: |
    `_presentedId` (line 185) is a plain `String?` field on `_UnitShellState`, initialized to `null` and NEVER read from `state.currentExerciseId` anywhere — the ONLY place it is ever set is inside `_advanceSelection()` (`setState(() => _presentedId = next);`), which only runs when the child taps the "Next exercise" CTA during a live selection-mode session. `initState()` only calls `controller.start(...)`; it never seeds `_presentedId`.
    The render branch (build(), line 374-383):
    ```
    Expanded(
      child: (state.selectionActive && _presentedId != null)
          ? presentGraphExercise(data: data, exerciseId: _presentedId!, ...)
          : _section(data, index),
    ),
    ```
    Since a fresh app launch creates a brand-new `_UnitShellState` (`_presentedId == null`) AND `start()` resets `selectionActive` to `false` (previous evidence entry), this condition is ALWAYS false immediately after a cold relaunch — the shell unconditionally falls back to the legacy fixed `_section(data, index)` walk, never `presentGraphExercise`, regardless of the correctly-restored `state.currentExerciseId`.
  implication: This is the mechanism of the bug. On cold boot, the screen can never re-enter "selection mode" or re-render the specific graph node the child was on — it always falls back to the OLD Phase-15 fixed-section walk.

- timestamp: "2026-07-17T00:09:00.000Z"
  checked: lib/features/letter_unit/letter_unit_controller.dart — _sectionHintFor()
  found: |
    The fallback legacy walk's starting section index comes from `_sectionHintFor(saved, total)`, a COARSE heuristic: `cleared = saved.clearedCompetencies.length; if (cleared <= 0) return null;` (section defaults to 0 when null). `clearedCompetencies` only grows via `markNodeCleared()` when a specific exercise's Drift clean-rep counter reaches that node's `minCleanReps` (2-3 for trace/write nodes per 15-07-SUMMARY notes, 1 for lighter nodes). A short UAT session with "a few exercises" including pass/fail cycles and a step-down arc plausibly never reaches any node's full clean-rep threshold, so `clearedCompetencies` stays empty → hint is null → resume section defaults to 0 (`meet`, the intro teach card) — matching the owner's "started from scratch" report exactly.
  implication: Even the fallback section-index heuristic is disconnected from the actual exercise-level cursor (`currentExerciseId`); it is a second, independent layer of imprecision on top of the primary bug (selectionActive/_presentedId not restored). Confirms the root cause is a rendering-layer regression, not a missing-data regression — the data (`currentExerciseId`) genuinely IS in Drift and IS read back correctly, it's just never applied to what renders after a cold boot.

- timestamp: "2026-07-17T00:11:00.000Z"
  checked: .planning/phases/18-build-the-living-tutor-dynamic-exercise-selection/18-07-SUMMARY.md (key-decisions) and test/features/letter_unit/live_selection_shell_test.dart
  found: |
    18-07-SUMMARY.md explicitly documents the design choice: "The render swap uses a shell-local `_presentedId` (not `state.currentExerciseId`) so the swap happens on the CONTINUE CTA... never at verdict time — the feedback moment survives." This was a deliberate choice for WITHIN-session timing correctness (don't swap content mid-feedback), but it was never extended to also seed `_presentedId` from the restored `currentExerciseId` on a fresh mount/cold boot.
    `live_selection_shell_test.dart`'s two tests both pump ONE continuous widget instance through an entire session (ribbon-display-only-in-selection-mode; graph-exhausted-routes-to-Mastery) — neither test ever tears down and re-mounts `LetterUnitScreen` (simulating a relaunch) to assert that a SAVED `currentExerciseId`/selection-mode state re-renders correctly. This test gap is exactly why the regression shipped unnoticed, matching the project's own "live-path widget proof is MANDATORY for any wire-into-the-live-path plan" lesson (from the Phase-15 dead-wire precedent) — but that lesson was applied to forward-wiring, not to the resume/cold-boot path.
  implication: Confirms this is a genuine, previously-untested regression introduced by Phase 18-07 (not a config issue, not the nightly job, not the already-known per-child keying gap). The fix direction (not applied — diagnose-only mode) would need to either (a) persist `selectionActive` + seed `_presentedId` from `state.currentExerciseId` on `start()`/`initState()` when a saved position exists and is not a legacy-section id, or (b) unify the resume path so `_sectionHintFor` / the legacy walk is bypassed whenever a durable `currentExerciseId` exists, restoring directly into presenter mode.

## Resolution

root_cause: |
  Phase 18 (18-07) introduced a session-scoped "selection mode" render path (`LetterUnitState.selectionActive` + the widget-local `_UnitShellState._presentedId`) that determines what the Letter Unit screen actually renders: `presentGraphExercise(_presentedId)` when in selection mode, else the legacy fixed `_section(data, index)` walk. Neither `selectionActive` nor `_presentedId` is persisted anywhere (no Drift column exists for either — `LetterGraphPosition` only stores `currentExerciseId`/`clearedCompetencies`/`clearedTiers`), and `_presentedId` is never re-seeded from the restored `currentExerciseId` when the controller's `start()` correctly reads the durable Phase-15 resume cursor back from Drift. As a result, EVERY cold app relaunch resets `selectionActive` to `false` and `_presentedId` to `null`, so the screen's render condition (`state.selectionActive && _presentedId != null`) is always false immediately after boot — the shell unconditionally falls back to the OLD legacy `_section(index)` walk, discarding the dynamically-selected graph position the child was actually on. The legacy walk's own starting section index is a second, independent approximation (`_sectionHintFor`, keyed on `clearedCompetencies.length`, not on `currentExerciseId`) that stays at 0 ("Meet") whenever no node has yet reached its full clean-reps threshold within the session — which is common in a short session with pass/fail cycles / a step-down arc, exactly matching the owner's "started from scratch" report.

  This is confirmed to be architecturally UNRELATED to the nightly across-session profile-compile job (which only biases exercise SELECTION, has no read/write path to the resume cursor or the selection-mode UI state) and is a DIFFERENT bug from the already-filed per-child position-keying gap (.planning/todos/pending/2026-07-12-question-presentation-overhaul.md item 6 — that gap is about LetterGraphPosition rows being keyed by letterId only, causing cross-PROFILE collisions; this bug reproduces on a SINGLE profile with no profile switch involved, because the selection-mode UI state is never persisted/restored at all).
fix: (not applied — find_root_cause_only mode)
verification: (n/a — diagnose-only mode)
files_changed: []
