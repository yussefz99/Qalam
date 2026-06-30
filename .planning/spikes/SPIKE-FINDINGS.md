# Spike Findings — Stroke-Aware Coaching

**Date:** 2026-06-30
**Decision authority:** owner (Rami), on the evidence below + `docs/architecture/STROKE-AWARE-COACH-SPIKE-BRIEF.md`
**Input to:** an ADR (this reverses GROUND-02 — it must be recorded as a decision, per the brief §9.3)

## GATE: BUILD IT (geo_diff) — and ship the cheap-win prompt fix now, independently

Stroke-aware coaching **clearly and measurably beats the status quo**: given the child's actual
strokes, the tutor names the specific thing *this* child did — "the dot landed too far left," "the
right side of the bowl is flat" — feedback the deterministic scorer's small `mistakeId` set can never
express. Grounding held (the model never contradicted the frozen verdict), latency fits the presence
budget, and the privacy guards are achievable. This is a confident GO, with three conditions.

But the spike also found the **single biggest, cheapest win is independent of strokes**: today's coach
is worse than it needs to be because it **copies the GOLD EXEMPLARS verbatim**. Fixing that prompt
(exemplars as register to *emulate*, never to copy) removes the canned feel for *zero* new
architecture and *zero* privacy reversal. **Ship that first, regardless.**

## What we proved (5 spikes, 1 throwaway harness, ~375 live Vertex calls)

| H | Question | Verdict |
|---|----------|---------|
| H3 | Can the model read strokes, and in what form? | **YES — `geo_diff` ≈ `points` ≫ `image`.** A precomputed geometry diff (we compute, the model verbalizes) is accurate (0.87), specific (0.87), and barely hallucinates (0.07). The multimodal **image was the worst** (0.20 hallucination, ~4× payload, slowest) — the intuitively-richest input lost. |
| H2 | Does grounding survive once the model sees strokes? | **YES.** Across all arms: **0 advance-on-fail, 0 praise-on-fail in every stroke-aware arm**, even on adversarial cases where the strokes contradict the verdict. The scorer stays the judge; the AI only explains. |
| H1 | Is stroke-aware actually better + more varied? | **YES, with nuance.** It produces distinct, attempt-specific lines where the label collapses different errors (5/5 distinct shallow-bowl lines vs 1/5 for status quo; localizes dot left/right/above). It beats the *cheap-win prompt fix* specifically on **geometric localization** — which the cheap win provably cannot do. |
| H4 | Does it fit the ~2s warm presence budget? | **YES for geo_diff** (p50 0.86s, max 1.77s, ~1100 input tokens, ~25 output). `image` is borderline. Cost is a fraction of a cent/call. |
| H5 | Are the §4 privacy guards achievable? | **PARTIAL — achievable; two build gates remain.** No-training + logging-off + no-PII are already the project's posture (no Vertex prediction-logging sink exists). Consent copy + the contract reversal are build-phase work, not blockers. |

## The most important surprise (changes the build plan)

The brief's §6 prediction — *"the faithfulness premise shifts"* — is real and now measured. The
faithfulness *rate* appeared to drop in the varied arms (0.55–0.73 vs 0.91), which looks like a
grounding regression. It is not. The drop is almost entirely the **model-free D1/D2 substring gate
false-flagging correct paraphrases** ("deeper bowl" instead of the literal token "deeper curve";
"one smooth stroke" instead of "join"). The real verdict-contradiction count in the stroke arms was
**zero**.

**Implication:** the current `app/faithfulness.py` substring gate is incompatible with *any* varied
coaching — stroke-aware OR the cheap-win prompt fix. Before the gate can be trusted, it must move from
substring → **semantic** (judge-based, or a much broader expected-fix synonym set), and gain a new
check the spike surfaced: **"do not assert false geometry"** (on `adv_broken_but_pass` — a flat bowl
that the scorer passed — some arms invented "a deep, smooth bowl"). This is a precondition for the
build, and it equally protects the cheap win.

## Conditions for the build (carry into discuss-phase / plan-phase)

1. **Representation = precomputed `geo_diff`.** Server computes the geometry (bowl depth + left/right
   symmetry, dot offset/quadrant, tail, size, direction); the model only puts it in the mother's
   voice. Lowest hallucination surface, cheapest, fastest. `points` is the fallback. **Drop `image`.**
2. **Upgrade the eval before relying on the gate.** D1/D2 substring → semantic faithfulness; add the
   false-geometry check; regrow the gold set for stroke-level coaching and re-sign with the owner's
   mother (register authority). Until then the judge is advisory (as today).
3. **Privacy/contract reversal (§2/§4).** Replace the server's `extra="forbid"` with an explicit
   `strokes`/`reference` whitelist — client + server in **lockstep** (the 422 trap, hit before).
   Consent/onboarding copy must state handwriting is processed by an AI service (owner/legal). Record
   the GROUND-02 reversal as an ADR.

## What ships immediately, no phase needed

The **cheap-win prompt fix**: in `server/app/prompts.py`, reframe the GOLD EXEMPLARS as *register
guidance to emulate, never copy*; instruct fresh wording varied by `trajectory`/`recentMistakes`/
`struggleTags`. Server-side + redeploy. (Pair it with the eval upgrade so it doesn't trip the
substring gate.) This is separable from, and a prerequisite for, the stroke-aware build.

## Why this is a confident GATE, not an inconclusive one

The harness reused the production prompt, tools, faithfulness check, and judge rubric, so the numbers
map to `make eval`. The confound (exemplar parroting) was caught and controlled with a clean 3-arm
design (status quo / cheap-win / stroke-aware) that isolates the marginal value of *strokes* from the
value of *fixing the prompt*. Fixtures are synthetic perturbations of the real authored baa reference
— no child data. The one weakness — synthetic strokes, baa-only, single sample/fixture, local-cred
Vertex latency — bounds the *confidence*, not the *direction*: the direction (geo_diff reads strokes,
grounding holds, image loses, the eval must go semantic) is consistent and strong.

## Hand-off

- **Next GSD step:** `/gsd-discuss-phase` → `/gsd-plan-phase` for the build (the `strokes`/`reference`
  contract, the geo_diff coach prompt, the eval upgrade + mom re-sign-off, the privacy/consent work),
  per brief §9.2. Record the GROUND-02 reversal as an ADR (brief §9.3).
- **Independent quick win:** the prompt fix above (own `/gsd-quick`).
- **Reproduce:** `uv run --directory server --with pillow python .planning/spikes/_lib/experiment.py`
  then `.../001-stroke-representation/run.py` (and 002–004). Deletable: remove `.planning/spikes/`
  additions; no durable app code was touched.
