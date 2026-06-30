---
spike: 003
name: quality-bakeoff
type: standard
validates: "Given the eval set, when stroke-aware coaching is scored against the label-only status quo (and the cheap-win prompt fix) on the four eval dimensions + specificity/variety, then stroke-aware is meaningfully better and more varied."
verdict: VALIDATED
related: [001, 002]
tags: [stroke-aware, eval, bake-off, specificity, variety, register]
---

# Spike 003: Quality Bake-off — Stroke-Aware vs Status Quo vs Cheap-Win

## What This Validates

The core value (H1): does seeing strokes actually produce *better, more varied, still-grounded*
coaching than today's label-bounded coach? Critically, the bake-off isolates the **marginal value of
strokes** from the **value of just fixing the verbatim-exemplar prompt** (the brief's "cheap win"),
because the first smoke test showed the prompt confound dominates everything.

## Research — the three arms

| arm | prompt | sees strokes? | what it isolates |
|-----|--------|---------------|------------------|
| **A** label_verbatim    | production `COACH_PROMPT` (with GOLD EXEMPLARS) | no | the TRUE status quo |
| **B** label_anti_parrot | + "exemplars are register, never copy" | no | the CHEAP WIN alone |
| **C** stroke_aware      | + anti-parrot + a representation (geo_diff/points/image) | **yes** | strokes on top of B |

Same model (gemini-2.5-flash, temp 0.5 = production coach temp), same ACTION-tool binding, same
judge (gemini-2.5-flash, temp 0) against the production `JUDGE_RUBRIC.md`. A→B = value of the prompt
fix; **B→C = value of the strokes.**

## How to Run

```bash
uv run --project server python .planning/spikes/003-quality-bakeoff/run.py
```

## Investigation Trail

1. Status-quo (A) parrots: identical canned line for *every* shallowBowl and *every* dot problem.
2. The cheap win (B) freshens wording and lifts register — but is **geometrically blind**: it still
   can't tell `dot_left` from `dot_right`, or a right-side-flat bowl from a uniformly shallow one.
3. Stroke-aware (C) names the actual attempt: left/right/above, which side is flat.

## Results

**VALIDATED — stroke-aware clearly beats the status quo; and it adds a capability the cheap win
provably cannot.**

**Variety** — distinct lines within a same-mistakeId group (the crux):

| mistake group (n) | A verbatim | B cheap-win | C points | C geo_diff | C image |
|-------------------|-----------|-------------|----------|------------|---------|
| shallowBowl (5)   | **1**     | 2           | 5        | 4          | 5       |
| dotMisplaced (3)  | 2         | 3           | 3        | 3          | 3       |
| noDot (2)         | 1         | 2           | 2        | 2          | 2       |

Raw distinctness rises with B already (the cheap win helps). But **content** is the real story:

- A & B for `dot_left` / `dot_right` / `dot_above`: *all* say a generic "place the dot under the
  middle / below it." They **cannot** localize — they only have the label `dotMisplaced`.
- C says: "the dot is too far to the **left**", "too far to the **right**", "too **high**"; and for
  the asymmetric bowl, "needs to be deeper **on the right side**." Only strokes carry this.

**Judge means** (fails, core+variety, n=11/arm):

| arm | accuracy | specificity | register | correct_arabic | hallucination |
|-----|----------|-------------|----------|----------------|---------------|
| A verbatim    | 0.89 | 0.87 | 0.94 | 1.00 | 0.00 |
| B cheap-win   | 0.91 | 0.90 | 0.91 | 1.00 | 0.00 |
| C points      | 0.91 | **0.92** | 0.93 | 1.00 | 0.00 |
| C geo_diff    | 0.91 | 0.87 | 0.92 | 1.00 | 0.00 |
| C image       | 0.73 | 0.87 | 0.85 | 1.00 | **0.27** |

**The honest decision picture:**

- The **single biggest, cheapest win is the prompt fix (B)** — it kills the canned-parrot feel for
  *zero* new architecture and *zero* privacy reversal. Ship it regardless of the stroke-aware call.
- **Stroke-aware (C, geo_diff/points) adds a distinct, real increment on top of B**: attempt-specific
  geometric localization (which side, where the dot landed) that B *structurally cannot* produce. The
  gain is concentrated in dot-placement and asymmetry cases — exactly where one coarse `mistakeId`
  collapses several genuinely different errors.
- Register and correct-Arabic stay high across all arms (correct_arabic = 1.0 everywhere). The
  numeric register averages are similar (the judge rewards warmth, which all arms have); the
  difference the child feels is **specificity**, which only strokes make concrete.

So H1 is supported with nuance: **stroke-aware beats the status quo decisively, and beats the cheap
win specifically on geometric localization** — at the cost of the §2 privacy reversal and the §6
eval upgrade. The recommended representation is `geo_diff` (see 001).
