---
phase: 09-parent-dashboard
plan: 03
subsystem: parent-gate-and-dashboard
tags: [flutter, riverpod, go_router, pin, gate, read-only, dashboard, rtl, tdd-green, s1-11]

# Dependency graph
requires:
  - phase: 09-parent-dashboard
    plan: 01
    provides: Wave-0 RED contract (parent_gate_test.dart + parent_dashboard_test.dart) + parent ARB keys
  - phase: 09-parent-dashboard
    plan: 02
    provides: PinService (PBKDF2 + persisted cooldown), pinServiceProvider, AppDatabase.allMastered()/allInProgress(), ParentProgress/ParentLetterRow view model
provides:
  - ParentGate — per-entry lock/unlock ChangeNotifier (refreshListenable + /parent access boundary)
  - parentProgressProvider — hand-written FutureProvider<ParentProgress> assembled in curriculum intro order
  - ParentDashboardScreen — the /parent route widget; PIN gate while locked, read-only dashboard while unlocked
  - ParentPinGate — create-first / enter-after PIN flow (obscured numeric, persisted cooldown, soft feedback)
  - /parent route + unlocked Home "Parent" nav + boot-locked parentGate seed
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single /parent route whose widget is the access boundary (RESEARCH Pattern 3 — no redirect guard, no sub-routes, no redirect loop)"
    - "Merged refreshListenable: Listenable.merge([onboardingGate, parentGate]) so the router re-runs on every gate flip"
    - "Synchronous redirect only — the gate flag is read in-widget, never awaited in redirect (Pitfall 2)"
    - "Re-export of view-model types (ParentProgress/ParentLetterRow) from parent_providers.dart so the Wave-0 test's single-import surface resolves them"
    - "Provider degradation: loading/error .when() branches both render the calm empty state, never a spinner or stack trace (T-09-10)"

key-files:
  created:
    - lib/features/parent/parent_pin_gate.dart
    - lib/screens/parent_dashboard_screen.dart
    - .planning/phases/09-parent-dashboard/09-HUMAN-UAT.md
  modified:
    - lib/providers/parent_providers.dart
    - lib/router/app_router.dart
    - lib/screens/home_screen.dart
    - lib/main.dart
    - test/screens/home_screen_test.dart

key-decisions:
  - "Dashboard screen lives at lib/screens/parent_dashboard_screen.dart (NOT lib/features/parent/ as the plan's files_modified listed) — the Wave-0 tests import package:qalam/screens/parent_dashboard_screen.dart; the test import is the binding contract"
  - "parent_providers.dart re-exports ParentProgress/ParentLetterRow — the dashboard test imports them via parent_providers, and a plain Dart import does not re-export"
  - "Parent nav glyph = ink-drop.svg (A-02: lock.svg is never shipped for this item; star/check carry mastery semantics, map/nib are taken) — the only unused neutral brand glyph"
  - "Default parentGate provider value is unlocked:true ON PURPOSE — the body-only dashboard widget test overrides only parentProgressProvider; production always overrides parentGate LOCKED in main.dart (D-07)"

metrics:
  duration: "~30 min active (spanning a prior-executor crash + this continuation)"
  completed: 2026-06-13
  tasks_total: 4
  tasks_auto: 3
  tasks_deferred_checkpoint: 1
  files_touched: 9
---

# Phase 9 Plan 03: Parent Gate + Read-Only Dashboard Summary

Wires the end-to-end parent-dashboard slice (S1-11): the Home "Parent" nav item is
unlocked and routes to a per-entry PIN gate (create-on-first-access,
enter-on-every-entry, persisted cooldown); a correct PIN unlocks a read-only
"N of M letters mastered" summary + per-letter status list (or the calm empty
state); "Done" relocks the area. No cloud, no account, no network anywhere in the
flow.

## What was built

- **ParentGate** (already present from Task 1) — a `ChangeNotifier` with
  `unlocked` getter + `lock()`/`unlock()`. Starts locked every launch (D-07).
- **parentProgressProvider** (Task 1) — a hand-written `FutureProvider<ParentProgress>`
  (not codegen — its return type touches Drift rows, Pitfall 3) assembling rows in
  curriculum intro order; `total = getLetters().length` (never a literal 28, A-01).
- **ParentPinGate** — a `ConsumerStatefulWidget`: CREATE flow (enter + confirm,
  honest no-recovery copy, mismatch → restart) or ENTER flow (persisted-cooldown
  check with a live countdown, obscured numeric field, soft `warnSoft` wrong-PIN
  message + a single gentle wiggle skipped under reduced motion). The PIN controller
  value is never logged.
