# Phase 14: BUILD — TutorBrain spine + grounding invariant — Context

**Gathered:** 2026-06-22 (refreshed for the server architecture)
**Status:** Ready for planning
**Source:** ADR-015 (server-side LangGraph) + 14-AI-SPEC.md (implementation + eval contract) + ADR-014 (grounding invariant, still in force)
**Mode:** mvp (vertical slices)

<domain>
## Phase Boundary

Build the v2 AI-tutor **spine** for the baa letter family as a **capable server-side agent**:
a Python **LangGraph** agent on **Cloud Run** (analyze → plan → coach) called by the Flutter
client over a clean REST/SSE API, with the client's `TutorBrain` seam + `AuthoredFallback`
offline floor + grounding wired at the existing `ExerciseController`. Deliver a **grounded tutor
working end-to-end** — cloud-online via the server, offline via the authored floor — for baa.
NOT in this phase: dynamic grounded exercise selection (Phase 15), voice/TTS + the eval
regression gate (Phase 16), on-device Gemma (deferred — the floor is AuthoredFallback), the full
multi-node planning depth (Phase 15 thickens it).
</domain>

<decisions>
## Implementation Decisions (LOCKED — ADR-015 + AI-SPEC §2–§4b)

### Topology (reversed from ADR-014's client-only)
- **Server-side agent on Cloud Run**, Python. The Flutter client calls it over a **plain REST/SSE API**. Model keys live in **Secret Manager** (never in the client); client→server gated by **Firebase Auth ID token + App Check** (verified server-side with `firebase-admin`).

### Framework — LangGraph (confirmed via scored matrix; AI-SPEC §2)
- A `StateGraph` with nodes `analyze → plan → coach`; **conditional edges** so a clean pass is one cheap hop (coach only), a struggle runs analyze→plan→coach.
- **Per-node model routing** (model-agnostic via `init_chat_model`): initial analyze=Gemini Flash / Claude Haiku 4.5, plan=Claude Sonnet 4.6 / Gemini Pro, coach=Claude Haiku 4.5 — **eval-tunable** (the coach-node Claude-vs-Gemini Arabic bake-off is Phase 13/16).
- The **4 ACTION tools** (`present_activity`, `say`, `give_hint`, `advance`) bound with `tool_choice="any"` — the action space is pinned; **no verdict/star tool**. The server FORCES one tool call; the Flutter dispatcher EXECUTES it.
- Stateless server for v2 (`InMemorySaver` in-process); the checkpointer→Postgres path is the documented future for durable cross-session memory (NOT built now).

### Client seam (Flutter) — reshape the Wave-1 work for the capable agent
- `TutorBrain { Future<TutorDecision> next(TutorFacts facts); }` with two impls: **`RemoteAgentBrain`** (calls the LangGraph server) + **`AuthoredFallback`** (offline floor, pure Dart, mother-signed-off baa lines). `RemoteAgentBrain` auto-degrades to `AuthoredFallback` on timeout/offline/error (TUTOR-03).
- `TutorFacts` carries the **scored-attempt trajectory + session learner model** (not just last mistakeId). `TutorDecision` expresses **a plan/sequence + optional memory update**, not only one action. (Reshape the Wave-1 `lib/tutor/` types accordingly — they currently model the small agent.)
- Native **dispatcher** maps the returned ACTION to imperative widget calls; **the `StrokeCanvas` is never rebuilt from agent state** (Phase 11 kill-shot lesson). The brain's coaching line reaches the UI via a tutor-owned Riverpod provider that `exercise_scaffold.dart` reads — `ExerciseController` stays untouched.

### Grounding invariant (UNCHANGED — ADR-014; structural)
- The deterministic on-device scorer owns pass/fail + the star at `ExerciseController.applyResult(CheckResult)`. The agent reads the frozen verdict as a FACT and can never flip it.
- FACTS injected as TEXT (never a responseSchema combined with tools — it throws). The **non-PII chokepoint** guards the **server request body**: only `{letterId, mistakeId enum, struggleTags, pass/fail, trajectory}` cross — never raw strokes, never nickname/PII. GROUND-02 test runs on the serialized payload (build-failing).

### Learner model — on-device
- Session learner model on-device (Riverpod + Drift). Server is stateless → no child data stored server-side → no COPPA server-storage burden in v2.

