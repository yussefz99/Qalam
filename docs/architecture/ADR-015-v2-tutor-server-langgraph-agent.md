# ADR-015: v2 AI-Tutor — server-side LangGraph agent, model-agnostic per-task routing

**Status:** Accepted (owner, 2026-06-22)
**Supersedes:** ADR-014's **topology** decision (client-only). Everything else in ADR-014 — the
grounding invariant, the 4 ACTION tools, FACTS-in/ACTIONS-out, the `TutorBrain` seam, and the
`AuthoredFallback` offline floor — **remains in force**.
**Affects:** reshapes the Phase 14 plan (the client-only `GeminiBrain` path is replaced).

---

## Context

ADR-014 chose client-only largely because it assumed the agent's job was tiny. The owner
corrected that premise: the tutor is a **capable reasoning agent** — it analyzes the child's
scored attempts, builds a learner model / insight, and **plans** the next exercise, and must be
**architected for** cross-session insight + multi-unit planning later (see
`.planning/research/v2-tutor-architecture/CAPABLE-AGENT-SPEC.md`).

A focused topology re-evaluation (3 parallel investigations, 2026-06-22) found: the capable
*demo* agent is doable client-side **or** server-side; a server's real payoff is the **future**
(cross-session/multi-unit) plus restoring the **Claude warm-tutor voice** (the product's original
soul) plus mature streaming; and child-safety hinges on **storage**, not the model call (both
online topologies send non-PII facts to a cloud model — only *persistence* triggers COPPA-2025
server obligations).

**Owner decisions (2026-06-22):**
1. **Deploy a server** — better for the future; build something strong and organized.
2. Use a **model-agnostic agent framework** — *not* a hand-rolled `while tool_calls:` loop.
3. Use **different models for different tasks** (per-task model routing).

---

## Decision

### 1. Topology — server-side agent
A server-side tutor agent on **Cloud Run**. The Flutter client calls it over a **clean REST/SSE
API** — a deliberate, simple transport contract (this is *not* a "shallow agent"; the agent lives
*behind* the boundary). The brain's API keys live in server secrets, never in the client; App
Check gates the client→server calls.

### 2. Framework — LangGraph
**LangGraph** is the orchestration framework:
- **Model-agnostic** — each graph node binds its own model (required for per-task routing, §3).
- **Stateful, checkpointed graph** — the natural home for the planning loop *and* for durable
  cross-session state when that future arrives (the checkpointer → a store).
