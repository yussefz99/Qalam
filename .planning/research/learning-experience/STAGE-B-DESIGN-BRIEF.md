# Qalam — Stage B Prototype Brief (for the Claude Design product)

**Goal:** Build a clickable HTML/CSS prototype of the new **"Letter Unit"** learning experience
for one letter (**baa, ب**), plus one screen for each exercise type — faithful to the existing
Qalam Design System. This is a **throwaway prototype to validate the experience**, not production
code. The owner and the owner's mother will react to it; their feedback then drives the data
schema.

**Device:** Android **tablet, landscape**, **RTL**. Stylus handwriting.
**Audience:** children 5–10, heritage Arabic learners.

---

## 0. Read these first (all in this repo)

**The experience to build (what):**
- `.planning/research/learning-experience/CONCEPT-BRIEF.md` — the full spec for the Letter Unit, the forms model, and the exercise taxonomy. **This is the source of truth for *what* to build.**
- `.planning/research/learning-experience/A-letter-forms-pedagogy.md` — the 4 contextual forms.
- `.planning/research/learning-experience/B-exercise-taxonomy.md` — the 8 exercise types + what the child writes.
- `.planning/research/learning-experience/C-unit-ux-structure.md` — section flow, pacing, navigation.

**The look & feel (how) — match this exactly, don't invent:**
- `docs/design/kit/project/colors_and_type.css` — **design tokens (colors, type). USE THESE.**
- `docs/design/kit/project/SKILL.md` — brand rules.
- `docs/design/kit/project/ui_kits/qalam_app/` — the tablet UI kit: `index.html`, `app.css`, `components.jsx`, `screens.jsx`, `journey_preview.html`, `onboarding_preview.html`, `Alphabet.html`, `letters.js`.
- `docs/design/kit/project/screenshots/*.png` — rendered references (`home.png`, `01-flow.png`…`05-flow.png`, `*-celebration*.png`, `alphabet*.png`, `*-ready.png`, `*-locked-in.png`).
- `docs/design/kit/project/variants/Home & Celebration Variants.html` + the `*.jsx` variants.
- `docs/design/practice-redesign/mockup.html` + `PROMPT.md` — **the canonical trace/feedback surface** (three zones: Trace / Show-fix / Show-praise). Reuse this pattern for every writing surface.

**Existing screens to stay consistent with (Flutter — for behavior/layout reference):**
- `lib/screens/home_screen.dart`, `lib/features/journey/journey_screen.dart`,
  `lib/features/practice/practice_screen.dart`, `lib/features/practice/widgets/mastery_celebration.dart`.

**Mascot (the tutor persona) — bundled SVGs, use the right state per moment:**
- `assets/mascot/qalam-idle.svg` (neutral/present), `qalam-write.svg` (demonstrate), `qalam-think.svg` (prompt/listen), `qalam-cheer.svg` (praise/mastery), `qalam-try-again.svg` (gentle correction). Nib icon: `assets/icons/qalam-nib.svg`.

---

## 1. Product, in one paragraph

Qalam teaches children to *write* Arabic by hand, stroke by stroke, the way a patient teacher
sitting beside them would. The tutor is **warm, calm, specific** — never a cheerful chatbot.
"**Real Arabic. Not a game.**" Friendly, dignified presentation; serious curriculum.

---

## 2. Non-negotiable design rules

- **RTL.** Arabic content flows right-to-left; the app chrome is not globally mirrored.
- **Handwriting-first.** The child **writes/traces**. **NEVER** multiple-choice / tap-one-of-four — that is the anti-product.
- **Anti-gamification.** **ONE quiet star = "you mastered this letter."** NO points, NO running totals, NO streaks, NO badges, NO timers, NO leaderboards, NO "+N keep going" hype. The star is information, not score.
- **The mascot is the patient-teacher persona** — presents, demonstrates stroke order, reacts with a *specific* line. It is NOT a game mascot, never hypes.
- **Warm parchment/ink palette, rounded shapes, dignified.** Use the tokens in `colors_and_type.css`.
- **Arabic glyphs:** Noto Naskh (as in the kit). Feedback always names the exact fix (e.g. *"your baa needs a deeper curve at the bottom — try again, slower this time"*), never "oops, try again".

---

## 2.5 Reuse map — MATCH what exists, design only what's new

Qalam's core loop is **already built and working in Flutter**. The prototype must stay
consistent with these — **do NOT redesign them.** Reference the real screens/screenshots and
stitch the new flow around them.

