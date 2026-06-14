# C — Letter-Unit UX Structure & Flow

**Researched:** 2026-06-14
**Topic:** How to structure a per-letter learning UNIT into sections, and the overall flow — so Qalam becomes a real guided lesson, not a single tracing screen.
**Confidence:** HIGH on the section model, pacing, and navigation shape (well-grounded in Montessori/Kumon/attention-span research + the project's Decided rules); MEDIUM on exact rep counts and exercise mix — those are owner's-mother pedagogy and must be confirmed, not invented here.

---

## TL;DR recommendation

A Letter Unit is a **guided linear path of short sections** (not a free scrollable page, not a free hub), surfaced from the journey map as one "letter" and from the home screen as "today's lesson." The path is **resumable and chunked** so a 5-year-old can stop after Meet+Trace and a 10-year-old can finish in one sitting. The reed-pen tutor **threads through every section** as the presenter — it speaks the prompt, demonstrates the stroke, reacts to the trace — and a single quiet star is granted only at the end on real clean reps.

---

## 1. The Letter Unit section model (refined)

The strawman is sound. I keep all six sections, reorder slightly, and split tracing so **isolated form is mastered before connected forms** (the universal Arabic-teaching order: isolated → initial → final → medial). Refined model:

| # | Section | What it accomplishes | Why here |
|---|---------|---------------------|----------|
| 1 | **Meet the letter** | See the glyph, hear its **sound** (not its name — phonics-first, per Montessori), see the 4 forms once as a preview. | Orientation before muscle work. Sound-first builds the reading bridge. |
| 2 | **Watch & trace — isolated** | Tutor animates stroke order, child traces the isolated form to clean-rep threshold. | The core motor skill. Master the standalone shape before any connection. |
| 3 | **Watch & trace — in context** | Trace initial → final → medial forms, each with its own short animation. | Connected script is the hard part; isolate it *after* the base shape is owned. Drip the forms so it never feels like "4 letters in a row." |
| 4 | **Words** | 2–3 vocab words containing the letter; hear the word, see the letter highlighted, trace it inside the word. | Transfer: the letter now does real work. Vocab comes from the owner's mother's materials. |
| 5 | **Listen & write** | Dictation / phonological awareness: hear the sound or word, write the letter from memory (no dotted guide, or faded guide). | Moves from *tracing* to *recall* — the single biggest signal of real mastery. |
| 6 | **Mastery** | One quiet star on the journey map. Tutor gives a specific, warm close. | Information, not score. Only on clean reps across 2–5. |

**Why this order:** it mirrors the Montessori three-period lesson (introduce → practice → demonstrate mastery) and Kumon's "small steps, master before advancing." Sections 1–3 are *introduce*, 4–5 are *practice + transfer*, 6 is *demonstrate*. Recognition precedes production; tracing precedes recall.

**Practice questions (strawman §5):** I fold these *into* sections 4–5 rather than making a separate quiz block. A standalone "exercises" section reads as test-prep and risks points-chasing. Exercise *types* (which-form-is-this, trace-in-word, write-from-dictation, find-the-letter) become the activities *inside* Words and Listen-&-write.

---

## 2. Pacing & attention

Research is consistent: attention span ≈ **2–3 minutes × age**, so a 5-year-old sustains ~10–15 min, a 10-year-old ~20–27 min, and content should be chunked into **7–10 minute segments** with natural stop points. Kumon sessions run ~15–30 min total.

**Design rules:**
- **Each section = one chunk, ≤ 3–5 minutes.** A full unit is ~6 chunks ≈ 15–25 min — at the ceiling for the youngest, comfortable for the oldest.
- **A unit is explicitly splittable across sittings.** Natural break after section 3 (motor work done) and after section 5. The youngest child does Meet + isolated trace today, context + words tomorrow.
- **Reps per section: few and clean, not many.** Tie to the curriculum's "clean reps to advance" (owner's-mother spec). Per-form rep count should be small (e.g. 2–3 clean) so the child never grinds the same shape 10×.
- **Vary the activity every chunk** (watch → trace → listen → write) — the proven antidote to fatigue is changing the mode, not shortening total time.
- **No timers, no "hurry" pressure.** Kumon uses speed; Qalam deliberately does not — "no points-chasing," patient teacher.

---

## 3. Progression & mastery

**Within a unit:** advance section-by-section on **clean reps**, not on attempts. A section unlocks the next only when its trace(s) hit the scorer's clean-rep threshold (the owner's-mother count). A struggling child loops *within* the section with the tutor's specific feedback — they are never failed, never bounced back to the start. Recall in section 5 (faded/no guide) is the gate that proves the star is earned.

