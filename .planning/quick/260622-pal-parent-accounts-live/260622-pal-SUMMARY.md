---
phase: quick-260622-pal
plan: 01
status: complete
date: 2026-06-22
commit: bad0811
files_modified:
  - lib/services/auth_service.dart
  - lib/providers/auth_providers.dart
  - lib/screens/parent_auth_screen.dart
  - lib/router/app_router.dart
  - lib/data/app_database.dart
  - lib/data/child_profile_repository.dart
  - lib/providers/profile_providers.dart
  - lib/features/onboarding/onboarding_screen.dart
  - lib/features/onboarding/widgets/avatar_grid.dart
  - lib/screens/home_screen.dart
  - lib/screens/settings_screen.dart
  - CLAUDE.md
  - .planning/ROADMAP.md
files_removed:
  - lib/dev/parent_auth_spike_screen.dart
  - test/dev/parent_auth_spike_screen_test.dart
tests_added:
  - test/data/account_data_isolation_test.dart
  - test/providers/auth_gate_test.dart
  - test/screens/parent_auth_screen_test.dart
  - test/screens/settings_screen_test.dart
---

# Quick Task 260622-pal — parent accounts: spike → live

## What changed

Promoted the 260622-pas UI-only spike into a real, wired parent-account feature
(owner override 2026-06-22). Real Email/Password + Google parent sign-in/up,
reachable only from behind the PIN-gated parent area. The spike screen and its
launch flag are removed.

- **`lib/services/auth_service.dart`** — real parent flows: `signUpWithEmail`
  (links the boot anonymous identity when present — D-09c, preserving local
  progress; fresh-creates otherwise), `signInWithEmail`, `signInWithGoogle`
  (anonymous-link or sign-in), `sendPasswordReset`, `reauthenticateWithPassword`,
  `signOut` (restores an anonymous identity so offline curriculum reads keep
  working). Raw Firebase codes mapped to calm parent-readable sentences via a
  new `AuthFailure`. `authStateChanges()` uses `userChanges()` so the router
  reacts to linking that keeps the same UID. Google needs
  `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`; degrades gracefully while empty.
- **`lib/providers/auth_providers.dart`** (new) — `authServiceProvider`,
  `authStateProvider` (StreamProvider), and `AuthGate` (router refresh source;
  anonymous never counts as signed in).
- **`lib/screens/parent_auth_screen.dart`** (new) — `ParentAuthScreen` replaces
  the dev spike; sign-in/up toggle, validation, forgot-password, signed-in card,
  all Firebase work delegated to `AuthService`.
- **`lib/router/app_router.dart`** — new `/auth` front-door gate. A real account
  is required before any app content (anonymous boot identity is deliberately
  insufficient); profile setup is the second gate. `kParentAuthSpike` /
  `/dev/parent-auth` removed.
- **Account data isolation** (`lib/data/app_database.dart`) —
  `AppDatabase.forAccount(uid)` opens a `sha256(uid)`-named DB file per account,
  so two parents on one tablet never share progress. `appDatabaseProvider`
  rebuilds on the signed-in UID; `createProfile` now replaces any stale row;
  `requireProfileSetup()` re-gates onboarding on account switch.
- Onboarding polish + real avatar assets (`assets/avatars/avatar_1..6.png`).

## Safety / invariants

- **Children still never log in** (D-09b holds). Parent auth is reachable only
  from behind the PIN-gated parent area.
- Foundation scope — the account does not yet gate or sync any cloud data; tutor
  and Firestore sync remain v2.
- API key / secrets unchanged; no client-side tutor.

## Verification

- `flutter analyze` → no errors (59 info/warning lints, incl. the known
  intentional `unsupported_provider_value` for the Listenable-as-provider).
- `flutter test` → 533 passed. The 5 failures are pre-existing and unrelated
  (curriculum `alif_reference`, `exercise_test`, `meet_section`, and two goldens
  — none in this changeset). All new auth/router/data-isolation/onboarding/
  settings tests pass.

## NOT done (follow-ups)

- Firebase console: enable Google + add SHA-1 and supply
  `GOOGLE_SERVER_CLIENT_ID` before Google sign-in works end-to-end.
- Device UAT of the full sign-up → child-setup → sign-out → anonymous flow.
- Re-bake the 2 unrelated goldens / triage the curriculum baseline failures.
