---
status: complete
quick_id: 260601-wa0
description: Add DEMO launch flag to boot app at /demo/home
date: 2026-06-01
commit: eed35c0
---

# Quick Task 260601-wa0: DEMO launch flag

**Added a compile-time `DEMO` flag so the app can boot straight into the phase-02.1.1 presentation walkthrough, with default `flutter run` behavior unchanged.**

## What changed

- `lib/router/app_router.dart`: added top-level `const bool kDemoMode = bool.fromEnvironment('DEMO');` and changed `initialLocation: '/'` → `initialLocation: kDemoMode ? '/demo/home' : '/'`.

## How to use

- **Normal app (default):** `flutter run` → starts at `/` (the Phase-1 Home).
- **Demo walkthrough:** `flutter run --dart-define=DEMO=true` → starts at `/demo/home`; tap through Home → Watch → Trace → Feedback·miss → Try Again → Feedback·pass → Celebration → Back Home.

To build an APK for the presentation device: `flutter build apk --dart-define=DEMO=true`.

## Verification

- `flutter analyze lib/router/app_router.dart` → No issues found.
- Default branch unchanged (ternary defaults to `'/'` when the env flag is absent — `bool.fromEnvironment` returns false by default).
- Reversible: delete the const + restore `initialLocation: '/'`.

## Notes

- No new UI, no router restructure — a 7-line config change.
- Executed inline (no subagent) because subagent Bash was unavailable this session.
