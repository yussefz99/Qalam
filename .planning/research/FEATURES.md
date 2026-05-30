# Feature Research

**Domain:** Children's handwriting / early-literacy tablet app — Arabic for heritage learners (ages 5–10), Flutter/Android, RTL, on-device ML Kit Digital Ink scoring, anti-gamification. Scope anchored to Qalam **Sprint 1 = v1** (S1-01..S1-11). NO AI tutor in v1.
**Researched:** 2026-05-30
**Confidence:** MEDIUM — Competitor and tracing-UX conventions are well-attested (multiple app stores, review sites). Arabic stroke-order pedagogy findings are the *conventional baseline only*; **the owner's mother's spec is authoritative and overrides anything here**. ML Kit on-device feedback specifics are MEDIUM (R1 validated by owner; exact stroke-data API surface should be confirmed in implementation).

---

## Feature Landscape

### Table Stakes (Users Expect These)

Missing these = it doesn't feel like a real handwriting tutor. Every credible tracing app (iTrace, Writing Wizard, LetraKid, Write It! Arabic) ships all of these.

| Feature | Story | Why Expected | Complexity | Notes |
|---------|-------|--------------|------------|-------|
| Dotted/ghost guide letter behind the writing surface | S1-05 | Universal in every tracing app; a child can't trace blind. Often with a directional arrow showing entry point and direction. | LOW–MED | Ties to R3 (RTL/connected-script rendering): the guide glyph must render the *correct positional form* and sit behind the child's ink. |
| Stroke-order animation before writing | S1-04 | iTrace's "hand holding a pencil" and Writing Wizard both demo the stroke before the child writes. The single most-cited "teaches it right" feature. | MED | Animate the reference path stroke-by-stroke at child pace; replayable. Path data comes from the curriculum schema (owner's mother's stroke order). |
| Instant on-device feedback on the *actual strokes* | S1-05 | The line between a real handwriting tutor and a coloring app. Apps that only check final shape feel hollow; the ones reviewers praise ("Write It! Arabic evaluates the tracing *path*, not just shape") check the stroke. | HIGH | The core v1 deliverable. See "On-device deterministic feedback" below for what good looks like without an AI tutor. ML Kit Digital Ink + geometric path comparison. |
| Error highlighting / show where it went wrong | S1-05 | iTrace reports "too shaky," "out of bounds," "overextended" and erases a bad stroke back to the last good point. Children need to *see* the deviation, not just hear "wrong." | MED | Highlight the offending stroke segment; offer immediate redo of that stroke. Erase-to-last-good-point is the gentle convention (no full reset). |
| "Passing" a letter = clean reps threshold | S1-05, S1-09 | Every app has a pass bar. Convention: a letter is "done" after N acceptably-traced reps, not one. | MED | **Reps-to-advance is the owner's mother's spec, not ours.** Build the schema to hold a per-letter `repsToPass` + `passThreshold`. Default convention if unspecified: 3 clean reps. |
| Per-letter / per-word pronunciation audio | S1-06 | Heritage learners must hear the sound; "learn to say it, not just write it" (S1-06 verbatim). Table stakes for any Arabic-for-kids app. | LOW | Bundled audio assets (offline). Tappable on the letter and on each word. Native-speaker recordings sourced with curriculum. |
| Parent-created child profile (name + grade → right curriculum) | S1-02 | Sets the starting level. Standard onboarding for kids' education apps. | LOW | Local-only, no auth in v1. Grade selects the curriculum entry point. |
| Child personalization (avatar + nickname) | S1-03 | "Feels personal to me" (verbatim). Low-cost ownership cue; ubiquitous in kids' apps. | LOW | Pick from a fixed avatar set + nickname. No free-text that leaks PII; stored locally. Child-safety aligned (minimum data). |
| "Today's lesson already prepared" landing | S1-01 | Removes navigation burden for a 5–10 yo. The child opens straight into the next due lesson. | LOW–MED | v1 = deterministic "next unlocked lesson in sequence," not adaptive (adaptation is v2/S2-05). One big "Start" affordance. |
| Lesson unlock-on-pass | S1-09 | Mastery gating: "build on solid foundations" (verbatim). Standard in Duolingo/Prodigy-style progressions. | LOW–MED | Linear unlock keyed off the pass state. See "Mastery gating done well vs badly" below. |
| Quiet completion acknowledgment (single star) | S1-10 | A gentle reward on lesson completion. Explicitly bounded: one star, no streaks/badges. | LOW | Calm animation, no escalating-reward loop. This is the *only* sanctioned game-like element. |
| Local parent progress view (no account) | S1-11 | Parents expect to see completed lessons + scores. Without auth, this is an on-device read-only view. | LOW–MED | Simple list: lessons done, score/stars per lesson, current position. Possibly behind a light "are you a grown-up?" gate (see anti-features). |
| Works fully offline | S1-05, NTH-05 | Tracing + scoring on-device, curriculum as bundled assets. A child should study with no connection. | LOW | Falls out of the local-only v1 architecture; satisfied by design. Confirm via R2. |

