# baa Curriculum Graph — Owner-Mother Sign-Off Sheet (SIGNED)

**Status:** SIGNED — `signedOff: true` (owner-mother reviewed and signed at the tier level 2026-06-28; Plan 15-07 flipped the flag).
**Drafted:** 2026-06-27 (Phase 15, Plan 15-01).
**Signed:** 2026-06-28 (Phase 15, Plan 15-07) — Owner-mother (Arabic-teacher domain expert).
**Author:** Claude DRAFTED this mapping from the national grade-1 curriculum; the
owner-mother REVIEWS and signs (mirrors the `AUTHORED_BAA_IDS` sign-off gate). She
signs at the **tier level**, not per-row.

**Asset:** `assets/curriculum/curriculum_graph.json`
**Pedagogical source:** `docs/curriculum/national-curriculum-grade1.md`
(grade-1 competencies + the **منقول → منظور → غير منظور** إملاء difficulty ramp +
the §"What this means for Qalam" section-order prerequisite chain).

> **What this graph does.** It rails the AI tutor's exercise choices for **baa only**.
> The tutor moves **forward** along the competency chain, **picks freely among
> exercises within the tier the child has unlocked**, and **remediates backward down
> the إملاء tiers** (dictation → look-write → copy) when the child struggles. The one
> quiet mastery star fires only when **every essential competency** is cleared at the
> clean-reps below. This sheet reinforces **baa's own dot** only — it introduces **no
> ت/ث content** (cross-letter dot contrast is deferred).

---

## The competency chain (forward prerequisite order)

This is mom's section order, independently endorsed by the national curriculum as a
real prerequisite chain (national-curriculum-grade1.md §"What this means for Qalam").

