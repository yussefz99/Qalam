# Phase 2: Curriculum Schema & First-Letter Seed - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 2-Curriculum Schema & First-Letter Seed
**Areas discussed:** Stroke path authoring, Seed scope & letter order, Lessons.json skeleton

---

## Stroke Path Authoring

### Q1: How does mom supply stroke information?

| Option | Description | Selected |
|--------|-------------|----------|
| Prose / description only | She describes stroke order verbally/in writing; no coordinate data. A digitization step is required. | ✓ |
| Coordinates / traced paths | She can provide actual coordinate paths (traced from a font or on paper). | |

**User's choice:** Prose / description only
**Notes:** Mom provides stroke order as written description, not coordinate paths.

---

### Q2: How to capture reference coordinate paths?

| Option | Description | Selected |
|--------|-------------|----------|
| Extract from Noto Naskh font | Python script extracts contour components from the bundled TTF and normalizes them. No manual tracing. | ✓ |
| Dev-only capture screen | Build a temporary in-app screen where owner traces each reference letter with stylus and exports points. | |
| Hand-author placeholder paths | Rough normalized paths authored by hand as placeholders; calibrated in Phase 4. | |

**User's choice:** Extract from Noto Naskh font (recommended)
**Notes:** Font is already bundled from Phase 1. Python + fonttools is practical for a one-time authoring step.

---

### Q3: How to map font contours to individual strokes?

| Option | Description | Selected |
|--------|-------------|----------|
| Font contours + mother's stroke map | Extract discrete contour components (e.g. baa bowl + dot). Owner maps each contour to a stroke in mom's prescribed order. | ✓ |
| Font as guide only; strokes hand-authored | Use font outline for visual reference only; define each stroke path manually as simplified polylines. | |

**User's choice:** Font contours + mother's stroke map (recommended)
**Notes:** Owner reads mom's prose description and maps it to the correct extracted contour index for each letter.

---

## Seed Scope & Letter Order

### Q1: Which letter does mom introduce first?

| Option | Description | Selected |
|--------|-------------|----------|
| Alif (ا) | The simplest form — a single vertical stroke. Classical intro order. | ✓ |
| Baa (ب) | Bowl + dot. Two strokes, shows connected-script shaping and dot system. | |
| Another letter | Her curriculum starts with a different letter. | |

**User's choice:** Alif (ا)
**Notes:** Alif is first in mom's intro sequence and becomes Phase 3's trace target.

---

### Q2: How many letters in the seed?

| Option | Description | Selected |
|--------|-------------|----------|
| 3 letters (recommended) | Alif + 2 more from mom's intro sequence. Validates schema variety. | |
| 2 letters (alif + baa) | Minimum viable seed. | |
| 5 letters | Covers early lessons but more content work now. | |
| All 28 (user's choice) | Owner said "why not do all of them — the design I give you has it for all letters." | ✓ |

**User's choice:** All 28 letters (free-text "Other" response)
**Notes:** Owner wants to author the full 28-letter set now. Design docs are UI-only (not letter curriculum data), but mom's spec covers stroke order for all 28.

---

### Q3: What's available for all 28 letters right now?

| Option | Description | Selected |
|--------|-------------|----------|
| Full spec for all 28 | Stroke order, clean-reps, 3–4 mistakes + fix messages for all 28 ready to author now. | |
| Stroke order for all; mistakes for a few | Stroke order and intro sequence available for all 28. Common mistakes fully spec'd only for the first few. | ✓ |
| Partial — first batch ready | First N letters fully spec'd; rest need more sessions with mom. | |

**User's choice:** Stroke order for all; mistakes for a few
**Notes:** All 28 get stroke order + forms + intro order + cleanRepsToAdvance. Common mistakes + fix messages are authored where available, placeholder-marked where not. Phase 7 fills the gaps.

---

## Lessons.json Skeleton

### Q1: Does mom have a lesson grouping plan?

| Option | Description | Selected |
|--------|-------------|----------|
| Placeholder first lesson only | Phase 2 creates minimal lessons.json with lesson_01 (alif). Real groupings deferred to Phase 6/7. | ✓ |
| Mom's groupings available now | She knows which letters go together per lesson; author real lesson structure now. | |

**User's choice:** Placeholder first lesson only (recommended)
**Notes:** Minimal skeleton is enough for Phase 3 to boot. Real lesson structure waits for Phase 6 (Lesson Progression).

---

### Q2: Does Phase 2 also need exercises.json?

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 8's job | exercises.json deferred entirely. CurriculumRepository handles absence gracefully. | ✓ |
| Stub it now | Author empty exercises.json with schema comment to prevent null-check errors. | |

**User's choice:** Phase 8's job
**Notes:** Phase 3 only needs letters and a minimal lesson. Exercises are squarely Phase 8 scope.

---

## Claude's Discretion

- Location of the Python extraction script (`tools/`, `scripts/`, `dev/`)
- Font contour simplification algorithm (uniform resampling at N=50–100 points is the default recommendation)
- Whether `referenceStrokes` live inline in `letters.json` or in a companion file
- Exact Dart model field names and nullability for placeholder mistakes
- Whether JSON Schema validation is in scope for Phase 2
- Generic fallback message in scorer when `commonMistakes` is empty (scorer's problem, not Phase 2's)

## Deferred Ideas

- Real lesson groupings (which letters go per lesson, week order) → Phase 6/7
- `exercises.json` (sentence-building and grammar) → Phase 8
- Full common mistakes for all 28 letters → Phase 7 fill-in
- Audio references in `letters.json` → Phase 7 (when recordings exist)
- `signedOff: true` for letters 2–28 → Phase 7 gate (only alif must be signed off before Phase 2 closes)
- Owner's-mother sign-off process (not discussed; default applied: D-11 + D-12 in CONTEXT.md)