### Offline floor (TUTOR-02)
- `AuthoredFallback` (pure Dart, zero model, airplane mode) from baa's signed-off coaching content. Every coaching moment yields a grounded, correct-Arabic line; the loop never blocks.

### Claude's Discretion
- Exact `server/` layout (FastAPI app + the LangGraph graph module), the REST/SSE endpoint shape, the Pydantic FACTS/decision schemas, the dispatcher details, how `struggleTags`/trajectory are derived, and the Riverpod wiring.
</decisions>

<canonical_refs>
## Canonical References (read before planning/implementing)

- `docs/architecture/ADR-015-v2-tutor-server-langgraph-agent.md` — the binding topology + framework decision.
- `.planning/phases/14-build-tutorbrain-spine-grounding-invariant/14-AI-SPEC.md` — the implementation contract (LangGraph §3/§4/§4b: install, the StateGraph, per-node binding, tool_choice, Cloud Run deploy, pitfalls) + the 9-dimension eval strategy (§5–§7) + the domain rubric (§1b).
- `docs/architecture/ADR-014-v2-tutor-agent-architecture.md` — the grounding invariant + the 4 ACTION tools (still in force).
- `.planning/research/v2-tutor-architecture/CAPABLE-AGENT-SPEC.md` — what the agent must DO (analyze/insight/plan).
- Code seams: `lib/core/scoring/scoring_models.dart` (MistakeId/StrokeResult/LetterResult), `lib/core/exercise_engine/check_result.dart`, `lib/features/letter_unit/exercise_controller.dart` (applyResult — GROUND-01 seam, do not mutate), `lib/features/letter_unit/widgets/exercise_scaffold.dart` (where _TutorColumn reads the line), `lib/features/practice/widgets/stroke_canvas.dart` (read-only; never agent-rebuilt), `lib/services/auth_service.dart` + `lib/firebase_options.dart` (Firebase ID token for server auth).
- Wave-1 client code already on disk (reshape, don't discard): `lib/tutor/tutor_brain.dart`, `tutor_facts.dart`(+`_builder`), `tutor_decision.dart`, `authored_fallback_brain.dart`, `tutor_dispatcher.dart`.
- Deploy: Cloud Run + Secret Manager + Firebase Auth/App Check, GCP project `qalam-app-bd7d0`. Python tooling aligns with CLAUDE.md (Python-for-backend).
</canonical_refs>

<specifics>
## Specific Ideas — suggested MVP vertical slices
1. **Server skeleton + deploy seam:** the `server/` FastAPI app + a minimal LangGraph graph (one `coach` node) + the REST endpoint + Firebase-ID-token/App-Check verification + Secret Manager wiring + a `gcloud run deploy` path. A trivial grounded coach line returns end-to-end.
2. **The grounded agent graph:** analyze → plan → coach with per-node models + `tool_choice="any"` over the 4 tools + FACTS-as-text + the server-side grounding (no verdict tool) + bounded retry.
3. **Client `RemoteAgentBrain` + reshape the seam:** `RemoteAgentBrain` calls the server; reshape `TutorFacts`(trajectory+learner model)/`TutorDecision`(plan); auto-degrade to `AuthoredFallback`; wire the line into `exercise_scaffold` via the tutor provider; dispatcher.
4. **The guards:** the build-failing non-PII payload test (GROUND-02) + the durable-layers-no-agent-imports guard; AuthoredFallback offline-floor test.
Each slice should leave the baa trace loop working. Riverpod only; Android-only; anti-gamification.
</specifics>

<scope_fence>
## Scope Fence (NOT in Phase 14)
- No dynamic grounded exercise selection (Phase 15).
- No voice/TTS, no eval regression gate (Phase 16); the eval *harness* design lives in the AI-SPEC, built/promoted later.
- No on-device Gemma (deferred; offline floor is AuthoredFallback).
- No durable cross-session/server-side memory (stateless server; checkpointer→store is future).
- Do not mutate the durable v1 canvas/scorer/curriculum (read-only; guard-tested).
</scope_fence>

---

*Phase: 14-build-tutorbrain-spine-grounding-invariant*
*Context refreshed 2026-06-22 for the server-side LangGraph architecture (ADR-015 + 14-AI-SPEC.md).*
