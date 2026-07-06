# haa_c Curriculum Graph - Owner-Mother Sign-Off Sheet

**Status:** DRAFT - awaiting owner-mother sign-off.
**Drafted:** 2026-07-06.
**Author:** Codex converted the ready draft from `docs/curriculum/drafts/thaa-jeem-haa-DRAFT.md`
into unsigned curriculum content, then mapped it to the signed `baa` graph pattern.

**Assets:**
- `assets/curriculum/exercises.json`
- `assets/curriculum/words.json`
- `assets/curriculum/graphs/haa_c.json`

**Pedagogical sources:**
- `docs/curriculum/national-curriculum-grade1.md`
- `docs/curriculum/baa-curriculum-graph-signoff-sheet.md`
- `docs/curriculum/drafts/thaa-jeem-haa-DRAFT.md`

> **What this graph does.** It rails the AI tutor's exercise choices for `haa_c` only.
> It mirrors the signed `baa` graph structure over the 19 draft `haa_c` exercises.
> Cross-letter contrast stays deferred; this set reinforces `haa_c`'s own round belly
> with no dot.

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
| 1 | `haa_c.teachCard.meet` | recognize | yes | - | 1 |
| 2 | `haa_c.traceLetter.isolated` | positionalForms | yes | - | 3 |
| 3 | `haa_c.traceLetter.initial` | positionalForms | yes | - | 3 |
| 4 | `haa_c.traceLetter.medial` | positionalForms | yes | - | 3 |
| 5 | `haa_c.writeLetter.fromSound` | positionalForms | yes | - | 3 |
| 6 | `haa_c.writeLetter.fromPicture` | positionalForms | yes | - | 3 |
| 7 | `haa_c.writeLetter.writeForm` | positionalForms | yes | - | 3 |
| 8 | `haa_c.connectWord.hisaan` | copyWrite | yes | manqul | 3 |
| 9 | `haa_c.connectWord.hoot` | copyWrite | yes | manqul | 3 |
| 10 | `haa_c.completeWord.final` | copyWrite | yes | manqul | 3 |
| 11 | `haa_c.writeWord.copy` | copyWrite | yes | manzur | 3 |
| 12 | `haa_c.writeWord.picture` | copyWrite | yes | manzur | 3 |
| 13 | `haa_c.writeWord.dictation` | copyWrite | yes | ghayrManzur | 3 |
| 14 | `haa_c.buildSentence.hear` | fluentReading | yes | ghayrManzur | 1 |
| 15 | `haa_c.buildSentence.picture` | fluentReading | yes | manzur | 1 |
| 16 | `haa_c.fillBlank.noun` | wordBuilding | no | - | 1 |
| 17 | `haa_c.transformWord.dual` | grammarTransform | no | - | 1 |
| 18 | `haa_c.transformWord.plural` | grammarTransform | no | - | 1 |
| 19 | `haa_c.transformWord.opposite` | grammarTransform | no | - | 1 |

---

## Sign-Off Questions

### Q1 - Vocabulary and Words

The draft uses horse, whale, key, apple, and reused milk. Please confirm whether these
are the right early words for `haa_c`.

**[ ] Confirmed as drafted   [ ] Adjust**

### Q2 - Exercise Text and Tutor Voice

Do the feedback lines sound like the tutor's voice: warm, calm, and specific? In
particular, confirm the "no dot" guidance and whether it should name the contrast with
`jeem`.

**[ ] Confirmed as drafted   [ ] Adjust**

### Q3 - Grammar / Enrichment Items

Please confirm the draft enrichment items:

- dual: `حصان` -> `حصانان`
- plural: `حوت` -> `حيتان`
- opposite: `حلو` -> `مر`

**[ ] Confirmed as drafted   [ ] Adjust**

### Q4 - Graph Mapping and Clean Reps

Should `haa_c` use the signed `baa` graph mapping, essential/enrichment split, and clean
reps: tracing and writing = 3; lighter sentence/fill/transform items = 1?

**[ ] Confirmed as drafted   [ ] Adjust**

---

## Sign-Off

- [ ] Q1 vocabulary confirmed
- [ ] Q2 tutor voice confirmed
- [ ] Q3 grammar/enrichment confirmed
- [ ] Q4 graph mapping and clean reps confirmed
- [ ] Reviewed by: Owner-mother (Arabic-teacher domain expert)  Date: __________

When signed, flip only the reviewed `haa_c` `signedOff` fields to `true`.
