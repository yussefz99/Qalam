---
phase: 06-lesson-progression-home
plan: 02
subsystem: database
tags: [flutter, dart, drift, sqlite, migration, schema-v4, streams, tdd]

# Dependency graph
requires:
  - phase: 03-first-traceable-letter
    provides: LetterMastery table + ProgressRepository/DriftProgressRepository pass-record substrate
  - phase: 05-profiles-onboarding
    provides: ChildProfiles table (schema v3), onboarding_data gradeToStartingLessonId/resolveStartingLessonId seam
provides:
  - "Schema v4: LetterReps table (letterId + cleanRepCount + updatedAt only — no PII) with idempotent v3→v4 migration preserving AppSettings, LetterMastery, ChildProfiles"
  - "startingLessonId namespace normalized: v4 migration rewrites stored 'alif' → 'lesson_01'; gradeToStartingLessonId now emits lesson ids"
  - "drift .watch() streams: watchMasteredLetterIds + watchCleanReps on ProgressRepository (S1-09 immediacy substrate)"
  - "ProgressRepository extension: setCleanReps / getCleanReps with write-through overwrite semantics (reset-to-0 supported for 06-04)"
affects: [06-03 providers, 06-04 practice-ramp, 06-05 home, 06-06 journey]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Idempotent migration ladder: if (from < 4) block extends the v2→v3 precedent in app_database.dart"
    - "Stream-first repository: watch* methods return drift .watch() streams, never polled queries"
    - "Migration test against temp-file DB (not in-memory) so the v3→v4 path runs against a real persisted schema"
    - "Drift + flutter_test: import 'package:drift/drift.dart' hide isNull, isNotNull; in mixed tests"

key-files:
  created: []
  modified:
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart
    - lib/data/progress_repository.dart
    - lib/data/drift_progress_repository.dart
    - lib/features/onboarding/onboarding_data.dart
    - test/data/app_database_test.dart
    - test/data/progress_repository_test.dart
    - test/features/onboarding/onboarding_data_test.dart
    - test/features/onboarding/onboarding_screen_test.dart
    - test/screens/home_screen_test.dart

key-decisions:
  - "LetterReps stores letterId + cleanRepCount + updatedAt only — child-data minimization (T-06-01), no PII beyond what LetterMastery already holds"
  - "startingLessonId migration does BOTH the stored-row rewrite (customStatement in v4) AND the resolver code change — doing only one leaves mixed namespaces"
  - "setCleanReps uses overwrite semantics (not increment) so 06-04's reset-on-miss is a plain setCleanReps(0)"
  - "Migration test uses a temp-file database so the v3→v4 upgrade path runs against a genuinely persisted schema"

patterns-established:
  - "watch* repository methods: drift .watch() streams as the only reactivity substrate (first StreamProvider-feeding usage in lib/)"

requirements-completed: []  # S1-01/S1-09 span all 8 phase plans; REQUIREMENTS.md updated by orchestrator at phase close

# Metrics
duration: ~30min
completed: 2026-06-11
---

# Phase 06 Plan 02: Schema v4 — LetterReps, Watch Streams, Lesson-Id Namespace Summary

**Schema v4 ships the LetterReps persisted-rep table with an idempotent v3→v4 migration, drift `.watch()` streams on ProgressRepository, and the startingLessonId 'alif'→'lesson_01' namespace normalization (stored rows + resolver).**

## Performance

- **Duration:** ~30 min (agent) + orchestrator-assisted closeout
- **Tasks:** 3/3
- **Files modified:** 12

## Accomplishments
- LetterReps table at schema v4: letterId PK + cleanRepCount + updatedAt, nothing else (child-data minimization, T-06-01)
- v3→v4 migration is idempotent and preserves AppSettings, LetterMastery, and ChildProfiles; verified against a temp-file (persisted) database simulating a real upgrade
- `watchMasteredLetterIds` / `watchCleanReps` expose drift `.watch()` streams — the S1-09 "immediate unlock" substrate for 06-03's providers
- `setCleanReps` / `getCleanReps` with overwrite semantics (reset-to-0 works for 06-04's ramp reset-on-miss)
- startingLessonId namespace fixed in BOTH places: v4 `customStatement` rewrites stored `'alif'` rows to `'lesson_01'`, and `gradeToStartingLessonId` now emits lesson ids (grep: `'alif'` count 0 in onboarding_data.dart, `lesson_01` count 7)

## Task Commits

1. **Task 1: RED — v3→v4 migration + rep-persistence + stream tests** - `4449c43` (test)
2. **Task 2: GREEN — schema v4: LetterReps, idempotent migration, watch streams** - `78de0a4` (feat)
3. **Task 3: Repository extension + lesson-id namespace** - `f4da948` (feat)

## Decisions Made
- Three practice-test fakes gained the new ProgressRepository interface members (required for compilation; no behavior change)
- Two stale provider `.g.dart` files re-synced by build_runner during Task 2 (generated artifacts, committed with the schema change)
- Migration test switched from in-memory to temp-file DB so the upgrade path is exercised against persisted state

## Deviations from Plan

None of substance — plan executed as written. One execution anomaly (see Issues).

## Issues Encountered
- **Mid-session Bash permission denial on `git commit`** blocked Task 3's commit inside the executor agent (work complete, staged, verified). The orchestrator committed the staged changes (`f4da948`) and wrote this SUMMARY from the agent's structured checkpoint report. All verification had already passed inside the agent: `flutter test test/data/ test/features/onboarding/` → 32/32 green; home_screen_test shows only the documented stale Test 4 (06-05's debt); all acceptance greps pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- 06-03 can build stream-derived providers on `watchMasteredLetterIds`/`watchCleanReps`
- 06-04 has `setCleanReps` overwrite semantics for ramp write-through + reset-on-miss
- Namespace is consistent: every stored and resolved startingLessonId is a lesson id

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-11*
