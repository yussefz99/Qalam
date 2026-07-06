# thaa Curriculum Graph - Owner-Mother Sign-Off Sheet

**Status:** DRAFT - awaiting owner-mother sign-off.
**Drafted:** 2026-07-06.
**Author:** Codex converted the ready draft from `docs/curriculum/drafts/thaa-jeem-haa-DRAFT.md`
into unsigned curriculum content, then mapped it to the signed `baa` graph pattern.

**Assets:**
- `assets/curriculum/exercises.json`
- `assets/curriculum/words.json`
- `assets/curriculum/graphs/thaa.json`

**Pedagogical sources:**
- `docs/curriculum/national-curriculum-grade1.md`
- `docs/curriculum/baa-curriculum-graph-signoff-sheet.md`
- `docs/curriculum/drafts/thaa-jeem-haa-DRAFT.md`

> **What this graph does.** It rails the AI tutor's exercise choices for `thaa` only.
> It mirrors the signed `baa` graph structure over the 19 draft `thaa` exercises.
> Cross-letter dot contrast stays deferred; this set reinforces `thaa`'s own boat shape
> with three dots above.

---

## The Competency Chain

This is the same prerequisite chain signed for `baa`.

| Competency | Essential? | Prerequisites | Basis |
|---|---|---|---|
| `recognize` | yes | - | letter sound, name, and shape |
| `positionalForms` | yes | recognize | isolated, initial, medial, final forms |
| `copyWrite` | yes | positionalForms | copied, seen-then-written, and dictated writing |
| `fluentReading` | yes | copyWrite | whole-sentence work |
| `wordBuilding` | no | copyWrite | enrichment vocabulary / blank work |
| `grammarTransform` | no | copyWrite | enrichment dual, plural, and opposite work |

The essential core is `recognize -> positionalForms -> copyWrite -> fluentReading`.
`wordBuilding` and `grammarTransform` remain enrichment and do not gate the mastery star.

## The Difficulty Tiers

`manqul` (copy what's in front of you) -> `manzur` (look, then write what you saw)
-> `ghayrManzur` (write from memory / dictation).

The tutor should not present a harder tier before the easier prerequisite for the same
skill, and should remediate backward within the same competency when the child struggles.

---

## Full Per-Node Mapping

`tier` is non-null only for the writing-ramp exercises. The clean-rep pattern follows
the owner-mother's signed `baa` adjustment: writing and tracing require 3 clean reps;
lighter exercises require 1.

| # | exerciseId | competency | essential? | tier | minCleanReps |
|---|---|---|---|---|---|
| 1 | `thaa.teachCard.meet` | recognize | yes | - | 1 |
| 2 | `thaa.traceLetter.isolated` | positionalForms | yes | - | 3 |
| 3 | `thaa.traceLetter.initial` | positionalForms | yes | - | 3 |
| 4 | `thaa.traceLetter.medial` | positionalForms | yes | - | 3 |
| 5 | `thaa.writeLetter.fromSound` | positionalForms | yes | - | 3 |
| 6 | `thaa.writeLetter.fromPicture` | positionalForms | yes | - | 3 |
| 7 | `thaa.writeLetter.writeForm` | positionalForms | yes | - | 3 |
| 8 | `thaa.connectWord.thalab` | copyWrite | yes | manqul | 3 |
| 9 | `thaa.connectWord.thawm` | copyWrite | yes | manqul | 3 |
| 10 | `thaa.completeWord.middle` | copyWrite | yes | manqul | 3 |
| 11 | `thaa.writeWord.copy` | copyWrite | yes | manzur | 3 |
| 12 | `thaa.writeWord.picture` | copyWrite | yes | manzur | 3 |
| 13 | `thaa.writeWord.dictation` | copyWrite | yes | ghayrManzur | 3 |
| 14 | `thaa.buildSentence.hear` | fluentReading | yes | ghayrManzur | 1 |
| 15 | `thaa.buildSentence.picture` | fluentReading | yes | manzur | 1 |
| 16 | `thaa.fillBlank.noun` | wordBuilding | no | - | 1 |
| 17 | `thaa.transformWord.dual` | grammarTransform | no | - | 1 |
| 18 | `thaa.transformWord.plural` | grammarTransform | no | - | 1 |
| 19 | `thaa.transformWord.opposite` | grammarTransform | no | - | 1 |

---

## Sign-Off Questions

### Q1 - Vocabulary and Words

The draft uses worksheet-backed words: fox, snow, snake, garlic, and triangle. Should
all five stay for a 5-10 year old, or should any be swapped?

**[ ] Confirmed as drafted   [ ] Adjust**

### Q2 - Exercise Text and Tutor Voice

Do the feedback lines sound like the tutor's voice: warm, calm, and specific? In
particular, confirm the repeated prompt to put three dots above the boat.

**[ ] Confirmed as drafted   [ ] Adjust**

### Q3 - Grammar / Enrichment Items

Please confirm the draft enrichment items:

- dual: `ثعلب` -> `ثعلبان`
- plural: `ثعلب` -> `ثعالب`
- opposite: `ثقيل` -> `خفيف`

**[ ] Confirmed as drafted   [ ] Adjust**

### Q4 - Graph Mapping and Clean Reps

Should `thaa` use the signed `baa` graph mapping, essential/enrichment split, and clean
reps: tracing and writing = 3; lighter sentence/fill/transform items = 1?

**[ ] Confirmed as drafted   [ ] Adjust**

---

## Sign-Off

- [ ] Q1 vocabulary confirmed
- [ ] Q2 tutor voice confirmed
- [ ] Q3 grammar/enrichment confirmed
- [ ] Q4 graph mapping and clean reps confirmed
- [ ] Reviewed by: Owner-mother (Arabic-teacher domain expert)  Date: __________

When signed, flip only the reviewed `thaa` `signedOff` fields to `true`.