### Differentiators (Competitive Advantage)

Where Qalam beats the field. These align directly with Core Value: *real curriculum, teacher-quality specificity, anti-gamification*.

| Feature | Story | Value Proposition | Complexity | Notes |
|---------|-------|-------------------|------------|-------|
| Real teacher's curriculum, faithfully structured | (all) | Stroke order, reps-to-advance, the 3–4 common mistakes per letter, and intro order come from a graduate-level Arabic teacher (owner's mother), not guesswork. No competitor cites a named pedagogy. | MED (schema) | The schema is the differentiator's vehicle — build it to hold *her* spec exactly. This is the moat: anyone can draw dotted letters; few have the pedagogy. |
| Deterministic feedback that *names the specific mistake* | S1-05 | Even without the AI tutor, mapping ML Kit stroke output to the curriculum's known per-letter mistakes ("your baa's curve is too shallow") feels like a teacher caught it — not a generic "try again." | HIGH | The bridge between v1's deterministic scoring and v2's warm tutor. The per-letter "common mistakes" list is the magic ingredient. See below. |
| Handwriting-first, anti-gamification by design | S1-10 | The market is saturated with points/streaks/mascots. "Real Arabic. Not a game." is itself the differentiator. Calm, focused, teacher-like. | LOW | A *design posture*, not a feature to build — but it must be defended in every UI decision. |
| Heritage-learner framing (not foreign-language drill) | S1-06, S1-07, S1-08 | Sentence-building and grammar treated as *writing/meaning* practice, not tap-the-answer vocabulary quizzes. Distinguishes from Duolingo-style apps. | MED | The hard part is keeping S1-07/S1-08 handwriting-first (see below) rather than sliding into multiple-choice. |
| RTL + connected-script done correctly | S1-04, S1-05 | Most cheap tracing apps mishandle positional forms or letter connections. Correct isolated/initial/medial/final shaping is a visible quality signal. | MED–HIGH | Gated by R3. A real differentiator *only if* execution is clean; done wrong it's a table-stakes failure. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Streaks / daily-streak pressure (NTH-01) | "Drives daily engagement" | Pressure mechanic; punishes missed days; antithetical to the calm-teacher posture. Explicitly excluded by decision. | The quiet per-lesson star (S1-10) and the parent progress view (S1-11) are the only progress signals. |
| Collectible badges / trophies (NTH-02) | "Kids love collecting" | Points-chasing; shifts motivation from learning to acquiring. Excluded by decision. | Intrinsic progress: unlocking the next *real* lesson is the reward. |
| Multiple-choice / tap-the-answer letter & word quizzes | "Easy to build, easy to score, 'fun'" | This is **the anti-product** (PROJECT.md). Teaches recognition, not formation; the exact failure mode Qalam positions against. | Everything is a writing/tracing task. Grammar and sentence work are expressed through handwriting and ordering, not tapping options. |
| Cartoon mascot / over-praise / confetti spam | "Engagement for young kids" | Chatbot-cheerful, not teacher-calm. Over-praising sloppy work undermines real feedback. Conflicts with the tutor voice the product is built around. | Warm-but-specific tone; honest acknowledgment. Celebrate *real* progress only. |
| Free-text profile fields, photos, real names exposed | "Personalization" | Child-safety risk; PII on a children's app. Conflicts with minimum-data / private-by-default. | Fixed avatar set + nickname (S1-03), name used only locally to load curriculum (S1-02). |
| Adaptive/AI feedback in v1 | "Make feedback smart now" | The Claude tutor, placement, and adaptation are deliberately **v2** (S2-xx). Pulling them forward breaks the milestone and adds backend/cost/latency (R4) prematurely. | v1 ships deterministic on-device feedback; the AI tutor layers on in v2 atop this foundation. |
| Speed/timed test mode for young kids | Competitor "Write It! Arabic" has a timed test mode | Timed pressure works against calm mastery for 5–10 yos and conflicts with anti-gamification. | Untimed practice; mastery measured by clean reps, not speed. |
| Unbounded retries that auto-pass eventually | "Avoid frustration" | If a child can mash through, "passing" becomes meaningless and the foundation isn't solid (defeats S1-09). | Gentle scaffolding *within* a letter (more guidance after repeated misses) rather than lowering the bar. See gating notes. |

