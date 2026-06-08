---
phase: 05-profiles-onboarding
plan: 03
subsystem: onboarding
tags: [flutter, riverpod, go_router, onboarding, child-profile, s1-02, s1-03, gate, tdd]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: appDatabaseProvider override seam + AppDatabase.hasProfile()
  - plan: 05-01
    provides: RED screen + router gate test contract (keyed fixed-set cells, PopScope, no-loop)
  - plan: 05-02
    provides: ChildProfileRepository + childProfileProvider + OnboardingGate + onboarding_data.dart
provides:
  - OnboardingScreen — single scrollable card (grade chips -> avatar grid -> nickname grid -> "Let's go"), PopScope(canPop:false), no free-text
  - grade_chips / avatar_grid / nickname_grid — keyed fixed-set tap pickers (no keyboard)
  - app_router /onboarding route + synchronous redirect gate (both rules, no loop) driven by OnboardingGate as refreshListenable
  - main.dart boot-time hasProfile() read + appDatabaseProvider/onboardingGateProvider overrides (gate correct before first frame)
  - onboarding l10n keys (title/subtitle/prompts, 5 grade labels, "Let's go" CTA)
affects: [home-greeting-integration, 06-lessons (reads startingLessonId), 09-parent-area (claims the local profile)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Synchronous GoRouter redirect gate with BOTH rules (no-profile->/onboarding, has-profile->/) + ChangeNotifier refreshListenable (Pattern 3 / Pitfall 1)"
    - "Boot-time one-time hasProfile() read + ProviderScope.override seeding so the redirect resolves on the first frame (no async-in-redirect)"
    - "Single shared AppDatabase instance via appDatabaseProvider override owning disposal (Pitfall 7)"
    - "Fixed-set tap pickers (GestureDetector tap-cell idiom) carrying stable Keys; ZERO free-text surface (S1-03)"
    - "ID->placeholder-visual mapping lives in widget code (avatar tints), never in the DB (D-3)"

key-files:
  created:
    - lib/features/onboarding/onboarding_screen.dart
    - lib/features/onboarding/widgets/grade_chips.dart
    - lib/features/onboarding/widgets/avatar_grid.dart
    - lib/features/onboarding/widgets/nickname_grid.dart
  modified:
    - lib/router/app_router.dart
    - lib/router/app_router.g.dart
    - lib/main.dart
    - lib/l10n/app_en.arb

key-decisions:
  - "Trimmed onboarding card vertical spacing so the 'Let's go' CTA fits within the 800x600 widget-test viewport (the Wave-0 happy-path test taps the CTA without scrolling)"
  - "Used State.mounted (not context.mounted) after the async create() in a ConsumerState submit handler, per the use_build_context_synchronously lint"
  - "kGradeKeys declared in grade_chips.dart as the single-source grade tap contract, mirrored against onboarding_data.dart's gradeToStartingLessonId for the submit validation"

patterns-established:
  - "When a Wave-0 widget test taps a CTA without scrolling, the implemented screen must keep the CTA within the 800x600 default test viewport (compact spacing) rather than relying on the test to scroll"

requirements-completed: [S1-02, S1-03]

# Metrics
duration: 11min
completed: 2026-06-08
---

# Phase 05 Plan 03: Wave 2 Onboarding + Gate Summary

**Built the first-launch onboarding vertical slice end-to-end — a single scrollable card (grade chips -> avatar grid -> nickname grid -> "Let's go") with NO free-text and `PopScope(canPop:false)`, wired to a synchronous GoRouter redirect gate (both rules, no loop) driven by `OnboardingGate` as `refreshListenable`, seeded by a one-time boot `hasProfile()` read — turning Wave 0's screen + router RED tests GREEN.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-06-08T17:08Z
- **Completed:** 2026-06-08T17:19Z
- **Tasks:** 3 (2 code, 1 end-of-phase human-check)
- **Files modified:** 8 (4 created, 4 extended)

## Accomplishments
- `OnboardingScreen` (`ConsumerStatefulWidget`): one scrollable surface card with heading + three keyed fixed-set pickers + the teal "Let's go" pill, wrapped in `PopScope(canPop: false)` (blocks Android back + predictive-back; `WillPopScope` avoided).
- Three picker widgets — `GradeChips` (5 chips: kg/grade1/grade2/grade3/grade4plus), `AvatarGrid` (6 placeholder colored circles, ID->tint mapped in code, D-3), `NicknameGrid` (8 Arabic nicknames via `ArabicText`) — each tappable cell carrying a stable `Key` (`grade_*`, `avatar_*`, `nickname_*`).
- Submit sequence (gated on all three selections): validate each selection in its fixed set (T-05-02) -> `resolveStartingLessonId(grade)` -> `create(...)` -> `markProfileCreated()` -> `invalidate(childProfileProvider)` -> `context.go('/')`.
- `app_router.dart`: reads `onboardingGateProvider`, adds `refreshListenable: gate` + a **synchronous** `redirect` with BOTH rules (`!hasProfile && !onOnboarding -> /onboarding`, `hasProfile && onOnboarding -> /`) so there is no redirect loop (Pitfall 1); demo mode bypasses the gate; adds the `/onboarding` route. Regenerated `app_router.g.dart`.
- `main.dart`: one-time boot `await db.hasProfile()`; `ProviderScope` overrides seed a single shared `AppDatabase` (provider owns disposal, Pitfall 7) + `OnboardingGate(hasProfile)` so the redirect is correct before the first frame (no async-in-redirect, no flicker — Pattern 3).
- l10n: onboarding title/subtitle/section prompts, the five grade labels, and the "Let's go" CTA, each with a sibling `@`-metadata block.
- Invariants verified by grep: NO `TextField`/`TextFormField`/`EditableText`, NO `QalamColors.reward`, NO global `Directionality`, NO `await` inside the router redirect.

## Task Commits

Each task was committed atomically:

1. **Task 1: Router gate + main.dart boot read** - `ebeac2e` (feat)
2. **Task 2: Onboarding screen + picker widgets + l10n** - `834b4ce` (feat)
3. **Task 3: End-to-end human verification** - no code change (end-of-phase `<human-check>`; see Pending Human Verification below)

## Files Created/Modified
- `lib/features/onboarding/onboarding_screen.dart` - the combined onboarding card, PopScope, submit sequence (created).
- `lib/features/onboarding/widgets/grade_chips.dart` - keyed single-select grade chips + `kGradeKeys` (created).
- `lib/features/onboarding/widgets/avatar_grid.dart` - keyed single-select avatar circles (placeholder tints) (created).
- `lib/features/onboarding/widgets/nickname_grid.dart` - keyed single-select Arabic nickname cells via `ArabicText` (created).
- `lib/router/app_router.dart` - gate redirect (both rules) + `refreshListenable` + `/onboarding` route (modified).
- `lib/router/app_router.g.dart` - regenerated (modified).
- `lib/main.dart` - boot `hasProfile()` read + `appDatabaseProvider`/`onboardingGateProvider` overrides (modified).
- `lib/l10n/app_en.arb` - onboarding keys + sibling `@`-metadata (modified).

## Decisions Made
- **Compacted the card's vertical spacing** so the "Let's go" CTA lands within the default 800x600 widget-test viewport. The Wave-0 happy-path test taps `onboardingSubmit` without scrolling; with the original generous spacing the CTA laid out at y~726 (off-screen) and the tap missed. Reducing section gaps and the avatar cell size brought the CTA on-screen. Design feel is preserved (parchment card, ink-teal pill, comfortable tap targets >= 64dp); only whitespace shrank.
- **Used `State.mounted` (not `context.mounted`)** after the async `create()` in the `ConsumerState` submit handler, per `use_build_context_synchronously` — the State's mounted check is the correct guard here.
- **`kGradeKeys` is declared in `grade_chips.dart`** as the single-source grade tap contract and is cross-checked against `onboarding_data.dart`'s `gradeToStartingLessonId` keys in the submit validation (T-05-02 defence-in-depth).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CTA off-screen made the Wave-0 happy-path tap miss; compacted card spacing**
- **Found during:** Task 2 (running `onboarding_screen_test.dart`).
- **Issue:** The Wave-0 test taps `onboardingSubmit` without scrolling. With the plan's generous spacing (`space8`/`space10` gaps, 96px avatars) the CTA laid out at y~726 in the 800x600 test viewport — outside the root render bounds — so `tap()` hit-test-missed and `create()` never ran (`repo.lastCreated` was null).
- **Fix:** Reduced inter-section gaps (space8/space10 -> space5/space3), outer + card padding (space8 -> space2/space5), and avatar cell size (targetLarge 96 -> targetComfy 72) so the full card fits within 600px tall and the CTA is hittable without scrolling. No behavior change; design feel preserved.
- **Files modified:** lib/features/onboarding/onboarding_screen.dart, lib/features/onboarding/widgets/avatar_grid.dart
- **Verification:** `flutter test test/features/onboarding/onboarding_screen_test.dart` -> all 3 GREEN.
- **Committed in:** `834b4ce` (Task 2 commit).

**2. [Rule 3 - Blocking] `Override` type name not exported under flutter_riverpod in this toolchain**
- **Found during:** Task 1 (main.dart edit).
- **Issue:** Typing the overrides list as `<Override>[...]` produced "The name 'Override' isn't a type" — the symbol is not exported under that bare name in the installed riverpod version.
- **Fix:** Dropped the explicit type argument; `overrides: [...]` infers correctly.
- **Files modified:** lib/main.dart
- **Verification:** `flutter analyze lib/main.dart` -> No issues found.
- **Committed in:** `ebeac2e` (Task 1 commit).

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). No public-API or test-contract change; no scope creep.

