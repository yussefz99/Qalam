---
phase: 09-parent-dashboard
plan: 01
subsystem: testing
tags: [flutter, drift, riverpod, go_router, l10n, pbkdf2, pin, security, tdd-red]

# Dependency graph
requires:
  - phase: 05-profiles-onboarding
    provides: OnboardingGate redirect-gate pattern + the drift/flutter_test matcher-collision import convention
  - phase: 06-journey-progression
    provides: AppDatabase LetterMastery/LetterReps accessors + the in-memory simulated-restart (D-09) test shape
provides:
  - RED contract (3 new test files) pinning every Phase-9 PIN, cooldown, route-gate, and read-only-dashboard behavior before any implementation
  - The persisted brute-force cooldown survives-a-restart assertion (the phase's single most important security check)
  - 17 Phase-9 ARB copy keys with correct placeholders so downstream screens compile against real l10n
  - RED assertions for the not-yet-built allMastered()/allInProgress() read accessors
affects: [09-02-pin-service-and-accessors, 09-03-parent-gate-and-dashboard]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave-0 RED-by-missing-symbol contract (mirrors 05-01): tests import not-yet-built lib/ symbols and fail to compile — that compile failure IS the contract"
    - "Persisted-cooldown restart proof: a second AppDatabase over the SAME shared in-memory executor (D-09 shape) asserts the throttle survives a force-quit"

key-files:
  created:
    - test/services/pin_service_test.dart
    - test/router/parent_gate_test.dart
    - test/screens/parent_dashboard_test.dart
  modified:
    - test/data/app_database_test.dart
    - lib/l10n/app_en.arb

key-decisions:
  - "Drift in-progress rows class is LetterRep (not the research-guessed LetterRepData); mastered rows class is LetterMasteryData — verified against app_database.g.dart"
  - "Generated lib/l10n/app_localizations.dart is gitignored (regenerated on build) — not committed; only the source app_en.arb is tracked"
  - "parentSummary uses {mastered}/{total} int placeholders — the N-of-M denominator is never hardcoded to 28 (Pitfall 5)"

patterns-established:
  - "Phase-9 tests obscured-field assertion: find a TextField with obscureText == true AND keyboardType == TextInputType.number for the PIN entry"
  - "Read-only dashboard guard: assert no delete/edit/restore/clear IconButton AND no Text matching /delete|edit|reset|remove|clear/i"

requirements-completed: [S1-11]

# Metrics
duration: 3min
completed: 2026-06-13
---

# Phase 9 Plan 01: Parent-Dashboard Wave-0 RED Contract Summary

**Three failing test files + 17 l10n keys that pin every Phase-9 PIN-hash, persisted-cooldown, /parent route-gate, and read-only-dashboard behavior as executable assertions before any implementation exists.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-13T21:16:11Z
- **Completed:** 2026-06-13T21:19:43Z
- **Tasks:** 2
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments
- RED `pin_service_test.dart` pinning PBKDF2 hash/verify, salt randomness (same PIN → different stored hash), isPinSet, and — most importantly — a persisted brute-force cooldown that **survives a simulated restart** (T-09-01 / T-09-02).
- RED `parent_gate_test.dart` pinning default-deny on `/parent` (locked never leaks the dashboard), unlock-after-PIN, per-entry relock on "Done" (D-07), and an obscured numeric PIN field (T-09-03).
- RED `parent_dashboard_test.dart` pinning the `{mastered} of {total}` summary (denominator never hardcoded), mastered + in-progress rows, the calm empty state, and the read-only no-edit/delete constraint (T-09-04).
- Extended `app_database_test.dart` with RED assertions for the `allMastered()` / `allInProgress()` read accessors.
- Added all 17 Phase-9 ARB copy keys with correct placeholder types; `gen-l10n` regenerates `AppLocalizations` cleanly with the new getters.

## Task Commits

Each task was committed atomically:

1. **Task 1: RED test files for PIN service, route gate, and dashboard** - `f43f8a6` (test)
2. **Task 2: Extend app_database_test + add all Phase-9 ARB copy keys** - `d64de99` (feat)

**Plan metadata:** committed separately (docs: complete plan)

## Files Created/Modified
- `test/services/pin_service_test.dart` - RED: PinService hash/verify/salt-randomness/isPinSet + persisted-cooldown-survives-restart (S1-11, T-09-01/02)
- `test/router/parent_gate_test.dart` - RED: /parent default-deny, unlock-after-PIN, per-entry relock, obscured numeric field (T-09-03)
- `test/screens/parent_dashboard_test.dart` - RED: N-of-M summary, per-letter rows, empty state, read-only (T-09-04)
- `test/data/app_database_test.dart` - RED: allMastered()/allInProgress() read-accessor assertions (LetterMasteryData/LetterRep)
- `lib/l10n/app_en.arb` - 17 new Phase-9 copy keys (parentTitle, parentPin*, parentSummary, parentRow*, parentEmpty*, commonContinue/commonDone)

## Decisions Made
- **Drift data-class names corrected:** the research draft used `LetterRepData`, but the generated `app_database.g.dart` declares the in-progress row class as `LetterRep` (mastered rows are `LetterMasteryData`). The tests use the real names — verified against the generated file, as the plan instructed.
- **Generated l10n not committed:** `lib/l10n/app_localizations.dart` is gitignored and regenerated on build, so only the source `app_en.arb` is tracked. The new getters were confirmed present after `gen-l10n`.
- **`commonContinue` / `commonDone` newly added:** a grep confirmed neither key pre-existed, so both were created (no duplication).

## Deviations from Plan

None - plan executed exactly as written. The Drift class-name correction (`LetterRep` vs the research-draft `LetterRepData`) was an explicitly-instructed verification step ("Verify the Drift data-class names against app_database.g.dart"), not a deviation.

## Issues Encountered
None. All three new test files and the extended file are RED exactly as the Wave-0 contract requires — they fail to compile by the missing not-yet-built symbols (`PinService`, `parentGateProvider`/`ParentGate`, `ParentDashboardScreen`, `parentProgressProvider`/`ParentProgress`/`ParentLetterRow`, and `allMastered()`/`allInProgress()`). The l10n getters now resolve after `gen-l10n`.

## Known Stubs
None. This is a RED-contract plan by design — no production logic ships. The RED tests are the intended deliverable; 09-02 and 09-03 turn them green.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- **09-02** (Wave 1) implements `PinService` (PBKDF2 hash/verify + persisted cooldown) and the `allMastered()`/`allInProgress()` accessors — turning `pin_service_test.dart` and the `app_database_test.dart` additions green. Note: 09-02 adds the `crypto` package (pub.dev first-party, audited in 09-RESEARCH) and carries the package-legitimacy checkpoint — no package was installed in this plan.
- **09-03** (Wave 2) builds `parent_providers.dart` (`parentGateProvider`/`ParentGate`, `parentProgressProvider`, `ParentProgress`, `ParentLetterRow`) and `ParentDashboardScreen` + the `/parent` route — turning `parent_gate_test.dart` and `parent_dashboard_test.dart` green.
- All downstream screens can now compile against real l10n getters.

## Self-Check: PASSED

All 6 deliverable files exist on disk and both task commits (`f43f8a6`, `d64de99`) are present in git history.

---
*Phase: 09-parent-dashboard*
*Completed: 2026-06-13*
