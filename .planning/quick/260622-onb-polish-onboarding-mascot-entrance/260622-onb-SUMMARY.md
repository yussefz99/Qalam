---
phase: quick-260622-onb
plan: 01
status: complete
date: 2026-06-22
files_modified:
  - lib/features/onboarding/onboarding_screen.dart
---

# Quick Task 260622-onb — Polish onboarding (mascot welcome + entrance)

## What changed

Two warmth beats added to the first-launch onboarding card, both mirroring
existing home-screen idioms; flow, data, and every v1 safety invariant untouched.

1. **Mascot welcome.** The card header is now a leading-mascot Row (same shape as
   the home greeting): `assets/mascot/qalam-idle.svg` beside the title + subtitle,
   with a graceful `SizedBox` fallback via `placeholderBuilder` if the asset is
   missing. Qalam — the tutor's persona (Decided) — now greets the child on the
   very first screen.
2. **Gentle entrance.** New private `_OnboardingEntrance` wrapper fades the card in
   while sliding it up ~24px (`QalamSpace.space6`) over `QalamMotion.durSlow`
   (420ms) with `easeOutQuart` — a one-shot per arrival (decision held in State).
   Reduced motion (`MediaQuery.disableAnimations`) returns the child fully settled,
   no controller. Directly mirrors home's `_PreparedDeskEntrance`.

Added the `flutter_svg` import. No l10n strings changed (reused
`onboardingTitle` / `onboardingSubtitle`). The "here's you" live preview was
deliberately deferred to a follow-up pass.

## Invariants held

- No free-text widget added (no TextField/TextFormField/EditableText).
- `PopScope(canPop: false)` preserved — child still cannot skip onboarding.
- No `QalamColors.reward` / gold; semantic tokens only.
- Submit/validation/data path (`create` → `markProfileCreated` → `go('/')`) unchanged.

## Verification

- `dart format` applied; `flutter analyze lib/features/onboarding/onboarding_screen.dart` → **No issues found**.
- `flutter test test/features/onboarding/onboarding_screen_test.dart test/screens/home_screen_test.dart` → **16/16 passed** (no-free-text, PopScope block, happy-path persist+navigate all green; no overflow/exception).

## Not done (out of scope / follow-up)

- "Here's you!" live preview of chosen avatar + Arabic nickname (next polish pass).
- Per-selection confirm animation.
- Commit not yet made (awaiting owner go-ahead; see STATE Quick Tasks row).