## Deferred Issues

Logged to `.planning/phases/05-profiles-onboarding/deferred-items.md` (out of scope for 05-03 — these tests touch files 05-03 does not modify):

1. **`test/screens/home_screen_test.dart` Test 1** (RED) — expects the Home greeting to read the profile nickname instead of `"Welcome back, Layla."`. This is the separate **home-greeting-integration** item (requires editing `lib/screens/home_screen.dart`, not in 05-03's files). Owner: a later home-greeting plan.
2. **`test/screens/home_screen_test.dart` Test 4** (stale) — asserts the Journey nav must not navigate, but commit `4d03e63` intentionally unlocked Journey navigation. Test is stale vs. that prior change; not caused by 05-03.
3. **`test/widgets/qalam_mascot_test.dart`** — SVG mascot pose test; unrelated, pre-existing.

## Known Stubs

Carried forward from 05-02 (intentional, owner's-mother's domain per 05-CONTEXT.md "Out of Scope"):
- **Avatar art** — 6 placeholder colored circles with an index glyph; `avatar_grid.dart` maps `avatar_<n>` -> a warm tint placeholder. Real illustrated art is a later asset swap with no code change (D-3). The profile stores only the id.
- **Nickname wording** — `kNicknames` (in `onboarding_data.dart`) ships 8 placeholder Arabic labels flagged `TODO(owner's-mother sign-off)`; the profile stores the id, so labels change with no data migration.
- **Per-grade entry points** — all grades resolve to `'alif'` (single-source map, flagged for sign-off).

These are deliberate per the locked Phase-5 decisions; the mechanism (fixed-set pickers + grade->lesson resolver + persistence + gate) is fully wired and tested. They do not block the plan's goal.

## Pending Human Verification (Task 3 — end-of-phase `<human-check>`)

Config `human_verify_mode: end-of-phase` + `auto_advance: false`, so Task 3 is a non-interactive end-of-phase check (not a blocking checkpoint). The code-level acceptance criteria are met (GREEN tests + invariant greps). A human still needs to confirm on a fresh install:
1. App opens on `/onboarding` (not Home); Android back button does nothing.
2. No text field / keyboard ever; visuals match the design kit (parchment bg, ink-teal "Let's go" pill, NO gold); Arabic nickname labels render as correct connected glyphs.
3. Tap grade + avatar + nickname + "Let's go" -> lands on Home; force-quit + relaunch opens directly on Home (onboarding skipped).

## Threat Flags

None — no new security surface beyond the plan's `<threat_model>`. The mitigations are realized:
- **T-05-01 / T-05-02** (no free-text PII / out-of-set tampering): the screen has zero `TextField`/`TextFormField`/`EditableText` (asserted GREEN); submit validates each selection in `kGradeKeys`/`kAvatarIds`/`kNicknames` before `create()`.
- **T-05-05** (bypass onboarding): `PopScope(canPop:false)` + the router redirect force `/onboarding` until a profile exists.
- **T-05-06** (redirect loop): both redirect rules present + gate flips via `markProfileCreated()`; the gate router test asserts no `_SentinelError` (no loop).
- **T-05-SC**: no packages added.

## User Setup Required
None — local-only, no external service configuration.

## Next Phase Readiness
- A fresh install now lands a real user on a working onboarding card and, after one tap-through, on Home; relaunch skips onboarding.
- The remaining **home-greeting-integration** task (read `childProfileProvider` in `_GreetingHeader`, resolve `nicknameId -> label`) is the last RED test in Phase 5 (`home_screen_test.dart` Test 1) — out of scope here, ready for a follow-up plan.
- Phase 6 can read `startingLessonId` off the persisted profile directly (no re-derivation from grade).

## Self-Check: PASSED

- All 4 created files verified present on disk; all 4 modified files committed.
- Both task commits (ebeac2e, 834b4ce) verified in git log.
- Target tests GREEN: `test/router/onboarding_gate_test.dart` + `test/features/onboarding/` (13 tests pass).
- `flutter analyze` on the changed files: No issues found.
- Out-of-scope failures (home greeting integration, stale Journey-nav test, mascot SVG) logged to deferred-items.md, not fixed (SCOPE BOUNDARY).

---
*Phase: 05-profiles-onboarding*
*Completed: 2026-06-08*
