# CHANGES.md — deviations & open questions

What changed versus the **Stage-B brief**, the **CONCEPT-BRIEF**, and **COMPONENT-SYSTEM.md** — the
owner's edits, the deviations we made (and why), and the open pedagogy TBDs. Nothing here is papered
over; the gaps are the point.

---

## 1. Owner's edits (decisions taken during design)

| Decision | Effect |
|---|---|
| **Keep the baseline as the spine; explore directions, then graft the best idea back.** | Three concept directions were built (Manuscript / Qalam-is-the-Pen / Shape-Shifter). The **morph** from Shape-Shifter was grafted into the baseline's "Meet the letter" section. The other directions live in the design project as exploration, not in this handoff. |
| **Leave the mascot / tutor panel & celebration exactly as built.** | Reserved for a future **interactive (AI) tutor** in that space. We did not restyle it. |
| **Skip the wax-seal mastery treatment.** | Mastery stays the existing **single quiet star**. |
| **Refine the exercise taxonomy** (was "8 types"). | Collapsed to **6 question types + 2 support screens** (below). |

## 2. Taxonomy correction (vs an earlier "8 exercise types" pass)
The earlier cut split the *same response prompted differently* into separate "types" and had **no home
for grammar or sentences**. Corrected to match COMPONENT-SYSTEM.md's principle (**prompt modality is a
parameter, not a type**):

- **Merged** `writeFromSound` + `writeFromPicture` → **`writeLetter`** (variants: hear / picture / write-the-form).
- **Folded** `dictateWord` → **`writeWord`** (variants: hear=إملاء / copy=نسخ / picture).
- **Split** `produceForm`: its positional-form job folded into `traceLetter`/`writeLetter` (form is a
  `surface.guideForm` parameter); its grammar job became the new **`transformWord`**.
- **Kept** `connectWord`; **added** `completeWord` (via `surface.given`).
- **Added** `transformWord` (مثنى/جمع/عكس) and **`buildSentence`** (+`fillBlank`) — the missing grammar/syntax.
- **`teachCard` + `letterMaze`** kept, now explicitly **support screens**, not assessed questions.

Result: 6 question types + 2 support, all one engine. Matches the §4 proof table in COMPONENT-SYSTEM.md.

## 3. Deviations from COMPONENT-SYSTEM.md (with reasons)
All additive; none break the architecture. Full list with fixes in **SCHEMA-BINDINGS.md §C**. Summary:

1. **`feedback` shape** — spec is `{<mistakeId>: line}` (fixes only). We reserved key **`pass`** for the
   praise line, which had no home. *Reconcile: add `praise` or bless `pass`.*
2. **`surface.reps`, `surface.demo`, `surface.ghost`** — clean-rep count, Watch-me animation, and
   green ghost-correction are real surface states with no spec field. *Reconcile: add to `surface`.*
3. **`text` flags `reveal:"thenHide"` (copy) and `loose:true` (connect)** — the `text` PromptPart needed
   behavior modifiers. *Reconcile: extend `text`.*
4. **`prompt.kind:"forms"`** — the teachCard four-forms strip isn't a spec PromptPart. *Reconcile: add
   `forms`, or compose from `image`+`text`.*
5. **`type` label** — added as a convenience; the spec treats type as emergent. *Reconcile: optional tag.*
6. **Local token re-declaration & two name drifts** (`--gold`→`--gold-ink`, `--white`→`--surface-raised`).
   *Reconcile per TOKENS.md.*

## 4. Honored constraints (called out because they're easy to break)
- **Handwriting-first, always.** Every graded screen has the child **write**, never tap a choice. The
  only buttons are Play / Clear / Mark / Next. No multiple-choice anywhere.
- **One quiet star. No gamification.** No points, streaks, timers, or running tallies. (Note: some
  *existing* built screens show a "42 stars +3 today" tally — that contradicts the brief's anti-gamification
  rule, so the new surfaces deliberately **omit** it. Flag for the team to reconcile in the existing screens.)
- **RTL, landscape tablet; Arabic always larger than English; never harsh red.**
- **Reused** the existing trace canvas, stroke animation, mascot, and celebration — not reinvented.

---

## 5. Open pedagogy TBDs — the owner's-mother's calls
Surfaced in-product as quiet **"TBD"** chips on the relevant screen. **No answers collected yet — all
open.** These **block locking the schema's content**, not its shape.

| # | Question | Where surfaced | Status |
|---|---|---|---|
| 1 | Which question types — and how many — per letter? | every screen (global chip) | **OPEN** |
| 2 | Clean-rep count required to pass (per type)? | trace / write-word | **OPEN** → `surface.reps` |
| 3 | Vocabulary words & which get illustrations? | writeLetter / writeWord | **OPEN** |
| 4 | Medial-form scope — teach for every connector, or only where it differs? | traceLetter / writeLetter | **OPEN** |
| 5 | Grammar scope & the answer-word set (dual/plural/opposite)? | transformWord | **OPEN** |
| 6 | Sentence bank & difficulty per level? | buildSentence / fillBlank | **OPEN** |
| 7 | Scope of ة / ى and which letters have which forms? | teachCard | **OPEN** |
| 8 | How does a mastered letter resurface for review? | letterMaze | **OPEN** |

When the mother answers these, the values drop straight into `EXERCISE-CONFIGS.json` and `signedOff`
flips true per exercise — the components don't change.
