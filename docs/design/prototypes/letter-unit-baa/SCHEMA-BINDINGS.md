# SCHEMA-BINDINGS.md — design → schema map

For every **interactive / data-bearing element** in the prototype, the `Exercise` field that drives
it. Schema shape: `COMPONENT-SYSTEM.md §3`. Concrete values: `EXERCISE-CONFIGS.json`.

Goal: an engineer can lock the schema knowing every pixel traces to a field — and can see the
**fields the spec is missing** to express what was designed (flagged ⚠ throughout, summarized at end).

---

## A. Bindings by element (applies to every screen)

| On-screen element | Component | Driven by config field |
|---|---|---|
| Eyebrow label ("Q3 · writeWord") | ExerciseScaffold | `id` / `type` ⚠ (type is design-added) |
| Mascot speech line | PromptHeader `say` | `prompt[kind=say].line` |
| Mascot pose (idle/think/write/cheer/try-again) | ExerciseScaffold | derived from validator state, not authored |
| Play button (letter / word / sentence) | PromptHeader `audio` | `prompt[kind=audio].audioId` |
| Picture stub + caption | PromptHeader `image` | `prompt[kind=image].imageId`, `.caption` |
| Arabic prompt text | PromptHeader `text` | `prompt[kind=text].text` |
| Missing-word box `▢` | PromptHeader `text` | `prompt[kind=text].gaps[kind=word]` |
| Missing-letter slot `◌` | PromptHeader `text` | `prompt[kind=text].gaps[kind=letter].index` |
| "Shown then hidden" word (copy/نسخ) | PromptHeader `text` | `prompt[kind=text].reveal:"thenHide"` ⚠ |
| Loose letters (connect) | PromptHeader `text` | `prompt[kind=text].loose:true` ⚠ |
| Rule chip («مثنى/جمع/عكس») | PromptHeader `rule` | `prompt[kind=rule].label` |
| Trace vs blank-line canvas | WriteSurface | `surface.mode` (`trace`\|`write`) |
| Canvas width / glyph size | WriteSurface | `surface.unit` (`glyph`\|`word`\|`sentence`) |
| Dotted guide form shown | WriteSurface | `surface.guideForm` |
| Animated "Watch me" demo | WriteSurface | `surface.demo` ⚠ (not in spec's surface) |
| Pre-filled letters + blank cell | WriteSurface | `surface.given.word`, `.blankIndex` |
| Green ghost-correction overlay | WriteSurface | `surface.ghost` ⚠ (not in spec) |
| Clean-rep pips | WriteSurface | `surface.reps` ⚠ (not in spec) — **the rep-count TBD lives here** |
| What "correct" means | (validator) | `expected` + `check` |
| Pass star + praise line | FeedbackPanel | `feedback.pass` ⚠ (see gap #2) |
| Coral fix line | FeedbackPanel | `feedback[<mistakeId>]` |
| Progress dots | ProgressRibbon | unit/section position (not in `Exercise`; lives on the Unit) ⚠ |
| Four-forms strip (teachCard) | customSurface | `prompt[kind=forms]` ⚠ (not in spec) |

---

## B. Bindings by screen (what's live on each)

**traceLetter** (×3 forms) — `say`(+`rule`/`audio`) → `surface.mode=trace, unit=glyph, guideForm=*` → `expected.glyph{char,form}` → `check=glyph(+positionalForm)`.
**writeLetter** — `say` + (`audio`|`image`|`rule`) → `surface.write·glyph` → `expected.glyph` → `check=glyph(+positionalForm)`. *Modality = which prompt part; surface identical.*
**writeWord** — `say` + (`audio`|`text.reveal`|`image`) → `surface.write·word` → `expected.word{text}` → `check=sequence`.
**connectWord** — `say` + `text.loose` → `surface.write·word` → `expected.word` → `check=sequence+joinContinuity`.
**completeWord** — `say` + `text.gaps[letter]` → `surface.write·glyph, given{word,blankIndex}` → `expected.glyph` → `check=glyph`.
**transformWord** — `say` + `text`(base) + `rule` → `surface.write·word` → `expected.word` → `check=sequence+transformRule`.
**fillBlank** — `say` + `text.gaps[word]` → `surface.write·word` → `expected.word` → `check=sequence`.
**buildSentence** — `say` + (`audio`|`image`) → `surface.write·sentence` → `expected.words[]` → `check=order(+sequence)`.
**teachCard** *(support)* — `say` + `audio` + `image` + `forms` → **no surface / expected / check / feedback**.
**letterMaze** *(support)* — `say` → `surface.trace·glyph` → relaxed validator, **no-fail** (`check=glyph·relaxed`) ⚠.

---

## C. Fields the spec is MISSING to express the design ⚠

These are real gaps — the prototype needed them and the `Exercise` shape in COMPONENT-SYSTEM.md §3
does not currently express them. **Locking the schema means deciding each:**

1. **`feedback.pass` / praise line.** Spec models `feedback` as `{<mistakeId>: line}` (fix lines only).
   The pass/praise line had no home. We reserved key `pass`. → *Add a `praise` field, or bless `pass`.*
2. **`surface.reps` (clean-rep count).** The "how many clean reps to pass" rule is per-exercise and is
   an owner's-mother TBD. No field exists. → *Add `surface.reps` (or `policy.reps`).*
3. **`surface.demo` / `surface.guide.animated`.** The Watch-me animated stroke is a real surface state.
   Spec mentions "optionally animated (the Watch step)" in prose but has no field. → *Add `surface.demo`.*
4. **`surface.ghost` (ghost-correction).** Showing the correct path in green on a miss. → *Add, or make
   it a global FeedbackPanel policy rather than per-exercise.*
5. **`text` sub-modifiers `reveal:"thenHide"` and `loose:true`.** Copy (نسخ) and connect both reuse the
   `text` part but need behavior flags. Spec's `text` only has `text, gaps?`. → *Extend the `text` PromptPart.*
6. **`prompt.kind:"forms"`.** The teachCard four-forms strip. → *Add `forms` as a PromptPart kind, or
   compose from `image`+`text`.*
7. **`type` (question-type label).** Emergent in the spec ("a type is just a set of values"), but every
   downstream tool (authoring UI, analytics, the gallery) wanted a stable label. → *Add an optional `type`
   tag, or a `templateId` the author picks.*
8. **Progress / section position.** `ProgressRibbon` is driven by the Unit's section index, which is
   **not** part of `Exercise`. → *Confirm this lives on a `Unit`/`Lesson` object that sequences Exercises.*
9. **`check` as string vs structured.** We encode modifiers as `"sequence+joinContinuity"`. A structured
   `{base, modifiers[]}` is cleaner for the validator. → *Decide string-grammar vs object.*
10. **`relaxed`/`noFail` policy** (letterMaze). Enrichment runs the scorer but never fails. → *Add a
    `policy.noFail` or `gradePolicy:"relaxed"`.*

None of these break the architecture — they're additive fields on `surface`, `feedback`, `prompt`, and
a thin `Unit` wrapper. Decide them and the schema locks.
