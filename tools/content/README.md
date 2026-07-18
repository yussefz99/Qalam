# `tools/content/` — draft vocabulary bank + letter validator

Structures candidate vocabulary for all 28 letters and checks it (and the live
content) against the curriculum's intro order. **It never invents pedagogy** —
every word is `signedOff: false` and sourced; the owner's mother signs, the owner
promotes signed words into the live `assets/curriculum/words.json`.

## Pieces

| file | what it is |
|------|-----------|
| [`arabic.py`](arabic.py) | Arabic string → 28-letterId decomposition (written skeleton). Handles the traps explicitly (hamza forms, taa marbuta, alif maqsura, lam-alif, harakat/shadda) and **flags** anything it can't confidently place — never guesses. |
| [`build_draft.py`](build_draft.py) | Regenerates `words_draft.json` from a curated, sourced word list. `letters[]` is **computed** by `arabic.py`, so the bank is self-consistent. |
| [`words_draft.json`](words_draft.json) | The DRAFT bank — 89 words, all 28 letters, live-file schema + `source`/`focusLetter`/`signedOff`, plus a `decompositionReport` of every flagged word. |
| [`validate.py`](validate.py) | The legality report (draft + live). Writes `validation_report.md`. |

## Commands

Run from the `tools/` directory:

```bash
python -m content.build_draft   # regenerate words_draft.json
python -m content.validate      # write validation_report.md + print a summary
```

## What the validator reports

1. **Draft-bank legality** — the earliest intro-order unit each candidate word
   becomes legal (all its letters introduced), and per focus letter which words
   are on-time vs. reach ahead for letters not yet taught.
2. **Live `words.json` consistency** — each live word's stored `letters[]` vs the
   computed decomposition. (This is how the current `بطة` / `حليب` / `توت` drift
   surfaces.)
3. **Live `exercises.json`** — existing content that demands unlearned letters.

The validator is **read-only** against the live curriculum and mutates nothing
there. It exits non-zero only if the *draft bank itself* has a blocking
(unmappable) decomposition — live findings are report content, not build errors.

## Decomposition conventions (flagged for the mother, not silently applied)

| character | mapped to | flag | basis |
|---|---|---|---|
| أ إ آ ٱ | `alif` | `hamza_alif` | established (live `words.json`: أسد → alif) |
| ة | `taa_marbuta` | `taa_marbuta` | app convention — **not one of the 28 taught letters**; the mother decides when/whether it's taught |
| ى | `alif` | `alif_maqsura` | **provisional** — written like yaa, sounds like alif |
| ؤ / ئ | `waaw` / `yaa` | `hamza_waw` / `hamza_yaa` | **provisional** |
| ء | — (omitted) | `hamza_standalone` | unmappable; word flagged, not guessed |
| لا | `laam` + `alif` | — | ligature decomposed |

`source` values: words lifted from the mother's materials are cited; everything
else is `model-suggested (…)` and explicitly awaits her review.
