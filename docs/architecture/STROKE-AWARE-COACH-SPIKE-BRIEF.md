# Stroke-Aware Coaching — Spike + Architecture Brief

**Status:** Proposed — owner-approved direction, NOT yet built. Run as a GSD spike → phase.
**Owner decision:** 2026-06-30 — the owner (Rami) explicitly directed that the AI tutor
must **see the child's actual strokes** (raw stroke order + path) against the correct
reference, because the deterministic scorer's small mistake taxonomy caps how specific
the coaching can ever be. This brief scopes how to do that **correctly**.
**Authority note:** This reverses two locked "Decided" rules (see §2). The reversal is an
explicit owner call, recorded here so it is traceable — not a silent drift.

---

## 1. Why (the motivation)

Today the coach AI never sees the child's writing. It receives only the deterministic
scorer's **derived verdict** — a single `mistakeId` from a small fixed set
(`noDot`, `shallowBowl`, `hasTail`, `tooBig`, `lifted`, …) plus non-PII session facts.

Consequences observed on-device (2026-06-30, iPad):
- Feedback is **bounded by the scorer's mistake taxonomy** — it can only ever say a
  handful of things.
- The coach prompt's **GOLD EXEMPLARS are parroted verbatim** (one fixed line per
  `mistakeId`), so every "missing dot" returns the identical sentence → feels **static
  and canned**, "AI" in name only ([prompts.py](../../server/app/prompts.py) §GOLD EXEMPLARS).

Letting the model reason over the **actual stroke path vs the reference** unlocks coaching
the scorer can never express: stroke *order* ("you drew the bowl right-to-left"),
*direction*, dot *placement* ("the dot landed left of center"), *proportion*, and
sequencing ("stroke two started before stroke one finished").

---

## 2. What this reverses (flagged loudly — this is the whole reason to do it deliberately)

| Locked rule | Today | After this change |
|---|---|---|
| **GROUND-02 (privacy invariant)** — raw strokes never leave the device; only the derived verdict crosses | Raw strokes stay on-device | A child's **actual handwriting geometry** is sent to a cloud model (Vertex/Gemini) |
| **Child-data minimization** (CLAUDE.md Decided — "treat children's data as sensitive") | Minimum data sent | More data (stroke geometry) sent — must be justified + guarded |

These are real reversals. They are acceptable **only** with the safeguards in §4 and the
grounding preservation in §3. If those cannot be met, do not ship this.

---

## 3. Non-negotiables we KEEP (how grounding survives)

The richer feedback must NOT cost us the grounding safety the product is built on:

1. **The deterministic scorer stays the FROZEN judge.** It still owns pass/fail and the
   star (GROUND-01 / ADR-014). The AI sees strokes **only to explain and coach**, never to
   re-decide. A clean pass is a pass even if the AI thinks the shape is ugly; a fail is a
   fail even if the AI is charmed.
2. **The grounding guards stay.** `coach.py` G2/G3/G4 already rewrite any fail-advance /
   out-of-set / unauthored action to a grounded `say`. The new stroke input changes what
   the coach can *describe*, not its authority to *judge*.
3. **The faithfulness gate still applies** — see §6. The AI may describe the strokes but
   may never contradict the scorer's verdict (no praise-on-fail, no "you missed it" on a
   pass). This stays a zero-tolerance eval dimension.

Net: the scorer is the judge; the AI becomes a far better *explainer* of the judge's verdict.

---

## 4. Privacy & safety design (the cost of admission)

If a child's handwriting is going to a cloud model, these are mandatory:

- **Geometry only, no identifiers.** Send the normalized stroke path (resampled points,
  per-stroke, in a unit box) + the reference template. **No** child name, nickname, device
  id, or any PII alongside it (extends the existing GROUND-02 whitelist discipline).
- **No training use.** Vertex request/response logging off; the no-training-without-
  separate-verifiable-parental-consent constraint (already on the eval gold set, D-10)
  extends to live stroke payloads.
- **Minimal retention.** Strokes are transient coaching input, not stored server-side
  beyond the request (confirm Cloud Run / Vertex retention posture).
- **Parental consent must cover it.** The consent/onboarding copy must reflect that
  handwriting attempts are processed by an AI service. (Legal/owner review.)
- **Re-confirm the data is non-sensitive enough.** Letter tracings are not faces/voices,
  but the project's stance treats child data as sensitive by default — the owner signs off
  that stroke geometry under these guards is acceptable.

