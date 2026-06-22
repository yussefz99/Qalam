# Phase 14: BUILD — TutorBrain spine + grounding invariant — Context

**Gathered:** 2026-06-22
**Status:** Ready for planning
**Source:** ADR Ingest Express Path (docs/architecture/ADR-014-v2-tutor-agent-architecture.md) + Phase 11 SPIKE-FINDINGS (GATE: drop)
**Mode:** mvp (vertical slices)

<domain>
## Phase Boundary

Build the v2 AI-tutor **spine** for the baa letter family: a swappable `TutorBrain` with three
backends, the 4 ACTION tools, FACTS-in/ACTIONS-out, and the grounding invariant wired at the
existing `ExerciseController` seam. **Client-only, no server, no GenUI/A2UI/AG-UI/MCP** (Phase 11
GATE: drop; ADR-014). This phase delivers the architecture and the offline+cloud coaching path;
it does NOT yet do dynamic exercise selection (Phase 15) or voice/TTS + eval gate (Phase 16),
and GemmaBrain ships as a stub/experimental only (bake-off is Phase 13).
</domain>

<decisions>
## Implementation Decisions (LOCKED — from ADR-014, accepted 2026-06-22)

### Topology
- **Client-only.** Flutter talks to Gemini directly via `firebase_ai` (Firebase AI Logic). No server, no protocol layer. This is the accepted ADR-014 decision; do not reintroduce AG-UI/A2UI/MCP/backend.

### The seam — `TutorBrain`
- `abstract class TutorBrain { Future<TutorDecision> next(TutorFacts facts); }`
- **`TutorFacts` (FACTS-in):** a whitelisted, non-PII DTO built by ONE chokepoint function — `{letterId, mistakeId (enum), struggleTags, pass/fail, session-derived recent mistakes}`. Raw `List<Offset>` strokes and nickname/PII NEVER reach this builder.
- **`TutorDecision` (ACTIONS-out):** exactly one of the 4 ACTION tool calls — `present_activity{coachingLine, letterId}`, `say{text}`, `give_hint{}`, `advance{}`. The verdict + mastery star are NOT tools.
- Three impls behind the one interface: **GeminiBrain** (cloud), **GemmaBrain** (on-device, experimental stub), **AuthoredFallback** (offline floor). A factory/router picks: online+capable → Gemini; offline/experimental → Gemma; no model/failure → AuthoredFallback.
- **Durable v1 layers (canvas / scorer / curriculum) carry ZERO `firebase_ai` / `genui` / `flutter_gemma` imports** (TUTOR-01/04). Enforce with a guard test (grep durable dirs for forbidden imports).

### Agent loop — GeminiBrain
- `FirebaseAI.googleAI().generativeModel(model: <gemini Flash — confirm exact string at build>, tools: [4 FunctionDeclarations], toolConfig: ToolConfig(functionCallingConfig: FunctionCallingConfig.any({'present_activity','say','give_hint','advance'})))`. `.any({4})` pins the action space — a grounding lever.
- Loop = `startChat()` → `sendMessage(Content.text(systemInstruction + FACTS))` → `while (response.functionCalls.isNotEmpty) { dispatch; sendMessage(Content.functionResponses(...)); }` (official flutter.dev pattern, ~30 lines).
- **FACTS injected as system-instruction / Content TEXT — never as a `responseSchema`** (structured-output + function-calling throws an `application/json` mime exception — verified).
- **ACTION turns run NON-streamed** (`chat.sendMessage`); streaming + tool-calls is undocumented on Dart. Defer streamed `say()` warmth (revisit trigger, not built now).
- Bounded manual retry-with-backoff around `sendMessage`. **Auto-degrade to AuthoredFallback on offline/timeout/error** (TUTOR-03).
- **App Check MUST be enforced in prod** (limited-use / replay-protection tokens) — Phase 11 left it off for the throwaway spike (TUTOR-03). Key never in client (Firebase AI Logic proxy).

### Agent ↔ UI — native function-call dispatcher (NO protocol)
- A `switch (functionCall.name)` (~100 lines) maps each ACTION tool to an imperative call on a native controller. **The `StrokeCanvas` stays a plain `StatefulWidget` OUTSIDE any reactive/agent-driven rebuild scope — dispatch imperatively, never rebuild the canvas from agent state.** (The Phase 11 kill-shot lesson; guard in code review.)

### Grounding invariant enforcement (GROUND-01/02)
1. Action space pinned by `FunctionCallingConfig.any({4 names})` — model cannot emit a 5th action.
2. Verdict/star never appear as tools; they are FACTS-as-text. The dispatcher has NO "set verdict" branch.
3. Pass/fail + star decided by the deterministic scorer at the `ExerciseController` seam (`applyResult(CheckResult)`); no agent path can flip a fail to a pass.
4. One DTO chokepoint builds `TutorFacts`; a **unit test asserts the serialized payload contains only enum/id fields — no raw strokes, no PII** (GROUND-02; build-failing).
5. Dispatcher is a closed `switch` over the 4 names; unrecognized call = logged no-op, not a crash.

