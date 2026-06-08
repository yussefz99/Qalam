---
phase: 05-profiles-onboarding
plan: 02
subsystem: data
tags: [flutter, drift, riverpod, child-profile, onboarding, migration, s1-02, s1-03]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: AppDatabase Drift seam + NativeDatabase.memory() restart-sim idiom + appDatabaseProvider
  - phase: 03-practice-loop
    provides: LetterMastery v1->v2 migration template + DriftProgressRepository analog
  - plan: 05-01
    provides: RED data-layer test contract (ChildProfileRepository API, ChildProfiles migration, grade->alif resolver, fixed-set shape)
provides:
  - ChildProfiles Drift table at schema v3 (fixed-set IDs only, no real name)
  - v2->v3 idempotent migration preserving AppSettings + LetterMastery rows
  - AppDatabase.hasProfile/getProfile/createProfile accessors
  - ChildProfileRepository + childProfileRepositoryProvider (keepAlive)
  - childProfileProvider (invalidatable FutureProvider<ChildProfile?>)
  - OnboardingGate ChangeNotifier + onboardingGate provider (router refreshListenable)
  - onboarding_data.dart (kAvatarIds, kNicknames, gradeToStartingLessonId, resolveStartingLessonId)
affects: [05-03 onboarding-screen, 05-04 router-gate, home-greeting-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ChildProfiles v2->v3 migration mirrors the LetterMastery v1->v2 version-guarded idiom"
    - "Hand-written FutureProvider for a Drift-generated return type (riverpod_generator 4.0.3 InvalidTypeException workaround)"
    - "ChangeNotifier-as-provider (OnboardingGate) for the router refreshListenable seam"
    - "ID->label / ID->asset mapping lives in code (onboarding_data.dart), never in the DB"

key-files:
  created:
    - lib/data/child_profile_repository.dart
    - lib/data/child_profile_repository.g.dart
    - lib/providers/profile_providers.dart
    - lib/providers/profile_providers.g.dart
    - lib/features/onboarding/onboarding_data.dart
  modified:
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart

key-decisions:
  - "childProfileProvider is a hand-written FutureProvider (not @riverpod codegen) because riverpod_generator 4.0.3 throws InvalidTypeException when a functional provider's return type is a Drift-generated data class"
  - "Shipped 8 placeholder Arabic nicknames (within the required 8-10) flagged for the owner's mother's sign-off"
  - "All five grades map to 'alif' (a letter id) via a single-source map, with a namespace flag for Phase 6 (letter id vs lesson id)"

patterns-established:
  - "When riverpod_generator cannot emit a generated (Drift) type as a provider return type, drop to a plain hand-written FutureProvider — it preserves the .overrideWith((ref) async => value) test contract"

requirements-completed: [S1-02, S1-03]

# Metrics
duration: 20min
completed: 2026-06-08
---

# Phase 05 Plan 02: Wave 1 Child-Profile Data Foundation Summary

**Added the `ChildProfiles` Drift table (schema v3, fixed-set IDs only — no real name), a `ChildProfileRepository`, the invalidatable `childProfileProvider`, the `OnboardingGate` router seam, and `onboarding_data.dart` (6 avatars, 8 placeholder nicknames, all-grades->alif resolver) — turning Wave 0's data-layer RED tests GREEN.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-08T16:43Z
- **Completed:** 2026-06-08T17:04Z
- **Tasks:** 2
- **Files modified:** 7 (5 created, 2 extended)

## Accomplishments
- `ChildProfiles` table with `id/nicknameId/avatarId/grade/startingLessonId/createdAt` — NO real-name / free-text column (S1-03 / T-05-01).
- Schema bumped v2->v3 with an idempotent `if (from < 3) await m.createTable(childProfiles);` line; existing `if (from < 2)` line untouched; `_ownsExecutor`/`close()` logic untouched (Pitfall 7).
- `hasProfile/getProfile/createProfile` accessors mirroring the `recordMastery`/`getSetting` style; profile values never logged.
- `ChildProfileRepository` (copy-and-rename of `drift_progress_repository.dart`) + `childProfileRepositoryProvider` (`@Riverpod(keepAlive: true)`).
- `childProfileProvider` invalidatable `FutureProvider<ChildProfile?>` so Wave 2 can `ref.invalidate` it after onboarding.
- `OnboardingGate extends ChangeNotifier` with `markProfileCreated()` -> `notifyListeners()`, plus its keepAlive provider (the router's `refreshListenable`, overridden at boot in Wave 2).
- `onboarding_data.dart`: `kAvatarIds` (6), `kNicknames` (8 placeholder Arabic ID+label pairs), `gradeToStartingLessonId` (5 keys -> 'alif'), `resolveStartingLessonId` (unknown -> 'alif'), with two LOUD `TODO(owner's-mother sign-off)` comments and a Phase-6 letter-id-vs-lesson-id namespace flag.
- Load-bearing constants from Wave 0 honored: grade `kg` -> `startingLessonId 'alif'`; `nick_star` -> `'نجمة'`; ids `avatar_1`, `nick_star`, grades `kg`/`grade1`/`grade2`/`grade3`/`grade4plus`.

## Task Commits

Each task was committed atomically:

1. **Task 1: ChildProfiles table + v2->v3 migration + accessors** - `555e40a` (feat)
2. **Task 2: ChildProfileRepository + profile_providers + onboarding_data** - `2363ed9` (feat)

## Files Created/Modified
- `lib/data/app_database.dart` - +`ChildProfiles` table, +`ChildProfiles` in `@DriftDatabase`, schemaVersion 2->3, +v2->v3 migration line, +`hasProfile/getProfile/createProfile` accessors.
- `lib/data/app_database.g.dart` - regenerated (adds `childProfiles` getter, `ChildProfile` data class, `ChildProfilesCompanion`).
- `lib/data/child_profile_repository.dart` - `ChildProfileRepository` + `childProfileRepositoryProvider` (keepAlive).
- `lib/data/child_profile_repository.g.dart` - regenerated provider.
- `lib/providers/profile_providers.dart` - hand-written `childProfileProvider` + `OnboardingGate` + codegen `onboardingGate`.
- `lib/providers/profile_providers.g.dart` - regenerated `onboardingGate` provider.
- `lib/features/onboarding/onboarding_data.dart` - fixed sets + grade resolver (mechanism only; placeholders flagged for owner sign-off).

## Decisions Made
- **`childProfileProvider` is a hand-written `FutureProvider`, not `@riverpod` codegen.** riverpod_generator 4.0.3 throws `InvalidTypeException: The type is invalid and cannot be converted to code.` whenever a functional provider's return type is a Drift-generated data class (`ChildProfile`, declared in `app_database.g.dart`). Verified the failure persists for both nullable (`Future<ChildProfile?>`) and non-nullable (`Future<ChildProfile>`) forms and across arrow/async/block bodies and an explicit `show ChildProfile` import — so the trigger is the generated return type, not nullability or body shape. The hand-written `FutureProvider<ChildProfile?>` is the idiomatic Riverpod escape hatch and preserves the exact Wave-0 test contract (`childProfileProvider.overrideWith((ref) async => profile)` with a `ChildProfile?` value). `onboardingGate` (return type is the hand-written `OnboardingGate` class) stays on codegen.
- **Shipped 8 placeholder Arabic nicknames** (within the required 8-10 inclusive): نجمة, قمر, أسد, شمس, وردة, عصفور, بحر, غيمة — all flagged `TODO(owner's-mother sign-off)`.
- **All five grades -> 'alif'** via a single-source map; left a Phase-6 namespace flag (letter id `alif` vs a future distinct lesson id) so a rename is one edit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `childProfileProvider` switched from `@riverpod` codegen to a hand-written `FutureProvider`**
- **Found during:** Task 2 (`dart run build_runner build`).
- **Issue:** riverpod_generator 4.0.3 aborts with `InvalidTypeException: The type is invalid and cannot be converted to code.` when generating a functional provider whose return type is the Drift-generated `ChildProfile` data class. This blocked all codegen (`wrote 0 outputs`), so even `onboardingGate`'s generated provider could not be produced.
- **Fix:** Declared `childProfileProvider` as a plain `final childProfileProvider = FutureProvider<ChildProfile?>((ref) => ref.watch(childProfileRepositoryProvider).getProfile());`. This sidesteps the generator entirely for this one provider while keeping the identical public API and the Wave-0 `.overrideWith((ref) async => profile)` contract. `onboardingGate` remains `@riverpod`.
- **Files modified:** lib/providers/profile_providers.dart
- **Verification:** `dart run build_runner build` then succeeds (`Built ... wrote 10 outputs`); `flutter test test/data/ test/features/onboarding/onboarding_data_test.dart` -> all 24 green.
- **Committed in:** `2363ed9` (Task 2 commit).

---

**Total deviations:** 1 auto-fixed (1 blocking). The plan's `<action>` for Task 2 prescribed a `@riverpod Future<ChildProfile?> childProfile(Ref ref)`; the blocking generator bug forced the equivalent hand-written FutureProvider. No public-API or test-contract change resulted.

## Deferred Issues

**`unsupported_provider_value` warning on `onboardingGate` (1 analyzer warning).**
`flutter analyze` reports exactly one warning: `The value returned by the provider is not supported` at the `onboardingGate` declaration, because `OnboardingGate` is a `ChangeNotifier` rather than Future/Stream state. This is the exact `ChangeNotifier`-as-`refreshListenable` provider shape prescribed by 05-PATTERNS.md (the router gate seam). It is a riverpod_lint plugin false-positive for a deliberate design. Three suppression attempts were made and the plugin does **not** honor inline `// ignore:`, an `// ignore:` between annotation and declaration, or `// ignore_for_file:` for this diagnostic in the current toolchain (riverpod_lint 3.1.3). The warning is therefore left visible and documented in-code; no functional impact. The plan's verification line ("flutter analyze exits 0") is met except for this single un-suppressible, intentional, prescribed-pattern warning.

## Known Stubs

`onboarding_data.dart` ships **intentional placeholders** flagged for the owner's mother's sign-off (per 05-CONTEXT.md "Out of Scope" — final values are her domain, Phase 5 ships the mechanism):
- `kNicknames` — 8 placeholder Arabic ID+label pairs (`TODO(owner's-mother sign-off): finalize the nickname wording`). The profile stores the id, so labels change with no data migration.
- `gradeToStartingLessonId` — all grades -> `'alif'` (`TODO(owner's-mother sign-off): replace 'alif' with real per-grade entry-point ids`). Single-source map; the mechanism is complete and tested.

These are deliberate per the locked Phase-5 decisions, not unfinished work, and do not block the plan's goal (the data layer + resolver mechanism is fully wired and tested).

## Threat Flags

None — no new security surface beyond the plan's `<threat_model>`. T-05-01 (no free-text PII) is satisfied: the `ChildProfiles` table has only fixed-set IDs + grade + startingLessonId + createdAt and is never logged. T-05-04 (unknown grade) is satisfied: `resolveStartingLessonId` falls back to `'alif'` (covered by `onboarding_data_test`). No packages added (T-05-SC).

## User Setup Required
None — no external service configuration required (local-only, no Firebase this phase).

## Next Phase Readiness
- Wave 2/3 can now build the `OnboardingScreen` against the real data layer: read `kAvatarIds`/`kNicknames`/`resolveStartingLessonId`, call `ref.read(childProfileRepositoryProvider).create(...)`, then `ref.read(onboardingGateProvider).markProfileCreated()` + `ref.invalidate(childProfileProvider)`.
- `main.dart` boot override seam is ready: `onboardingGateProvider.overrideWith((ref) => OnboardingGate(hasProfile))` + the existing `appDatabaseProvider` override.
- Home greeting integration can watch `childProfileProvider` and resolve `nicknameId -> label` via `kNicknames`.
- The still-RED Wave 2/3 tests (`onboarding_screen_test`, `onboarding_gate_test`, extended `home_screen_test`) remain targets for later plans — out of scope here.

## Self-Check: PASSED

- All 7 files verified present on disk (5 created, 2 extended).
- Both task commits (555e40a, 2363ed9) verified in git log.
- All 24 Wave-1-owned tests verified GREEN (`test/data/` + `test/features/onboarding/onboarding_data_test.dart`).
- `dart run build_runner build` succeeds and the three `.g.dart` files are regenerated + committed.

---
*Phase: 05-profiles-onboarding*
*Completed: 2026-06-08*
