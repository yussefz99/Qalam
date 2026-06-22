---
phase: quick-260622-pas
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/dev/parent_auth_spike_screen.dart
  - lib/router/app_router.dart
  - test/dev/parent_auth_spike_screen_test.dart
autonomous: true
requirements: [v2-spike-parent-auth-ui]

must_haves:
  truths:
    - "A UI-only parent-account auth screen exists at lib/dev/parent_auth_spike_screen.dart with a Sign in <-> Sign up toggle, email + password fields, a teal primary CTA, and a 'Continue with Google' button, styled to the Qalam kit."
    - "It is reachable ONLY via the hidden dev route /dev/parent-auth (not surfaced in any user-facing nav), mirroring the other /dev/* seams."
    - "It is NOT wired to Firebase/AuthService, the parent gate, or any child data: the CTAs are inert (show a 'not wired yet (v2)' note). No new pub dependency is added."
  artifacts:
    - path: "lib/dev/parent_auth_spike_screen.dart"
      provides: "v2 parent-account auth UI prototype (sign in/up toggle, email+password, Google button, inert CTAs)"
      contains: "ParentAuthSpikeScreen"
    - path: "test/dev/parent_auth_spike_screen_test.dart"
      provides: "widget test: renders, toggles modes, fields present, CTAs inert"
  key_links:
    - from: "lib/router/app_router.dart"
      to: "lib/dev/parent_auth_spike_screen.dart"
      via: "GoRoute path '/dev/parent-auth' builder => const ParentAuthSpikeScreen()"
      pattern: "/dev/parent-auth"
---

<objective>
v2 SPIKE (prototype, NOT production). Build a parent-account sign in / sign up
SCREEN so the owner can see and react to it before any real auth or child-data
posture changes ship. UI ONLY: no Firebase, no AuthService.linkToPermanent call,
no parent-gate wiring, no child data, no new dependency.

The no-free-text invariant is a CHILD-onboarding guardrail (real-name leak, S1-03);
a parent typing their OWN email/password is a different context, so TextFields are
appropriate here. Real anonymous->permanent account-linking (D-09c) stays a
clearly-separated follow-up pending owner sign-off.
</objective>

<verification>
- lib/dev/parent_auth_spike_screen.dart defines ParentAuthSpikeScreen with a mode toggle, email + password fields, primary CTA, and a Google button.
- /dev/parent-auth route added to app_router.dart (dev seam, not in nav).
- CTAs are inert (no Firebase/AuthService import; tap shows a "not wired (v2)" SnackBar).
- No new dependency in pubspec.yaml (no google_sign_in).
- flutter analyze clean for the new/edited files; the new widget test passes.
</verification>

<success_criteria>
The owner can open /dev/parent-auth on a tablet and see a kit-styled parent-account
sign in/up screen, clearly labelled a v2 prototype, with inert buttons and zero
impact on the v1 anonymous-only, account-free, child-safe runtime.
</success_criteria>

<output>
Create `.planning/quick/260622-pas-parent-auth-spike-v2/260622-pas-SUMMARY.md` when done.
</output>
