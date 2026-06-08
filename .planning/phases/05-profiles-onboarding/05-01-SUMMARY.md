---
phase: 05-profiles-onboarding
plan: 01
subsystem: testing
tags: [flutter, drift, riverpod, go_router, tdd, nyquist, onboarding, child-profile]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: AppDatabase Drift seam + NativeDatabase.memory() restart-sim test idiom
  - phase: 03-practice-loop
    provides: LetterMastery table + DriftProgressRepository test analog
  - phase: 03.1-journey-map-screen
    provides: HomeScreen greeting + GoRouter-as-provider + demo_routes_test gate analog
provides:
  - Failing-test contract (RED) for the entire Phase 5 onboarding feature
  - S1-02 data-layer assertions (profile persist/restart, grade->alif resolver, v2->v3 migration)
  - S1-03 no-free-text + PopScope invariants encoded as executable assertions
  - Onboarding redirect-gate + no-loop invariant encoded against a _SentinelError errorBuilder
affects: [05-02 child-profile-data-layer, 05-03 onboarding-screen, 05-04 router-gate, home-greeting-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave 0 RED-first contract: tests reference not-yet-built symbols on purpose"
    - "drift/drift.dart imported with `hide isNull, isNotNull` to avoid matcher collision"
    - "Recording test-double implementing the repository interface for screen happy-path"
    - "Inline gated GoRouter + _SentinelError errorBuilder to assert no-redirect-loop"

key-files:
  created:
    - test/data/child_profile_repository_test.dart
    - test/features/onboarding/onboarding_data_test.dart
    - test/features/onboarding/onboarding_screen_test.dart
    - test/router/onboarding_gate_test.dart
  modified:
    - test/data/app_database_test.dart
    - test/screens/home_screen_test.dart

key-decisions:
  - "Pinned nick_star -> display label 'نجمة' (Najma) in the home greeting test per PATTERNS placeholder set"
  - "Asserted startingLessonId == 'alif' for grade kg to lock the S1-02 default seam"
  - "Used keyed fixed-set cells (grade_kg, avatar_avatar_1, nickname_nick_star, onboardingSubmit) as the screen tap contract"

patterns-established:
  - "Wave 0 Nyquist contract: every S1-02/S1-03/gate behavior has an executable RED assertion before implementation"
  - "Drift matcher de-collision: `import 'package:drift/drift.dart' hide isNull, isNotNull;` in tests that use flutter_test null matchers"

requirements-completed: []

# Metrics
duration: 18min
completed: 2026-06-08
---

# Phase 05 Plan 01: Wave 0 Failing-Test Contract Summary

**RED test contract for the whole Phase 5 onboarding feature — S1-02 profile persistence + grade->alif resolver + v2->v3 migration, and S1-03 no-free-text / PopScope / no-redirect-loop invariants — all failing against not-yet-built symbols.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-08
- **Completed:** 2026-06-08
- **Tasks:** 2
- **Files modified:** 6 (4 created, 2 extended)

## Accomplishments
- Authored 4 new RED test files + extended 2 existing ones, covering every Phase 5 requirement row in 05-VALIDATION.md.
- Encoded S1-03's no-free-text invariant as `find.byType(TextField/TextFormField/EditableText) findsNothing` plus a `PopScope(canPop: false)` assertion.
- Encoded the redirect gate's no-loop invariant using a real `GoRouter` + `_SentinelError` errorBuilder (mirrors demo_routes_test).
- Verified all six files are RED (compile-fail on absent Wave 1-3 symbols) by running them through the Flutter SDK — no false greens.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the data-layer RED tests (S1-02)** - `aa1b969` (test)
2. **Task 2: Author the screen + router RED tests (S1-03, gate)** - `938d2f0` (test)

## Files Created/Modified
- `test/data/child_profile_repository_test.dart` - S1-02 create/persist/restart-survival + hasProfile contract against `ChildProfileRepository` (RED)
- `test/features/onboarding/onboarding_data_test.dart` - grade->alif map covers every grade option, default fallback, 6 avatars, 8-10 nicknames, ID uniqueness (RED)
- `test/features/onboarding/onboarding_screen_test.dart` - S1-03 no-free-text + `PopScope(canPop:false)` + tap-to-persist-and-navigate via a recording repository double (RED)
- `test/router/onboarding_gate_test.dart` - no-profile->/onboarding, profile->/, no loop after `markProfileCreated()` via `_SentinelError` (RED)
- `test/data/app_database_test.dart` - extended with v2->v3 `ChildProfiles` migration test preserving `AppSettings` + `LetterMastery` rows (RED); existing D-09 test untouched
- `test/screens/home_screen_test.dart` - greeting test now overrides `childProfileProvider` and asserts resolved nickname label 'نجمة' + keyed avatar instead of hardcoded 'Layla'; anti-gamification Test 3 unchanged (RED)

## Decisions Made
- Pinned `nick_star` -> display label `'نجمة'` (Najma) in the home greeting assertion, matching the placeholder nickname set in 05-PATTERNS.md. This is a placeholder pending the owner's mother's sign-off; the label-by-ID mapping means it can change with no data migration.
- Asserted `startingLessonId == 'alif'` for grade `kg` to lock the S1-02 default seam (all grades -> alif until real per-grade entry points are supplied).
- Chose stable widget Keys (`grade_kg`, `avatar_avatar_1`, `nickname_nick_star`, `onboardingSubmit`, `homeAvatar_avatar_1`) as the tap/finder contract the Wave-3 screen must honor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Hid Drift's `isNull`/`isNotNull` from the drift import in two test files**
- **Found during:** Task 1 (data-layer tests) and the app_database_test extension
- **Issue:** `package:drift/drift.dart` exports query-builder matchers `isNull`/`isNotNull` that collide with `flutter_test`'s expectation matchers of the same name, producing an ambiguous-import compile error unrelated to the intended RED state.
- **Fix:** Changed the import to `import 'package:drift/drift.dart' hide isNull, isNotNull;` in `test/data/child_profile_repository_test.dart` and `test/data/app_database_test.dart` so the matcher versions resolve.
- **Files modified:** test/data/child_profile_repository_test.dart, test/data/app_database_test.dart
- **Verification:** The collision error disappeared; remaining errors are only the intended absent-symbol RED errors.
- **Committed in:** `aa1b969` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to keep RED meaning "implementation absent" rather than "test harness broken." No scope creep — tests-only, no production code touched.

## Issues Encountered
- `flutter` is not on the Bash PATH in this environment; resolved by invoking the VS Code-bundled SDK at `C:\Users\yusse\.vscode\flutter\bin\flutter.bat` (Flutter 3.41.7 / Dart 3.11.5) via `cmd.exe /c` to run the RED verification.

## Threat Flags

None — no new security surface beyond the plan's `<threat_model>`. The new tests actively encode the T-05-01 (no free-text PII) and T-05-02 (fixed-set tampering) mitigations as assertions.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Every Wave 1-3 task now has a concrete `<automated>` RED target — no "MISSING — Wave 0 must create…" gaps remain.
- Implementation plans must produce these exact symbols: `ChildProfiles` table + `createProfile`/`getProfile`/`hasProfile` accessors, `ChildProfileRepository` (+ `childProfileRepositoryProvider`), `onboarding_data.dart` (`kAvatarIds`, `kNicknames`, `gradeToStartingLessonId`, `resolveStartingLessonId`), `OnboardingScreen`, `profile_providers.dart` (`childProfileProvider`, `OnboardingGate`/`onboardingGateProvider`), and the keyed widgets listed above.
- Reminder for the implementer: the home greeting test expects nickname label `'نجمة'` for `nick_star` and a widget keyed `homeAvatar_avatar_1`.

---
*Phase: 05-profiles-onboarding*
*Completed: 2026-06-08*