### Offline floor — AuthoredFallback (TUTOR-02)
- Pure Dart, zero model, airplane-mode. Coaches from the owner's-mother signed-off lines (the existing per-letter `feedback`/coaching content for baa). Every coaching moment yields a grounded, correctly-Arabic line; the trace loop never blocks.

### Claude's Discretion
- Exact file layout under `lib/` (suggest `lib/tutor/`), provider wiring (Riverpod), the FunctionDeclaration JSON shapes, the router heuristic details, and how `TutorFacts` derives `struggleTags`/recent mistakes from session state.
</decisions>

<canonical_refs>
## Canonical References (downstream agents MUST read before planning/implementing)

### Architecture (binding)
- `docs/architecture/ADR-014-v2-tutor-agent-architecture.md` — the accepted v2 tutor architecture (topology, loop, dispatcher, grounding, the 5-part Decision).
- `.planning/spikes/11-genui-native-canvas/SPIKE-FINDINGS.md` — GATE: drop; resolved firebase_ai/firebase_core versions + the firebase_ai function-calling caveats (FACTS-as-text, non-streamed ACTION turns); App-Check-must-enforce flag.
- `.planning/research/v2-tutor-architecture/` — the decision matrix + research summary (why client-only, why not AG-UI/A2UI/MCP).

### Code seams the spine plugs into (read before touching)
- `lib/core/scoring/scoring_models.dart` — `enum MistakeId {…}`, `StrokeResult`, `LetterResult` (the FACTS source).
- `lib/core/exercise_engine/check_result.dart` — `CheckResult{passed, mistakeId(String)}` (the verdict bridge).
- `lib/features/letter_unit/exercise_controller.dart` — `ExerciseController.applyResult(CheckResult)` (the scorer-owns-verdict seam, GROUND-01 plugs here).
- `lib/features/letter_unit/widgets/write_surface.dart` — `WriteSurface(... onResult: (CheckResult) ...)`.
- `lib/features/practice/widgets/stroke_canvas.dart` — the native canvas (DO NOT host in a reactive rebuild scope; read-only to the tutor).
- `lib/data/progress_repository.dart` — `ProgressRepository` (cleanReps / mastery; the star).
- `lib/services/auth_service.dart` + `lib/firebase_options.dart` — Firebase init/anon auth (GeminiBrain reuses, read-only).
- baa's signed-off `feedback`/coaching content (via `CurriculumRepository.getExercises()`) — the AuthoredFallback source of truth.

### Versions (re-pin at build — they ship ~monthly)
- `firebase_ai 3.13.0`, `firebase_core 4.11.0`, `firebase_auth 6.5.3`, `firebase_app_check 0.4.5`, `flutter_gemma 1.0.2` (GemmaBrain, experimental). Confirm the exact Gemini Flash model string at build.
</canonical_refs>

<specifics>
## Specific Ideas
- MVP vertical slices, suggested: (1) `TutorBrain` interface + `AuthoredFallback` + the dispatcher + wire to `ExerciseController` → a grounded offline tutor end-to-end; (2) `GeminiBrain` (function-calling loop, App Check, auto-degrade) behind the same seam; (3) the non-PII guard test + the durable-layers-no-forbidden-imports guard; (4) `GemmaBrain` stub. Each slice should leave the baa trace loop working.
- Riverpod only. Android-only. Anti-gamification (one quiet star — no new counters).
- Reuse the emulator (Pixel Tablet) for testing the cloud path; Firebase AI Logic is already enabled on qalam-app-bd7d0.
</specifics>

<deferred>
## Deferred Ideas
- Dynamic grounded exercise selection (Phase 15, DYN-01/02).
- Streamed/TTS coaching + presence latency budget (Phase 16 / Phase 12).
- The on-device Gemma bake-off + adoption decision (Phase 13 / Phase 16) — GemmaBrain stays an experimental stub here.
- Across-session nightly profile compiler (future milestone).
</deferred>

<scope_fence>
## Scope Fence (do NOT do in Phase 14)
- No server / Cloud Function / AG-UI / A2UI / MCP / GenUI.
- No changes to the durable v1 canvas, scorer, or curriculum logic (read-only; guard-tested).
- No dynamic exercise selection (that replaces LetterUnitController's walk in Phase 15).
- No real Gemma model shipping decision (stub/experimental only).
- No TTS/voice.
</scope_fence>

---

*Phase: 14-build-tutorbrain-spine-grounding-invariant*
*Context gathered: 2026-06-22 via ADR Ingest (ADR-014) — architecture pre-decided by the Phase 11 GATE.*
