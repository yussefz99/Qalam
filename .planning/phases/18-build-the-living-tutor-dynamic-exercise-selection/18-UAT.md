---
status: complete
phase: 18-build-the-living-tutor-dynamic-exercise-selection
source: [18-01-SUMMARY.md, 18-02-SUMMARY.md, 18-03-SUMMARY.md, 18-04-SUMMARY.md, 18-05-SUMMARY.md, 18-06-SUMMARY.md, 18-07-SUMMARY.md, 18-08-SUMMARY.md, 18-09-SUMMARY.md, 18-10-SUMMARY.md, commits 2d5f0b0/7bf60e7 (owner UAT fixes 2026-07-12)]
started: "2026-07-16T18:41:38.353Z"
updated: "2026-07-17T08:17:53.651Z"
---

## Current Test

[testing complete]

## Tests

### 1. Exercise opens with instruction held, not a bare canvas
expected: Open any exercise. The tutor speaks what's needed for that question, and the canvas is visible but NOT writable (dimmed / strokes don't register) until the instruction finishes speaking (capped ~8s). It should never open as a bare, immediately-writable canvas with no instruction.
result: pass

### 2. Stimulus picture is large and readable
expected: For an exercise with a picture prompt, the image renders large (roughly 260x176) and clearly — easy to make out on the tablet, not a tiny thumbnail.
result: issue
reported: "here i gave you a screenshot it can be much much better"
severity: cosmetic

### 3. A single wrong attempt never jumps forward
expected: Get one attempt wrong. The app offers retry-in-place (or a one-tier-down remediation) — it does NOT silently advance to a new, unrelated exercise after just one miss.
result: issue
reported: "the question now is write baa intial form without the dots and i write it wring it succesfuly caught the mistake but now when i press write again nothing happens and i am stuck i can only press clear and there should be somthing to make the tutor speak again the instructions of the question"
severity: major

### 4. Two same-mistake fails in a row step down immediately
expected: Make the same kind of mistake twice in a row on the same letter. The very next card steps DOWN to a simpler guided trace exercise for that letter (not a third repeat of the identical failing card). Since micro-drills are currently parked, the step-down should land on tracing, not a drill screen.
result: pass

### 5. A pass gives a specific reason, not generic praise
expected: After a correct attempt, the tutor's feedback/next-pick names something specific about what you're working on — not just a bare "Great job, next!" with no reason.
result: issue
reported: "its feels static always showing your baa wants a deeprer bowl a low smooth scoop before you lift"
severity: major

### 6. Teacher's Margin note is visible beside the canvas, with no gamification language
expected: A small warm text note near the writing canvas narrates what's happening (e.g. naming the focus of the current exercise or step-down). No points, streaks, badges, "+N", or score language appears anywhere on screen.
result: issue
reported: "it got stuck now and wont let me move to the next one i got out of the app and went again , now for the teacher margin i never understood at all"
severity: blocker

### 7. A returning child's session reflects past struggles (across-session memory)
expected: If you can test this (requires a prior session's data plus the nightly profile compile, or a manual job re-run), a returning child's first pick in a new session should reflect what they struggled with before — not start cold every time. If you can't set this up right now, say "blocked" and why.
result: issue
reported: "when i closed the app and reopend it did start from scrathc in unit baa , i dont think so and i think we should chage that nightly job"
severity: major

## Summary

total: 7
passed: 2
issues: 5
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "For an exercise with a picture prompt, the image renders large (roughly 260x176) and clearly — easy to make out on the tablet, not a tiny thumbnail."
  status: failed
  reason: "User reported: here i gave you a screenshot it can be much much better"
  severity: cosmetic
  test: 2
  artifacts: []
  missing: []

- truth: "Get one attempt wrong. The app offers retry-in-place (or a one-tier-down remediation) — it does NOT silently advance to a new, unrelated exercise after just one miss."
  status: failed
  reason: "User reported: the question now is write baa intial form without the dots and i write it wring it succesfuly caught the mistake but now when i press write again nothing happens and i am stuck i can only press clear and there should be somthing to make the tutor speak again the instructions of the question"
  severity: major
  test: 3
  artifacts: []
  missing: []

- truth: "After a correct attempt, the tutor's feedback/next-pick names something specific about what you're working on — not just a bare 'Great job, next!' with no reason."
  status: failed
  reason: "User reported: its feels static always showing your baa wants a deeprer bowl a low smooth scoop before you lift (same line every time, not generated per-attempt)"
  severity: major
  test: 5
  artifacts: []
  missing: []

- truth: "A small warm text note near the writing canvas narrates what's happening. No points, streaks, badges, '+N', or score language appears anywhere on screen."
  status: failed
  reason: "User reported: it got stuck now and wont let me move to the next one i got out of the app and went again , now for the teacher margin i never understood at all"
  severity: blocker
  test: 6
  artifacts: []
  missing: []

- truth: "A returning child's session reflects past struggles (across-session memory); resuming should not lose in-progress position within the same unit either."
  status: failed
  reason: "User reported: when i closed the app and reopend it did start from scrathc in unit baa , i dont think so and i think we should chage that nightly job"
  severity: major
  test: 7
  artifacts: []
  missing: []
