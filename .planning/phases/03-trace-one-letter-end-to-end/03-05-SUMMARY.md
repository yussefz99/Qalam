---
plan: 03-05
phase: 03-trace-one-letter-end-to-end
subsystem: home-screen
status: complete
completed: 2026-06-07
tags: [home-screen, navigation, anti-gamification, l10n, widget-tests]

dependency_graph:
  requires: [03-04]
  provides: [home-screen-demo, nav-rail, lesson-card]
  affects: [lib/screens/home_screen.dart, lib/l10n/app_en.arb, test/screens/home_screen_test.dart]

tech_stack:
  added: []
  patterns:
    - NavigationRail with locked/disabled items (Opacity + null onTap)
    - SvgPicture.asset with placeholderBuilder graceful fallback
    - GestureDetector with Key for testable tap targets
    - Null-safe l10n reads via ?. and ?? fallback (D-05 compat)

key_files:
  modified:
    - lib/screens/home_screen.dart
    - lib/l10n/app_en.arb
  created:
    - test/screens/home_screen_test.dart

decisions:
  - Used Row(NavRail + Expanded content) instead of Flutter's NavigationRail widget
    to avoid NavigationRail's opinionated selected-index state and forced icon requirement.
    The hand-rolled _NavItem gives full control over the locked/disabled appearance.
  - Journey and Parent nav items use Opacity(0.5) + null onTap — visibly disabled
    with no gesture forwarding. No route is wired; no context.go('/journey') anywhere.
  - Mascot and lock icon both use SvgPicture.asset placeholderBuilder → SizedBox fallback
    matching the MasteryCelebration pattern from Plan 03-03.

metrics:
  duration: ~25 minutes
  tasks_completed: 3
  files_changed: 3
  tests_added: 4
  total_tests_passing: 151
---

# Phase 03 Plan 05: Warm Demo Home Screen Summary

Upgraded `lib/screens/home_screen.dart` from the Phase-1 walking skeleton into a warm,
de-gamified demo home with mascot greeting, alif lesson card, and a locked left nav.

## What was built

**`lib/l10n/app_en.arb`** — 9 new keys added and generated via `flutter gen-l10n`:
`homeGreeting`, `homeGreetingSubtitle`, `homeLessonEyebrow`, `homeLessonTitle`,
`homeLessonSubtitle`, `navHome`, `navJourney`, `navParent`, `comingSoon`.

**`lib/screens/home_screen.dart`** — replaced walking skeleton body with:
- Left nav-rail (`_HomeNavRail`): Home (active, teal), Journey (locked, 50% opacity,
  "Coming soon"), Parent (locked, same). No `context.go('/journey')` or
  `context.go('/parent')` — both are null-onTap inert items.
- Greeting header (`_GreetingHeader`): `qalam-idle.svg` mascot with graceful
  `placeholderBuilder` fallback + "Welcome back, Layla." heading + subtitle.
- Today's lesson card (`_TodaysLessonCard`, `Key('todaysLessonCard')`):
  ArabicText('ا') alif glyph in a teal-tint container, lesson title/eyebrow/subtitle,
  chevron button. `onTap: () => context.go('/practice')`.
- `_PersistenceProof` kept from Phase 1 (round-tripped Drift value, visible seam).
- All l10n reads null-safe: `l10n?.getter ?? 'fallback'` — no `!` force-unwraps.
- `QalamColors.reward` (gold) absent from all widget code. Tokens only throughout.

**`test/screens/home_screen_test.dart`** — 4 widget tests:
1. Renders "Welcome back, Layla.", "The Letter Alif", and ArabicText('ا') glyph.
2. Key('todaysLessonCard') tap navigates to /practice (GoRouter stub confirms
   'Practice Screen' scaffold appears).
3. Anti-gamification: no "THIS WEEK", no "stars this week", no LinearProgressIndicator,
   no "⭐" emoji.
4. Journey/Parent "Coming soon" labels present; tapping either does not change the
   router location (confirmed via `router.routerDelegate.currentConfiguration.uri`).

## Verification

```
flutter analyze lib/screens/home_screen.dart lib/l10n  →  No issues found!
flutter test                                            →  151 tests passed
```

- D-05 direction test (`test/direction_test.dart`) stays green — the bare
  `MaterialApp(home: HomeScreen())` path works because all l10n reads are null-safe
  and `_PersistenceProof` degrades to SizedBox.shrink() without a ProviderScope.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written with one structural decision:

**[Decision] Hand-rolled nav-rail instead of Flutter NavigationRail widget**
- The plan specified "a left nav with Home (active), Journey (locked/Coming soon),
  Parent (locked/Coming soon)".
- Flutter's `NavigationRail` requires a `selectedIndex` and `onDestinationSelected`
  callback and imposes its own icon/label layout constraints. Wiring locked items into
  it cleanly while disabling gesture forwarding required more boilerplate than a
  hand-rolled Column of `_NavItem` widgets with `null onTap`.
- The hand-rolled approach is simpler, token-compliant, and the tests confirm the
  locked/navigation behavior works correctly.

## Known Stubs

- Greeting uses static "Welcome back, Layla." (no profile system — Phase 5).
  Tracked as intentional: the plan explicitly specifies "hardcoded placeholder".
- Lesson card always shows alif (no lesson-selection logic — Phase 6).
  Intentional for this phase.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes introduced.

## Self-Check: PASSED

- `lib/screens/home_screen.dart` — exists and passes `flutter analyze`
- `lib/l10n/app_en.arb` — 9 new keys confirmed in generated `app_localizations_en.dart`
- `test/screens/home_screen_test.dart` — exists, all 4 tests pass
- Commit `2e7a011` confirmed in `git log --oneline`
- `flutter test` → 151 tests passed (D-05 green, 4 new home_screen_test green)