**ALREADY BUILT — match, don't reinvent:**
- **Trace/practice surface** (ink over dotted guide; three-zone Trace / Show-fix / Show-praise; hear-the-letter) → `docs/design/practice-redesign/mockup.html`, `lib/features/practice/practice_screen.dart`.
- **Stroke-order animation** (the Watch step) → screenshots `01-flow.png`…`05-flow.png`.
- **Mastery celebration** (one quiet star) → `lib/features/practice/widgets/mastery_celebration.dart`, screenshots `*-celebration*.png`.
- **Home** (today's lesson, mascot greeting) → `home.png`, `lib/screens/home_screen.dart`.
- **Journey map** → `docs/design/kit/project/ui_kits/qalam_app/journey_preview.html`, `lib/features/journey/journey_screen.dart`.
- **Mascot + tokens** → `assets/mascot/*.svg`, `docs/design/kit/project/colors_and_type.css`.

**NEW — design these fresh, in the same visual language (no implementation exists yet):**
- The **Letter Unit shell**: the 6-section container + R→L progress ribbon + section transitions.
- **Meet the letter** as a section (all forms + sound).
- **In-context forms** practice (initial / medial / final) — only the isolated form exists today.
- **Words / vocab** section.
- **Listen & write** exercises (dictation, write-from-sound).
- The **8 exercise-type** screens.

**Rule of thumb:** trace surface, stroke animation, celebration → **reuse the existing design**.
Unit shell, forms, words, listen-&-write, exercise types → **design fresh, same visual language.**

## 3. What to build — Screen list

### A) The Letter Unit flow for baa (ب) — a guided linear path

A slim **R→L progress ribbon** across the top shows *position in the unit* (dots, NO numbers, NO score). Six sections, each its own screen, navigable in order, resume-aware, no dead ends:

1. **Meet the letter** — large ب, a play-sound button (🔊 its phoneme), and the letter's **forms** shown (isolated + initial/medial/final). Mascot (idle/think) introduces it.
2. **Watch & trace — isolated** — stroke-order **animation** of the isolated form, then a **trace surface** (ink over a faint dotted guide) using the `practice-redesign` three-zone pattern. Mascot demonstrates (write), then reacts.
3. **Watch & trace — in-context forms** — the connecting forms as steps (initial → final → medial), then a **connect-in-a-word** trace using already-known letters. (Note: baa connects all sides; show all three forms.)
4. **Words** — 3–4 **vocab cards**: the word (Noto Naskh), an illustration placeholder, a play-audio button, and a trace-the-word surface.
5. **Listen & write** — **dictation**: hear a word → write it; and **write-from-sound**: hear a word → write its first letter. Writing surface = dotted guide / ruled line. Mascot reacts with a specific fix or praise.
6. **Mastery** — exactly **ONE quiet star** + mascot (cheer) + a warm line + a "**Next letter**" affordance. (See `*-celebration*.png` and `mastery_celebration.dart` for the established look — match it.)

### B) One screen per exercise type (the 8 from the taxonomy)

Each as a standalone screen showing: the **prompt** (mascot + audio/picture), the **write surface**, and a **feedback state** (coral-highlighted failing stroke + specific fix; and a clean-pass praise + star variant). Types:

`traceLetter` · `writeFromSound` · `writeFromPicture` · `dictateWord` (إملاء) · `connectWord` (ربط) · `produceForm` (write the positional form) · `teachCard` (non-interactive meet/teach card) · `letterMaze` (trace a path of the target letter).

For each, make clear **what the child writes** and that it's checked by writing, never tapping.

---

## 4. Interaction & feel notes

- Each section is short (a couple of minutes); the unit can be **paused and resumed**.
- The tutor **presents the prompt** and **reacts with a specific authored line** — wire in believable copy in the tutor's voice (warm, 5–10 yo, names the exact fix). Use placeholder lines where pedagogy isn't settled.
- Every writing surface reuses the **Trace / Show-fix / Show-praise** three-zone pattern from `docs/design/practice-redesign/mockup.html`.
- Progress ribbon shows **position, not score** (R→L dots).
- Landscape tablet frame; comfortable stylus targets; generous spacing.

---

## 5. Deliverable

- A **clickable HTML/CSS prototype** (one or a few files), navigable in order, **no dead ends**, **screenshot-ready**.
- Faithful to the **tokens** in `colors_and_type.css`, **RTL**, **landscape tablet**.
- Use illustration/audio **placeholders** clearly marked (real assets come later).
- Goal is to **validate the experience and how the sections fit together** — throwaway, not production.
- **Design with reuse in mind:** the validated design will be implemented as a **Flutter `/demo` flow that wires the existing widgets** (trace surface, stroke animation, mastery celebration, mascot) into the new sections — the project's proven pattern (Phase 02.1.1 demo screens → became Phase 3's real UI). So the new surfaces must sit naturally next to the already-built ones, not replace them.

---

## 6. Open pedagogy questions — DON'T invent; show placeholders

These are the owner's-mother's calls (mark them visibly as TBD in the mockup so she can react):
1. Scope of ة / ى, and which letters are body-reshape exceptions.
2. Clean-rep counts per section. 3. Exercise mix per letter. 4. Vocab words per letter.
5. Whether medial is taught for every connector. 6. How a mastered letter resurfaces for review.

---

*When the prototype feels right (owner + mother), we lock Curriculum Schema v2 from it
(`/gsd:spec-phase 7`) and then build — golden-slice baa first, then batch the rest.*
