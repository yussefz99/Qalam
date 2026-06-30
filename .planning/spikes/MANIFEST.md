# Spike Manifest

## Idea

**Stroke-aware coaching** — should the AI tutor *see the child's actual strokes* (raw path + order vs
the authored reference) so it can coach the specific thing this child did, instead of being bounded by
the deterministic scorer's small `mistakeId` taxonomy? This reverses two LOCKED "Decided" rules
(GROUND-02 raw-strokes-never-leave-device + child-data minimization) — an explicit owner call recorded
in `docs/architecture/STROKE-AWARE-COACH-SPIKE-BRIEF.md`. The spike proves (or refutes) the §7
hypotheses on a throwaway harness before any production wiring, and returns an evidence-backed verdict:
**build it as a phase, or keep the scorer-bounded coach and just fix the verbatim-exemplar prompt.**

## Requirements (emerged during spiking — non-negotiable for the real build)

- **Representation = precomputed `geo_diff`** (server computes the geometry; the model only verbalizes
  it). Grounding-safest + cheapest + fastest. `points` is the fallback; **`image` is rejected**
  (highest hallucination, ~4× payload, slowest).
- **The scorer stays the frozen judge.** Strokes are input to the *explainer* only; G2/G3/G4 guards
  stay. Grounding held in the spike (0 advance-on-fail, 0 praise-on-fail in stroke arms).
- **The eval must go semantic before relying on the gate.** The model-free D1/D2 *substring*
  faithfulness check (`app/faithfulness.py`) false-flags correct paraphrases and will fail varied
  wording — stroke-aware OR the cheap-win prompt fix. Add a "do-not-assert-false-geometry" check.
- **Ship the cheap-win prompt fix independently** (exemplars as register guidance, never copied) — it
  is free, needs no privacy reversal, and removes the canned-parrot feel on its own.
- **Privacy reversal is bounded:** geometry-only/no-PII whitelist replacing `extra="forbid"` (client+
  server in lockstep — the 422 trap); no-training + logging-off is already the posture; consent copy +
  legal review are build gates.

## Spikes

| # | Name | Type | Validates | Verdict | Tags |
|---|------|------|-----------|---------|------|
| 001 | stroke-representation | comparison (image/points/geo_diff) | model reads strokes accurately, which encoding is best | **VALIDATED — geo_diff ≈ points ≫ image** | representation, multimodal |
| 002 | grounding-under-strokes | standard | model never contradicts the frozen verdict with strokes in hand | **VALIDATED — grounding holds (0/0); drop is an eval artifact** | grounding, faithfulness |
| 003 | quality-bakeoff | standard | stroke-aware beats status quo + cheap win on specificity/variety | **VALIDATED — beats status quo; beats cheap-win on localization** | eval, specificity, variety |
| 004 | latency-cost | standard | stroke-aware fits the ~2s warm presence budget | **VALIDATED — geo_diff p50 0.86s; image borderline** | latency, cost |
| 005 | privacy-guards | desk-check | §4 guards achievable on Vertex/Cloud Run | **PARTIAL — achievable; consent+contract are build gates** | privacy, GROUND-02 |

## Overall verdict

**BUILD IT** as a phase, using `geo_diff` — stroke-aware coaching clearly and measurably beats the
status quo on attempt-specificity and variety, with grounding intact and latency/privacy acceptable.
**AND ship the cheap-win prompt fix now**, independently — it is the single biggest cheap improvement
and a prerequisite either way. Conditions: (1) representation = geo_diff; (2) upgrade the eval
faithfulness from substring → semantic + add the false-geometry check; (3) the §2/§4 privacy +
contract-reversal work lands. Full reasoning in `SPIKE-FINDINGS.md`.

## How it was built (throwaway harness)

Shared lib in `_lib/` (synthetic baa fixtures from the real `assets/curriculum/letters.json`
reference — NO real child data; three representations; injected-user-cred Vertex client; the two
coaches reusing the production `COACH_PROMPT` + ACTION tools; scoring reusing `app/faithfulness.py` +
the production `JUDGE_RUBRIC.md`). One model pass (`_lib/experiment.py`, ~375 Vertex calls, ~64s) →
`_artifacts/results.json`; each spike's `run.py` analyses it offline. Fully additive + deletable.
