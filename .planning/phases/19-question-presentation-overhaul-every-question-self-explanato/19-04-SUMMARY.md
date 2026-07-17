---
phase: 19-question-presentation-overhaul-every-question-self-explanato
plan: 04
subsystem: database
tags: [drift, letter-exercise-reps, letter-reps, aggregate, riverpod, d-15, progress-repository, offline]

# Dependency graph
requires:
  - phase: 15
    provides: "LetterExerciseReps composite-PK table + per-exercise clean-rep accessors (setExerciseCleanReps/exerciseCleanRepsFor)"
  - phase: 18
    provides: "the 6 progress tables at schema v6; LetterUnitController writing LetterExerciseReps on the live baa path"
provides:
  - "LetterExerciseReps MAX-aggregate accessors on AppDatabase (letterCleanReps / watchLetterCleanReps / allInProgressByExerciseReps) that fold the three legacy LetterReps reads without a schema change (schemaVersion stays 6)"
  - "ProgressRepository interface + DriftProgressRepository delegation for the folded aggregate (letterCleanReps / watchLetterCleanReps / setLetterCleanReps → a single synthetic per-letter LetterExerciseReps row)"
  - "The three live LetterReps reader sites re-pointed onto the aggregate: journey ribbon (progression_providers), parent dashboard in-progress (parent_providers), practice resume+write-through (practice_providers)"
  - "LetterReps present-but-unused by any live code path — safe for 19-06 to DROP in the v6→v7 migration"
