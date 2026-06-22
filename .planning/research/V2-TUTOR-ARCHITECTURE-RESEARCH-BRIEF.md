# Research Brief — v2 AI-Tutor Agent Architecture & Protocol Choice

> **Status:** PREP (not yet executed). This brief defines *what* to research and *how*,
> so the actual research run produces a confident, evidence-backed architecture decision.
> Prepared 2026-06-21. Owner approves scope before execution.

---

## 0. Why this research exists

We are about to build the v2 AI tutor (Phases 14–16). The Phase 11 spike already
de-risked the GenUI/native-canvas hosting question and leaned us toward "raw
`firebase_ai` function-calling + native dispatcher." Before we commit Phase 14 to that,
the owner wants to be sure we are not missing a better-fit approach the ecosystem has
converged on — specifically **AG-UI**, the **Google agent ecosystem**, and **what new
startups actually ship** for this kind of mission. This is a "research before you build"
gate (CLAUDE.md), and the answer reshapes Phase 14.

## 1. The decision this research must produce

A single, defensible recommendation for the v2 tutor's **agent architecture**, covering:
1. **Topology** (the hinge — see §2).
2. The **agent reasoning/loop** mechanism (how the model reasons + calls our 4 ACTION tools).
3. The **agent↔UI** mechanism (how decisions reach the Flutter widgets).
4. The **on-device / offline** story (Gemma, hybrid inference, the AuthoredFallback floor).

**Deliverables:** a scored comparison matrix (§4), a recommended architecture, an ADR in
`docs/architecture/`, and concrete inputs to the Phase 14 plan. Plus explicit "revisit
triggers."

## 2. THE central fork — topology (everything hinges on this)

Grounding finding: **AG-UI (CopilotKit), A2UI (Google), and MCP (Anthropic) are
complementary, not competing** — the 2026 pattern is "MCP to call tools, A2UI to describe
UI, AG-UI to push updates to the frontend." **But all three presuppose an agent
backend/runtime** the frontend connects to. We deliberately deferred that server. So the
real question is topology:

- **Path A — Client-only (current decision).** Flutter calls Gemini/Gemma directly via
  Firebase AI Logic (which now offers *hybrid* on-device/cloud inference). The agent loop
  is a small Dart function-calling loop + a native dispatcher mapping tool calls to widget
  actions. No AG-UI/A2UI/MCP needed (they have nothing to connect to). Simplest, no-server,
  lowest cost, offline-capable, lowest latency. Risk: we hand-roll orchestration; limited
  multi-step sophistication.
- **Path B — Thin agent backend.** A small server (Cloud Run/Function) runs an agent
  framework (LangGraph / Google ADK / Genkit) and speaks **AG-UI** (a community Dart SDK
  exists) to the Flutter app; can use **MCP** for tools and **A2UI** for generative UI.
  This is where the ecosystem + startups converge. Cost: reintroduces the deferred server,
  adds network latency to every coaching turn, more moving parts, more to demo-harden on a
  Technion timeline.
- **Path C — Hybrid / staged.** Ship Path A for the Technion demo (reflex + simple loop),
  but design the `TutorBrain` seam so a Path-B backend can slot in later without touching
  the canvas/scorer. (The deferred-server note in PROJECT.md already gestures at this.)

**The research must pick a topology with eyes open, and only then evaluate protocols that
fit it.** The no-server decision is *deferred, not forbidden* — it is in scope to revisit
IF the evidence strongly favors a backend, weighed against cost/latency/timeline.

> ⚠️ Naming correction to research the right things: **AG-UI = CopilotKit** (agent→frontend
> event stream, 17 event types, SSE/WS/HTTP, has a *community* `ag_ui` Dart SDK on pub.dev).
> **A2UI = Google** (the surface/catalog protocol GenUI uses — we already spiked it in
> Phase 11). They are now being *bridged* (CopilotKit AG-UI ↔ A2UI). The owner referred to
> "ag-ui from the Google ecosystem" — research BOTH, and keep them distinct.