- Industry-leading for stateful single-agent orchestration; Python (the owner's strength;
  aligns with CLAUDE.md's Python-for-backend rule).

**Ruled out:** Genkit (Python tier is Beta — pre-1.0 churn, the genui lesson); Pydantic AI
(explicitly excluded in PROJECT.md); CrewAI / AutoGen (multi-*agent* crews — overkill for one
tutor); Claude Agent SDK (first-party but single-model — conflicts with model-agnostic + per-task
routing); Google ADK (capable + GA, but Gemini-leaning and less model-flexible than LangGraph —
kept as the fallback framework if LangGraph proves too heavy).

### 3. Per-task multi-model routing (the agent graph)
Each LangGraph node uses its best-fit model. Conditional edges skip nodes when not needed, so a
clean pass is **one cheap hop**, not three. Models are **tunable and eval-validated**, not locked.

| Node | Job | Model (initial) |
|------|-----|-----------------|
| **analyze** | scored-attempt trajectory + session learner model → structured insight | Gemini Flash or Claude Haiku 4.5 (frequent, cheap, structured) |
| **plan** | sequence the next exercise(s); branch on the insight | Claude Sonnet 4.6 (or Gemini Pro) — hardest reasoning, runs less often |
| **coach** | the warm, specific, Arabic-register coaching line | Claude Haiku 4.5 — the voice; eval Claude vs Gemini on Arabic register |

Cost stays low: Haiku for frequent nodes, Sonnet only for planning, prompt-cache the stable
mother's-voice + curriculum prefix (~0.1× input on Claude).

### 4. Grounding invariant — UNCHANGED (structural, topology-independent)
- The **deterministic on-device scorer owns pass/fail + the mastery star.** The agent reads a
  **frozen verdict** as FACTS at every node and can never re-judge or flip it.
- **ACTIONS-out = the closed 4 tools** (`present_activity`, `say`, `give_hint`, `advance`); no
  node has a verdict/star tool. The provider's tool-forcing (`tool_choice: any` / equivalent)
  pins the action space.
- The **non-PII chokepoint** now guards the **server request body**: only
  `{letterId, mistakeId enum, struggleTags, pass/fail, trajectory}` crosses — never raw strokes,
  never nickname/PII. The GROUND-02 test runs against the serialized payload.

### 5. Memory — on-device, server stateless
The **learner model lives on-device (Drift)** through v2. The server is **stateless** (facts in,
coaching out, nothing child-derived persisted server-side) → **no COPPA-2025 server-storage
obligation**. Cross-session / cross-device persistence is a **triggered future migration**
(LangGraph checkpointer → a store), gated by a real need (second device or aggregating parent
dashboard) and carrying its controls (retention policy, deletion path, auth-scoped rules, App
Check on the store).

### 6. Offline floor — preserved
`AuthoredFallback` (client-side, pure Dart, owner's-mother signed-off lines) stays the floor:
server unreachable / timeout → a grounded authored line; the trace loop never blocks.

---

## Consequences

**Good**
- A real framework foundation that scales to the planning loop *and* durable cross-session memory — not a loop we outgrow.
- Per-task models optimize cost/latency/quality independently; Claude restores the warm-tutor voice; Gemini available where it fits; no single-provider lock-in.
- Mature server-side streaming for the `say()` turn (resolves ADR-014's deferred streaming gap).
- The future vision (cross-session insight, multi-unit planning) is first-class via LangGraph state, not bolted on.
- Child data stays on-device (stateless server) — smallest practical storage surface.

**Bad / accepted costs**
- A server to run: Cloud Run (~$0 in the free tier for a demo; cold-start ~0.5–2s, masked with a session-start warm-up ping; one deploy + one secret).
- Multiple model calls per coaching moment add latency — mitigated by conditional routing + caching, and acceptable because the tutor coaches *between* exercises, never mid-stroke.
- A multi-provider model bill (tiny with Haiku + prompt caching).
- LangGraph learning curve (Python — the owner's strength).
- Reverses ADR-014's "no server / $0 ops" — a deliberate trade for the capable agent + future + the Claude voice.

---

## Alternatives considered
- **Client-only capable agent (ADR-014):** rejected now — viable for the demo, but makes cross-session/multi-unit hard and rules out Claude; the owner chose to invest in the stronger server foundation.
- **Hand-rolled server loop (no framework):** rejected by the owner — you outgrow it; a real framework from the start is the senior call.
- **Single-model server:** rejected — model-agnostic per-task routing gives better cost/quality and avoids lock-in.
- **Genkit / ADK / Claude Agent SDK / Pydantic AI / CrewAI:** see Decision §2.

## Revisit triggers
- Multi-node latency hurts the demo → collapse nodes / cache harder / fewer hops.
- Real cross-device or parent-dashboard need → move the learner model server-side (LangGraph checkpointer + store) **with** the COPPA controls listed in §5.
- Arabic-register eval strongly favors one provider → simplify routing toward it.
- LangGraph proves too heavy for the timeline → fall back to Google ADK (model-agnostic via LiteLLM) or a bounded custom loop.

## Seam impact (for the Phase 14 re-plan)
- The `TutorBrain` seam stays; the primary online impl becomes a **`RemoteAgentBrain`** that calls the LangGraph server over the API. `AuthoredFallback` stays client-side; the client-side `GeminiBrain` (Phase 14 plan 14-02) is replaced.
- `TutorFacts` carries the **trajectory + session learner model**; `TutorDecision` expresses a **plan + memory update** (per CAPABLE-AGENT-SPEC).
- The existing Wave-1 code (seam types, `AuthoredFallback`, dispatcher, non-PII builder) largely survives; the topology-specific work changes.
- New structure: a **Python LangGraph server sub-project** (the agent graph) + the Flutter client (`RemoteAgentBrain` + `AuthoredFallback` + dispatcher). The current Phase 14 plans (built for client-only) are superseded and must be re-planned against this ADR.
