---
spike: 001
name: stroke-representation
type: comparison
validates: "Given a baa attempt + the reference, when sent to Gemini as (a) image, (b) points, (c) geo-diff, then the model accurately names the REAL geometric error without hallucinating — and one representation is best."
verdict: VALIDATED
related: [002, 003, 004]
tags: [stroke-aware, representation, multimodal, gemini, vertex, baa]
---

# Spike 001: Stroke Representation (image vs points vs geo-diff)

## What This Validates

Given a child's baa strokes + the authored reference, when the same attempt is encoded three ways
and sent to Gemini-2.5-flash-on-Vertex, **which encoding lets the model accurately describe the
actual error without hallucinating** — and is any encoding good enough to build on at all? This is
the foundational H3: if the model can't read strokes in *any* form, the whole idea is dead.

## Research

- **Coach model:** `gemini-2.5-flash` on Vertex (the production coach default, `app/models.py`),
  `thinking_budget=0` (without it Gemini 2.5 spends the budget on hidden thinking and returns empty
  content — verified on the auth probe).
- **Multimodal:** Gemini 2.5 Flash accepts inline images; Claude-Haiku-on-Vertex is text-only and
  gated behind Model-Garden Enable — so the image variant (and this whole spike) runs on Gemini.
- **Representations** (`_lib/representations.py`):
  - **image** — child strokes (blue) overlaid on the faint-gray reference, 512px PNG, inline.
  - **points** — child + reference strokes arc-length-resampled to 16 normalized points each, JSON.
  - **geo_diff** — a *precomputed* structured diff (bowl depth ratio, left/right symmetry, dot
    offset + "left/right/above", tail, size, direction) — the model only *verbalizes* it.

## How to Run

```bash
# regenerate the model data (≈60s, ~375 Vertex calls): writes _artifacts/results.json
uv run --project server --with pillow python .planning/spikes/_lib/experiment.py
# analyse this spike (offline):
uv run --project server python .planning/spikes/001-stroke-representation/run.py
```

Rendered fixture images are in `../_artifacts/*.png` (overlay of child blue vs reference gray).

## Investigation Trail

1. **Auth first.** Local ADC is absent; the harness mints the owner's `gcloud auth
   print-access-token` and injects it as the credential (same project/keyless posture, throwaway).
   The Vertex round-trip returned 200 — live legs run autonomously.
2. **First smoke surfaced the confound:** every representation returned the *verbatim gold-exemplar
   line* — the model parrots `COACH_PROMPT`'s GOLD EXEMPLARS rather than reading the strokes. Added
   an anti-parrot instruction (the brief's "cheap win") so the representation could actually show.
3. **With anti-parrot on,** the representations diverged sharply on geometric-localization cases.
4. **Hardened geo-diff** after it missed a tail (the tail tip corrupted an endpoint-average rim) and
   averaged away an asymmetric bowl — now rim = body start; added left/right depth split.

## Results

**VALIDATED — the model reads strokes well; `geo_diff` ≈ `points` ≫ `image`.**

Per-representation means over 15 fixtures (judge = gemini-2.5-flash, temp 0):

| representation | accuracy | specificity | hallucination rate | mean input tok | p50 latency |
|----------------|----------|-------------|--------------------|----------------|-------------|
| **geo_diff**   | 0.87     | 0.87        | **0.07**           | 1095           | 0.86s       |
| **points**     | 0.87     | 0.89        | **0.00**           | 1461           | 0.79s       |
| image          | 0.80     | 0.86        | **0.20**           | 2183           | 1.34s       |

The localization evidence (the `dotMisplaced` group — dot left / right / above):

- **geo_diff** → "the dot is a little too far to the **left**" / "too far to the **right**" / "too
  **high**" — names the actual offset every time.
- **points** → same: "too far to the left" / "too far to the right".
- **image** → softer/less reliable: often "not to the side" / "right under it" without the precise
  direction, and it produced the spike's only hallucinations (e.g. on the asymmetric bowl it
  invented "the line on the left is a little long").

**Winner: `geo_diff`** for the build. Not because it scores highest in the abstract (points edges it
on this small synthetic set) but because it is the **grounding-safest**: we compute the geometry
deterministically server-side and the model only puts it into the mother's voice — so the model has
the *least* latitude to miscompute or hallucinate. `points` is a close, viable fallback (it asks the
model to do the geometry — more room to misread on harder real strokes). **`image` is not
recommended** — highest hallucination (0.20), heaviest payload (~4× the text baseline), slowest.

**Surprise:** the multimodal image — the intuitively "richest" input — was the *worst*. A
precomputed numeric diff beats a picture here because the product needs the model to *report*
geometry, not *perceive* it.
