---
phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release
plan: 01
subsystem: auth
tags: [go_router, riverpod, firebase_auth, firebase_auth_mocks, routing, account-first]

# Dependency graph
requires:
  - phase: 06.1-parent-accounts
    provides: "AuthService (anonymous boot + linkWithCredential), AuthGate, account-first app_router redirect"
provides:
  - "Live-path router regression test proving sign-out lands on /auth and never strands (D-01b)"
  - "Greppable never-strand invariants documented at each load-bearing wire (redirect, AuthGate, signOut, both call sites)"
  - "Confirmation that the account-first sign-out routing already works both directions (sign out → /auth, sign back in → forward)"
affects: [26-06-device-verification, entry-identity, sign-out, account-first]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Live-path router test: drive the REAL appRouterProvider + AuthGate + AuthService.signOut through firebase_auth_mocks (no hand-rolled router) so the wiring cannot silently rot (Phase-15 dead-wire lesson)"
    - "Deterministic router-test harness: pin onboardingGate + null childProfile + fake progress/curriculum so destination screens render cheaply and off the real Drift DB / rootBundle"

key-files:
  created:
    - "test/router/sign_out_routing_test.dart"
  modified:
    - "lib/router/app_router.dart"
    - "lib/providers/auth_providers.dart"
    - "lib/services/auth_service.dart"
    - "lib/screens/settings_screen.dart"
    - "lib/screens/parent_auth_screen.dart"

key-decisions:
  - "The strand was already fixed upstream by the ratified account-first AuthGate wiring; this plan LOCKS the correct behavior with a live-path regression test + invariant comments rather than changing routing behavior (D-01: ratify as-built, D-01b: never strand)"
  - "Rely on the app_router redirect for both sign-out call sites — NO explicit context.go — to avoid double-navigation fighting the redirect (plan constraint)"

patterns-established:
  - "Never-strand invariant: authGate stays in the router's merged refreshListenable AND AuthGate excludes anonymous (!isAnonymous) — both greppable to D-01b/Plan 26-01"

requirements-completed: [D-09b, D-09c, PLAT-01]

# Metrics
duration: 47min
completed: 2026-07-20
---

# Phase 26 Plan 01: Sign-out routing — never strand (D-01b) Summary

**Live-path GoRouter regression test proving account-first sign-out lands cleanly on `/auth` (no loop, no strand) and works both directions, plus greppable never-strand invariants cemented at every load-bearing wire — the D-09c anonymous restore and D-01a child-login ban left fully intact.**

## Performance

- **Duration:** ~47 min
- **Started:** 2026-07-20T14:41Z
- **Completed:** 2026-07-20T15:28Z
- **Tasks:** 2
- **Files modified:** 6 (5 source/test modified, 1 test created)

## Accomplishments
- Wrote `test/router/sign_out_routing_test.dart` (300 lines): a LIVE-PATH test that drives the REAL `appRouterProvider` (production redirect + merged `refreshListenable`), the REAL `AuthGate`, and the REAL `AuthService.signOut()` via `firebase_auth_mocks`. Asserts all four required behaviors — sign-out from `/settings` → `/auth` and stays (no loop); `AuthGate.signedIn == false` after the D-09c anonymous restore; a usable sign-in form present at `/auth`; and signing back in routes forward off `/auth` to Home.
- Empirically confirmed (TDD) that the account-first router ALREADY routes sign-out cleanly — the strand that triggered the phase was resolved by the ratified AuthGate wiring (anonymous never counts as signed-in + `authGate` in `refreshListenable`). The fix is to make that guarantee un-regressible.
- Cemented the never-strand invariant with concise, greppable `D-01b / Plan 26-01` comments at each load-bearing wire: the router redirect (keep `authGate` in `refreshListenable`), `AuthGate` (`!isAnonymous` is load-bearing), `AuthService.signOut` (keep the D-09c restore), and both sign-out call sites (rely on the redirect, no double-navigation).
- Verified the child-safety core is untouched: `signOut()` still restores anonymous (D-09c), `AuthGate` still excludes anonymous (D-01a), the redirect is still synchronous with both loop-guard rules, and no new child-facing login surface exists (D-09b).

## Task Commits

Each task was committed atomically:

1. **Task 1: Reproduce the strand with a live-path router test, then fix sign-out routing** - `8e43ca7` (fix) — live-path regression test + invariant comments in app_router / auth_providers / auth_service
2. **Task 2: Make both sign-out call sites route consistently** - `68af95a` (fix) — reconcile settings_screen + parent_auth_screen `_signOut` to the redirect (no double-nav)

_Note: this is a `type=tdd` Task 1 executed as a single fix commit because the behavior was already GREEN against the current code — the test locks it rather than driving a RED→GREEN code change (see Deviations)._

