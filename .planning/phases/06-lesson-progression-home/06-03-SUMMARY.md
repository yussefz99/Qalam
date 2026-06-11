---
phase: 06-lesson-progression-home
plan: 03
subsystem: providers
tags: [flutter, riverpod, drift, streams, go_router, deep-link, tdd]

# Dependency graph
requires:
  - phase: 06-lesson-progression-home plan 01
    provides: ProgressionSnapshot.compute / todayLesson engine + lesson catalog
  - phase: 06-lesson-progression-home plan 02
    provides: ProgressRepository watch streams (watchMasteredLetterIds / watchCleanReps)
  - phase: 05-profiles-onboarding
    provides: childProfileProvider + onboarding redirect gate (matchedLocation path-only)
provides:
  - "masteredLetterIdsProvider / cleanRepsForLetterProvider: AsyncNotifiers fed by ProgressRepository watch streams (first emission completes build, later emissions push state)"
  - "progressionProvider / todayLessonProvider: recompute on every mastery emission via .future watch — zero invalidate (S1-09 immediacy)"
  - "/practice?lesson= deep link with ValueKey-fresh PracticeScreen State + catalog-allowlist degradation (T-06-03)"
  - "/journey?highlight= inert param staged for 06-06 (D-15)"
  - "Home copy-contract ARB keys for 06-05: homeLessonTitleFor, homeAllMastered*, homeInkFillSemantics"
affects: [06-04 ramp, 06-05 home, 06-06 journey, 06-07 celebration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Drift-stream → AsyncNotifier bridge (_bindDriftStream): Riverpod 3 pauses unlistened StreamProvider subscriptions, leaving bare container.read(.future) hanging — AsyncNotifier build runs to completion on first read"
    - "Repository-seam providers: progression providers consume progressRepositoryProvider (fakeable), never appDatabaseProvider directly"
    - "Bounded profile await with degradation: .timeout(3s) catch → first-lesson fallback; ref.watch keeps the dependency live so late resolution self-heals (T-05-07)"
    - "Route query params via state.uri.queryParameters on hand-written GoRoute builders; gate untouched (matchedLocation is path-only)"

key-files:
  created:
    - lib/providers/progression_providers.dart
    - test/providers/progression_providers_test.dart
  modified:
    - lib/router/app_router.dart
    - lib/features/practice/practice_screen.dart
    - lib/features/journey/journey_screen.dart
    - lib/l10n/app_en.arb
    - test/router/onboarding_gate_test.dart

key-decisions:
  - "StreamProvider REJECTED for the mastery/reps providers: probe-verified on flutter_riverpod 3.3.1 that bare container.read(streamProvider.future) never resolves (paused without listeners). AsyncNotifier bridge keeps the same reactivity with working .future reads."
  - "Providers consume the ProgressRepository seam, not appDatabaseProvider — widget tests fake the repository without a database (discovered when practice_screen_test broke against the DB-direct wiring)."
  - "childProfileProvider await is bounded (3s timeout → degrade to first lesson): the unoverridden profile read HANGS in headless test envs (platform-channel future never completes); production self-heals via the live ref.watch dependency."
  - "PracticeScreen resolves its lesson once in initState (catalog allowlist → today → 'lesson_01'), rendering the neutral loading treatment while resolving."

patterns-established:
  - "_bindDriftStream: the project's canonical drift-stream → Riverpod bridge for .future-readable live data"

requirements-completed: []  # S1-01/S1-09 span all 8 phase plans; REQUIREMENTS.md updated by orchestrator at phase close

# Metrics
duration: ~75min (incl. two permission-gate interruptions + Riverpod 3 semantics debugging)
completed: 2026-06-11
---

# Phase 06 Plan 03: Live Progression Providers + Lesson Routes Summary

**Stream-derived progression providers (AsyncNotifier bridge over drift watch streams, zero-invalidation S1-09 immediacy) plus `/practice?lesson=` and `/journey?highlight=` deep links that provably cannot disturb the Phase-5 onboarding gate.**

## Performance

- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments
- recordMastery → providers recompute with zero invalidate calls (proven: the contract test file contains no manual refresh)
- D-06 entry-point honored: startingLessonId lesson_03 → today is lesson_03; mastering a skipped earlier letter does not move today
- /practice?lesson=lesson_02 reaches a fresh PracticeScreen State (ValueKey); junk `?lesson=` degrades silently to today's lesson (catalog allowlist, T-06-03)
- Gate tests extended: query params neither bypass the no-profile redirect nor get stripped for profiled users (T-06-06)
- Home copy contract (5 ARB keys incl. a11y-only ink-fill label) staged for 06-05

## Task Commits

1. **Task 1: Wave-0 RED — stream-driven immediacy provider tests** - `7e4b39c` (test)
2. **Task 2: GREEN — live progression providers over drift streams** - `1df3382` (feat)
3. **Task 3: Route query params + lessonId-aware PracticeScreen + Home ARB keys** - `b7ed83e` (feat)

## Decisions Made
See key-decisions frontmatter — the load-bearing one for downstream plans: **Riverpod 3 pauses unlistened stream subscriptions**, so any provider whose `.future` must resolve on a bare read needs the `_bindDriftStream` AsyncNotifier bridge, not StreamProvider.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] StreamProvider .future hangs without listeners (Riverpod 3.3.1)**
- **Found during:** Task 2 GREEN verification (initial-state contract test timed out)
- **Issue:** Plan/research assumed StreamProvider over drift .watch(); bare `.future` reads never resolve under Riverpod 3 pause semantics (reproduced with a minimal probe)
- **Fix:** AsyncNotifier bridge (_bindDriftStream) — build future completes on first emission, later emissions push state
- **Verification:** all 5 contract tests green, unmodified
- **Committed in:** 1df3382

**2. [Rule 1 - Bug] Providers bypassed the ProgressRepository seam**
- **Found during:** Task 3 verification (practice_screen_test went 2→6 failures)
- **Issue:** Providers watched appDatabaseProvider directly; widget tests fake progressRepositoryProvider and have no database
- **Fix:** Consume progressRepositoryProvider; add bounded (3s) profile await with first-lesson degradation for the headless-env platform-channel hang
- **Verification:** practice_screen_test 6/6 green, provider contract 5/5 green
- **Committed in:** b7ed83e

---

**Total deviations:** 2 auto-fixed (both Rule 1 correctness)
**Impact on plan:** Architecture improved (repository seam honored); no scope creep.

## Issues Encountered
- **Bash permission denials in executor subagents** (same anomaly as 06-02): Task 1's commit and all of the continuation agent's Bash were denied. The orchestrator committed Task 1's staged work, verified/committed Task 2's agent-written code, and executed Task 3 inline. All TDD gates preserved (RED 7e4b39c precedes GREEN 1df3382).

## User Setup Required

None.

## Next Phase Readiness
- 06-04 can read cleanRepsForLetterProvider + setCleanReps for the ramp
- 06-05 watches todayLessonProvider + the staged ARB keys
- 06-06 watches progressionProvider (unlockedLessonIds, lessonIdByLetterId) + consumes JourneyScreen.highlightId

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-11*
