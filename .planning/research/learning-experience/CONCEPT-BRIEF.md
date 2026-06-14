# Qalam Learning Experience — Concept Brief (Stage A synthesis)

**Date:** 2026-06-14
**Status:** Draft for owner + owner's-mother review → feeds Stage B prototype (Claude Design) → Stage C schema spec
**Sources:** `A-letter-forms-pedagogy.md`, `B-exercise-taxonomy.md`, `C-unit-ux-structure.md`

> The single-letter "trace screen" becomes a **Letter Unit** — a short, guided, Kumon-style
> lesson that takes a child through meeting, writing (all its forms), reading, and practicing
> one letter, ending in one quiet mastery star. Phases 7–8 build this teaching structure into
> the app; the AI tutor (v2) later makes the mascot's feedback *adaptive* — the scaffolding is
> all v1.

---

## 1. The Letter Unit (the new core)

A **guided linear path** of six short sections (≤3–5 min each; full unit ~15–25 min, explicitly
splittable across sittings with natural breaks after sections 3 and 5):

1. **Meet the letter** — see it, hear its sound, see its forms.
2. **Watch & trace (isolated)** — stroke-order animation, then trace the isolated form to mastery.
3. **Watch & trace (in context)** — the connecting forms (initial → final → medial), then a
   connection-in-a-word using already-mastered letters.
4. **Words** — vocabulary carrying the letter; hear + trace the words.
5. **Listen & write** — dictation / phonological-awareness, handwriting-first.
6. **Mastery** — one quiet star, earned on clean reps (the recall sections are the real gate).

"Practice questions" are **folded into sections 4–5**, not a separate quiz — this avoids
points-chasing and keeps it a lesson, not a test. The single reed-pen **mascot threads through
every section** as presenter / demonstrator / reactor (pedagogical presence, not a game mascot).

**Navigation:** the journey-map node and today's-lesson home both **deep-link into a
resume-aware unit**; the existing trace screen becomes the *inner trace widget*. A slim R→L
progress ribbon shows *position, not score*.

---

## 2. Letter forms — the model (resolves the "we only did one shape" gap)

Each letter is a unit with **four nullable form slots**: `{ isolated, initial?, medial?, final? }`.
Each slot holds its own authored stroke path + connector metadata + per-form mistake list.

- **Non-connectors** (ا د ذ ر ز و) have **only isolated + final** — `initial`/`medial` are null
  *by design* ("does not exist," not TODO).
- **Stroke order is consistent across a letter's forms** — teach one body stroke + connector
  rules, not four fresh motions. Tag each form `reuses_core` (connector overlay on the isolated
  body — the common case) vs `distinct` (body reshape needing full re-authoring: ‘ayn/ghayn/
  haa/kaaf/jiim-family).
- **Special cases:** laam-alif (لا) = its own letter-like unit; hamza (ء) = a seat-letter + mark,
  not a connecting letter; taa marbuuta (ة) / alif maqsuura (ى) = final-only — **scope to confirm
  with mom.**
- **Teaching sequence:** isolated → initial → medial → final as separate gated targets
  (auto-skipping null slots), then one connection-in-a-word target. **One mastery star per letter
  unit**, not per form (preserves anti-gamification).
- **Per-form mistakes → named scorer checks + authored feedback:** disconnecting a connector,
  wrong form mid-word (tail mid-word), wrong proportion, mirror/direction, dot placement,
  connector off-baseline.

---

## 3. Exercise / question taxonomy (all handwriting-first)

Every exercise resolves to the child **writing** a known letter/word, checked by the existing
geometric stroke scorer — **never a tap** (multiple-choice is the anti-product). Recognition/
matching/coloring worksheet types become **production** tasks (e.g. "color images that start with
ت" → *hear a word, write its first letter*). Dictation and vocabulary convert almost directly.

**8 exercise types** (each = one Flutter interaction widget), backed by **only 2 validators**
(single-glyph scorer, sequence validator) + a thin rule layer (positional-form, join-continuity,
wrong-letter):

| `type` | Child does | Checked by |
|---|---|---|
| `traceLetter` | trace a form over the dotted guide | single-glyph scorer |
| `writeFromSound` | hears a word → writes its **first letter** | single-glyph + rule |
| `writeFromPicture` | sees a picture → writes its first letter / the word | single-glyph / sequence |
| `dictateWord` (إملاء) | hears a word → writes the whole word | sequence validator |
| `connectWord` (ربط) | writes/joins letters into a connected word | sequence + join rule |
| `produceForm` | writes the correct positional form of a letter | single-glyph + positional rule |
| `teachCard` | non-interactive "meet/teach" card (sound, forms) | — |
| `letterMaze` | enrichment; trace a path of the target letter | single-glyph |

The owner's mother authors all content (audio ids, images, answer words, mascot mistake lines);
engineering reuses the one scorer throughout.

---

## 4. Progression & mastery

- Advance **section-by-section** on the owner's-mother **clean-rep gate**; a section loops on
  failure (never a hard "wrong"). Few clean reps; vary the mode every chunk; no timers.
- The **star** is earned only on clean reps across the recall sections (4–5), which are the real
  gate. The **next letter unlocks then**; the 28-letter intro order stays the mother's.
- Reuses the Phase 6 progression engine (clean-reps-to-advance) and the journey map.

---

## 5. What this means for Curriculum Schema v2 (locked in Stage C, not here)

The data model must hold: per-letter **form slots** (nullable, with per-form strokes + mistakes +
tolerances), a **words/vocab** collection (text, audio, image, letterId), and a typed
**exercise** union (the 8 types above). This extends — does not replace — the Firestore +
bundle model Phase 06.1 is building. **We do not lock the schema until the Stage B prototype
validates the experience.**

---

## 6. Open questions for the owner's mother (the sign-off agenda)

Collected from all three research tracks — these are pedagogy calls only she can make:
1. Scope of taa marbuuta (ة) / alif maqsuura (ى), and which letters are true **body-reshape**
   exceptions (full re-authoring vs connector overlay).
2. **Clean-rep counts** per section / per form.
3. The **exercise mix** per letter (which of the 8 types, how many).
4. **Vocab** per letter (which words — from `الحروف مع صور وكلمات`).
5. **Medial-form scope** — teach medial for every connector, or only where it differs enough to matter?
6. **Review re-entry** — how a mastered letter resurfaces for spaced practice.
7. Whether forms are taught **per-letter in isolation** first, vs introduced **in words** earlier.

---

## 7. Next step — Stage B: prototype in Claude Design

Turn this brief into clickable HTML mockups (via `/gsd:sketch`), grounded in the existing
design-kit tokens + mascot: the full six-section Letter Unit journey for one letter, plus one
screen per exercise type. Iterate with the owner (and mom) until "yes, this is the app." Only
then derive Schema v2 (Stage C, `/gsd:spec-phase 7`).
