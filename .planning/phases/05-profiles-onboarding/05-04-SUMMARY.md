---
phase: 05-profiles-onboarding
plan: 04
subsystem: home
tags: [flutter, riverpod, l10n, onboarding, child-profile, s1-03, home-greeting]

# Dependency graph
requires:
  - phase: 03.1-journey-map-screen
    provides: HomeScreen + _GreetingHeader + _PersistenceProof scope-aware reader pattern
  - plan: 05-01
    provides: RED home greeting contract (nick_star -> 'نجمة', homeAvatar_avatar_1 key)
  - plan: 05-02
    provides: childProfileProvider + onboarding_data (kAvatarIds/kNicknames)
  - plan: 05-03
    provides: onboarding screen + gate that writes the profile the greeting now reads
provides:
  - Home greeting renders the child's chosen fixed-set nickname LABEL (via ArabicText) + chosen avatar circle, read from childProfileProvider (S1-03 "shown on home")
  - resolveNicknameLabel(id) presentation resolver in onboarding_data.dart (ID->label in code, never the DB)
  - {nickname} String-placeholder ARB template (homeGreeting) with literal fallback
  - Scope-aware greeting split (_GreetingHeader/_GreetingHeaderReader/_GreetingLayout) so the bare harness still renders (T-05-07)
