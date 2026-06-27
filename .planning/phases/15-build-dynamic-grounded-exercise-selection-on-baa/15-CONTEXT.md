# Phase 15: BUILD — dynamic grounded exercise selection on baa - Context

**Gathered:** 2026-06-27
**Status:** Ready for planning
**Source:** ROADMAP.md Phase 15 (DYN-01, DYN-02, GROUND-03) + the national grade-1 Arabic curriculum (new, owner-supplied) + ADR-014 (grounding invariant) + Phase 14 spine (ADR-015 / 14-AI-SPEC).
**Mode:** mvp (vertical slices)

<domain>
## Phase Boundary

Replace `LetterUnitController`'s fixed `meet→watchTrace→forms→words→listenWrite→mastery`
walk with the **server agent's plan node choosing the next exercise** from baa's 19
signed-off Schema-v2 configs, reasoning about the child's recent mistakeIds/struggles. The
**curriculum graph rails the choices** (forward only along a prerequisite chain; backward
remediation down a difficulty lattice), the flow is **resume-aware**, mastery ends in **one
quiet star**, and **grounding faithfulness is first-measured + enforced** here for baa.

**NOT in this phase:** voice/TTS + the eval *regression gate* (Phase 16); the full
Claude-vs-Gemini coach bake-off / 9-dimension eval (Phase 13); latency/presence budget
(Phase 12); any letter other than baa; cross-letter ت/ث contrast activities; on-device
Gemma; durable cross-session/server-side memory.
</domain>

<decisions>
## Implementation Decisions

### Selection policy — curriculum-graph gated (DYN-01)
- **D-01:** Selection is **gated by a curriculum graph**, not free reorder and not just
  membership. The graph encodes mom's section order as a **forward prerequisite chain** plus
  **difficulty tiers** (notably the national curriculum's إملاء **منقول → منظور → غير منظور**
  = copy → look-then-write → dictation-from-memory ramp). The agent moves **forward only**
  along the chain, **picks freely among exercises within the reachable tier** to respond to
  recent mistakeIds/struggles, and **remediates BACKWARD down the lattice** on a struggle
  (e.g. failed dictation → look-write → copy).
- **D-02:** The membership rail (`AUTHORED_BAA_IDS` / `is_authored`, already built in Phase
  14) stays as the inner guard. The graph adds the **order/prerequisite/difficulty** rail on
  top. The agent can never present an unauthored id OR a tier the child hasn't unlocked.
- **D-03:** SC-1's "responds to mistakes rather than a fixed order" is satisfied primarily by
  **backward remediation** (the clearest, safest visible dynamism) + within-tier choice.

### Curriculum graph artifact — where it lives + how it's signed
- **D-04:** The curriculum graph (per-config **competency + difficulty tier + prerequisites**)
  is **authored in the Flutter curriculum assets** (extend the existing seed under
  `assets/curriculum/`); `server/app/curriculum_data/generate.py` **derives the server's
  copy**; the **Dart offline walker reads the assets directly**. Same proven single-source
  pattern as `AUTHORED_BAA_IDS` — both sides derive, can't drift, fully offline-capable.
- **D-05:** The graph is **new curriculum data → owner-mother's domain**. Claude **drafts the
  full 19-config graph from the national curriculum** as a clean sign-off sheet; she
  **reviews/adjusts at the tier level and signs**. Nothing curriculum-shaping ships unsigned
  (project rule). Treat the drafted graph as PROVISIONAL until signed (mirror the
  `AUTHORED_BAA_IDS` sign-off gate).

### Mastery + the quiet star (DYN-02)
- **D-06:** Mastery is a **deterministic on-device condition the scorer owns** — the agent can
  suggest `advance` but can **never declare mastery** (ADR-014 invariant). The one quiet star
  fires when the **essential-core competencies are cleared through the mastery section**
  (recognize → positional forms → copy-write → fluent vowelized reading), each at
  **mom's per-skill clean-reps**. This uses the national curriculum's **70/30 essential vs
  enrichment** split: enrichment exercises are **optional practice that do NOT gate the star**.