affects: ["19-06 keying migration (un-skips the v6→v7 case + drops letter_reps)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DB-layer aggregate accessor via selectOnly + column.max() + groupBy(having:) — MAX(clean_reps) over a letter's LetterExerciseReps rows, watched through Drift .watch() (re-emits on any per-exercise write)"
    - "Reader-fold-before-table-drop: fold all live readers onto the target table's aggregate FIRST (this plan), drop the retired table SECOND (19-06), in the same v6→v7 story — the phase-mandated order that de-risks the migration"
    - "Behavior-preserving legacy write-through: the per-letter /practice counter banks ONE synthetic exercise row (`__whole_letter__`), so MAX == that single value == the old LetterReps.cleanReps"
    - "Ribbon read stays on the ProgressRepository seam via _bindDriftStream (never a bare StreamProvider.future — Riverpod-3 pause, Pitfall 5)"

key-files:
  created: []
  modified:
    - lib/data/app_database.dart
    - lib/data/progress_repository.dart
    - lib/data/drift_progress_repository.dart
    - lib/providers/progression_providers.dart
    - lib/providers/parent_providers.dart
    - lib/providers/practice_providers.dart
    - test/data/app_database_test.dart
    - test/providers/progression_providers_test.dart
    - test/features/practice/session_controller_test.dart
    - test/features/practice/practice_screen_test.dart
    - test/features/practice/getting_ready_test.dart
    - test/features/letter_unit/letter_unit_screen_test.dart
    - test/router/letter_unit_route_test.dart
    - test/screens/home_screen_test.dart

key-decisions:
  - "AGGREGATION RULE = MAX(clean_reps) across a letter's LetterExerciseReps rows (the plan sanctioned 'essential-node floor OR max'). MAX chosen because it is purely DB-computable — the essential-node set lives in lib/curriculum, not the DB layer — and because it is behavior-identical to the old LetterReps counter for the legacy single-row /practice path. The aggregate is a DISPLAY/RESUME indicator only; the authoritative star gate remains isMasteryMet over essential nodes (unchanged, D-06)."
  - "Practice provider RE-POINTED (Task-2c option A), not retired: it is still the live path for non-unit letters (home routes only alif/baa/taa to /unit; every other letter → /practice). Its D-20 resume read + D-10 write-through now target LetterExerciseReps via a single synthetic exercise id, keeping the home ink-fill + resume behavior-preserving. Retiring would have zeroed the ink-fill/resume for /practice letters."
  - "The folded write-through banks under a documented sentinel exercise id `__whole_letter__` (DriftProgressRepository.wholeLetterExerciseId). It never collides with a real graph exercise id (`<letter>.<config>`), and unit letters never take the /practice loop, so a letter never mixes the synthetic row with graph rows."
  - "Legacy LetterReps accessors (setCleanReps/getCleanReps/watchCleanReps/allInProgress) KEPT on both AppDatabase and the ProgressRepository interface — present-but-unused by live code; 19-06 removes them with the table. This is why the interface temporarily carries both the old and folded method sets."
  - "QP-09 NOT marked complete — this plan is D-15 fold PREP only. It does not drop LetterReps or run the v6→v7 keying migration; 19-06 un-skips the migration case and completes QP-09 (19-01 precedent)."

patterns-established:
  - "Aggregate stream accessor: selectOnly(table)..addColumns([col.max()])..where(...) then .watchSingleOrNull().map((row) => row?.read(max) ?? 0) — emits 0 on an empty set and re-emits on writes"
  - "Interface-fold-in-lockstep: adding folded methods to a shared repository interface forces every fake to implement them; map the new methods onto each fake's existing rep store so test bodies stay behavior-identical after the re-point"

requirements-completed: []

# Metrics
duration: 12min
completed: 2026-07-17
---

# Phase 19 Plan 04: LetterReps → LetterExerciseReps Fold (D-15 prep) Summary

**Folded the three live `LetterReps` reader sites — journey ribbon, parent-dashboard in-progress, and the practice resume/write-through — onto a MAX-aggregate over `LetterExerciseReps` (no schema change, schemaVersion stays 6), so `LetterReps` is present-but-unused and 19-06 can safely DROP it in the v6→v7 migration.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-17T21:55:44Z
- **Completed:** 2026-07-17T22:08:05Z
- **Tasks:** 2
- **Files modified:** 14 (6 lib, 8 test)

## Accomplishments

- **Task 1 — aggregate accessors:** Added `letterCleanReps` (one-shot), `watchLetterCleanReps` (stream), and `allInProgressByExerciseReps` (letters with ≥1 exercise clean-rep → MAX) to `AppDatabase`, computed as `MAX(clean_reps)` over a letter's `LetterExerciseReps` rows via `selectOnly + column.max() + groupBy(having:)`. Surfaced `letterCleanReps` / `watchLetterCleanReps` / `setLetterCleanReps` on the `ProgressRepository` interface + `DriftProgressRepository` delegation. `build_runner` regenerated cleanly with **no** change to `app_database.g.dart` (no schema change — schemaVersion still 6). The legacy `LetterReps` accessors are kept intact for 19-06.
- **Task 2 — re-point the three readers (behavior-preserving):**
  - `progression_providers` — the journey ribbon (`_CleanRepsNotifier`) reads `watchLetterCleanReps` via the **same** `_bindDriftStream` bridge (never a bare `StreamProvider.future` — Pitfall 5).
  - `parent_providers` — the dashboard in-progress list reads `allInProgressByExerciseReps()` (a `Map<String,int>`) instead of `allInProgress()`; `parentProgressProvider` stays hand-written (Pitfall 6).
  - `practice_providers` — the D-20 resume prime + D-10 write-through target the folded aggregate (`letterCleanReps` / `setLetterCleanReps`, the latter banking a single synthetic `__whole_letter__` exercise row).
- **No live `lib/providers/` path reads or writes `LetterReps`** (grep-verified); the `LetterReps` table class is still present for 19-06 to drop.
- **TDD both tasks:** RED authored+verified before GREEN (evidence below). Updated the provider seed test in lockstep and extended the 6 fake `ProgressRepository` implementations to the folded interface.

## Task Commits

Each task was committed atomically:

1. **Task 1: LetterExerciseReps aggregate accessors** — `dfb1008` (feat)
2. **Task 2: Re-point the three LetterReps readers + fold the write-through** — `1390613` (feat)

**Plan metadata:** _(this SUMMARY + STATE/ROADMAP — final docs commit)_

## Files Created/Modified

- `lib/data/app_database.dart` — `letterCleanReps` / `watchLetterCleanReps` / `allInProgressByExerciseReps` MAX-aggregate accessors over `LetterExerciseReps` (documented aggregation rule); legacy `LetterReps` accessors untouched
- `lib/data/progress_repository.dart` — folded interface methods (`letterCleanReps` / `watchLetterCleanReps` / `setLetterCleanReps`) alongside the retained legacy set
- `lib/data/drift_progress_repository.dart` — delegation for the folded methods; `wholeLetterExerciseId = '__whole_letter__'` sentinel for the synthetic per-letter write-through
- `lib/providers/progression_providers.dart` — ribbon reads `watchLetterCleanReps` via `_bindDriftStream`
- `lib/providers/parent_providers.dart` — in-progress read via `allInProgressByExerciseReps()`
- `lib/providers/practice_providers.dart` — resume read + write-through folded onto the aggregate
- `test/data/app_database_test.dart` — 3 new aggregate-accessor tests (RED→GREEN)
- `test/providers/progression_providers_test.dart` — ribbon seed re-pointed to `setExerciseCleanReps` in lockstep
- `test/features/practice/session_controller_test.dart`, `practice_screen_test.dart`, `getting_ready_test.dart`, `test/features/letter_unit/letter_unit_screen_test.dart`, `test/router/letter_unit_route_test.dart`, `test/screens/home_screen_test.dart` — extended fake `ProgressRepository` implementations to the folded interface (mapped onto each fake's existing rep store, so assertions are behavior-identical)

## RED/GREEN Evidence

| Test | RED | GREEN |
|------|-----|-------|
| `app_database_test.dart` (3 fold-accessor tests) | compile error — `letterCleanReps`/`watchLetterCleanReps`/`allInProgressByExerciseReps` undefined | `+11 ~1` (skip = v6→v7 case) after implementing accessors |
| `progression_providers_test.dart` (ribbon aggregate) | `+4 -1` — provider still read LetterReps, so the LetterExerciseReps seed emitted 0 not 2 | `+19 ~1` across the full Task-2 verify suite after the re-point |

## Decisions Made

- **MAX aggregation rule** (see frontmatter). Purely DB-computable and behavior-identical to the old counter for the single-row legacy path; the aggregate is display/resume only, never the star gate (isMasteryMet unchanged).
- **Re-point the practice provider (option A), not retire it.** It is still live for non-unit letters, and retiring would zero the home ink-fill + resume for those letters (not behavior-preserving). Its write-through banks a single synthetic `__whole_letter__` exercise row.
- **Kept the legacy `LetterReps` accessors** on the DB and the interface (present-but-unused) so the migration/allInProgress DB-level tests stay green and 19-06 owns the removal.
- **QP-09 left open** — this plan is fold-prep; 19-06 completes the keying migration and un-skips the migration case.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Extended the shared `ProgressRepository` interface forced fake updates across 6 test files**
- **Found during:** Task 1 (surfacing the folded accessors on the interface, as the plan's acceptance requires)
- **Issue:** Adding `letterCleanReps` / `watchLetterCleanReps` / `setLetterCleanReps` to the `ProgressRepository` interface makes every `implements ProgressRepository` fake non-compiling until it implements them. Five of the affected test files are outside the plan's declared `files_modified`, but the tree cannot compile without them.
- **Fix:** Added the three methods to each fake, mapped onto its existing rep store (`reps` / `_reps`) — or a no-op/0 for the const-return fakes — so every test body is behavior-identical after the practice provider re-points onto the folded seam. The throwing fake overrides `letterCleanReps`/`setLetterCleanReps` to throw so the "persistence failures are swallowed" test still exercises a failing read+write.
- **Files modified:** `session_controller_test.dart`, `practice_screen_test.dart`, `getting_ready_test.dart`, `letter_unit_screen_test.dart`, `letter_unit_route_test.dart`, `home_screen_test.dart`
- **Verification:** `flutter analyze` → 0 errors (no "missing concrete implementation"); `flutter test test/features/practice/session_controller_test.dart` → 16/16 pass; full Task-2 verify suite `+19 ~1`.
- **Committed in:** `dfb1008` (Task 1 — fakes) + `1390613` (Task 2 — re-point)

---

**Total deviations:** 1 (Rule 3 — blocking, interface fold-in-lockstep)
**Impact on plan:** No scope creep — the fake updates are the mechanical, unavoidable consequence of the plan-required interface surface. No behavior changed in the affected suites.

## Issues Encountered

- **`having` is a named parameter of `groupBy`, not a `JoinedSelectStatement` method** (Drift API) — the initial `..having(...)` did not compile; moved it to `groupBy([...], having: ...)`. Resolved before the first run.
- **Pre-existing golden failure (out of scope):** `test/features/practice/mastery_celebration_golden_test.dart` fails with a 2px font-drift diff. Verified it **also fails on `HEAD` before this plan's Task-2 changes**, and it lives in a widget this fold does not touch — the documented font-rendering drift (memory: "Golden tests font drift … don't re-bake"; 19-01 SUMMARY). **Not re-baked**, not fixed. It is NOT in the plan's Task-2 verify suite (`test/providers/ test/features/parent/ test/data/app_database_test.dart`), which is fully green.

## User Setup Required

None — no external service configuration required (no packages added).

## Next Phase Readiness

- **19-06 unblocked:** every live reader now points at the `LetterExerciseReps` aggregate; `LetterReps` is present-but-unused (grep-clean in `lib/providers/`), so 19-06 can DROP `letter_reps` in the v6→v7 `TableMigration` and un-skip the migration case (`skip: 'v6→v7 lands in 19-06 (QP-09)'`) as its only permitted edit to `app_database_test.dart`.
- **QP-09 remains open** — completed by 19-06 (keying migration + table drop).
- **Do NOT re-bake goldens** (`mastery_celebration`, `glyph_audit`, `alif_reference`) — pre-existing font drift, not regressions.

---
*Phase: 19-question-presentation-overhaul-every-question-self-explanato*
*Completed: 2026-07-17*

## Self-Check: PASSED

- Files: all 6 lib files + `19-04-SUMMARY.md` FOUND.
- Commits: `dfb1008` FOUND, `1390613` FOUND.