| Competency | Essential? | Prerequisites | National-curriculum basis |
|---|---|---|---|
| `recognize` | ✅ essential | — | letter sound + name + shape (competency #1) |
| `positionalForms` | ✅ essential | recognize | the letter **in its positions** — isolated/initial/medial/final (#1) |
| `copyWrite` | ✅ essential | positionalForms | the **منقول → منظور → غير منظور** writing ramp (إملاء) |
| `fluentReading` | ✅ essential | copyWrite | fluent fully-vowelized reading/sentence work (#6) |
| `wordBuilding` | ⬜ enrichment | copyWrite | richer word/blank work (the 30% enrichment) |
| `grammarTransform` | ⬜ enrichment | copyWrite | dual/plural/opposite morphology (the 30% enrichment) |

The **70/30 essential-vs-enrichment** split (national curriculum's official تقسيم):
the **essential core** = `recognize → positionalForms → copyWrite → fluentReading`
(these gate the star); `wordBuilding` + `grammarTransform` are **enrichment**
(reachable, but they do **not** gate the star).

## The difficulty tiers (the إملاء ramp)

`manqul` (copy what's in front of you) → `manzur` (look, then write what you saw) →
`ghayrManzur` (write from memory / dictation). Easiest → hardest. The tutor never
presents a harder tier before its easier prerequisite for the same skill, and
remediates **`ghayrManzur → manzur → manqul`** within the same competency on a struggle.

---

## The full per-node mapping (one reviewable row per exercise)

`tier` is non-null **only** for the إملاء (copy/look-write/dictation) writing exercises;
recognition, trace, single-letter recall, and morphology exercises carry `tier: null`.

| # | exerciseId | competency | essential? | tier | draft minCleanReps |
|---|---|---|---|---|---|
| 1 | `baa.teachCard.meet` | recognize | ✅ | — | 1 |
| 2 | `baa.traceLetter.isolated` | positionalForms | ✅ | — | 3 |
| 3 | `baa.traceLetter.initial` | positionalForms | ✅ | — | 3 |
| 4 | `baa.traceLetter.medial` | positionalForms | ✅ | — | 3 |
| 5 | `baa.writeLetter.fromSound` | positionalForms | ✅ | — | 2 |
| 6 | `baa.writeLetter.fromPicture` | positionalForms | ✅ | — | 2 |
| 7 | `baa.writeLetter.writeForm` | positionalForms | ✅ | — | 2 |
| 8 | `baa.connectWord.baab` | copyWrite | ✅ | manqul | 2 |
| 9 | `baa.connectWord.kitaab` | copyWrite | ✅ | manqul | 2 |
| 10 | `baa.completeWord.middle` | copyWrite | ✅ | manqul | 2 |
| 11 | `baa.writeWord.copy` | copyWrite | ✅ | manzur | 2 |
| 12 | `baa.writeWord.picture` | copyWrite | ✅ | manzur | 2 |
| 13 | `baa.writeWord.dictation` | copyWrite | ✅ | ghayrManzur | 2 |
| 14 | `baa.buildSentence.hear` | fluentReading | ✅ | ghayrManzur | 1 |
| 15 | `baa.buildSentence.picture` | fluentReading | ✅ | manzur | 1 |
| 16 | `baa.fillBlank.adjective` | wordBuilding | ⬜ | — | 1 |
| 17 | `baa.transformWord.dual` | grammarTransform | ⬜ | — | 1 |
| 18 | `baa.transformWord.plural` | grammarTransform | ⬜ | — | 1 |
| 19 | `baa.transformWord.opposite` | grammarTransform | ⬜ | — | 1 |

*(All 19 rows correspond exactly to the signed baa.* exercise ids in
`server/app/curriculum_data/baa_authored_ids.json`. No new exercises were invented;
the graph only adds the competency / tier / prerequisite / clean-reps **metadata**.)*

---

## The three tier-level sign-off questions (for owner-mother)

Please confirm at the **tier level** (not row-by-row). These are the three items the
national-curriculum extract (§"Open for owner-mother sign-off") leaves to your domain.

### Q1 — Competency mapping

Does each baa exercise sit under the right competency?

- `recognize` = meeting the letter (sound/name/shape) — **1 exercise** (the teach card).
- `positionalForms` = the four shapes, traced then written from recall — **6 exercises**
  (3 traces + 3 single-letter writes).
- `copyWrite` = the إملاء word-writing ramp (copy → look-write → dictation) — **6 exercises**.
- `fluentReading` = whole-sentence work — **2 exercises**.
- `wordBuilding` (enrichment) = fill-the-blank — **1 exercise**.
- `grammarTransform` (enrichment) = dual / plural / opposite — **3 exercises**.

**☐ Confirmed as drafted   ☐ Adjust (note changes below)**

### Q2 — The 70/30 essential / enrichment split

Should `wordBuilding` (fill-blank) and `grammarTransform` (dual/plural/opposite) be
**enrichment** — i.e. reachable practice that does **not** gate the mastery star — while
`recognize / positionalForms / copyWrite / fluentReading` form the **essential core**
that **does** gate the star?

**☐ Confirmed as drafted   ☐ Adjust (note changes below)**

### Q3 — The per-skill clean-reps

How many **clean repetitions** should each skill require before it counts as cleared?
Draft values (yours to set):

- Trace exercises (`traceLetter.*`): **3** clean reps each.
- Single-letter writes (`writeLetter.*`) and word-writing (`connectWord/completeWord/writeWord`): **2** each.
- Teach card, sentence, fill-blank, and transforms: **1** each.

**☐ Confirmed as drafted   ☑ Adjust (note changes below)**

> **Owner-mother adjustment (2026-06-28):** "Writing & tracing = 3 clean reps;
> lighter exercises stay at 1." Applied: **all single-letter writes
> (`writeLetter.fromSound/.fromPicture/.writeForm`) and all word-writing
> (`connectWord.baab/.kitaab`, `completeWord.middle`, `writeWord.copy/.picture/.dictation`)
> moved from draft 2 → 3** clean reps (nine nodes), joining the trace exercises already
> at 3. Grammar/enrichment and the lighter exercises (teach card, sentences, fill-blank,
> transforms) are **unchanged at 1**. No change to competency mapping, the 70/30
> essential/enrichment split, prerequisites, or difficulty tiers.

---

## Sign-off

- [x] Q1 competency mapping confirmed — **approved as drafted**
- [x] Q2 70/30 essential/enrichment split confirmed — **approved as drafted**
      (grammar/`grammarTransform` + fill-blank/`wordBuilding` remain enrichment —
      mandatory grade-1 content presented to the child, but with a simple bar:
      `essential: false`, `minCleanReps: 1`. They do NOT gate the mastery star.)
- [x] Q3 per-skill clean-reps confirmed — **adjusted** (writing & tracing → 3 clean reps;
      lighter exercises stay at 1; see the Q3 adjustment note above)
- [x] Reviewed by: **Owner-mother (Arabic-teacher domain expert)**  Date: **2026-06-28**

> All three confirmed (Q1/Q2 approved as drafted, Q3 adjusted), so Plan 15-07 flipped
> `signedOff: true` in `assets/curriculum/curriculum_graph.json` behind the human-verify
> checkpoint, re-derived the server copy via `generate.py`, and recorded the human-UAT
> entry. The graph is now the signed demo path.
