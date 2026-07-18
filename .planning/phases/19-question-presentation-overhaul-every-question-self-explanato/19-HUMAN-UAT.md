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
result: ISSUES FOUND 2026-07-18 (owner iPad session) → FIXED same day, re-test pending:
  (a) micro-drills interrupted the unit flow — owner ordered them OUT of the live graph (reverses D-18; third flip of this feature, see graph _meta.owner_removal_2026_07_18);
  (b) the 6 D-19-gated cards were missed on device ("perfect and really impressive") — owner ordered ALL 6 RESTORED with an owner-approved learned-letters lint exception (reverses D-19);
  (c) kitaab card word changed to بابا (dad) — owner's pick from the 19-REVIEW-PACKET alternatives (alif+baa only, no duplicate of baab).
  Presentation itself (instruction bar / stimulus / affordances) not yet judged — re-test on the rebuilt install.

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
result: PASSED 2026-07-18 — owner authorized in-session ("Deploy now"); rev qalam-tutor-00028-bzr serving 100%; /health 200, /coach unauthenticated 401.

## Summary

total: 5
passed: 1
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
