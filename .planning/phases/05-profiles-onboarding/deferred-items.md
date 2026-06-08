# Phase 05 — Deferred Items (out of scope for the discovering plan)

## Discovered during 05-03 (Wave 2 onboarding + gate)

These test failures are **out of scope for plan 05-03** (whose files_modified are the
onboarding screen/widgets, router, main.dart, and l10n — not home_screen.dart). Logged
per the executor SCOPE BOUNDARY rule; NOT fixed here.

1. **`test/screens/home_screen_test.dart` Test 1 — greeting reads profile nickname (RED).**
   Wave 0 extended this test to expect the Home greeting to render the chosen nickname
   label instead of the hardcoded `"Welcome back, Layla."`. Turning it GREEN requires
   editing `lib/screens/home_screen.dart` (the `_GreetingHeader`) to watch
   `childProfileProvider` and resolve `nicknameId → label`. This is the separate
   **home-greeting-integration** item (listed under `affects` in 05-01/05-02 SUMMARYs),
   not part of the 05-03 onboarding+gate slice. Owner: a later home-greeting plan.

2. **`test/screens/home_screen_test.dart` Test 4 — "Journey nav must not navigate" (stale).**
   This test asserts tapping the Journey nav item does NOT navigate (expects `/`), but
   commit `4d03e63` ("fix(nav): wire GestureDetector to _NavItem + add home button to
   JourneyScreen") intentionally unlocked Journey navigation, so the tap now goes to
   `/journey`. The test is stale relative to that prior, intentional change. Not caused
   by 05-03 and touches no file 05-03 modifies. Owner: whoever reconciles the nav-unlock
   change with this assertion.

3. **`test/widgets/qalam_mascot_test.dart` — SVG asset pose test (unrelated).**
   Mascot SVG rendering test; unrelated to onboarding/gate. Pre-existing, untouched by
   05-03. Owner: mascot/asset maintenance.

## Status update at end of Phase 05 (post-05-04 full-suite run)

- **Item 1 — RESOLVED by 05-04.** The home greeting now reads `childProfileProvider`
  and renders the chosen nickname label / avatar; `home_screen_test.dart` Test 1 is GREEN.
- **Item 3 — no longer failing.** All four `qalam_mascot_test.dart` tests pass in the
  end-of-phase suite run. Leave for routine asset maintenance; not a Phase 05 concern.
- **Item 2 — still RED (stale, out of scope).** Unchanged; see above.

4. **`test/features/practice/mastery_celebration_golden_test.dart` — "no See Journey
   button (Phase 6 not yet built)" (stale, same root cause as item 2).**
   The test asserts no "See journey" button exists, but that button was added in commit
   `0ee118a` ("feat(03.1-01): … See journey button") during **Phase 03.1**, which
   predates Phase 05. Phase 05 modified none of the `lib/features/practice/*` files.
   This is the same intentional Journey-nav unlock that made item 2 stale. Not a Phase 05
   regression. Owner: whoever reconciles the Phase 03.1 nav-unlock with these assertions.