## 3. Candidate landscape to evaluate

### Layer 1 — Agent reasoning / orchestration
- **Raw `firebase_ai` function-calling (Dart client)** — current lean; client-only.
- **Flutter AI Toolkit** (official Flutter) — function calling, Gemini + Vertex.
- **Google Genkit** — does it have a usable Dart/client story, or is it server-only (JS/Go/Python)?
- **Google ADK (Agent Development Kit)** — server (Python/Java); pairs with A2A/A2UI.
- **LangGraph** — server (Python/JS); 2026 #1 for stateful agents; no Dart client.
- **Claude Agent SDK** — server; **Claude is ruled out for our client** (note as out-of-scope, confirm).
- **Vercel AI SDK** — JS/web; generative UI via RSC; no Flutter.

### Layer 2 — Agent ↔ UI mechanism
- **Raw function-calling + native dispatcher** — current lean; no protocol.
- **AG-UI (CopilotKit)** — Dart SDK exists; needs an agent backend (Path B).
- **A2UI / GenUI (Google)** — already spiked (Phase 11); leaning "drop" — re-confirm against this wider frame.
- **MCP (Anthropic)** — agent↔tools/context; relevant to our 4 tools, or overkill for a fixed curriculum?

### Layer 3 — On-device / offline
- **`flutter_gemma`** — mature; Gemma 4 / 3n, native function calling, GPU accel, many small models (FunctionGemma 270M).
- **Firebase AI Logic hybrid inference** — on-device-when-available, seamless cloud fallback (Dart SDK). Could it *unify* GeminiBrain + GemmaBrain + offline floor under one seam?
- **Gemini Nano / AICore** — Android on-device; availability/coverage on target tablets?

## 4. Decision matrix (score every applicable candidate)

| Criterion | Why it matters to Qalam |
|---|---|
| Flutter/Dart support | first-class / community / none — a great protocol with no Dart story is a dead end |
| No-server fit / server cost | our strong preference; Technion has no ops budget |
| Gemini + Gemma + hybrid inference | the decided model set; offline floor |
| Grounding-invariant support | can it cleanly do FACTS-in / ACTIONS-out, scorer-owns-verdict (GROUND-01/02)? |
| Offline floor | graceful zero-model degrade (TUTOR-02) |
| Latency on a Pixel Tablet (+TTS/stream) | PRES-01 budget; per-turn network cost of Path B |
| Child-safety / non-PII enforceability | only mistakeId/struggle-tags/letterId may cross the wire (GROUND-02) |
| Real-time native canvas hosting | the Pitfall-1 lesson — keep the canvas out of any reactive rebuild scope |
| Maturity / churn risk | pre-1.0 bit us (genui 0.9.2); how stable is each? |
| Ecosystem momentum / longevity | are we building toward where things are going, or a dead end? |
| Migration path | can we start simple (Path A) and grow into Path B without ripping out the canvas/scorer? |
| Fit to timeline + "low magic" | Technion deadline; owner is new to Dart, wants explainable code |

## 5. Specific questions the research must answer

- **AG-UI:** Can the `ag_ui` Dart SDK do anything useful *without* an agent backend? What
  concretely would it buy a client-only Qalam vs. a hand-rolled dispatcher? Maturity of the
  *community* Dart SDK? What does the AG-UI↔A2UI bridge change for a Flutter app?
- **A2UI/GenUI (re-litigate the spike):** Given the wider frame, is "drop" still right? Does
  any 2026 GenUI release fix the canvas-State-teardown risk we saw?
- **MCP:** Useful for our 4 ACTION tools / scorer-facts, or overkill for a fixed-curriculum,
  no-external-tools tutor?
- **Firebase AI Logic hybrid inference:** Can ONE seam serve cloud-Gemini + on-device-Gemma +
  offline floor? Does it support function-calling on both paths? This could collapse three of
  our backends into one.
