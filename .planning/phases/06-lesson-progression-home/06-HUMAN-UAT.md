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

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
