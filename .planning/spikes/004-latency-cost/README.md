---
spike: 004
name: latency-cost
type: standard
validates: "Given the winning representation, when the stroke-aware coach round-trips on Vertex, then it stays within the ~2s warm presence budget (the spoken line a beat after the local instant reflex), at acceptable cost."
verdict: VALIDATED
related: [001, 003]
tags: [stroke-aware, latency, cost, presence-budget, vertex]
---

# Spike 004: Latency & Cost

## What This Validates

H4: the heavier stroke payload + reasoning must fit the presence budget. Per Phase-12/16: the
millisecond stroke reflex stays **local**; the *spoken* coaching line lands a beat later, target
**~2s warm**. Does sending strokes blow that?

## Research / Method

Latency is measured around the live `model.invoke` in `_lib/coaches.py` (warm calls — the experiment
runs 75 calls concurrently, so the pool is warm). Token counts come from Gemini's `usage_metadata`.
This is a *local-harness* number (user-cred Vertex from a laptop), not the Cloud Run number — treat
it as a **lower bound on the relative cost between representations**, not the production absolute. The
production path adds Cloud Run + auth + the analyze/plan nodes; Phase-12's on-device budget is the
real gate.

## How to Run

```bash
uv run --project server python .planning/spikes/004-latency-cost/run.py
```

## Results

**VALIDATED for `geo_diff` and `points`; `image` is borderline on tail latency + cost.**

| arm | p50 latency | max latency | mean input tok | mean output tok |
|-----|-------------|-------------|----------------|-----------------|
| A label_verbatim    | 0.81s | 1.65s | 569  | 18 |
| B label_anti_parrot | 0.84s | 1.90s | 644  | 21 |
| C points            | 0.79s | **2.94s** | 1461 | 23 |
| C geo_diff          | **0.86s** | 1.77s | 1095 | 25 |
| C image             | 1.34s | 2.89s | 2183 | 22 |

Findings:

- **`geo_diff` is the sweet spot:** p50 0.86s, max 1.77s, ~1095 input tokens (≈2× the text baseline).
  Comfortably inside the ~2s warm budget on its own leg.
- **`points`** has a similar p50 but a fatter tail (one 2.94s call) — sending raw coordinate arrays
  costs more tokens (1461) and the model does more work.
- **`image`** is the heaviest: p50 1.34s, ~2183 input tokens (≈4× baseline), and a 2.89s tail.
  Combined with its hallucination rate (001), it is not recommended.
- **Output is tiny everywhere** (~20–25 tokens) — coaching is one short line, so output cost is
  negligible; the cost variable is the *input* payload, which `geo_diff` keeps modest.

**Cost:** at Gemini-2.5-flash-on-Vertex pricing, ~1100 input + ~25 output tokens/call is a fraction
of a cent — well inside the per-session budget. The strokes do not change the cost story materially
for `geo_diff`.

**Caveat (must verify at build):** the absolute ~2s budget is the *deployed* stroke→scorer→agent→
render→first-TTS path on a real Pixel Tablet (Phase-12). This spike only shows the **Vertex coach
leg is cheap and well within budget for geo_diff**, and that strokes don't blow it up. The end-to-end
device number is a build-phase measurement, not proven here.