- **D-07:** Anti-gamification holds (CLAUDE.md Decided): **one** quiet star = mastery marker,
  no streaks/totals/extra stars. Exact clean-reps numbers are **owner-mother's to set**.

### Resume (DYN-02)
- **D-08:** Re-entering the baa unit restores **graph position + replays the trajectory**:
  persist the child's position in the curriculum graph (cleared tiers/competencies) to
  **Drift** (survives app restart) AND **replay the recent mistake/struggle trajectory to the
  agent** so it resumes its reasoning where it left off. Server stays stateless; all resume
  state lives **on-device** (no durable server-side child data — v2 COPPA posture unchanged).

### Offline selection (new in Phase 15; TUTOR-03 robustness)
- **D-09:** When the agent is unavailable (offline/timeout/error), a **pure-Dart deterministic
  walker drives the SAME curriculum graph**: advance along the prerequisite chain on a pass,
  remediate one tier down on a fail — same shape of adaptivity as online, minus the LLM's
  nuance. The **curriculum graph is the shared source of truth**: agent-reasoned online,
  deterministically walked offline. Coaching lines still come from **`AuthoredFallback`** (the
  signed offline floor); selection no longer silently reverts to a non-adaptive linear walk.

### Grounding faithfulness — first-measure (GROUND-03)
- **D-10:** Build the **narrow GROUND-03 slice in Phase 15**, NOT the full Phase 13 harness.
  A **Python check over fixed scorer verdicts + a small labeled set** flags any coaching that
  **praises a failed stroke or names the wrong fix**, and **reports a faithfulness rate**.
  This is the **seed** Phase 13/16 grow into the full bake-off + regression gate (per the
  roadmap's description of the Phase-13 harness). The faithfulness dimension is
  **verdict-driven** (buildable without mom); the Arabic-register dimension stays Phase 13.
  The check is **model-agnostic** — it does NOT pre-empt the Phase 13 Claude-vs-Gemini choice.

### ta/tha dot-discrimination (GROUND-03 / coaching scope)
- **D-11:** Coaching may **reinforce baa's own dot identity** ("one dot below the line") but
  must **not introduce ت/ث**. Explicit cross-letter dot-contrast is **deferred to a future
  multi-letter unit**. Keeps the baa unit focused; avoids confusing a 5–10 year-old mid-trace.

### Claude's Discretion
- Exact shape of the curriculum-graph schema (fields, edge representation) and how it extends
  the existing `assets/curriculum/` seed; the `generate.py` extension; the Dart walker's API
  and where it sits relative to the reshaped `TutorBrain`/`TutorDecision` seam; how the plan
  node's prompt is thickened to reason over the graph + recent mistakes; the Drift schema for
  resume position; the labeled-set format + size for the faithfulness check; Riverpod wiring.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Curriculum (the new grounding for selection)
- `docs/curriculum/national-curriculum-grade1.md` — grade-1 national Arabic curriculum extract
  (competencies + the difficulty lattice). Contains the DRAFT baa-config→competency mapping —
  **pending owner-mother sign-off** (D-05). The basis for the curriculum graph.
- `docs/curriculum/baa-family-authoring-sketch.md` — existing baa authoring sketch.
- `server/app/curriculum.py` + `server/app/curriculum_data/baa_authored_ids.json` — the
  `AUTHORED_BAA_IDS` membership rail + the `generate.py` derive-from-assets pattern to extend.
- `assets/curriculum/units.json` + `assets/curriculum/exercises.json` — the canonical Flutter
  seed where the curriculum graph is authored (D-04).

### Grounding & the agent spine (locked, do not relitigate)
- `docs/architecture/ADR-014-v2-tutor-agent-architecture.md` — grounding invariant: the scorer
  owns pass/fail + the star; the agent can never flip it (drives D-06).
- `docs/architecture/ADR-015-v2-tutor-server-langgraph-agent.md` — server topology/framework.
- `.planning/phases/14-build-tutorbrain-spine-grounding-invariant/14-AI-SPEC.md` — the eval
  strategy (§5–§7) the minimal faithfulness check (D-10) seeds from; the StateGraph contract.
- `.planning/phases/14-build-tutorbrain-spine-grounding-invariant/14-CONTEXT.md` — the Phase 14
  decisions this phase builds directly on.

### Code seams to thicken / replace
- `server/app/nodes/plan.py` — the plan node that already emits a curriculum-railed
  `next_exercise_id` with the G3 (verdict-lock) / G4 (membership) guards. **The seam Phase 15
  thickens** to reason over the graph + recent mistakes.
- `server/app/tools.py` — the 4 ACTION tools incl. `present_activity`.
- `lib/features/letter_unit/letter_unit_controller.dart` — the fixed 6-section walk **being
  replaced** by the agent-driven (online) / deterministic-graph-walk (offline) flow.
- `lib/tutor/` (`tutor_brain.dart`, `tutor_facts.dart`, `tutor_decision.dart`,
  `authored_fallback_brain.dart`, `tutor_dispatcher.dart`) — the Phase-14 client seam to extend
  (the offline graph walker + resume trajectory replay attach here).
- `lib/data/drift_progress_repository.dart` — the local progress/mastery write seam; resume
  graph position persists here (D-08).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`AUTHORED_BAA_IDS` + `generate.py`**: the proven "author in Flutter assets, derive the
  server copy" pattern — extend it for the curriculum graph (D-04), don't invent a new sync.
- **`plan.py` (analyze→plan→coach + G3/G4 guards)**: the selection mechanism already exists and
  is curriculum-railed for membership; Phase 15 thickens its reasoning + adds the graph rail.
- **`LetterUnitController` resume map + `ProgressRepository.recordMastery`**: the resume/mastery
  seams to evolve (in-memory map → Drift-persisted graph position; mastery condition → D-06).
- **`AuthoredFallback`**: the signed offline floor for coaching lines stays; only **selection**
  is newly handled offline by the Dart graph walker (D-09).

### Established Patterns
- Grounding invariant (ADR-014): scorer owns the star → mastery must be deterministic on-device.
- Non-PII chokepoint (GROUND-02, Phase 14): only derived facts cross the wire — unchanged.
- Riverpod only; Android-only; anti-gamification (one quiet star).

### Integration Points
- Curriculum graph (assets) → `generate.py` → server plan-node prompt/rail; same graph →
  Dart offline walker.
- Plan node `next_exercise_id` → Flutter dispatcher → the baa unit (replacing the static walk).
- Resume graph position ↔ Drift; recent trajectory ↔ on-device session learner model → server FACTS.
</code_context>

<specifics>
## Specific Ideas

- The national curriculum's **منقول → منظور → غير منظور** ramp is the authoritative difficulty
  order for the writing exercises — use it as the spine of the difficulty lattice.
- Demo story for SC-1: "watch the tutor re-surface the isolated trace because she's still
  wobbling on the medial form" — backward remediation is the clearest thing to show.
- Mastery framing from the curriculum's 70/30 split: essential core gates the star; enrichment
  is optional practice.
</specifics>

<deferred>
## Deferred Ideas

- **Cross-letter ب/ت/ث contrast unit** — the curriculum names dot-discrimination as a grade-1
  competency; Phase 15 reinforces baa's own dot only. An explicit ta/tha contrast activity is a
  future multi-letter unit.
- **Roadmap-sequencing flag (NOT a Phase 15 decision):** both Phase 15 and Phase 16 lean on
  Phases 12 (latency budget) and 13 (Claude-vs-Gemini bake-off), and **neither spike has run**.
  The minimal check (D-10) covers Phase 15's slice, but before Phase 16 decide whether to run
  the 12/13 spikes against the deployed server (the "de-risk on the live system" step the
  roadmap intended).
- **Broader national curriculum (grades 1–6, all language domains)** — future curriculum work;
  Phase 15 uses only the grade-1 / baa-relevant slice.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

---

*Phase: 15-build-dynamic-grounded-exercise-selection-on-baa*
*Context gathered: 2026-06-27*
