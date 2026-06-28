# Phase 16: BUILD — presence + voice + eval gate + demo-harden - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-29
**Phase:** 16-build-presence-voice-eval-gate-demo-harden
**Areas discussed:** Spike fold-in (12 & 13), How the tutor speaks, Eval regression gate, Demo-harden + demo path

---

## Spike fold-in (Phases 12 & 13)

| Option | Description | Selected |
|--------|-------------|----------|
| Fold lean versions in | Measure latency on the Pixel Tablet while demo-hardening + run a small Claude-vs-Gemini coach comparison on the EVAL-01 harness. No separate phases. | ✓ |
| Define inline by judgment | Pick a target budget + keep AI-SPEC default coach, no formal measurement/bake-off. | |
| Run 12 & 13 first, separately | Two quick spikes as their own phases before the finale. | |

**User's choice:** Fold lean versions in.
**Notes:** The "de-risk on the live system" the roadmap intended, done in-phase on the Technion timeline.

### Coach-model finalization (sub-question)

| Option | Description | Selected |
|--------|-------------|----------|
| Eval data decides, Claude default | Default claude-haiku-4-5; eval scores can override to Gemini. | |
| Lock Claude now | Commit to Claude, bake-off is confirmation only. | |
| Optimize for cost/latency | Prefer Gemini Flash unless quality clearly worse. | |
| **Other (free text)** | "prioritize the best models with arabic and use vertex ai" | ✓ |

**User's choice (free text):** Prioritize the best models for Arabic register, and route through Vertex AI.
**Notes:** Reflected back and confirmed via a follow-up — ALL nodes (analyze/plan/coach) route
through Vertex AI, keyless on Technion credits, no Anthropic key in Secret Manager. Coach = the
best-Arabic model available on Vertex per the eval. Research must confirm Claude Haiku 4.5's Vertex
Model Garden reachability in-region, else fall back to best Vertex-available Claude, or Gemini if it
wins the Arabic eval. (Chosen over "allow a keyed-Anthropic fallback" and "Gemini-only on Vertex".)

---

## How the tutor speaks (PRES-02)

### Voice engine

| Option | Description | Selected |
|--------|-------------|----------|
| On-device TTS | flutter_tts; voices the offline floor too; lowest first-TTS latency; no cloud cost. | ✓ |
| Cloud TTS via Vertex/Google | Premium neural voice; adds a round-trip; can't voice dynamic lines offline. | |
| Hybrid | On-device floor + cloud when online; best feel, most work. | |

**User's choice:** On-device TTS.

### Voice rhythm

| Option | Description | Selected |
|--------|-------------|----------|
| Speaks on both pass & miss, trailing the visual | Two clocks: instant silent visual, spoken line a beat later, on pass and miss. | ✓ |
| Speaks only on a miss | Quiet on clean passes. | |
| Stream text token-by-token + TTS as it arrives | Full SSE streaming + incremental TTS; most engineering. | |

**User's choice:** Speaks on both pass & miss, trailing the visual.
**Notes:** Whole short line spoken; text streaming optional. flutter_tts needs the package-legitimacy
checkpoint; mixed English+Arabic locale-switching is a known pitfall to research.

---

## Eval regression gate (EVAL-01 / EVAL-02)

### Gate form

| Option | Description | Selected |
|--------|-------------|----------|
| Local pre-merge script, faithfulness zero-tolerance | `make eval`/pytest run before merge; faithfulness fails the build on any contradiction. | ✓ |
| GitHub Actions CI on every PR | Auto-runs in CI; needs CI plumbing + Vertex auth in CI. | |
| Both — one script, CI runs it too | CI-portable script; most complete, more upfront work. | |

**User's choice:** Local pre-merge script, faithfulness zero-tolerance.

### Quality scoring (register + correct-Arabic)

| Option | Description | Selected |
|--------|-------------|----------|
| Vertex LLM-judge, calibrated to a mom-signed gold set | Claude drafts gold examples, mother signs; Vertex judge scores register + Arabic; faithfulness stays model-free. | ✓ |
| Human spot-check for register, automate only faithfulness | Register stays a manual pre-demo review; not a true regression gate. | |
| Faithfulness-only gate | Register/Arabic tracked but never block; under-delivers EVAL-01. | |

**User's choice:** Vertex LLM-judge, calibrated to a mom-signed gold set.
**Notes:** Mirrors the curriculum sign-off pattern (model drafts, mother signs). Faithfulness =
zero-tolerance hard gate; register/Arabic = threshold.

---

## Demo-harden + demo path (DEMO-01)

### Demo posture

| Option | Description | Selected |
|--------|-------------|----------|
| Live online agent + warm-up ping + invisible floor | Real agent; session-start warm-up ping kills cold-start; AuthoredFallback auto-takes-over on timeout/drop. | ✓ |
| Offline-floor only | Bulletproof but only the deterministic walker + authored lines; undersells v2. | |
| Live, with a one-tap manual fallback | Online + presenter control to switch to offline; more presenter burden. | |

**User's choice:** Live online agent + warm-up ping + invisible floor.

### Hero moment

| Option | Description | Selected |
|--------|-------------|----------|
| Grounded adaptivity: struggle → backward remediation + spoken fix + star | Seeded wobble → tutor re-surfaces an easier exercise, speaks the fix, earns one quiet star. | ✓ |
| Grounding guarantee front-and-center | Wrong-order attempt → right fix, never fakes a pass; strong for a technical audience. | |
| Clean successful walkthrough | Smooth pass-everything run; safe but doesn't show adaptivity/grounding. | |

**User's choice:** Grounded adaptivity (backward remediation + spoken fix + star).
**Notes:** Needs a reliable seeded demo state so the moment fires on cue. The grounding guarantee is
a strong second beat for the Technion staff.

---

## Claude's Discretion

- Exact latency budget numbers (from on-device measurement); whether to add SSE text streaming;
  the warm-up-ping mechanism + timing; the seeded-demo-state mechanism; the LLM-judge prompt/rubric
  + gold-set size & format; whether to add a one-tap manual demo fallback; flutter_tts config
  (voice/rate/pitch/locale switching); the eval-gate harness shape; Riverpod wiring; latency
  instrumentation placement.

## Deferred Ideas

- Premium/cloud TTS voice (future voice-quality upgrade).
- Token-by-token text streaming + incremental TTS (optional; whole-line is baseline).
- GitHub Actions CI for the eval gate (local pre-merge now).
- One-tap manual demo fallback control (optional belt-and-suspenders).
- On-device GemmaBrain coach backend (TUTOR-04 — stays deferred; swappable seam preserved).
- Voice input / STT (S2-03), cross-letter ب/ت/ث contrast unit, parent struggle-analytics (out of v2.0 scope).