- **ParentDashboardScreen** — the `/parent` route widget and access boundary: renders
  the PIN gate while `parentGate` is locked, the read-only dashboard once unlocked.
  Summary line in Heading (information, never gold/score); per-letter rows reuse the
  soft-aqua card shape (mastered: success glyph + reps + date; in-progress: muted
  reps, no glyph); the calm empty state on empty/loading/error; a "Done" control that
  relocks before navigating Home. The Arabic glyph (`ArabicText`) is the only RTL
  island.
- **Wiring** — `/parent` GoRoute (single route, widget is the boundary);
  `refreshListenable: Listenable.merge([onboardingGate, parentGate])`; redirect stays
  synchronous. Home "Parent" nav unlocked → `context.go('/parent')` with the ink-drop
  glyph and no "Coming soon". `main.dart` seeds `parentGateProvider` LOCKED at boot.

## Continuation notes (prior-executor crash recovery)

This plan was resumed after a prior executor crashed on an API socket error.
Task 1 (`7bec271`) was already committed. The prior executor had ALSO left, uncommitted:
`parent_providers.dart` edits, `parent_pin_gate.dart`, and `parent_dashboard_screen.dart`
(the latter correctly placed at `lib/screens/`, matching the test imports — no
duplicate to remove). The route/nav/boot wiring portion of Task 2 had NOT been done.
On resumption: validated the in-flight files against the RED tests, added the
missing view-model re-export, completed the router/nav/boot wiring, reconciled the
stale Home nav test, and committed Tasks 2 + 3.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Dashboard test could not resolve ParentProgress/ParentLetterRow**
- **Found during:** Task 3 validation (first run of `parent_dashboard_test.dart`).
- **Issue:** The test imports `ParentProgress`/`ParentLetterRow` from
  `package:qalam/providers/parent_providers.dart`, but those types live in
  `lib/features/parent/parent_progress.dart`. A plain Dart `import` does not
  re-export, so the test failed to compile ("Type not found").
- **Fix:** Added `export '../features/parent/parent_progress.dart' show ParentProgress, ParentLetterRow;`
  to `parent_providers.dart`.
- **Files modified:** lib/providers/parent_providers.dart
- **Commit:** 4607edd

**2. [Rule 1 - Stale test] Home nav Test 4 asserted "Parent stays Coming soon"**
- **Found during:** Task 2 wiring (full-suite run after unlocking the Parent nav).
- **Issue:** `test/screens/home_screen_test.dart` Test 4 asserted Parent shows
  "Coming soon" and does not navigate — directly contradicted by this plan's
  intentional S1-11 change. Caused exactly by my Task 2 edit (in scope).
- **Fix:** Added a `/parent` stub route to the test router; updated Test 4 to assert
  Parent now navigates to `/parent` and "Coming soon" appears nowhere.
- **Files modified:** test/screens/home_screen_test.dart
- **Commit:** 4607edd

**3. [Rule 1 - Dead code] Unused `sublabel` parameter on _NavItem**
- **Found during:** Task 2 (analyzer warning after dropping the Parent "Coming soon" sublabel).
- **Issue:** `_NavItem.sublabel` was only ever supplied by the now-removed
  Parent coming-soon label, leaving an unused-parameter warning.
- **Fix:** Removed the `sublabel` field + its render block from `_NavItem`.
- **Files modified:** lib/screens/home_screen.dart
- **Commit:** 4607edd

## Verification

- `flutter test test/router/parent_gate_test.dart test/screens/parent_dashboard_test.dart` — GREEN (8 tests).
- `flutter test test/screens/ test/router/` — GREEN (30 tests, includes reconciled Home nav test).
- `flutter test` (full suite) — `+369 -1`. The single failure is the KNOWN
  pre-existing Phase 06-07 golden font-drift test
  (`test/features/practice/mastery_celebration_golden_test.dart`, 0.28% pixel diff,
  "deliberately re-baked in 06-07") — NOT touched, NOT a regression from this plan.
- `flutter analyze` on all changed files — zero errors/warnings (the documented
  `unsupported_provider_value` info on `parentGate` is the only allowed diagnostic).
- grep: no `QalamColors.reward` in `parent_dashboard_screen.dart` (only a comment);
  no `print`/`debugPrint` of the PIN in `parent_pin_gate.dart`.

## Deferred: Task 4 device UAT (end-of-phase)

Task 4 is a `checkpoint:human-verify` END-OF-PHASE device UAT. Per
`human_verify_mode=end-of-phase`, it is RECORDED as a deferred human verification
(see `.planning/phases/09-parent-dashboard/09-HUMAN-UAT.md`) and does NOT block
autonomous progress. The highest-value device check is the force-quit / persisted-cooldown
step (item 4). All flutter_test-exercisable behavior is already GREEN.

## Self-Check: PASSED
