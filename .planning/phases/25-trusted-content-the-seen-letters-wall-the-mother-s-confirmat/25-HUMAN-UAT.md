---
status: partial
phase: 25-trusted-content-the-seen-letters-wall-the-mother-s-confirmat
source: [25-REVIEW-PACKET.md]
started: 2026-07-20T00:00:00Z
updated: 2026-07-20T12:00:00Z
---

## Current Test

[live walkthrough COMPLETE 2026-07-20 — the mother ruled on all 19 rows, owner reading aloud (D-11). Two follow-ups remain: (1) A1 baa graph change + tutor-server redeploy, (2) the taa/thaa "letter-form" rework, which is new authoring she must sign — see notes.]

<!--
CAPTURE COMPLETE. Verdicts recorded from the 2026-07-20 live sitting. Reworks captured
VERBATIM. She is the curriculum authority (CUR-01); these are HER decisions. Ingestion
(Plan 25-07 Task 2) flips signedOff to match the CONFIRMED rows; the REWORK rows that
require new content (A1 reps, the taa/thaa letter-form rewrite) are follow-up authoring
she must sign before those flip.
-->

## Verdicts

### A1 — baa writing/tracing clean-reps
- what to confirm: signed 3 → live 1
- verdict: **rework — restore to 3**
- rework instruction: Put baa writing & tracing back to 3 clean reps, as originally signed. (alif/taa/thaa stay at 1 — see A2.)
- ingestion effect: edit writing/tracing minCleanReps 1→3 in BOTH graphs/baa.json AND curriculum_graph.json (byte-parity, D-14). STRUCTURAL baa graph change → triggers the Task 3 tutor-server redeploy question (owner-gated).

### A2 — alif / taa / thaa clean-reps
- what to confirm: currently 1 each, never signed
- verdict: **confirm 1**
- rework instruction: [—]
- ingestion effect: graphs keep minCleanReps=1 (fixes the NUMBER; taa/thaa LETTER graphs stay signedOff:false — letter-signing is Phase 27, D-10).

### B1 — baa sentence questions removed (`baa.buildSentence.hear`, `baa.buildSentence.picture`)
- what to confirm: keep removed?
- verdict: **confirm removal**
- rework instruction: [—]
- ingestion effect: the two cards stay dormant.

### B2 — taa/thaa sentence questions removed (`taa.buildSentence.hear/.picture`, `thaa.buildSentence.hear/.picture`)
- what to confirm: keep removed?
- verdict: **rework (rule) — stay removed**
- rework instruction (VERBATIM): "if the question only asks from us to write the first letter and its a letter learned then keep it other than that remove it"
- ingestion effect: the four sentence cards ask for whole sentences (not the first letter) → stay dormant. This rule is her GUIDING PRINCIPLE and is the basis for the F2 rework below.

### C1 — alif letter-level shrink
- what to confirm: the narrowed alif unit
- verdict: **confirm**
- rework instruction: [—]
- ingestion effect: alif stays letter-level.

### C2 — new `alif.writeLetter.fromPicture` draft (lion → أسد → write ا)
- what to confirm: the wording + lion → أسد pairing
- verdict: **confirm (lion → أسد)**
- rework instruction: [—]
- ingestion effect: alif.writeLetter.fromPicture signedOff:false → true in exercises.json (D-15 promote). Two different alif example words are intentional: أرنب (rabbit) on the meet card, أسد (lion) here — she confirmed both (see D1). **APPLIED 2026-07-20 (signedOff→true).**

### D1 — picture swaps (`taa.teachCard.meet`, `taa.writeLetter.fromPicture`, `taa.writeWord.picture`, `taa.buildSentence.picture`, `alif.teachCard.meet`)
- what to confirm: example words + art; rabbit vs lion for alif
- verdict: **confirm**
- rework instruction: [—]
- ingestion effect: the swaps stay; the two alif example words (rabbit meet / lion writeLetter) are both approved. **alif.teachCard.meet APPLIED 2026-07-20 (signedOff→true).** (taa.* swaps stay signedOff:false — folded into the F2·taa rework.)

