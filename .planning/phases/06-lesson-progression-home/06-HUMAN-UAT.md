---
status: partial
phase: 06-lesson-progression-home
source: [06-VERIFICATION.md]
started: 2026-06-13T00:00:00Z
updated: 2026-06-13T00:00:00Z
---

## Current Test

[awaiting human testing on a real Android tablet]

## Tests

### 1. Device UAT — launch → today's lesson → pass → unlock flow
expected: Fresh app launch lands directly on today's lesson card with one Start and no navigation; trace the letter to its clean-reps-to-advance count; the celebration appears; tapping Next Lesson opens the newly unlocked letter, and returning Home shows that letter as today's lesson.
why_human: Stylus capture + real-device launch/scoring/unlock behavior is not emulatable in flutter_test; on-device confirmation is the canonical end-of-phase gate per 06-VALIDATION.md.
result: [pending]

### 2. Device UAT — Fix A: curl letters load without crashing (06-09)
expected: Open a curl letter (e.g. jeem or taa_h) on a real tablet — it loads and is practicable without crashing. The app no longer throws the "looks like a closed outline loop" validation error when the curl-stroke letter is selected.
why_human: The crash only reproduces with the real curriculum data loaded on-device; the fix is validated by the owner opening the letter and tracing it.
result: [pending]

### 3. Device UAT — Fix B: dots visible in Watch + Trace (06-10)
expected: On baa, taa, and thaa, the dot is visible in BOTH the "Watch me write" animation AND the dotted Trace guide. It renders as a calm ink dot (deep-ink color, ~stroke-width) — no bounce, no hype, and NOT gold (the gold start-dot and pen-tip stay reward-exclusive). The dot appears just after its body stroke in the Watch animation.
why_human: Visual dot rendering across the 15 dotted letters is confirmed by eye on a real tablet; flutter_test proves the painter draws the circle, but on-device confirms it reads correctly to a child.
result: [pending]

note: The only expected residual automated failure is `test/glyph_audit_golden_test.dart` (and any mastery_celebration goldens) — documented environmental Noto-Naskh font drift, NOT a regression. Do NOT re-bake these goldens to "fix" them.

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
