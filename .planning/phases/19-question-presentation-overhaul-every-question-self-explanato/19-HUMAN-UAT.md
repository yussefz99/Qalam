---
status: partial
phase: 19-question-presentation-overhaul-every-question-self-explanato
source: [19-VERIFICATION.md]
started: 2026-07-18T00:00:00Z
updated: 2026-07-18T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Cold-read legibility on a real tablet (sound off)
expected: Every non-trace question type, read cold from the screen with sound off, tells the child what to do — instruction bar (icon + short text), large stimulus (image / replayable audio card / word-to-copy), and a per-type affordance (gap slot box, copy hide+peek, trace ghost). The spoken line is reinforcement only.
result: [pending]

### 2. WR-03 — no audio overlap on listen-and-write
expected: On a listen-and-write question, the hero audio card's clip auto-plays once WITHOUT the spoken instruction talking over it in the same frame; tapping the instruction bar still re-speaks the instruction.
result: [pending]

### 3. WR-04 — fast-tap step-down integrity
expected: Failing a trace twice with an active arc steps down to the guaranteed-doable floor trace even when "Next"/"Try again" is tapped quickly; "Next exercise" never becomes a permanently dead button.
result: [pending]

### 4. Mother's sign-off on the review packet
expected: 19-REVIEW-PACKET.md reviewed by the owner's mother — the kitaab→باب rewrite (note: duplicates the existing baa.connectWord.baab card; packet offers alternatives) and the 6 gated cards' Phase 20/21 placement confirmed. Rewrite ships signedOff:false until she signs (D-11, non-blocking by design).
result: [pending]

### 5. Owner-authorized server redeploy
expected: The re-derived server curriculum_data (WR-05 — G4 gate now accepts restored micro-drills + final trace + kitaab, rejects the 6 gated ids) is deployed to the tutor server. Committed but NOT deployed — each prod deploy needs fresh explicit owner wording.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
