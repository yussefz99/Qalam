# Curriculum Schema v2 (Stage C — locked shape)

**Date:** 2026-06-15
**Derived from:** the validated Claude Design handoff at
`docs/design/prototypes/letter-unit-baa/` (`HANDOFF.md`, `SCHEMA-BINDINGS.md §C`,
`EXERCISE-CONFIGS.json`) + `COMPONENT-SYSTEM.md`.
**Extends:** the Firestore + bundle model built in Phase 06.1 (adds `forms`, `words`,
`exercises`, `units`).
**Status:** Shape LOCKED (engineering). Content OPEN (the 8 owner's-mother TBDs fill values
and flip `signedOff` — they do **not** change the shape).

---

## 1. The 10 additive fields — resolved

| # | Gap (from SCHEMA-BINDINGS.md §C) | Decision |
|---|---|---|
| 1 | praise line had no home | **Bless `feedback.pass`** as the reserved praise key; all other keys are mistakeIds. |
| 2 | clean-rep count | **`policy.reps`** (per-exercise, owner-tunable; the rep-count TBD lives here). |
| 3 | Watch-me animation | **`surface.demo: bool`**. |
| 4 | ghost-correction | **Global FeedbackPanel behavior, NOT a config field** — consistent system behavior, so it's removed from per-exercise config. |
| 5 | copy/connect text modifiers | **Extend `text` PromptPart** with `reveal:"thenHide"` and `loose:true`. |
| 6 | four-forms strip | **Add `forms` PromptPart kind** (cleaner than composing image+text). |
| 7 | type label | **Add optional `type`** (template label — authoring UI + analytics). |
| 8 | progress / section position | **Add a `LetterUnit` object** that owns ordered sections; `ProgressRibbon` reads its position. |
| 9 | `check` string vs structured | **Structured** `{ base, modifiers[] }` (cleaner for the validator). |
| 10 | relaxed/no-fail (letterMaze) | **`policy.noFail: bool`** (folded with #2 into `policy`). |

> Three are genuine judgment calls — flag if you'd prefer otherwise: **#1** (`pass` vs a separate
> `praise` field), **#4** (ghost global vs per-exercise), **#9** (structured `check` vs string).
> I chose the cleaner/simpler option for each. Everything else is mechanical.

---

## 2. The objects

### Letter — curriculum content (authored, mom signs off)
```
Letter:
  id            "baa"
  char          "ب"
  name          { ar:"باء", en:"baa" }
  introOrder    int
  audio         { letterSound: audioId }
  forms:                          # NULLABLE slots — non-connectors (ا د ذ ر ز و) keep only isolated+final
    isolated    Form
    initial     Form | null
    medial      Form | null
    final       Form | null
  vocab         [ wordId, ... ]
  signedOff     bool

Form:
  referenceStrokes  Stroke[]      # pen-path; Firestore {x,y} point codec from 06.1
  commonMistakes    [ { id, fix } ]   # named checks → authored fix lines
  tolerances        {...}          # per-form, owner-tunable
```

### Word — vocab
```
Word: { id, text:"باب", audio: audioId, image: imageId, gloss:{en}, letters:[letterId...] }
```

### Exercise — the question config (LOCKED shape)
```
Exercise:
  id          "baa.writeWord.dictation"
  type        "writeWord"                 # optional template label (#7)
  skill       "formation"|"recall"|"spelling"|"grammar"|"syntax"|"comprehension"
  prompt      PromptPart[]                # ordered
  surface     Surface | null             # null for teachCard
  expected    Answer  | null
  check       Check   | null             # structured (#9)
  feedback    { pass: line, <mistakeId>: line } | null   # 'pass' reserved (#1)
  policy      { reps?: int, noFail?: bool }               # (#2, #10)
  signedOff   bool

PromptPart  (discriminated by `kind`):
  { kind:"say",   line }
  { kind:"audio", audioId }
  { kind:"image", imageId, caption? }
  { kind:"text",  text, gaps?: Gap[], reveal?:"thenHide", loose?: bool }   # (#5)
  { kind:"rule",  label }
  { kind:"forms", char, forms: FormName[] }                                # (#6)

Gap        { kind:"letter"|"word", index }
Surface    { mode:"trace"|"write", unit:"glyph"|"word"|"sentence",
             guideForm?: FormName, demo?: bool, given?:{ word, blankIndex } }   # demo (#3)
Answer     one-of: { glyph:{char,form} } | { word:{text} } | { words:[text...] }
Check      { base:"glyph"|"sequence"|"order",
             modifiers: ("positionalForm"|"joinContinuity"|"transformRule")[] }   # (#9)
FormName   "isolated"|"initial"|"medial"|"final"
```

### LetterUnit — sequences sections + exercises (#8)
```
LetterUnit:
  letterId
  sections [ { id:"meet"|"watchTrace"|"forms"|"words"|"listenWrite"|"mastery",
               exercises:[ exerciseId... ] } ]
  # progression: section-by-section gated by policy.reps; ONE quiet star at unit mastery
```

### Global behaviors (not config)
- **Ghost-correction** (green correct path on a miss) — a system-wide FeedbackPanel behavior (#4).
- Mascot pose (`idle/think/write/cheer/try-again`) — derived from validator state, not authored.

---

## 3. Validators (reuse — COMPONENT-SYSTEM.md §6)
- **glyph** → existing geometric scorer vs `surface.guideForm` reference strokes *(built)*.
- **sequence** → per-letter glyph in order *(thin wrapper)*; modifier `joinContinuity`.
- **order** → word order *(thin wrapper)* + per-word sequence.
- **modifiers:** `positionalForm`, `joinContinuity`, `transformRule` (small rule checks).

≈ one core scorer + two wrappers + a few rule checks for the entire question system.

---

## 4. Firestore mapping (extends 06.1)
- `letters/{id}` — adds `forms` (nested; {x,y} point codec from 06.1), `vocab` refs.
- `words/{id}` — new collection.
- `exercises/{id}` — new collection.
- `units/{letterId}` — new (or embed `sections` on the letter).
- `meta/*` — toleranceRamp etc. (06.1).
All read **live + offline-cached + bundled-seed fallback** via the existing `CurriculumRepository`
seam (06.1 pattern). The Dart `Exercise`/`Letter` models deserialize these 1:1.

---

## 5. Locked vs waiting on the owner's mother
- **Shape: LOCKED** (everything above). Engineering can build against it now.
- **Content: OPEN — the 8 TBDs** (CHANGES.md §5): which types & how many per letter · `policy.reps`
  counts · vocab words · medial-form scope · grammar scope/answers · sentence bank · ة/ى scope ·
  review re-entry. These fill `EXERCISE-CONFIGS.json` values + flip `signedOff:true`. **No shape change.**

---

## 6. Next
1. Formalize this via `/gsd:spec-phase 7` (falsifiable SPEC.md) — optional; this doc is the contract.
2. **Rewrite Phases 7 & 8** to build it for real:
   - **Phase 7** — Schema v2 in Firestore (extends 06.1) + the 5 components + the 6-section Letter Unit, proven end-to-end on **baa** (all forms authored + signed off, vocab, audio, every exercise type).
   - **Phase 8** — author the full 28-letter curriculum + all question configs (grammar + sentence) into the engine, batched behind the mother's sign-off → full v1 content-complete.
3. The mother answers the 8 TBDs in parallel (they don't block the build of the engine, only the content).
