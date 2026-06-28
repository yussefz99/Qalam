---
status: passed
phase: 15-build-dynamic-grounded-exercise-selection-on-baa
source: [15-07-PLAN.md, docs/curriculum/baa-curriculum-graph-signoff-sheet.md]
reviewer: Owner-mother (Arabic-teacher domain expert)
reviewed: 2026-06-28T00:00:00Z
started: 2026-06-28T00:00:00Z
updated: 2026-06-28T00:00:00Z
---

## Current Test

[complete — owner-mother tier-level sign-off of the baa curriculum graph]

## Tests

### 1. Curriculum graph sign-off — competency mapping (Q1, D-05)
expected: >-
  The owner-mother confirms each of the 19 baa configs sits under the right competency
  (recognize / positionalForms / copyWrite / fluentReading / wordBuilding / grammarTransform)
  in assets/curriculum/curriculum_graph.json, reviewed via
  docs/curriculum/baa-curriculum-graph-signoff-sheet.md.
result: [pass] — APPROVED as drafted. No change to any node's competency field.

### 2. Curriculum graph sign-off — 70/30 essential/enrichment split (Q2, D-05)
expected: >-
  The owner-mother confirms recognize / positionalForms / copyWrite / fluentReading are the
  essential core that gates the mastery star, while wordBuilding (fill-blank) and
  grammarTransform (dual/plural/opposite) are enrichment that does NOT gate the star.
result: >-
  [pass] — APPROVED as drafted. Grammar (grammarTransform) and fill-blank (wordBuilding) remain
  essential:false (enrichment). Reviewer note: grammar is still mandatory grade-1 content
  presented to the child, but with a simple bar — which the model already reflects (enrichment
  nodes are reachable/presented with minCleanReps:1; they do not gate the star). No change to any
  essential flag or prerequisites.

### 3. Curriculum graph sign-off — per-skill clean-reps (Q3, D-05/D-07)
expected: >-
  The owner-mother sets the clean-reps each skill requires before it counts as cleared.
result: >-
  [pass] — ADJUSTED. "Writing & tracing = 3 clean reps; lighter exercises stay at 1." Applied to
  assets/curriculum/curriculum_graph.json: minCleanReps 2 → 3 for the nine writing nodes
  (writeLetter.fromSound/.fromPicture/.writeForm, connectWord.baab/.kitaab, completeWord.middle,
  writeWord.copy/.picture/.dictation), joining the three traceLetter.* already at 3. All other
  nodes (teachCard.meet, buildSentence.hear/.picture, fillBlank.adjective, transformWord.* ×3)
  stay at 1. No change to competencies, essential flags, prerequisites, or difficulty tiers.

### 4. signedOff flip + derived server copy (D-05 / Pitfall 4)
expected: >-
  After sign-off, signedOff flips false → true ONLY in the canonical asset, and the read-only
  server copy is re-derived from it via generate.py (never hand-edited).
result: >-
  [pass] — assets/curriculum/curriculum_graph.json now signedOff:true; server copy regenerated
  via `cd server && uv run python -m app.curriculum_data.generate` → signedOff:true, 19 baa.*
  nodes, reps match the asset byte-for-byte. Acceptance check prints
  "signed + derived + baa-only OK".

### 5. baa-only scope (D-11)
expected: >-
  No ت/ث (taa/thaa) cross-letter content in the signed graph — baa's own dot only.
result: >-
  [pass] — every node exerciseId starts with baa.; no taa/thaa nodes. (baa.connectWord.kitaab is
  a baa word-writing exercise — the word كتاب — not taa content.)

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

## Notes

Tier-level sign-off (D-05) recorded by the owner-mother on 2026-06-28 against
docs/curriculum/baa-curriculum-graph-signoff-sheet.md (now marked SIGNED). This human-UAT
entry accompanies the signedOff:true commit per Pitfall 4 — never ship model-DRAFTED pedagogy
as if signed.

FOLLOW-UP (OPS / human, needs gcloud auth — NOT done by this plan): re-deploy the qalam-tutor
Cloud Run service so the signed graph (server/app/curriculum_data/curriculum_graph.json) AND the
enlarged non-PII wire contract from 15-02/15-04 (clearedTiers/clearedCompetencies on
TutorFactsIn) are live before on-device /coach testing. The standalone server re-deploy is safe
(backward-compatible defaults; rail no-op on empty), and MUST land before the Dart side relies on
the graph-position fields online.