### D2 — feedback rewordings (`taa.writeWord.dictation`, `taa.writeWord.copy`, `alif.writeWord.dictation`, `alif.writeWord.copy`)
- what to confirm: corrected feedback lines (dictation = listening, copy = word-shown)
- verdict: **confirm**
- rework instruction: [—]
- ingestion effect: the reworded lines stay. **alif.writeWord.dictation + alif.writeWord.copy APPLIED 2026-07-20 (signedOff→true).** (taa.writeWord.dictation/.copy stay signedOff:false — folded into the F2·taa rework.)

### E1 — word/label diff (old → new)
- what to confirm: the diff incl. `taa.completeWord.middle` label `[taa]`→`[taa, waaw]`
- verdict: **confirm**
- rework instruction: [—]
- ingestion effect: the diff stands (label fix is a truthfulness correction). NOTE: taa.completeWord.middle is itself in the F2·taa set → reworked to letter-form below.

### F1-a — `baa.fillBlank.adjective` (البابُ ___ / كبير) — reaches ahead (raa, kaaf, yaa), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: **confirm (keep live)**
- rework instruction: [—]
- ingestion effect: exercise-level signedOff:false → true in exercises.json; stays an owner+mother-approved exception. **baa.fillBlank.adjective APPLIED 2026-07-20 (signedOff→true).**

### F1-b — `baa.transformWord.dual` (باب → بابان) — reaches ahead (noon), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: **confirm (keep live)**
- rework instruction: [—]
- ingestion effect: exercise-level signedOff → true; stays an approved exception. **baa.transformWord.dual APPLIED 2026-07-20 (signedOff→true).**

### F1-c — `baa.transformWord.plural` (باب → أبواب) — reaches ahead (waaw), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: **confirm (keep live)**
- rework instruction: [—]
- ingestion effect: exercise-level signedOff → true; stays an approved exception. **baa.transformWord.plural APPLIED 2026-07-20 (signedOff→true).**

