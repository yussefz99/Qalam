---
phase: 05-profiles-onboarding
verified: 2026-06-08T00:00:00Z
status: human_needed
score: 3/3 must-haves verified
overrides_applied: 0
human_verification:
  - test: "End-to-end first-launch flow on a fresh install"
    expected: "App opens on /onboarding (not Home); Android back button does nothing; no text field or keyboard appears; grade chips, 6 avatar circles, and nickname grid are visible with correct Arabic glyph shaping; tapping grade + avatar + nickname then 'Let's go' lands on Home; force-quit + relaunch opens directly on Home (onboarding skipped)"
    why_human: "Visual layout, correct Arabic connected-glyph rendering (no tofu), and the full device-level back-button + force-quit-restart cycle cannot be verified by grep or widget tests alone"
  - test: "Home greeting shows the chosen nickname + avatar after onboarding"
    expected: "The chosen nickname's Arabic label renders as a correctly-shaped glyph in the greeting header (not the hardcoded 'Layla'); the matching placeholder avatar circle is visible beside it; no gold/reward chrome is present"
    why_human: "Arabic glyph correctness (Noto Naskh shaping for each of the 8 placeholder labels) requires visual inspection; automated tests only check the widget predicate, not rendering quality"
---

# Phase 5: Profiles & Onboarding Verification Report

**Phase Goal:** A parent can create a local child profile by picking a grade (which
selects the curriculum entry point), and on first open the child picks an avatar and a
nickname from fixed sets (no free-text, no real name) — all persisted locally with
minimum child data.

**Verified:** 2026-06-08
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A parent can create a child profile by picking a grade; it persists across restarts, and the grade maps to a starting lesson (default alif). | VERIFIED | `ChildProfiles` table in `app_database.dart` lines 50-57 with `grade`, `startingLessonId`; `schemaVersion=3` + v2->v3 migration; `createProfile`/`hasProfile`/`getProfile` accessors; `gradeToStartingLessonId` in `onboarding_data.dart` maps all 5 grade keys → `'alif'`; `resolveStartingLessonId` fallback. `child_profile_repository_test.dart` asserts persist + restart survival. |
| 2 | The child can pick an avatar and a nickname from a fixed set (no free-text identity leak); the choice persists and shows on the home surface. | VERIFIED | `OnboardingScreen` (consumerStatefulWidget) wraps the three fixed-set pickers: `GradeChips` (5 chips, stable keys `grade_*`), `AvatarGrid` (6 circles, stable keys `avatar_*`), `NicknameGrid` (8 Arabic labels via `ArabicText`, keys `nickname_*`). Zero `TextField`/`TextFormField`/`EditableText` found in `lib/features/onboarding/**`. Submit sequence calls `childProfileRepositoryProvider.create(...)` then `markProfileCreated()` + `ref.invalidate(childProfileProvider)` + `context.go('/')`. Home greeting reads `childProfileProvider` via scope-aware `_GreetingHeaderReader` and renders `resolveNicknameLabel(profile.nicknameId)` through `ArabicText` + keyed avatar circle. `onboarding_screen_test` tests 1-3 GREEN; `home_screen_test` Test 1 GREEN. |
| 3 | Child data is stored in app-private local storage only, with no cloud, no account, and no real-name exposure beyond the device. | VERIFIED | `ChildProfiles` table has only `id`, `nicknameId`, `avatarId`, `grade`, `startingLessonId`, `createdAt` — no `name`/free-text column (verified line by line in `app_database.dart`). Storage uses `getApplicationDocumentsDirectory()` (app-private). Zero Firebase/network calls added. No packages added (confirmed in all SUMMARYs). Security comment at `app_database.dart` lines 44-57 explicitly states "ONLY fixed-set IDs … NO real-name column … never logged". |

