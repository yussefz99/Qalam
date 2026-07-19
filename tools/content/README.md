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
python -m content.build_draft     # regenerate words_draft.json
python -m content.validate        # write validation_report.md + print a summary
python -m content.validate --gate # + FAIL the build on live-node findings (criterion 1)
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
there. Without `--gate` it exits non-zero only if the *draft bank itself* has a
blocking (unmappable) decomposition — live findings are report content, not build
errors.

## The build gate (`--gate`) — the seen-letters wall's L0

`python -m content.validate --gate` is the build gate criterion 1 references
(Phase 25, D-04..D-09). After regenerating the report it exits **non-zero** when
any **live graph-node** card either:

- **reaches ahead** — its stored `letters[]` demands a letter whose `introOrder`
  is later than the card's unit (via `unlearned_letters_for_exercise`), or
- **is unlabeled** — its `letters[]` is missing/empty or drifts from the
  decomposition of its display text (via `unlabeled_cards`).

Scoping matches the Dart lint exactly (`live_graph_node_ids` mirrors the lint's
`liveNodeIds`): **dormant** configs — cards in `exercises.json` referenced by no
live graph node, e.g. `alif.buildSentence.hear` — are never gated, and the
`OWNER_APPROVED_EXCEPTIONS` (the 4 D-09 baa ids, pending the mother's ruling) are
exempt. The seeder (`tools/firebase/seed_curriculum_v2.py`, L2) imports the same
`unlearned_letters_for_exercise` / `live_graph_node_ids` / `OWNER_APPROVED_EXCEPTIONS`,
so all four wall layers (L0 audit, L1 lint, L2 seeder, L3 runtime guard) refuse
identical content. The gate exits 0 once the live worklist is triaged to zero.

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