**The 4 forms without it feeling long:** dripping one form per micro-step (§3 above) and using *real words* in §4 means the child meets initial/medial/final **in context**, not as four abstract drills. The medial form especially only makes sense inside a word — so it lives there.

**Unit → next letter:** a letter is "mastered" (star) when sections 2–5 are clean. The next letter unlocks then. **Letter order comes from the owner's mother**, not frequency lists — do not reorder the 28. Optionally allow a *review* re-entry to a mastered unit (no new star) for spaced repetition, but never a "redo for more stars" loop.

---

## 4. Navigation & structure

**Recommendation: a guided linear path** (not one long scroll, not a free hub) for ages 5–10.

- A **free scroll** lets a child skip the hard recall section and over-trace the easy part — wrong incentives, and scroll fatigue.
- A **free hub** (pick any section) demands self-regulation these ages don't have and breaks the introduce→practice→master arc.
- A **guided linear path** matches how a teacher sits beside a child: one thing at a time, forward motion, the tutor leading. Show a slim **progress ribbon** (6 dots/segments) so the child sees "where am I," but it is *position*, not a score, and not a percentage to maximize.

**How it nests:**
- **Journey map (28 letters)** → each node is one Letter Unit. A node shows locked / available / mastered (star). Tapping an available node enters the unit at its first unfinished section (resume-aware).
- **Today's-lesson home** → deep-links into the current unit's next section ("Continue with baa"). Home is the *daily on-ramp*; the journey map is the *whole arc*. The existing single trace screen becomes section 2/3's inner widget — reused, not thrown away.

---

## 5. RTL, tablet layout & the tutor thread

**RTL / tablet (landscape):**
- Reading and progress flow **right → left**: the progress ribbon fills R→L, "next" advances leftward, the journey map reads R→L. Mirror all directional affordances; never hard-code left-as-forward.
- **Landscape split:** tutor/prompt on one side (the "teacher's seat"), the large trace canvas on the other, generously sized for a stylus and a child's hand-rest. Keep the writing surface the visual hero; chrome stays minimal and parchment-quiet.
- One consistent layout skeleton across all six sections so navigation feels like *the same room*, only the activity changes.

**The single reed-pen tutor as the thread (not a game mascot):**
- The tutor **presents every section** — speaks/labels the prompt ("Listen, then write the sound you hear"), **demonstrates** stroke order in §2–3, and **reacts** to a trace with specific, warm feedback ("Your baa needs a deeper curve at the bottom — slower this time"). This is the persona from the owner's mother's voice; in v2 the feedback *is* Qalam speaking.
- It is **pedagogical presence, not reward theater**: no confetti-on-tap, no mascot cheering for points, no "+N keep going." Its celebration at the star is dignified and specific, once.
- It is the **continuity** that makes six separate sections feel like one lesson with one teacher — the strongest argument for the linear path over a hub.

---

## Open questions for the owner's mother (do not invent)

1. **Clean-rep count per section / per form** — the gate values in §3.
2. **Exercise mix** inside Words and Listen-&-write — which activity types, how many.
3. **Vocab words per letter** (2–3) — from her materials.
4. Whether **medial form** is taught for every letter or only where pedagogically standard.
5. Whether a **review re-entry** to mastered units is desired for spaced repetition.

---

## Sources

- [The Montessori writing sequence](https://www.wonderfulmontessori.com/the-writing-sequence)
- [Teaching Reading and Writing with Montessori — three-period lesson](https://guidepostmontessori.com/blog/teaching-reading-writing-montessori/)
- [Montessori Letters: Sandpaper Letters & Moveable Alphabet](https://themontessorisite.com/montessori-letters/)
- [Kumon — repetition and its purpose](https://www.kumon.com/resources/repetition-and-its-purpose-in-the-kumon-program/)
- [Kumon — small-step worksheets / mastery before advancing](https://www.kumon.com/about-kumon/kumon-method/small-step-worksheets/worksheets)
- [Normal attention span expectations by age (≈2–3 min × age)](https://www.brainbalancecenters.com/blog/normal-attention-span-expectations-by-age)
- [Content chunking (7–10 min segments)](https://tlconestoga.ca/content-chunking/)
- [Breaking up long periods to maintain focus](https://www.edutopia.org/article/breaking-up-long-class-periods-maintain-students-focus/)
- [Arabic letter forms — isolated/initial/medial/final teaching order](https://www.arabacademy.com/the-different-forms-of-arabic-letters-and-how-they-come-together/)
- [Jeem in initial/medial/final forms (context teaching)](https://pajykids.com/en/jeem-letter-in-initial-medial-and-final-forms/)