## Files Created/Modified
- `test/router/sign_out_routing_test.dart` (created) - Live-path router regression: 3 testWidgets covering the four D-01b behaviors against the real appRouter/AuthGate/AuthService
- `lib/router/app_router.dart` - Comment cementing the sign-out landing invariant (authGate must stay in refreshListenable); no logic change
- `lib/providers/auth_providers.dart` - Comment marking `&& !user.isAnonymous` as load-bearing (D-01a/D-01b); no logic change
- `lib/services/auth_service.dart` - Comment documenting that the D-09c anonymous restore does not re-strand; no logic change
- `lib/screens/settings_screen.dart` - Comment: `_signOut` relies on the redirect to reach `/auth`; no explicit navigation (no double-nav)
- `lib/screens/parent_auth_screen.dart` - Comment: `_signOut` relies on the `authStateProvider` rebuild (form returns, stays on `/auth`); no explicit navigation

## Decisions Made
- **Ratify, then lock (D-01/D-01b):** the account-first router was already correct; the deliverable is a live-path regression test + greppable invariants, not a routing rewrite. "Ship exactly as-built" was not an option per D-01b only in the sense that an *un-guarded* strand would be a bug — the guard is now the test.
- **No explicit post-signOut navigation:** both call sites rely on the router redirect (one relocation mechanism each), honoring the plan's "no double-navigation" constraint.
- **Deterministic harness over full boot:** pinned `onboardingGate`, null `childProfile`, and fake progress/curriculum so `/settings`, `/auth`, and Home render cheaply, off the real Drift DB and off `rootBundle` (curriculum loaded via `dart:io` File) — sidestepping the known rootBundle isolate-decode stall.

## Deviations from Plan

**1. [Finding — no code fix required] The strand was already resolved; Task 1 is GREEN on first run**
- **Found during:** Task 1 (writing the live-path regression test, TDD)
- **Issue:** The plan's premise is a live sign-out strand. Running the new live-path test against the current code showed it PASSES — the ratified account-first `AuthGate` (anonymous → `signedIn == false`) plus `authGate` in the router's merged `refreshListenable` already routes sign-out cleanly to `/auth` and back. The plan explicitly anticipated this branch: "IF the redirect alone does not relocate a screen … add an explicit post-signOut relocation" — the redirect DOES relocate, so no explicit relocation was added.
- **Fix:** Locked the correct behavior with the live-path regression test and cemented the load-bearing invariants with greppable `D-01b` comments across the five files the plan names, so a future refactor cannot silently reintroduce the strand (e.g., dropping `authGate` from `refreshListenable`, or weakening the AuthGate formula to `user != null`). No routing/identity behavior changed.
- **Files modified:** all five source files + the new test
- **Verification:** `flutter test test/router/sign_out_routing_test.dart` (3/3 pass); full related suite green (`test/router/`, `settings_screen_test`, `parent_auth_screen_test`, `auth_gate_test`, `auth_service_test` — 45/45 pass); `flutter analyze` clean on all touched files
- **Committed in:** `8e43ca7` (Task 1), `68af95a` (Task 2)

---

**Total deviations:** 1 (a finding — the routing logic was already correct; scope stayed within the plan's own anticipated "redirect is sufficient" branch)
**Impact on plan:** None negative. All four required behaviors are asserted against the REAL router; the child-safety invariants (D-09b/D-09c/D-01a) are preserved and grep-verified. No scope creep.

## Issues Encountered
- **Fresh worktree missing generated l10n:** `lib/l10n/app_localizations*.dart` is gitignored (known project memory), so the fresh worktree failed to compile until `flutter pub get` + `flutter gen-l10n` were run. Generated output stays gitignored (not committed). Standard fresh-checkout step.
- **firebase_auth_mocks anonymous-restore assertion:** `MockUserCredential` asserts `mockUser.isAnonymous == isAnonymous`, so when a permanent `mockUser` is configured, the `signOut → ensureSignedIn → signInAnonymously` restore trips the assert. `AuthService.ensureSignedIn()`'s try/catch swallows it (fail-safe boot), leaving `currentUser` null instead of anonymous. Either way `signedIn == false` and the redirect fires to `/auth`, so the ROUTING behavior under test matches production (where the real anonymous restore succeeds). Documented in the test header; the real D-09c restore is unit-tested in `test/services/auth_service_test.dart`.

## User Setup Required
None - no external service configuration required. (Device confirmation of the full sign-out/sign-in walk on Android is scoped to Plan 26-06.)

## Next Phase Readiness
- Sign-out routing (SC1: "router + sign-out implement exactly the entry model") is proven at the widget/router level and locked against regression. Device confirmation is owned by 26-06.
- D-02 (formally amending the CLAUDE.md `Decided` gating clauses) is a separate plan's work — deliberately NOT touched here.
- No blockers.

## Self-Check: PASSED

- All created/modified files present on disk (6 source/test + SUMMARY).
- All task commits present: `8e43ca7` (Task 1), `68af95a` (Task 2), `3919b34` (SUMMARY).
- Working tree clean; no unintended deletions.
- `flutter test test/router/sign_out_routing_test.dart` → 3/3 pass; related suite 45/45 pass; `flutter analyze` clean on all touched files.

---
*Phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release*
*Completed: 2026-07-20*