---

## 5. Proposed architecture (data flow)

```
WriteSurface/StrokeCanvas (child strokes, already captured for the scorer)
        │  normalize → resampled points per stroke, unit box, no PII
        ▼
client → POST /coach   { ...existing non-PII facts,
                         strokes: [[{x,y,t?}...], ...],     # NEW
                         reference: <baa template id or inline> }
        ▼
server coach node:  scorer verdict is ALREADY frozen (passed/mistakeId unchanged)
        │  give the model: child strokes + reference template + verdict
        ▼
coach model reasons over path-vs-reference → grounded, specific `say`
        │  G2/G3/G4 guards unchanged (cannot flip the verdict)
        ▼
CoachOut → client (display-only, a beat after the instant verdict)
```

Key: the `strokes` + `reference` are **new request fields**; the verdict path is unchanged.
Client↔server contract changes (schema `extra="forbid"` → both sides must land together,
the same "422 trap" we just hit — deploy server only after the Dart mirror lands).

---

## 6. Eval impact (the faithfulness premise shifts — re-anchor it)

The Phase-16 faithfulness gate assumes the AI judges nothing (it only maps a verdict to a
line). Once the AI describes geometry, the eval must check a new failure mode:

- **Still zero-tolerance:** never praise-on-fail, never contradict the frozen verdict.
- **New checks:** the stroke *description* must be accurate (no hallucinated "your dot is
  too high" when there is no dot at all), and must stay consistent with `mistakeId`.
- The gold set + judge rubric (Phase 16) grow to cover stroke-level coaching, re-signed by
  the owner's mother (register authority).

---

## 7. The SPIKE — what to prove before committing to build it

Throwaway harness, no production wiring. Hypotheses:

1. **Quality:** AI-sees-strokes coaching is meaningfully *better and more varied* than the
   current label-based coaching, scored on the eval dimensions (specific-fix, register,
   correct-Arabic) — measured, not vibes.
2. **Grounding holds:** with strokes in hand, the model still never contradicts the frozen
   verdict (faithfulness stays 100% on the adversarial probes).
3. **Representation:** which stroke representation works best for the model —
   (a) a rendered **image** of child-vs-reference (multimodal), (b) **structured points**
   (JSON path), or (c) a precomputed **geometric diff** (angles, order, dot offset). Decide
   by experiment.
4. **Latency/cost:** the heavier payload + reasoning stays within the presence budget
   (the instant reflex is local; the spoken line a beat later — current ~2s warm).
5. **Privacy acceptable:** the §4 guards are achievable on Vertex/Cloud Run.

**Spike success criterion:** a written, evidence-backed verdict — does stroke-aware coaching
clearly beat the status quo on the eval, with grounding intact and latency/privacy
acceptable? Pass → build it as a phase. Fail/weak → keep the scorer-bounded coach and just
fix the verbatim-exemplar prompt (the cheap win).

---

## 8. Open research questions

- Does the chosen coach model (Gemini-2.5-flash, or Claude-on-Vertex if Enabled) reason
  well over stroke geometry / a rendered image? (Spike H3.)
- Best normalized stroke format (resampling rate, time included?, per-stroke vs merged).
- Reference representation: the authored stroke template per letter form — does it exist in
  a model-consumable shape, or must we render it?
- Retention/no-training guarantees on Vertex for live (not just eval) payloads.
- Consent copy + any legal review for sending child handwriting to an AI service.

---

## 9. Suggested GSD path

1. **`/gsd-spike`** — build the throwaway harness, run §7, write the verdict.
2. If the spike passes → **`/gsd-discuss-phase`** then **`/gsd-plan-phase`** for a build
   phase: the new `strokes`/`reference` contract (client + server in lockstep), the
   stroke-aware coach prompt, the grounding-guard re-verification, the eval growth + mom
   re-sign-off, and the privacy/consent work.
3. Record the final decision as an **ADR** (this brief becomes its input), since it reverses
   GROUND-02.

---

## Interim cheap win (independent of this spike)

Even without strokes, the current coach is worse than it needs to be because it **copies the
gold exemplars verbatim**. A focused prompt rework — exemplars as *register guidance to
emulate, never to copy*; generate fresh wording; vary with `trajectory`/`recentMistakes`/
`struggleTags` — would make today's coach feel far less static, server-side + redeploy. This
is a small, separable improvement that can ship before the stroke-aware spike if desired.
</content>
