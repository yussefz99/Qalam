# Qalam — Exercise Component System (the reusable engine)

**Date:** 2026-06-14
**Status:** Architecture proposal → feeds the Claude Design prototype + Curriculum Schema v2
**Premise (owner's insight):** the *frontend* of almost every question is the same — the child
**writes ink on a surface**. What differs is the *backend* — the prompt, the expected answer, and
how it's checked. So we build a small set of reusable **components** and express every question
type as **data (config)**, not a new screen.

> **Goal:** one component system that can render *any* question we can think of for this level
> (grade-1 Arabic literacy, handwriting-first), where a "new question type" = a new config row,
> never new UI.

---

## 1. The principle — compose, don't multiply

Every question decomposes into four orthogonal parts:

| Part | Question | Owned by |
|---|---|---|
| **Prompt** | how the child is *cued* (hear / see / read / rule) | `PromptHeader` (composable parts) |
| **Response** | what the child *writes* (glyph / word / sentence) | `WriteSurface` (mode + unit) |
| **Check** | how it's *validated* | backend validator |
| **Feedback** | pass or specific fix | `FeedbackPanel` (shared) |

Because these are independent, **any question = a combination.** That's what lets the system
express questions we haven't thought of yet.

---

## 2. Frontend — 5 reusable components (the whole UI)

### `ExerciseScaffold`
The page: RTL, landscape. Slots = `PromptHeader` (top) · `WriteSurface` (center) · `FeedbackPanel`/CTA (bottom) · `ProgressRibbon` (edge) · the reed-pen **mascot** as presenter/reactor. Hosts *every* exercise — and every unit section.

### `PromptHeader` — renders an ordered list of **PromptParts** (this is the magic)
Any subset, in any order:
- **`audio`** — a play button (hear a letter / word / sentence / instruction). `{ audioId }`
- **`image`** — a picture. `{ imageId, caption? }`
- **`text`** — Arabic text, with optional **gap** tokens: a `__blank__` (missing word) or a missing-letter slot inside a word. `{ text, gaps? }`
- **`rule`** — a labeled instruction chip, e.g. «اكتب الجمع» / «العكس». `{ label }`
- **`say`** — the mascot's spoken instruction line (always present). `{ line }`

Compose these and you can cue the child *any* way: hear-a-word, see-a-picture, read-a-sentence-with-a-blank, "write the plural of…", etc.

### `WriteSurface` — the one canvas (reuses the existing ink/trace component)
Props:
- **`mode`**: `trace` (faint dotted guide overlay) | `write` (blank ruled line)
- **`unit`**: `glyph` | `word` | `sentence` (sets width / cell count)
- **`given?`**: pre-filled ink the child does *not* write — e.g. the surrounding letters in *complete-the-word*, or starter letters in *connect*
- **`guide?`**: reference for `trace` mode — which letter **form** (isolated/initial/medial/final), optionally animated (the Watch step)

Emits raw strokes → handed to the backend validator. **This single component covers trace, write-a-letter, write-a-word, and write-a-sentence.**

### `FeedbackPanel` — two states, shared by all types
- **`pass`** → praise line (tutor voice) + **one quiet star**
- **`fix`** → coral-highlight the failing element (stroke / glyph / word) + the **specific** authored fix line
Driven entirely by the validator result. Never "oops, try again".

### `ProgressRibbon`
R→L position dots. Position, **not score**. No numbers, no gamification.

*(Reused as-is: the mascot avatar with states `idle/think/write/cheer/try-again`, and the design tokens.)*

---

## 3. Backend — one config shape expresses any question

```
Exercise:
  id
  skill:    "formation" | "recall" | "spelling" | "grammar" | "syntax" | "comprehension"
  prompt:   PromptPart[]                       # audio | image | text(gaps) | rule | say
  surface:  { mode: "trace"|"write", unit: "glyph"|"word"|"sentence", given?, guideForm? }
  expected: Answer                             # glyph{char,form} | word{text} | words[]
  check:    "glyph" | "sequence" | "order"     # + modifiers: positionalForm, joinContinuity, transformRule
  feedback: { <mistakeId>: "<authored line>" } # owner's-mother authored
  signedOff: bool
```

A question type is **just a set of values here**. The frontend reads `prompt`/`surface`; the
backend reads `expected`/`check`. Same components, different data.

---

## 4. Proof — every known type is one config (no new UI)

| Type | prompt | surface | expected | check |
|---|---|---|---|---|
| **traceLetter** | say (+guide) | trace · glyph · guideForm | glyph(form) | glyph |
| **writeLetter** (from sound) | say + audio | write · glyph | glyph(form) | glyph (+positionalForm) |
| **writeLetter** (from picture) | say + image | write · glyph | glyph | glyph |
| **writeWord** (dictation/إملاء) | say + audio | write · word | word | sequence |
| **writeWord** (picture) | say + image | write · word | word | sequence |
| **writeWord** (copy/نسخ) | say + text(shown→hidden) | write · word | word | sequence |
| **completeWord** | say + text(missing-letter) | write · glyph · *given=rest* | glyph | glyph |
| **connectWord** (ربط) | say + text(loose letters) | write · word | word | sequence + joinContinuity |
| **transformWord** (مثنى/جمع/عكس) | say + text(base) + rule | write · word | word | sequence + transformRule |
| **fillBlank** | say + text(sentence with `__blank__`) | write · word | word | sequence |
| **buildSentence** | say + image/meaning | write · sentence | words[] | order (+sequence/word) |
| **comprehension** | say + audio/text(question) | write · word | word | sequence |

Twelve "types" → **2 canvases (trace/write) + a handful of validators**, all data-driven.

---

## 5. New questions are FREE

Anything we invent later for this level is a new **config row**, not new code, as long as it
decomposes into prompt + write + check. Examples that need *zero* new components:
- "Write the word that *rhymes* with what you hear" (وعي صوتي/سجع) → audio prompt + write·word + sequence.
- "Write the *first* and *last* letter of the word you hear" → audio + write·glyph ×2.
- "Write the missing letter in the *middle*" → text(missing-letter) + write·glyph + given.

**If a future question can't be expressed as prompt + write + check, that's the signal we need a
new component — and only then do we add one.**

---

## 6. Validators — reuse the one scorer

- **`glyph`** → the existing geometric stroke scorer, against the `guideForm` reference strokes (per contextual form). *(already built)*
- **`sequence`** → run the glyph scorer per letter in order; `+joinContinuity` checks the letters connect. *(thin wrapper)*
- **`order`** → compare the written words against the expected order. *(thin wrapper)*
- **modifiers** (`positionalForm`, `transformRule`) → small rule checks layered on top.

≈ **one core scorer + two thin wrappers + a few rule checks** for the entire question system.

---

## 7. Authoring model (the owner's mother)

She never needs an engineer to add a "new kind of question." To create one she fills:
**prompt parts** (pick audio/image/text/rule) · **expected** answer · **feedback** lines per mistake.
Variety lives in **content + prompt composition**, not in screen count.

---

## 8. It also composes the unit sections (bonus)

The six Letter-Unit sections are the same system:
- **Meet** = `PromptHeader` only (say + image + audio + forms), no `WriteSurface`.
- **Watch & trace** = `WriteSurface` in `trace` mode with an animated `guide`.
- **Words / Listen & write** = sequences of the exercises above.
- **Mastery** = the shared celebration (`FeedbackPanel` pass at unit scope) + one star.

So the *whole* learning experience is `ExerciseScaffold` + 5 components + config.

---

## 9. What this buys us

- **Build once:** ~5 widgets + 1 scorer + 2 wrappers → the entire question system.
- **Author forever:** every new question is data your mother composes.
- **Schema v2 falls out of this** directly (the `Exercise` shape above).
- **The design product** builds *components*, not 12 screens — and a thin gallery that swaps configs.
