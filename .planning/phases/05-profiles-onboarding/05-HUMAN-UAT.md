---
status: partial
phase: 05-profiles-onboarding
source: [05-VERIFICATION.md]
started: 2026-06-08T17:45:43Z
updated: 2026-06-08T17:45:43Z
---

## Current Test

[awaiting human testing on an Android tablet / emulator]

## Context

Phase 05 verification reached `human_needed`: all 3 must-haves (S1-02, S1-03) are
verified in code with no gaps. The two items below cannot be confirmed by code
inspection — they need the app running on a real Android device/emulator.

Run the app with the bundled SDK on PATH:
`C:\Users\yusse\.vscode\flutter\bin\flutter.bat run` (it is not on the default PATH).

## Human Verification Items

### 1. End-to-end first-launch flow (fresh install)
- [ ] On a **fresh install**, first open lands on the onboarding screen (not Home).
- [ ] Picking grade → avatar → nickname → "Let's go" creates the profile and lands on Home.
- [ ] The **soft keyboard never appears** at any point in onboarding (fixed-set only, no free text).
- [ ] **Android back button** does not back out of onboarding before a profile exists (`PopScope`).
- [ ] **Force-quit and relaunch** skips onboarding and goes straight to Home (gate does not loop).
- [ ] Design-kit fidelity: parchment/ink-teal palette, rounded shapes, no gold/reward chrome, no counters/streaks.

### 2. Home greeting Arabic rendering
- [ ] The chosen nickname renders on Home as correctly shaped connected Arabic
      (isolated/initial/medial/final forms) in Noto Naskh — visually inspect all
      relevant placeholder labels, not just `نجمة`.
- [ ] The chosen avatar shows in the Home greeting header.

## On completion

When all items pass, re-run verification so the phase flips to `passed`:
`/gsd:verify-work 05`  (or re-run `/gsd:execute-phase 05` verification).

Note: the 8 placeholder Arabic nicknames and per-grade entry points carry
`TODO(owner's-mother sign-off)` in `onboarding_data.dart` — pedagogical wording
is pending the curriculum owner's review (tracked, intentional, not code debt).
