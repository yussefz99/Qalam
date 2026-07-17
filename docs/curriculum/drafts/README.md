# `docs/curriculum/drafts/` — model-authored curriculum drafts (UNSIGNED)

Everything here is **DRAFT, `signedOff: false`**. Nothing reaches a child until the
owner's mother reviews and signs it, and the owner promotes it into the live
`assets/curriculum/` files. These drafts exist to make her review sessions
*review-and-correct*, not *start-from-blank* — the same role the review packets play
for stroke data. **The live `exercises.json` / `curriculum_graph.json` are never
written by this tooling.**

## What's here

| path | what | generator |
|------|------|-----------|
| `thaa-jeem-haa-DRAFT.md` | earlier hand-authored draft for letters 4–6 (richer wording — **precedence** for thaa/jeem/haa) | (hand-authored) |
| `source-digest/` | text extracted from the mother's worksheets, per letter, + candidate words. `imageOnly` files had no extractable text. | `python -m content.extract_source` |
| `exercises/` | 25 draft 19-question sets (letters 4–28), mirroring the signed taa template | `python -m content.build_exercises_draft` |
| `graphs/` | 26 draft curriculum graphs (taa + letters 4–28), mirroring the signed baa graph | `python -m content.build_graphs_draft` |

## Regenerate

From the `tools/` directory, in order:

```bash
python -m content.build_draft          # words_draft.json (vocab bank)
python -m content.extract_source       # source-digest/ (needs the raw worksheet folder)
python -m content.build_exercises_draft # exercises/
python -m content.build_graphs_draft   # graphs/ (needs exercises/ first)
```

## What still needs the mother (flagged, not faked)

- **Vocabulary** for letters whose worksheet was image-only (ayn, faa, ghayn, taa_h,
  zhaa) or not found — those sets use flagged draft-bank words (`vocabSource` says so).
  Confirm/swap them.
- **Grammar transforms** — `transformWord.plural` and `transformWord.opposite` carry
  `_review` + `_todo` and have **no** invented answer (broken plurals / antonyms are
  hers to set). `transformWord.dual` is a best-effort regular sound-dual (`+ان`), flagged.
- **Sentences** — `buildSentence.*` adjectives are placeholders (كبير / جميل), flagged
  `_review`; the sentence audio ids are drafts (`sentence.<letter>-draft`).
- **Feedback wording** — kept minimal and warm; her voice is the signature (see CLAUDE.md).
- **Graph placement** — she signs at the **tier level**: confirm each letter's
  competency/tier mapping and per-skill clean-reps.

The raw worksheet export itself is **not committed** (large binaries); only the
extracted `source-digest/` text is version-controlled.
