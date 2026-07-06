# taa Curriculum Graph - Owner-Mother Sign-Off Sheet

**Status:** DRAFT - awaiting owner-mother sign-off.
**Drafted:** 2026-07-06.
**Author:** Codex drafted this mapping from the signed `baa` graph pattern and the
national grade-1 curriculum. The owner-mother reviews and signs at the tier level.

**Asset:** `assets/curriculum/graphs/taa.json`
**Pedagogical sources:**
- `docs/curriculum/national-curriculum-grade1.md`
- `docs/curriculum/baa-curriculum-graph-signoff-sheet.md`
- Existing signed `taa.*` exercises in `assets/curriculum/exercises.json`

> **What this graph does.** It rails the AI tutor's exercise choices for `taa` only.
> It mirrors the signed `baa` graph structure over the 19 signed `taa` exercises:
> recognition first, positional forms next, then the copy/look-write/dictation writing
> ramp, followed by sentence fluency and enrichment. Cross-letter dot contrast stays
> deferred; this graph reinforces `taa`'s own form.

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
| 1 | `taa.teachCard.meet` | recognize | yes | - | 1 |
| 2 | `taa.traceLetter.isolated` | positionalForms | yes | - | 3 |
| 3 | `taa.traceLetter.initial` | positionalForms | yes | - | 3 |
| 4 | `taa.traceLetter.medial` | positionalForms | yes | - | 3 |
| 5 | `taa.writeLetter.fromSound` | positionalForms | yes | - | 3 |
| 6 | `taa.writeLetter.fromPicture` | positionalForms | yes | - | 3 |
| 7 | `taa.writeLetter.writeForm` | positionalForms | yes | - | 3 |
| 8 | `taa.connectWord.taaj` | copyWrite | yes | manqul | 3 |
| 9 | `taa.connectWord.bayt` | copyWrite | yes | manqul | 3 |
| 10 | `taa.completeWord.middle` | copyWrite | yes | manqul | 3 |
| 11 | `taa.writeWord.copy` | copyWrite | yes | manzur | 3 |
| 12 | `taa.writeWord.picture` | copyWrite | yes | manzur | 3 |
| 13 | `taa.writeWord.dictation` | copyWrite | yes | ghayrManzur | 3 |
| 14 | `taa.buildSentence.hear` | fluentReading | yes | ghayrManzur | 1 |
| 15 | `taa.buildSentence.picture` | fluentReading | yes | manzur | 1 |
| 16 | `taa.fillBlank.adjective` | wordBuilding | no | - | 1 |
| 17 | `taa.transformWord.dual` | grammarTransform | no | - | 1 |
| 18 | `taa.transformWord.plural` | grammarTransform | no | - | 1 |
| 19 | `taa.transformWord.opposite` | grammarTransform | no | - | 1 |

---

## Tier-Level Sign-Off Questions

### Q1 - Competency Mapping

Does each `taa` exercise sit under the right competency?

- `recognize`: 1 teach card.
- `positionalForms`: 3 trace exercises and 3 single-letter writing exercises.
- `copyWrite`: 2 connected-word exercises, 1 complete-word exercise, and 3 whole-word writing exercises.
- `fluentReading`: 2 sentence exercises.
- `wordBuilding`: 1 fill-blank enrichment exercise.
- `grammarTransform`: dual, plural, and opposite enrichment exercises.

**[ ] Confirmed as drafted   [ ] Adjust**

### Q2 - Essential / Enrichment Split

Should `recognize`, `positionalForms`, `copyWrite`, and `fluentReading` be the essential
core, while `wordBuilding` and `grammarTransform` remain enrichment that does not gate
the mastery star?

**[ ] Confirmed as drafted   [ ] Adjust**

### Q3 - Clean Reps

Should `taa` follow the signed `baa` clean-rep rule?

- Trace, single-letter writes, connected-word, complete-word, and whole-word writing: 3 clean reps.
- Teach card, sentence, fill-blank, and transforms: 1 clean rep.

**[ ] Confirmed as drafted   [ ] Adjust**

---

## Sign-Off

- [ ] Q1 competency mapping confirmed
- [ ] Q2 essential/enrichment split confirmed
- [ ] Q3 clean reps confirmed
- [ ] Reviewed by: Owner-mother (Arabic-teacher domain expert)  Date: __________

When signed, flip only `assets/curriculum/graphs/taa.json` `signedOff` to `true`.