- **flutter_gemma function-calling:** Is on-device Gemma's function-calling good enough to run
  our 4-tool loop, in Arabic, grounded? (Overlaps Phase 13 bake-off — coordinate, don't dup.)
- **Path B reality:** What's the *smallest* viable agent backend (LangGraph/ADK/Genkit) that
  speaks AG-UI to Flutter, and its true cost/latency/ops burden on a Technion timeline?
- **"What do startups actually ship for a Flutter mobile agent?"** Separate the React/web hype
  (CopilotKit, Vercel AI SDK, assistant-ui) from what mobile/Flutter teams ship (firebase_ai,
  Flutter AI Toolkit, flutter_gemma). Find real Flutter case studies, not React demos.

## 6. Constraints the research MUST respect (non-negotiables)

- Client-side first; **Gemini/Gemma, not Claude** (no client Claude path); key never in client
  (Firebase AI Logic + App Check, enforced in prod).
- **Grounding invariant:** deterministic scorer owns pass/fail + star; agent owns words; only
  derived non-PII facts cross the wire.
- **Offline floor** (AuthoredFallback) must always exist.
- Local **Drift** for progress (no Firestore child data); **Android Flutter**; **Riverpod**;
  anti-gamification (one quiet star); **baa-only** v2 scope; **reuse v1 durable layers untouched**.
- Open to revisiting **no-server** ONLY if evidence is strong; weigh cost/latency/timeline.

## 7. Sources & method (and how to stay honest)

- **Primary, recency-checked:** official docs (Firebase AI Logic, flutter_gemma, AG-UI docs,
  A2UI/GenUI, ADK, Genkit, MCP), GitHub repos (commit recency — these ship ~monthly), pub.dev
  (the real Dart-support truth, version + popularity).
- **Reuse:** Phase 11 `11-RESEARCH.md` already researched firebase_ai/function-calling/A2UI —
  start there, don't redo it.
- **Skeptical secondary:** 2026 "best agent framework" blogs are mostly React/Python/server —
  treat as signal about ecosystem direction, NOT as Flutter guidance. Verify every "supports
  Flutter" claim against pub.dev + a real example.
- **Adversarial check:** before finalizing, a reviewer agent tries to *refute* the recommended
  topology (find the case where it fails on latency, offline, child-safety, or timeline).

## 8. How we'll run it (execution plan)

Parallel research agents, one per cluster, each returning a structured findings doc; then a
synthesis + adversarial verification:
1. **Topology & ecosystem** — Path A vs B vs C; AG-UI/A2UI/MCP applicability; startup practice.
2. **Client-only agent loop** — firebase_ai + Flutter AI Toolkit function-calling; the 4-tool
   loop + native dispatcher; grounding seam.
3. **On-device/offline** — flutter_gemma + Firebase hybrid inference; can one seam unify the
   three backends? (coordinate with Phase 13.)
4. **AG-UI / Path-B deep dive** — the Dart SDK reality + smallest viable backend + true cost.
5. **Synthesis + adversarial verify** — fill the matrix (§4), recommend, write the ADR, refute it.

Output lands in `.planning/research/v2-tutor-architecture/` + an ADR. Then it feeds the Phase 14
plan (and may adjust Phases 12/13 scope).

## 9. Out of scope for THIS research (so it stays focused)

- The pen-feel / GenUI canvas-hosting question (settled by the Phase 11 spike).
- The across-session nightly profile compiler (deferred milestone).
- Building anything — this is a decision, not an implementation.

## 10. Open scoping questions for the owner (answer before we run)

1. **Is revisiting the no-server decision genuinely on the table**, or is "client-only unless
   it's impossible" a hard rail? (Changes how deep we go on Path B / AG-UI.)
2. **Depth/parallelism:** a focused 4-agent run (≈ a few hundred K tokens) or an exhaustive
   sweep with adversarial verification on every claim?
3. **Where should the on-device/Gemma research live** — here, or fold it into the Phase 13
   bake-off spike (avoid duplication)?
