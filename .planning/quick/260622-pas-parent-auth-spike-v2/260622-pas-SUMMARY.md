---
phase: quick-260622-pas
plan: 01
status: complete
date: 2026-06-22
files_modified:
  - lib/dev/parent_auth_spike_screen.dart
  - lib/router/app_router.dart
  - test/dev/parent_auth_spike_screen_test.dart
---

# Quick Task 260622-pas — v2 parent-auth UI spike

## What changed

A UI-only **v2 parent-account auth prototype** so the owner can see and react to a
real parent login before any v1 decision changes. Deliberately inert.

- **`lib/dev/parent_auth_spike_screen.dart`** (new) — `ParentAuthSpikeScreen`:
  a "V2 PROTOTYPE" chip, Sign in ⇄ Sign up segmented toggle, email + password
  fields (sign-up adds confirm-password), a teal primary CTA ("Sign in" /
  "Create account"), an "or" divider, an outlined "Continue with Google" button
  (a plain "G" badge — no asset, no `google_sign_in` dep), and a footer caveat.
  Styled entirely with existing kit tokens (surface card, ink-teal primary,
  parchment fields; no gold).
- **`lib/router/app_router.dart`** — added the hidden dev route
  `/dev/parent-auth` (not surfaced in any nav, alongside the other `/dev/*`
  seams) + a `kParentAuthSpike` launch flag (`--dart-define=PARENTAUTH=true`)
  that boots straight into the spike and bypasses the onboarding gate, mirroring
  the existing `kDemoMode` escape-hatch idiom.
- **`test/dev/parent_auth_spike_screen_test.dart`** (new) — 5 widget tests.

## Safety / invariants (why this does not touch v1)

- **No** `firebase_auth` / `AuthService` import, **no** `linkToPermanent` call,
  **no** parent-gate wiring, **no** persistence, **no** child data. Every CTA is
  inert — it only shows a "Not wired yet — parent accounts land in v2." SnackBar.
- v1 runtime stays anonymous-only and account-free (D-09b). Reachable only via the
  hidden dev route / launch flag.
- Free-text fields are scoped to a PARENT context; the no-free-text guardrail
  (S1-03) is specifically about a CHILD leaking a real name in onboarding.
- **No** new pub dependency (no `google_sign_in`).

## Verification

- `flutter analyze` on all three files → **No issues found**.
- `flutter test test/dev/parent_auth_spike_screen_test.dart` → **5/5 passed**
  (renders + fields, default Sign-in CTA, toggle→Create account + confirm field,
  primary CTA inert SnackBar, Google button inert).
- Router suite (`test/router/`) green after the route addition.
- Visually confirmed on the Pixel Tablet emulator via
  `flutter run --dart-define=PARENTAUTH=true`.

## NOT done (the gated follow-up)

Real anonymous→permanent account-linking (`AuthService.linkToPermanent`, D-09c) +
Firestore rules + a child-data review. **Pending the owner's sign-off** — do not
wire from the spike without it.