### F1-d — `baa.transformWord.opposite` (كبير → صغير) — reaches ahead (raa, saad, ghayn, yaa), D-09
- what to confirm: mother approval OR re-point/remove
- verdict: **confirm (keep live)**
- rework instruction: [—]
- ingestion effect: exercise-level signedOff → true; stays an approved exception. **baa.transformWord.opposite APPLIED 2026-07-20 (signedOff→true).** (baa's graph flag stays FALSE this pass — it only flips back to true once ALL baa rows are resolved, and A1 reps→3 is still a deferred rework.)

### F2·taa — the 10 taa reach-ahead questions (D-16)
- ids: `taa.writeWord.dictation/.copy/.picture`, `taa.connectWord.taaj/.bayt`, `taa.completeWord.middle`, `taa.fillBlank.adjective`, `taa.transformWord.dual/.plural/.opposite`
- verdict: **rework → letter-form practice**
- rework instruction (VERBATIM): "for taa also and thaa keep them use them only for writing a form of letter not a word if we contiune like that for each unit there will be minimial questions"
- ingestion effect: KEEP the 10 questions in the taa unit but re-author each to practice writing the taa LETTER-FORM (its shape in position), NOT a whole reach-ahead word. This SUPERSEDES D-16 for taa (they are no longer approved as reach-ahead words). This is NEW curriculum authoring the mother must specify + sign — NOT a mechanical flip. Until reworked+signed, these stay signedOff:false, kept safe by the wall. Once reworked to letter-forms they become legal by the wall's own rule and leave the exception set.

### F2·thaa — the 8 thaa reach-ahead questions (D-16)
- ids: `thaa.writeWord.dictation/.copy/.picture`, `thaa.connectWord.thalab/.thalj`, `thaa.completeWord.middle`, `thaa.fillBlank.adjective`, `thaa.transformWord.dual`
- verdict: **rework → letter-form practice**
- rework instruction (VERBATIM): same as F2·taa above.
- ingestion effect: KEEP the 8 questions in the thaa unit but re-author each to practice the thaa LETTER-FORM, not a whole word. Supersedes D-16 for thaa. New authoring, mother-signed. Same interim/end-state as F2·taa.

### G1 — `thaa.transformWord.dual` (draft ثعلبان)
- verdict: **rework → letter-form (superseded by F2·thaa)**
- rework instruction: Becomes letter-form practice per F2·thaa; no dual word needed.
- ingestion effect: folds into the F2·thaa rework.

### G2 — `thaa.transformWord.plural` (was a null placeholder)
- verdict: **rework → letter-form (superseded by F2·thaa)**
- rework instruction: Becomes letter-form practice; no broken-plural word needed.
- ingestion effect: folds into the F2·thaa rework; the null placeholder is retired.

### G3 — `thaa.transformWord.opposite` (was a null placeholder)
- verdict: **rework → letter-form (superseded by F2·thaa)**
- rework instruction: Becomes letter-form practice; no opposite pair needed.
- ingestion effect: folds into the F2·thaa rework; the null placeholder is retired.

### G4 — `thaa.buildSentence.hear` / `thaa.buildSentence.picture` (draft adjective; currently removed, Group B)
- verdict: **confirm removal (stays removed)**
- rework instruction: [—]
- ingestion effect: stays dormant per B1/B2 (a sentence is not a first-letter question). No adjective needed.

## Summary

total: 19
confirmed: 12   (A2, B1, C1, C2, D1, D2, E1, F1-a, F1-b, F1-c, F1-d, G4)
rejected: 0
reworked: 7    (A1 restore-3, B2 rule, F2·taa, F2·thaa, G1, G2, G3)
left open: 0

## Two follow-ups that keep Phase 25 from fully closing today

1. **A1 — baa reps 1→3 + tutor-server redeploy.** Restoring baa writing/tracing to 3 clean
   reps is a structural baa-graph change (curriculum_graph.json, the tutor server's source).
   A Cloud Run `qalam-tutor` redeploy needs FRESH EXPLICIT owner authorization (creds may be
   expired). Never assumed free (Plan 25-07 Task 3).

2. **F2 taa/thaa "letter-form" rework — the big one.** The mother kept the 18 taa/thaa
   questions but ruled they must practice the letter's FORM, not whole reach-ahead words.
   This SUPERSEDES the owner's D-16 (keep-as-words) — her authority governs pedagogy. It is
   NEW curriculum authoring (~18 questions re-specified as letter-form practice) that she must
   author + sign; it cannot be model-generated (CLAUDE.md: never ship model-authored curriculum
   unsigned). Until reworked, the 18 stay signedOff:false and safe behind the wall. Once
   reworked to letter-forms they become legal by the wall's own rule and leave the exception set.

## Server-redeploy disposition (Plan 25-07 Task 3 — resolved AFTER ingestion)

- baa graph structurally changed this phase (A1 restore-to-3): YES (pending ingestion)
- disposition: [pending owner authorization — one of: "authorized (redeployed)" / "deferred to <phase>"]
- note: every prod deploy is owner-gated; creds may be expired. Never assumed free.

## Gaps

- **PARTIAL INGEST APPLIED 2026-07-20:** the 8 mother-confirmed alif + baa exercise cards were
  flipped signedOff:false → true in exercises.json — C2 (alif.writeLetter.fromPicture),
  D1 (alif.teachCard.meet), D2 (alif.writeWord.dictation + alif.writeWord.copy), and
  F1-a..d (baa.fillBlank.adjective, baa.transformWord.dual/.plural/.opposite). Gate + lint +
  parity stayed green (signedOff is decoupled from enforcement, D-04/D-05). The baa GRAPH flag,
  curriculum_graph.json, and every taa.*/thaa.* card were left untouched (A1 + F2 are open).
- The mechanical CONFIRM flips (A2, B1, C1, C2, D1, D2, E1, F1-a..d) are ready to ingest now.
- A1 (reps→3) is ready to edit but pairs with an owner-gated server redeploy.
- F2·taa / F2·thaa (+ G1–G3) require the mother's authored letter-form content before they
  can be signed — this is the open work carrying Phase 25 (and likely folding into Phase 27).
