---
status: partial
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
source: [25-REVIEW-PACKET.md]
started: 2026-07-20T00:00:00Z
updated: 2026-07-20T00:00:00Z
---

## Current Test

[awaiting the mother's live walkthrough — D-11]

<!--
CAPTURE SCAFFOLD — no verdict is pre-filled. The owner reads each 25-REVIEW-PACKET.md
row aloud to the mother (physically next to him, D-11) and records HER verdict into the
`verdict:` line below, one of: confirm / reject / rework. For a `rework`, capture her
correction VERBATIM in `rework instruction:`. She is the curriculum authority (CUR-01);
these are HER pedagogical decisions, not Claude's. Same-session capture is the real
workflow (D-12); if she is ever unavailable, the SAME doc is filled asynchronously later.
Once every row carries a verdict + the Summary tally is filled, ingestion (Plan 25-07
Task 2) flips `signedOff` to match her answers EXACTLY and restores/re-works rejects.
The `ingestion effect:` line under each row is descriptive (what Task 2 will do per
verdict) — it is NOT a verdict.
-->

## Verdicts

_19 packet rows (25-REVIEW-PACKET.md Summary table). Mirror of 19-HUMAN-UAT.md's
expected/result form: `what to confirm` = expected, `verdict` = result._

### A1 — baa writing/tracing clean-reps
- what to confirm: signed 3 → live 1 (both buildSentence removed + 4 exceptions covered by their own rows)
- verdict: [pending]  (confirm 1 / restore to 3 / rework)
- rework instruction: [—]
- ingestion effect: confirm 1 → baa keeps minCleanReps=1. Restore to 3 → edit writing/tracing minCleanReps back to 3 in BOTH graphs/baa.json AND curriculum_graph.json (byte-parity, D-14) → this is a STRUCTURAL baa graph change → triggers the Task 3 server-redeploy question.

### A2 — alif / taa / thaa clean-reps
- what to confirm: currently 1 each, never signed — whatever she sets becomes their first signed spec
- verdict: [pending]  (confirm 1 / set a number / rework)
- rework instruction: [—]
- ingestion effect: confirm 1 → the graphs keep minCleanReps=1 (this fixes the NUMBER; taa/thaa LETTER graphs stay signedOff:false — letter-signing is Phase 27, D-10). Set a number → edit each affected graph's minCleanReps.

### B1 — baa sentence questions removed (`baa.buildSentence.hear`, `baa.buildSentence.picture`)
- what to confirm: keep removed (dormant)?
- verdict: [pending]  (confirm removal / bring back / rework)
- rework instruction: [—]
- ingestion effect: confirm removal → the two cards stay dormant. Bring back → re-activate the node(s).

### B2 — taa/thaa sentence questions removed (`taa.buildSentence.hear/.picture`, `thaa.buildSentence.hear/.picture`)
- what to confirm: keep removed (dormant)?
- verdict: [pending]  (confirm removal / bring back / rework)
- rework instruction: [—]
- ingestion effect: confirm removal → the four cards stay dormant. Bring back → re-activate the node(s).

### C1 — alif letter-level shrink (no word/sentence/grammar in the alif unit)
- what to confirm: the narrowed alif unit
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → alif stays letter-level. Reject/rework → restore/adjust the alif unit per her instruction.

### C2 — new `alif.writeLetter.fromPicture` draft (lion → أسد → write ا)
- what to confirm: the wording + the lion → أسد pairing (draft, signedOff:false)
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → alif.writeLetter.fromPicture signedOff:false → true in exercises.json (D-15 promote). Reject → remove the card. Rework → change the word/art per her instruction, stays signedOff:false until it matches.

### D1 — picture swaps (`taa.teachCard.meet`, `taa.writeLetter.fromPicture`, `taa.writeWord.picture`, `taa.buildSentence.picture`, `alif.teachCard.meet`)
- what to confirm: the example words + art; note alif meet uses أرنب (rabbit) while C2 uses أسد (lion) — confirm both or align them
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → the swaps stay. Reject/rework → restore the prior word/art or change per her instruction.

### D2 — feedback rewordings (`taa.writeWord.dictation`, `taa.writeWord.copy`, `alif.writeWord.dictation`, `alif.writeWord.copy`)
- what to confirm: the corrected feedback lines (dictation = listening, copy = word-shown)
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → the reworded lines stay. Reject/rework → restore the prior wording or change per her instruction.

### E1 — word/label diff (old → new)
- what to confirm: the full before/after table incl. the `taa.completeWord.middle` label fix (`[taa]`→`[taa, waaw]`)
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → the diff stands. Reject/rework → restore/change per her instruction (note: the label fix is a truthfulness correction, not a word change).

### F1-a — `baa.fillBlank.adjective` (البابُ ___ / كبير) — reaches ahead (raa, kaaf, yaa), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → exercise-level signedOff:false → true in exercises.json. Reject → re-point or remove the card AND drop `baa.fillBlank.adjective` from ALL THREE exception sets (validate.py OWNER_APPROVED_EXCEPTIONS, the lint's baaOwnerApprovedExceptions, L3 kApprovedReachAheadExceptions) so the wall stays in parity + L1's no-rot check holds.

### F1-b — `baa.transformWord.dual` (باب → بابان) — reaches ahead (noon), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → exercise-level signedOff → true. Reject → re-point/remove AND drop `baa.transformWord.dual` from all three exception sets.

### F1-c — `baa.transformWord.plural` (باب → أبواب) — reaches ahead (waaw), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → exercise-level signedOff → true. Reject → re-point/remove AND drop `baa.transformWord.plural` from all three exception sets.

### F1-d — `baa.transformWord.opposite` (كبير → صغير) — reaches ahead (raa, saad, ghayn, yaa), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → exercise-level signedOff → true. Reject → re-point/remove AND drop `baa.transformWord.opposite` from all three exception sets.

### F2·taa — the 10 taa reach-ahead questions (D-16)
- ids: `taa.writeWord.dictation/.copy/.picture`, `taa.connectWord.taaj/.bayt`, `taa.completeWord.middle`, `taa.fillBlank.adjective`, `taa.transformWord.dual/.plural/.opposite`
- what to confirm: approve the block (or mark any single one reject/rework)
- verdict: [pending]  (confirm / reject / rework — block or per-row)
- rework instruction: [—]
- ingestion effect: confirm → the 10 stay exempt (taa LETTER graph stays signedOff:false, Phase 27). Any rejected id → re-point/remove AND drop it from all three exception sets.

### F2·thaa — the 8 thaa reach-ahead questions (D-16)
- ids: `thaa.writeWord.dictation/.copy/.picture`, `thaa.connectWord.thalab/.thalj`, `thaa.completeWord.middle`, `thaa.fillBlank.adjective`, `thaa.transformWord.dual`
- what to confirm: approve the block (or mark any single one reject/rework)
- verdict: [pending]  (confirm / reject / rework — block or per-row)
- rework instruction: [—]
- ingestion effect: confirm → the 8 stay exempt (thaa LETTER graph stays signedOff:false, Phase 27). Any rejected id → re-point/remove AND drop it from all three exception sets.

### G1 — `thaa.transformWord.dual` (draft ثعلبان)
- what to confirm: is +ان → ثعلبان the right dual, or give the correct one
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → keep ثعلبان. Rework → set her dual in exercises.json.

### G2 — `thaa.transformWord.plural` (needs her word)
- what to confirm: the correct (broken) plural for the base word — currently a null placeholder
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: rework/give word → fill the placeholder (expected:null) with her plural. Left open → stays a placeholder.

### G3 — `thaa.transformWord.opposite` (needs her pair)
- what to confirm: an age-appropriate opposite pair — currently a null placeholder
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: rework/give pair → fill the placeholder (expected:null) with her pair. Left open → stays a placeholder.

### G4 — `thaa.buildSentence.hear` / `thaa.buildSentence.picture` (draft adjective; currently removed, Group B)
- what to confirm: the sentence + audio (draft adjective كبير)
- verdict: [pending]  (confirm / reject / rework)
- rework instruction: [—]
- ingestion effect: confirm → keep the draft adjective (cards stay dormant per B2 unless she also brings them back). Rework → set her adjective.

## Summary

total: 19
confirmed: ___
rejected: ___
reworked: ___
left open: 19 (all pending — awaiting the live walkthrough)

## Server-redeploy disposition (Plan 25-07 Task 3 — resolved AFTER ingestion)

- baa graph structurally changed this phase (git diff on curriculum_graph.json): [pending — checked in Task 3]
- disposition: [pending — one of: "no redeploy needed" / "authorized (redeployed)" / "deferred to <phase>"]
- note: a Cloud Run `qalam-tutor` redeploy needs FRESH EXPLICIT owner authorization (every prod deploy is owner-gated; creds may be expired). Never assumed free.

## Gaps

- Every row above is `[pending]`: this scaffold captures the mother's verdicts during the D-11 live walkthrough. No verdict is pre-filled. Ingestion (25-07 Task 2) proceeds only once the owner records her answers here.