---

## What "good" looks like (anchored to the questions)

### Letter-tracing UX for ages 5–10
- **Guide dots / ghost letter:** dotted outline + start-point dot + directional arrow. The dotted guide must render the *correct positional form* (R3 dependency).
- **Stroke-order animation (S1-04):** play before writing, child-paced, replayable; the "pencil hand demonstrates" pattern (iTrace) is the gold standard.
- **"Passing" (S1-05/S1-09):** N *clean* reps, not a single attempt. The threshold and N are the **owner's mother's spec**; build the schema to hold per-letter values. Convention fallback ≈ 3 clean reps.
- **Error highlighting:** show *where* the stroke deviated (out-of-bounds, wrong direction, shaky), erase back to the last good point, redo just that stroke. Never a punishing full reset.

### On-device deterministic feedback WITHOUT an AI tutor
The minimum that still "feels like a real teacher caught the mistake," in order of pedagogical value:
1. **Stroke count** — did the child use the right number of strokes? (e.g., dots/i'jām as separate strokes). Cheapest, high signal.
2. **Stroke order/sequence** — were strokes drawn in the taught order?
3. **Stroke direction** — was each stroke drawn the correct way (RTL entry, top-down, etc.)?
4. **Shape match %** — geometric closeness of each captured stroke to its reference path (DTW / Fréchet-style path distance), surfaced as a soft "how close."
5. **Mistake naming (the differentiator):** map the failure to the curriculum's per-letter "common mistakes" list so feedback is *specific* ("baa's curve too shallow") not generic. This is what bridges to the v2 tutor.

Minimum bar for v1: at least **stroke count + order + direction + a shape threshold**, with the failing stroke highlighted and a targeted redo. Shape-% alone (coloring-book grade) is below the bar.

### Lesson sequencing / unlock-on-pass (S1-09) — done well vs badly
- **Well:** linear unlock with a *clear, reachable* mastery bar; scaffolding that *increases support* after repeated misses (more guidance, slower animation) rather than lowering the bar; the child always sees what's next; passing reflects real mastery so the next lesson genuinely builds on it.
- **Badly:** opaque criteria, dead-ends with no path forward (frustration), or auto-passing after enough tries (mastery becomes meaningless). Adaptive difficulty is the usual fix — but in Qalam that's **v2**; v1 uses fixed scaffolding, not adaptation.

### Onboarding for young children
- **Parent profile (S1-02):** grown-up enters name + grade → grade selects curriculum entry point. Local, no auth.
- **Avatar + nickname (S1-03):** fixed set, no PII, child-driven, quick.
- **"Today's lesson prepared" (S1-01):** v1 = the next unlocked lesson in the fixed sequence, presented on open with one big Start. (Adaptive "what you need most" is v2/S2-05.)

### Keeping S1-06/07/08 handwriting-first (not foreign-language drill)
- **Pronunciation (S1-06):** tappable audio attached to letters/words; a listening *aid* to writing, not a quiz.
- **Sentence-building (S1-07):** express via *writing/ordering* — trace or arrange words RTL to form a sentence; the act is physical, not tap-one-of-four.
- **Grammar (S1-08):** lightweight, at-level, and expressed through writing/forming rather than multiple-choice. **Exact form is pedagogy → owner's mother's spec.** Guardrail: if a design reduces to "tap the right answer," it has drifted into the anti-product.

### Light parent progress view without accounts (S1-11)
Read-only on-device list: completed lessons, per-lesson score/stars, current position. Optionally behind a soft "are you a grown-up?" gate (a simple math challenge) so a child doesn't wander in — a common, low-cost kids'-app pattern. No analytics/struggle breakdown (that's v2/S2-06).

---

## Feature Dependencies

```
Curriculum schema (owner's mother's spec: stroke order, reps-to-pass, common mistakes, intro order)
    ├──required by──> S1-04 stroke-order animation (needs reference paths)
    ├──required by──> S1-05 on-device feedback (needs reference paths + per-letter mistakes + pass thresholds)
    ├──required by──> S1-06 pronunciation (needs audio assets keyed to letters/words)
    ├──required by──> S1-07/S1-08 sentence & grammar content
    └──required by──> S1-09 unlock order (needs lesson sequence)

R3 (RTL + connected-script rendering)
    └──required by──> S1-04 guide glyph + S1-05 ghost letter (correct positional forms)

R1 (ML Kit Digital Ink — RESOLVED) ──enables──> S1-05 on-device stroke feedback

S1-02 parent profile (grade) ──determines──> S1-01 today's lesson (curriculum entry point)
S1-05 pass state ──gates──> S1-09 unlock ──gates──> S1-01 next lesson
S1-09 pass/score ──feeds──> S1-10 star + S1-11 parent progress view

Anti-gamification posture ──conflicts with──> NTH-01 streaks, NTH-02 badges (excluded)
Handwriting-first posture ──conflicts with──> multiple-choice drills (the anti-product)
```

### Dependency Notes
- **Curriculum schema is the universal upstream dependency.** Almost every Sprint 1 story reads from it. Build it first and faithfully (it holds *her* pedagogy). It must carry: per-letter reference stroke paths, stroke order, `repsToPass`/`passThreshold`, the 3–4 common mistakes per letter, intro order, audio asset keys, and sentence/grammar content.
- **R3 must be resolved before S1-04/S1-05 UI:** the guide and ghost glyphs need correct positional shaping or the whole tracing surface is wrong.
- **R1 is resolved** (ML Kit Digital Ink, owner-validated) and unblocks S1-05; confirm the exact stroke-data surface during implementation.
- **S1-05 is the spine:** its pass state drives unlock (S1-09), which drives the landing lesson (S1-01), the star (S1-10), and the parent view (S1-11).

---

## MVP Definition

### Launch With (v1 = Sprint 1, as written)
- [ ] Curriculum schema loaded from owner's mother's spec (28 letters + words/sentences/grammar) — *everything depends on it*
- [ ] S1-02 parent-created child profile (name + grade)
- [ ] S1-03 avatar + nickname
- [ ] S1-01 "today's lesson prepared" landing (next unlocked lesson)
- [ ] S1-04 stroke-order animation
- [ ] S1-05 stylus tracing + on-device deterministic feedback (stroke count + order + direction + shape threshold, with error highlighting and targeted redo) — *the core*
- [ ] S1-06 pronunciation audio (letters + words)
- [ ] S1-07 sentence-building (handwriting/ordering form)
- [ ] S1-08 grammar exercises (at-level, handwriting-first)
- [ ] S1-09 unlock-on-pass
- [ ] S1-10 quiet completion star
- [ ] S1-11 local parent progress view
- [ ] Offline, local-only, no auth (NTH-05 by design)

### Add After Validation (v1.x, within the milestone if time allows)
- [ ] Mistake-naming layer mapping ML Kit output → curriculum's per-letter common mistakes — *trigger: core tracing loop validated; this is the highest-leverage polish before the v2 tutor*
- [ ] Increasing in-letter scaffolding after repeated misses — *trigger: observed child frustration in testing*

### Future Consideration (v2+ — deferred by decision)
- [ ] Warm Claude AI tutor: voice feedback (S2-02), ask-out-loud (S2-03) — the product's signature, sits on the v1 foundation
- [ ] Placement exam (S2-01); adaptive daily lesson + extra practice on weak areas (S2-04, S2-05)
- [ ] Parent struggle analytics, daily-goal, weekly report (S2-06, S2-07, S2-10)
- [ ] Vocabulary flashcards (S2-08), reading-comprehension passages (S2-09)
- [ ] Firebase Auth/Firestore/Cloud Functions — land with the tutor

---

## Feature Prioritization Matrix

| Feature | Story | User Value | Implementation Cost | Priority |
|---------|-------|------------|---------------------|----------|
| Curriculum schema | (all) | HIGH | MEDIUM | P1 |
| Stylus tracing + on-device feedback | S1-05 | HIGH | HIGH | P1 |
| Stroke-order animation | S1-04 | HIGH | MEDIUM | P1 |
| Unlock-on-pass | S1-09 | HIGH | LOW | P1 |
| "Today's lesson" landing | S1-01 | HIGH | LOW | P1 |
| Pronunciation audio | S1-06 | HIGH | LOW | P1 |
| Parent profile (grade) | S1-02 | MEDIUM | LOW | P1 |
| Avatar + nickname | S1-03 | MEDIUM | LOW | P1 |
| Quiet completion star | S1-10 | MEDIUM | LOW | P1 |
| Parent progress view | S1-11 | MEDIUM | LOW | P1 |
| Sentence-building (handwriting-first) | S1-07 | MEDIUM | MEDIUM | P1 |
| Grammar exercises (handwriting-first) | S1-08 | MEDIUM | MEDIUM | P1 |
| Mistake-naming layer | S1-05+ | HIGH | MEDIUM | P2 |
| Increasing in-letter scaffolding | S1-09 | MEDIUM | MEDIUM | P2 |
| AI tutor / adaptation | S2-xx | HIGH | HIGH | P3 (v2) |

All S1 items are P1 because the milestone *is* Sprint 1 as written; the matrix ranks intra-milestone build order and value, not inclusion.

---

## Competitor Feature Analysis (Research Brief R5 — kept short)

**The gap:** The Arabic-for-kids market is dominated by reading/listening/speaking apps (IReadArabic, Read Along, Siraj, Gus on the Go, Pimsleur, Duolingo) that do **no handwriting** — the foreign-language tap-the-answer model Qalam positions against. A second tier (Arabic Alphabet Tracing, Learn Arabic Letters & Draw, 3asafeer, TenguGo) offers *coloring-book tracing*: a dotted letter to fill in, but feedback is shape-only or absent — it doesn't check the *stroke*. Only a thin top tier evaluates the actual tracing path. **No competitor combines all three of: real path-based stroke evaluation + a named, graduate-level teacher's curriculum + an anti-gamification, heritage-learner posture.** That intersection is Qalam's opening.

| Feature | Coloring-book tracers (Arabic Alphabet Tracing, Learn & Draw) | Path-based tracers (Write It! Arabic) | General kids' handwriting (iTrace, Writing Wizard) | Qalam (v1) |
|---------|---------|---------|---------|---------|
| Dotted guide + arrow | Yes | Yes | Yes (pencil-hand demo) | Yes (S1-04/05) |
| Stroke-order animation | Sometimes | Yes | Yes (best-in-class) | Yes (S1-04) |
| Evaluates the *stroke path*, not just shape | No | Yes | Yes ("too shaky/out of bounds") | Yes — on-device ML Kit (S1-05) |
| Names the *specific* Arabic mistake | No | No | No | **Yes — curriculum's per-letter mistakes (differentiator)** |
| Connected/positional forms handled | Often poorly | Yes (4 forms) | N/A (Latin) | Yes (R3) |
| Named real-teacher curriculum | No | No | No (generic) | **Yes — owner's mother (differentiator)** |
| Anti-gamification posture | No (stickers/colors) | Mixed (timed test, stats) | No (stars/games/stickers) | **Yes — quiet star only (differentiator)** |
| Arabic-specific | Yes | Yes | No (Latin script) | Yes |

Closest competitor: **Write It! Arabic** (path-based, 4 forms, offline, all 28 letters) — but generic curriculum, includes timed-test pressure, and no per-mistake teacher feedback. Qalam differentiates on pedagogy + specificity + calm posture, not on the existence of tracing.

---

## Sources

Competitor / market (R5):
- [Top 19 Arabic Learning Apps For Kids — KALIMAH](https://kalimah-center.com/arabic-learning-apps-for-kids/)
- [Write It! Arabic — App Store](https://apps.apple.com/us/app/write-it-arabic/id1400942827) and [ArabTechGate review](https://arabtechgate.com/en/write-it-arabic-app/)
- [Arabic Alphabet Tracing — Google Play](https://play.google.com/store/apps/details?id=com.GameiFun.ArabicAlphabetWriting)
- [Learn Arabic Letters & Draw — App Store](https://apps.apple.com/us/app/learn-arabic-letters-draw/id1086471551)
- [Best Arabic Learning App for Kids 2026 — Alphazed](https://www.thealphazed.com/blog/best-arabic-learning-apps-kids-2026)

Tracing UX conventions:
- [iTrace handwriting practice — App Store](https://apps.apple.com/us/app/itrace-handwriting-practice/id645416621) and [itraceapp.com](https://itraceapp.com/)
- [Writing Wizard — L'Escapadou](https://lescapadou.com/wp/en/writing-wizard-app/)
- [9 Letter Tracing Apps for Kids — EducationalAppStore](https://www.educationalappstore.com/best-apps/5-best-letter-tracing-apps-for-kids)
- [Teaching handwriting — a stroke based approach — Skills for Action](https://skillsforaction.com/handwriting/stroke-based-approach)

Mastery gating:
- [What is Mastery-Based Learning? — Modern Classrooms Project](https://www.modernclassrooms.org/blog/what-is-mastery-based-learning)
- [Designing Educational Apps with Cognitive Learning Principles — Glance](https://thisisglance.com/blog/educational-apps-cognitive-learning-principles-in-design)

Arabic letter pedagogy (conventional baseline only — owner's mother's spec is authoritative):
- [Arabic Alphabet Writing And Tracing — Sahlah Academy](https://sahlahacademy.net/arabic-alphabet-writing/)
- [The Different Forms of Arabic Letters — Arab Academy](https://www.arabacademy.com/the-different-forms-of-arabic-letters-and-how-they-come-together/)

---
*Feature research for: children's Arabic handwriting tablet app (Qalam v1 / Sprint 1)*
*Researched: 2026-05-30*