affects: [09-parent-area (claims the local profile shown on Home)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scope-aware greeting read mirrors _PersistenceProof/_PersistenceProofReader (StatelessWidget scope check -> ConsumerWidget .when)"
    - "ID->label presentation resolver lives in onboarding_data.dart (never in the DB); labels change with no data migration"
    - "ARB {nickname} String placeholder regenerated via flutter gen-l10n (NOT build_runner); generated app_localizations*.dart are gitignored"

key-files:
  created: []
  modified:
    - lib/screens/home_screen.dart
    - lib/l10n/app_en.arb
    - lib/features/onboarding/onboarding_data.dart

key-decisions:
  - "Nickname renders as its own ArabicText RTL island next to an English 'Welcome back,' prefix (the contract test asserts a distinct ArabicText with text=='نجمة'), rather than embedding the label inside the {nickname} string"
  - "Home avatar reuses AvatarGrid's placeholder tint palette + index glyph so the Home circle visually matches the onboarding pick (D-3 placeholder art, no code change at real-art swap)"
  - "homeGreeting('') is the no-profile/no-scope/loading/error fallback path; the literal 'Welcome back, Layla.' remains only as the bare-harness (null l10n) fallback"

patterns-established:
  - "Greeting header is a three-part split: scope-aware StatelessWidget -> ConsumerWidget reader -> pure _GreetingLayout presentation, keeping the bare D-05 harness rendering and PLAT-03 invariants intact"

requirements-completed: [S1-03]

# Metrics
duration: 12min
completed: 2026-06-08
---

# Phase 05 Plan 04: Wave 3 Home Greeting Integration Summary

**The Home greeting now shows the child's chosen fixed-set nickname label (via an `ArabicText` island) and chosen avatar circle, read from `childProfileProvider` — replacing the hardcoded `'Welcome back, Layla.'` — closing the S1-03 "the choice shows on the home surface" loop and turning the last Phase-5 RED test (home_screen_test Test 1) GREEN.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-06-08
- **Completed:** 2026-06-08
- **Tasks:** 1
- **Files modified:** 3 (0 created, 3 modified)

## Accomplishments
- Split `_GreetingHeader` into a scope-aware `StatelessWidget` (checks for an ancestor `UncontrolledProviderScope`, degrades to the static greeting with no avatar when absent — bare D-05 harness still renders, T-05-07) and a `_GreetingHeaderReader` `ConsumerWidget` that `ref.watch(childProfileProvider).when(...)`.
- `.when` degrades to the static greeting on loading / error / no-profile; on a present profile it renders the chosen nickname label through `ArabicText` (RTL island, not raw `Text`, no global `Directionality` — Pitfall 3) and the chosen avatar as a keyed `homeAvatar_<avatarId>` circle in place of the mascot.
- Added `resolveNicknameLabel(String nicknameId)` to `onboarding_data.dart` — ID→label lookup in code (never the DB); returns `null` for unknown ids so callers degrade gracefully.
- Converted `app_en.arb` `homeGreeting` to a `{nickname}` `String`-placeholder template with the sibling `@homeGreeting` `placeholders` block; regenerated the (gitignored) `app_localizations*.dart` via `flutter gen-l10n`.
- Home avatar reuses `AvatarGrid`'s placeholder tint palette + index glyph so the Home circle matches the onboarding pick (D-3).
- PLAT-03 invariants held: NO `QalamColors.reward`, no counters/streaks; app chrome stays LTR.

## Task Commits

Each task was committed atomically:

1. **Task 1: Home greeting reads the profile (nickname label + avatar)** - `8924024` (feat)

## Files Created/Modified
- `lib/screens/home_screen.dart` - `_GreetingHeader` rewritten as scope-aware split (`_GreetingHeader` -> `_GreetingHeaderReader` -> `_GreetingLayout`); avatar circle keyed `homeAvatar_<id>`; nickname `ArabicText` island; added `onboarding_data.dart` + `profile_providers.dart` imports (modified).
- `lib/l10n/app_en.arb` - `homeGreeting` converted to a `{nickname}` `String`-placeholder template with `placeholders` metadata (modified).
- `lib/features/onboarding/onboarding_data.dart` - added `resolveNicknameLabel(id)` presentation resolver (modified).

## Decisions Made
- **Nickname renders as a distinct `ArabicText` island**, not embedded inside the `{nickname}` string. The Wave-0 contract (home_screen_test Test 1) asserts `find.byWidgetPredicate((w) => w is ArabicText && w.text == 'نجمة')` — i.e. the label must be its own RTL island with the exact label text. The greeting line is therefore a `Row` of an English `'Welcome back, '` prefix `Text` + the `ArabicText(label)`. The `{nickname}` ARB template still exists (must-have / acceptance) and drives the no-profile fallback path.
- **Home avatar reuses `AvatarGrid`'s tint palette + index glyph** so the circle on Home is visually identical to the one chosen at onboarding (D-3 placeholder art; a real-art swap is a later asset change with no code change).
- **`homeGreeting('')` is the degraded fallback** (no scope / loading / error / null profile) and `'Welcome back, Layla.'` survives only as the bare-harness (null `l10n`) literal — so the contract's `find.text('Welcome back, Layla.') findsNothing` holds when a profile is present.

## Deviations from Plan

None — plan executed as written. The plan anticipated `l10n?.homeGreeting(label)` driving the greeting; the contract's requirement that the label be a separate `ArabicText` island meant the present-profile branch composes prefix + `ArabicText` while the template drives the fallback. This is within the plan's `<action>` ("compose the greeting … and render it through `ArabicText`") and required no scope change.

## Deferred Issues

`test/screens/home_screen_test.dart` **Test 4** (`+3 -1` — Tests 1/2/3 pass, Test 4 fails) remains **out of scope** for this plan and is already logged in `.planning/phases/05-profiles-onboarding/deferred-items.md` (item 2): Test 4 asserts tapping the Journey nav must NOT navigate (expects `/`), but commit `4d03e63` ("fix(nav): wire GestureDetector to _NavItem …") **intentionally unlocked** Journey navigation, so the tap now goes to `/journey`. The test is stale relative to that prior intentional change — it touches the nav-rail, not the greeting this plan owns, and the `<prior_wave_context>` explicitly scopes it out. Item 1 of deferred-items.md (this plan's target, the home-greeting RED test) is now **resolved GREEN**.

Mascot SVG test (deferred-items item 3) is unrelated and untouched.

## Known Stubs

Carried forward from 05-02/05-03 (intentional, owner's-mother's domain per 05-CONTEXT.md "Out of Scope"); this plan adds no new stubs:
- **Nickname wording** — `kNicknames` ships 8 placeholder Arabic labels (`نجمة` etc.) flagged `TODO(owner's-mother sign-off)`. The profile stores the id, so labels (and the Home greeting) change with no data migration. The Home greeting resolves the id→label via the same in-code map.
- **Avatar art** — Home reuses the placeholder colored circle + index glyph; real illustrated art is a later asset swap with no code change (D-3).

## Threat Flags

None — no new security surface beyond the plan's `<threat_model>`. The mitigations are realized:
- **T-05-01** (real-name display): the greeting renders only the fixed-set nickname LABEL resolved from `nicknameId`; no real name exists; profile values are not logged.
- **T-05-07** (Home crashes with no profile / no scope): the scope-aware `_GreetingHeader` degrades to a static greeting on no-scope/loading/error/null-profile (mirrors `_PersistenceProofReader`); the bare harness still renders.

## User Setup Required
None — local-only, no external service configuration.

## Next Phase Readiness
- S1-03 is closed end-to-end: a child picks an avatar + nickname at onboarding, and that exact choice now visibly greets them on Home.
- Phase 9 (parent area) can surface/claim the same local profile the Home greeting reads.
- The stale Journey-nav assertion (home_screen_test Test 4) and the mascot SVG test remain in `deferred-items.md` for a future nav/asset reconciliation — neither blocks Phase 5.

## Self-Check: PASSED

- `lib/screens/home_screen.dart`, `lib/l10n/app_en.arb`, `lib/features/onboarding/onboarding_data.dart` verified modified and committed in `8924024`.
- Commit `8924024` verified in `git log`.
- `flutter test test/screens/home_screen_test.dart` → `+3 -1`: Test 1 (home greeting, this plan's target) GREEN; Tests 2/3 GREEN; Test 4 is the documented stale Journey-nav assertion (deferred-items item 2, out of scope).
- `flutter analyze lib/screens/home_screen.dart lib/features/onboarding/onboarding_data.dart` → No issues found.

---
*Phase: 05-profiles-onboarding*
*Completed: 2026-06-08*