**Score:** 3/3 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/data/app_database.dart` | ChildProfiles table + v2->v3 migration + accessors | VERIFIED | `class ChildProfiles` at line 50; `schemaVersion => 3`; `if (from < 3) await m.createTable(childProfiles)`; `hasProfile`/`getProfile`/`createProfile` accessors present; no free-text column |
| `lib/data/child_profile_repository.dart` | ChildProfileRepository + keepAlive provider | VERIFIED | `class ChildProfileRepository` wrapping `AppDatabase`; `@Riverpod(keepAlive: true)` provider wired to `appDatabaseProvider` via `ref.watch` |
| `lib/providers/profile_providers.dart` | childProfileProvider (invalidatable) + OnboardingGate | VERIFIED | Hand-written `FutureProvider<ChildProfile?>` (intentional codegen workaround documented); `OnboardingGate extends ChangeNotifier` with `markProfileCreated()` calling `notifyListeners()`; `@Riverpod(keepAlive: true) onboardingGate` |
| `lib/features/onboarding/onboarding_data.dart` | kAvatarIds (6), kNicknames (8-10), gradeToStartingLessonId (5 keys→alif), resolveStartingLessonId, resolveNicknameLabel | VERIFIED | Exactly 6 avatar IDs; 8 nickname options with Arabic labels; all 5 grade keys present; 2 `TODO(owner's-mother sign-off)` comments; `resolveNicknameLabel` added in Wave 3 |
| `lib/features/onboarding/onboarding_screen.dart` | PopScope(canPop:false) + no free-text + submit sequence | VERIFIED | `PopScope(canPop: false)` at line 94; no `TextField`/`TextFormField`/`EditableText` in file; submit sequence: validate → `resolveStartingLessonId` → `create()` → `markProfileCreated()` → `ref.invalidate` → `context.go('/')` |
| `lib/features/onboarding/widgets/grade_chips.dart` | 5 keyed grade chips, no free-text | VERIFIED | `kGradeKeys` list with 5 entries; `Key('grade_$key')` on each chip; pure `GestureDetector` tap cells |
| `lib/features/onboarding/widgets/avatar_grid.dart` | 6 keyed avatar circles, no free-text | VERIFIED | Loops over `kAvatarIds`; `Key('avatar_${kAvatarIds[i]}')` per cell; placeholder tints with index glyph; no keyboard surface |
| `lib/features/onboarding/widgets/nickname_grid.dart` | Keyed nickname cells with ArabicText, no free-text | VERIFIED | `Key('nickname_${option.id}')` per cell; `ArabicText(label)` for Arabic rendering; no global `Directionality.rtl` |
| `lib/router/app_router.dart` | /onboarding route + sync redirect (both rules) + refreshListenable: gate | VERIFIED | `GoRoute(path: '/onboarding', ...)` present; `refreshListenable: gate`; synchronous `redirect` with both rules: `!gate.hasProfile && !onOnboarding -> '/onboarding'` and `gate.hasProfile && onOnboarding -> '/'`; no `await` inside redirect |
| `lib/main.dart` | Boot-time hasProfile() read + ProviderScope overrides | VERIFIED | `final db = AppDatabase(); final hasProfile = await db.hasProfile();` then `ProviderScope(overrides: [appDatabaseProvider.overrideWith(...), onboardingGateProvider.overrideWith((ref) => OnboardingGate(hasProfile))])` |
| `lib/screens/home_screen.dart` | Greeting reads childProfileProvider for nickname + avatar | VERIFIED | `_GreetingHeader` scope-aware split: `_GreetingHeaderReader` ConsumerWidget does `ref.watch(childProfileProvider).when(...)` → `_GreetingLayout`; `resolveNicknameLabel` called; `ArabicText` for label; keyed `homeAvatar_$avatarId` circle |
| `lib/l10n/app_en.arb` | {nickname} template + 5 grade labels + "Let's go" key + @-metadata | VERIFIED | `homeGreeting` is `"Welcome back, {nickname}."` with `placeholders: { nickname: { type: String } }`; onboarding keys (title, subtitle, grade prompt, avatar prompt, nickname prompt, submit, 5 grade labels) each with sibling `@` block |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/data/child_profile_repository.dart` | `appDatabaseProvider` | `ref.watch(appDatabaseProvider)` | WIRED | Line 47: `ChildProfileRepository(ref.watch(appDatabaseProvider))` |
| `lib/providers/profile_providers.dart` | `childProfileRepositoryProvider` | `ref.watch(childProfileRepositoryProvider).getProfile()` | WIRED | `FutureProvider` body calls `ref.watch(childProfileRepositoryProvider).getProfile()` |
| `lib/main.dart` | `onboardingGateProvider` | `onboardingGateProvider.overrideWith(...)` | WIRED | Boot constructs `OnboardingGate(hasProfile)` and seeds the provider |
| `lib/router/app_router.dart` | `onboardingGateProvider` | `ref.watch(onboardingGateProvider)` as `refreshListenable` + redirect source | WIRED | `final gate = ref.watch(onboardingGateProvider)` then `refreshListenable: gate` |
| `lib/features/onboarding/onboarding_screen.dart` | `childProfileRepositoryProvider` | `create()` then `markProfileCreated()` then `invalidate(childProfileProvider)` then `context.go('/')` | WIRED | Submit handler lines 74-85 contain all four steps in the required order |
| `lib/screens/home_screen.dart` | `childProfileProvider` | `ConsumerWidget ref.watch(childProfileProvider).when(...)` | WIRED | `_GreetingHeaderReader.build` calls `ref.watch(childProfileProvider).when(...)` |
| `lib/screens/home_screen.dart` | `onboarding_data` (kNicknames / kAvatarIds) | `resolveNicknameLabel(profile.nicknameId)` + `_tintFor(avatarId)` | WIRED | Both calls present in `_GreetingLayout` |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `lib/screens/home_screen.dart` `_GreetingHeaderReader` | `childProfileProvider` async value | `ChildProfileRepository.getProfile()` → `AppDatabase.getProfile()` → Drift `select(childProfiles)..limit(1)` | Yes — real Drift query (not static/empty return) | FLOWING |
| `lib/features/onboarding/onboarding_screen.dart` | `_grade`, `_avatarId`, `_nicknameId` | Tap selections from fixed-set picker widgets; persisted via `childProfileRepositoryProvider.create(...)` → Drift insert | Yes — real Drift insert with user-selected values | FLOWING |
| `lib/main.dart` | `hasProfile` (gate seed) | `await db.hasProfile()` → Drift `select(childProfiles)..limit(1)` | Yes — real Drift query at boot | FLOWING |

---

### Behavioral Spot-Checks

Step 7b: The phase modifies Flutter widget/UI code with no CLI entry points runnable without a simulator. Spot-checks that do not require a running device are:

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No TextField/TextFormField/EditableText in onboarding screen | grep via Grep tool | Zero matches in `lib/features/onboarding/**` (only comment references) | PASS |
| PopScope(canPop:false) present in OnboardingScreen | Grep tool | `PopScope(canPop: false,` at line 94 of `onboarding_screen.dart` | PASS |
| Both redirect rules present in app_router.dart | Grep tool | Lines 47-48: both `!gate.hasProfile && !onOnboarding` and `gate.hasProfile && onOnboarding` rules present | PASS |
| No `await` inside router redirect | Grep tool | No `await` inside the `redirect:` lambda in `app_router.dart` | PASS |
| No QalamColors.reward usage in onboarding files | Grep tool | Zero `QalamColors.reward` references in `lib/features/onboarding/**` (only comment exclusions) | PASS |
| ChildProfiles table has no real-name column | Read tool | `app_database.dart` lines 50-57: columns are `id`, `nicknameId`, `avatarId`, `grade`, `startingLessonId`, `createdAt` — no `name` | PASS |
| kAvatarIds has exactly 6 entries | Read tool | `onboarding_data.dart` lines 20-27: 6 entries `avatar_1..avatar_6` | PASS |
| kNicknames has 8-10 entries | Read tool | `onboarding_data.dart` lines 33-42: 8 entries | PASS |
| homeGreeting is a {nickname} template | Grep tool | `app_en.arb` line 392: `"Welcome back, {nickname}."` with `placeholders` block | PASS |
| Full-suite test run on phase-owned test files | Provided by submitter (175 pass, 2 fail pre-existing) | Phase-owned tests (`test/data/*`, `test/features/onboarding/*`, `test/router/onboarding_gate_test.dart`, `home_screen_test.dart` Test 1) all GREEN | PASS |

Device-dependent checks (first-launch flow, Arabic glyph rendering, back button) routed to Step 8.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| S1-02 | 05-01, 05-02, 05-03 | Parent creates child profile with grade; grade selects curriculum entry point; persists locally | SATISFIED | `ChildProfiles` table + `createProfile`/`getProfile`/`hasProfile`; `gradeToStartingLessonId` all grades → `'alif'`; `resolveStartingLessonId`; profile survives restart (repository test); gate redirect wired; boot read seeds correct gate value |
| S1-03 | 05-01, 05-02, 05-03, 05-04 | Child picks avatar and nickname from fixed set (no free-text); shown on home screen | SATISFIED | `kAvatarIds` (6), `kNicknames` (8); zero `TextField`/`TextFormField`/`EditableText` in onboarding; `PopScope(canPop:false)`; Home greeting reads `childProfileProvider` and renders `resolveNicknameLabel` via `ArabicText`; keyed `homeAvatar_$avatarId`; `onboarding_screen_test` all 3 GREEN; `home_screen_test` Test 1 GREEN |

No orphaned Phase-5 requirements found in REQUIREMENTS.md traceability table.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/onboarding/onboarding_data.dart` | 29-32 | `TODO(owner's-mother sign-off): finalize nickname wording` | INFO | Intentional placeholder per locked Phase-5 decision (05-CONTEXT.md "Out of Scope"). The profile stores the stable id; label changes require no data migration. Flagged correctly with `TODO(owner's-mother sign-off)` rather than a plain `TBD`/`FIXME`/`XXX`. |
| `lib/features/onboarding/onboarding_data.dart` | 44-46 | `TODO(owner's-mother sign-off): replace 'alif' with real per-grade entry-point ids` | INFO | Same — deliberate mechanism-only placeholder. All grades resolve safely to `'alif'`; the single-source map means real per-grade values require one edit. |
| `lib/providers/profile_providers.dart` | 1-29 | `childProfileProvider` is hand-written `FutureProvider` instead of `@riverpod` codegen | INFO | Intentional deviation from plan documented with reason: riverpod_generator 4.0.3 `InvalidTypeException` on Drift-generated return type. Public API and test contract are identical. No functional impact. |

No `TBD`, `FIXME`, or `XXX` markers found in Phase-5-owned files. The `TODO(owner's-mother sign-off)` comments reference a specific formal sign-off gate (the curriculum/UX owner), which satisfies the debt-marker gate requirement for traceability.

---

### Human Verification Required

#### 1. End-to-end first-launch flow on a fresh install

**Test:** Build and run on an Android tablet or emulator with no existing profile (fresh install or cleared app data via `flutter run`):
1. Confirm the app opens on `/onboarding` (not Home).
2. Press the Android back button / back gesture — confirm nothing happens.
3. Confirm no text field is visible and the soft keyboard never appears at any point.
4. Confirm the card shows (in order): grade chips, 6 placeholder avatar circles, and a nickname grid of Arabic labels.
5. Confirm Arabic nickname labels render as correct connected Arabic glyphs (no tofu/boxes/missing characters).
6. Confirm the screen uses the parchment background + ink-teal "Let's go" pill and no gold/reward chrome.
7. Tap one grade chip, one avatar, one nickname, then "Let's go" — confirm it navigates to Home.
8. Force-quit and relaunch — confirm the app opens directly on Home (onboarding skipped).

**Expected:** All 8 steps pass. Specifically: back button does nothing, no keyboard ever appears, Arabic labels show correct Noto Naskh shaping, visual design matches the design kit (parchment bg, ink-teal CTA, no gold), profile survists force-quit restart.

**Why human:** Device-level back button behavior, Arabic connected-glyph rendering quality, soft keyboard non-appearance, and force-quit + restart survival require a running device. Widget tests cover the structural invariants but cannot verify rendering fidelity or real device behavior.

#### 2. Home greeting shows the chosen nickname and avatar after onboarding

**Test:** After completing the onboarding flow (or manually examining the Home screen with a real profile stored), confirm:
1. The greeting header shows "Welcome back," followed by the chosen Arabic nickname label as a correctly-shaped Arabic glyph (not the hardcoded "Layla" fallback).
2. The chosen avatar's placeholder circle is visible beside the greeting (matching the one picked at onboarding).
3. No gold/reward chrome is present on the Home screen.

**Expected:** The Arabic label renders with correct Naskh shaping for whichever nickname was chosen (e.g. "نجمة" for nick_star shows as a connected 4-letter word, not isolated glyphs or tofu).

**Why human:** Arabic glyph rendering quality (Noto Naskh shaping, correct isolated/initial/medial/final forms for each nickname label) cannot be verified programmatically. The widget test only checks that an `ArabicText` widget with the expected string exists — not that it renders correctly.

---

### Gaps Summary

No technical gaps identified. All three roadmap Success Criteria are verified:
1. Grade-to-lesson persistence: VERIFIED end-to-end through Drift (table, repository, provider, gate, router).
2. Fixed-set identity with no free-text, shown on Home: VERIFIED (no TextField/EditableText in onboarding; scope-aware greeting reads profile nickname + avatar via childProfileProvider).
3. App-private local storage, no cloud, no real name: VERIFIED (no network calls added; ChildProfiles table columns contain only fixed-set IDs; storage via getApplicationDocumentsDirectory).

The two human verification items are the only items preventing `passed` status. They cannot be resolved by code inspection: Arabic glyph rendering quality and the full device-level first-launch + restart flow require a running Android device or emulator.

**Pre-existing test failures (not Phase-5 regressions):**
- `home_screen_test.dart` Test 4 ("Journey nav must not navigate") — stale since Phase 03.1 commit `4d03e63` intentionally unlocked Journey navigation. Phase 5 did not modify `home_screen.dart`'s nav rail.
- `mastery_celebration_golden_test.dart` ("no See Journey button") — stale since Phase 03.1 commit `0ee118a`. Phase 5 did not touch `lib/features/practice/`.

Both are documented in `.planning/phases/05-profiles-onboarding/deferred-items.md` and confirmed out of scope.

---

_Verified: 2026-06-08_
_Verifier: Claude (gsd-verifier)_
