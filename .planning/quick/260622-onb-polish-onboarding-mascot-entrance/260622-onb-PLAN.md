---
phase: quick-260622-onb
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/onboarding/onboarding_screen.dart
autonomous: true
requirements: [S1-quick-onboarding-polish]

must_haves:
  truths:
    - "The onboarding setup card opens with the Qalam reed-pen mascot welcoming the child beside the title (the tutor's persona, tying the first screen to the rest of the app)."
    - "The card fades in while sliding up ~24px on first arrival (durSlow / easeOutQuart), and renders fully settled immediately under reduced motion."
    - "All v1 safety invariants are untouched: no free-text widget, no PII, no reward gold, PopScope(canPop:false) preserved, flow + data + submit logic unchanged."
  artifacts:
    - path: "lib/features/onboarding/onboarding_screen.dart"
      provides: "mascot welcome header + reduced-motion-safe one-shot entrance wrapper"
      contains: "qalam-idle.svg"
  key_links:
    - from: "lib/features/onboarding/onboarding_screen.dart"
      to: "assets/mascot/qalam-idle.svg"
      via: "SvgPicture.asset with placeholderBuilder fallback (mirrors home greeting)"
      pattern: "qalam-idle.svg"
---

<objective>
Polish the first-launch onboarding screen so it feels as warm as the rest of the
app, WITHOUT changing the flow, the data, or any v1 safety invariant. Two beats,
both mirroring existing home-screen idioms:

1. Mascot welcome — the Qalam reed-pen character (assets/mascot/qalam-idle.svg)
   greets the child beside the title, the same leading-mascot Row layout the home
   greeting uses. Qalam is the tutor's persona (Decided), so he belongs on the
   very first screen.
2. Gentle entrance — the setup card fades in while sliding up ~24px on first
   arrival (durSlow, easeOutQuart), mirroring home's prepared-desk settle. One-shot;
   reduced motion (MediaQuery.disableAnimations) renders fully settled at once.

Scope guardrails (do NOT exceed): only onboarding_screen.dart changes. Do NOT add
any free-text/TextField/EditableText, do NOT touch the submit/validation/data path,
do NOT remove PopScope(canPop:false), do NOT use QalamColors.reward (no gold). No
l10n string changes (reuse onboardingTitle/onboardingSubtitle). No "here's you"
live preview in this pass (deferred to a follow-up).
</objective>

<verification>
- onboarding_screen.dart references assets/mascot/qalam-idle.svg (mascot welcome present).
- A one-shot entrance wrapper fades+slides the card; reduced-motion path returns the child settled.
- find.byType(TextField/TextFormField/EditableText) still findsNothing; PopScope.canPop still false.
- flutter analyze clean for the file; onboarding_screen_test.dart + home suite green.
</verification>

<success_criteria>
The onboarding card opens with Qalam welcoming the child and settles in gently, and
every existing onboarding test (no-free-text, PopScope block, happy-path persist +
navigate) stays green.
</success_criteria>

<output>
Create `.planning/quick/260622-onb-polish-onboarding-mascot-entrance/260622-onb-SUMMARY.md` when done.
</output>
