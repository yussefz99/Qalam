# 07-07 SUMMARY — baa Letter Unit: forms drafted, owner-reviewed, sign-off PENDING

**Status:** Task 1 COMPLETE · Task 2 (sign-off gate) PARTIALLY APPROVED · Task 3 DEFERRED
**Plan goal:** Make baa real end-to-end (SC#4) — author the four contextual forms, get the
owner's-mother sign-off, then seed signed-off Schema v2 into Firestore.

## What landed (Task 1 — on main)
- `assets/curriculum/letters.json` — baa `contextualForms` authored for all four positions
  (isolated / initial / medial / final) as OPEN-CENTERLINE pen-tip paths (normalized 0..1,
  ordered, typed, dot-below, rightToLeft body). 3–4 `commonMistakes` per form in the tutor's
  voice; per-form `tolerances: {preset: normal}`. **Every `signedOff:false` kept.**
- `test/curriculum/baa_signoff_test.dart` — 18 validity assertions GREEN; 2 sign-off assertions
  **RED by design** (letter-level + per-exercise), proving the human gate is required.
- `exercises.json` / `words.json` — reviewed, already correct (door/duck/milk vocab; voice OK) — no edit.

## Sign-off gate outcome (owner decision, 2026-06-15)
Owner reviewed and **approved the drafted form shapes / mistakes / vocab pedagogically**, BUT:
- `signedOff` REMAINS `false` for baa and its exercises — NOT flipped.
- The approval is conditional on two things still pending:
  1. **Tablet re-capture** of initial / medial / final via `/dev/authoring` (best-effort
     centerlines only so far; device-gated like alif 04-06). isolated form is the validated boat+dot.
  2. **Real pronunciation audio** to replace the 07-02 placeholder clips in `assets/audio/`.

## Deferred — Task 3 (run on full sign-off)
When tablet re-capture + real audio land and the owner sets `signedOff:true`:
- Extend `tools/firebase/seed_firestore.py` / `export_firestore.py` to seed exercises/words/units
  + baa `contextualForms` (via `point_codec`), with a round-trip self-check (mirror 06.1-03;
  live Firestore seed stays SA-key/region gated).
- Flip the `baa_signoff_test.dart` sign-off group to a GREEN regression gate.

**Resume:** `/gsd:execute-phase 07 --wave 5` (or signal "signed off: baa" to the 07-07 executor)
once capture + audio are done and the flags are set true.
