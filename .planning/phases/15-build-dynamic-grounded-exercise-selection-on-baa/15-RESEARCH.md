# Phase 15: BUILD — dynamic grounded exercise selection on baa - Research

**Researched:** 2026-06-27
**Domain:** Agent-driven curriculum selection (LangGraph plan node + pure-Dart graph walker) over a NEW curriculum-graph rail; Drift resume persistence; deterministic on-device mastery; a minimal Python grounding-faithfulness check.
**Confidence:** HIGH (every seam read directly from the codebase; locked design in CONTEXT.md; no new external packages)

## Summary

Phase 15 is almost entirely an **integration / extension** phase over code that already exists and is deployed. The agent loop (`analyze → plan → coach` on LangGraph), the membership rail (`AUTHORED_BAA_IDS` + `is_authored`), the FACTS chokepoint (`buildTutorFacts`), the `TutorBrain`/`TutorDecision`/`AuthoredFallbackBrain`/`RemoteAgentBrain`/dispatcher seam, the Drift progress repo, and the per-exercise scoring seam (`ExerciseScaffold._onResult`) are all built and tested from Phase 14. **No new libraries are installed** — the stack is pinned (`langgraph 1.2.6`, `langchain 1.3.10`, Flutter Riverpod 3, drift 2.31). The work is: (1) add a curriculum-graph layer to the existing single-source asset→`generate.py`→server pattern; (2) thicken `plan.py` to reason over that graph (forward-only + within-tier choice + backward remediation) with two NEW guards on top of the existing G3/G4; (3) write a pure-Dart deterministic graph walker behind a new `TutorBrain`-adjacent seam and replace `LetterUnitController`'s fixed 6-section walk with agent-driven (online) / walker-driven (offline) selection; (4) persist graph position to Drift (new table, schema v4→v5 migration) and replay the session trajectory on resume; (5) express the deterministic "essential-core cleared, 70/30, mom's clean-reps" mastery condition on-device (scorer-owned star, ADR-014); and (6) add a model-free Python faithfulness check over a small labeled (verdict, coaching) set that flags verdict-vs-coaching contradictions and reports a rate.

The single most important architectural constraint is the **grounding invariant (ADR-014)**: the deterministic on-device scorer owns pass/fail + the star; the agent can only *suggest* `advance`. This means **mastery (D-06) must be computed on-device in Dart**, never trusted from a server response. The curriculum graph is the shared source of truth — agent-reasoned online, deterministically walked offline — and is **NEW curriculum data**, so it follows the `AUTHORED_BAA_IDS` sign-off gate: Claude drafts the full 19-config graph from the national curriculum, mom signs at the tier level, and `signedOff` gates it exactly like the existing seed.

**Primary recommendation:** Extend the *existing* single-source asset pattern with a new `assets/curriculum/curriculum_graph.json` (per-exercise `competency` + `tier` + `prerequisites`, `signedOff: false` until mom signs), derive the server copy via `generate.py`, and have BOTH the thickened `plan.py` rail and a NEW pure-Dart `CurriculumGraph` + walker read it. Mirror the proven `baa_authored_ids.json` derive-from-assets mechanics exactly — do not invent a new sync path.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Curriculum-graph authoring (competency/tier/prereq) | Flutter assets (`assets/curriculum/`) | — | D-04: single source of truth; same place `units.json`/`exercises.json` live, signed off by mom |
| Server's graph copy | Python server (`generate.py` → JSON) | — | Derived, never hand-edited; mirrors `baa_authored_ids.json`; provably can't drift |
| Online next-exercise selection (graph-reasoned) | API/Backend (`plan.py` node) | — | Hardest reasoning; agent reasons over graph + recent mistakeIds/struggles |
| Offline next-exercise selection (deterministic walk) | Browser/Client (pure-Dart `CurriculumGraphWalker`) | — | D-09: same graph, no LLM; sits behind a `TutorBrain`-adjacent selection seam |
| Verdict (pass/fail) + the star | Client (deterministic scorer) | — | ADR-014 invariant — agent NEVER owns this; mastery computed on-device only |
| Resume graph position (cleared tiers/competencies) | Client (Drift) | — | D-08: on-device only; server stays stateless (COPPA posture) |
| Trajectory replay to the agent | Client (FACTS chokepoint) → API (FACTS-as-text) | — | The session learner model arrives in each request; server never persists it |
| Grounding-faithfulness check | Python server tests (`server/tests/`) | — | D-10: model-free check over fixed verdicts + a labeled set; reports a rate |

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Selection is **gated by a curriculum graph** — not free reorder, not just membership. The graph encodes mom's section order as a **forward prerequisite chain** plus **difficulty tiers** (national curriculum's إملاء **منقول → منظور → غير منظور** = copy → look-then-write → dictation). The agent moves **forward only** along the chain, **picks freely among exercises within the reachable tier** to respond to recent mistakeIds/struggles, and **remediates BACKWARD down the lattice** on a struggle (failed dictation → look-write → copy).
- **D-02:** The membership rail (`AUTHORED_BAA_IDS` / `is_authored`, built Phase 14) **stays as the inner guard**. The graph adds the **order/prerequisite/difficulty** rail on top. The agent can never present an unauthored id OR a tier the child hasn't unlocked.
- **D-03:** SC-1's "responds to mistakes rather than a fixed order" is satisfied primarily by **backward remediation** + within-tier choice.
- **D-04:** The curriculum graph (per-config **competency + difficulty tier + prerequisites**) is **authored in the Flutter curriculum assets** (extend `assets/curriculum/`); `generate.py` **derives the server's copy**; the **Dart offline walker reads the assets directly**. Same single-source pattern as `AUTHORED_BAA_IDS`.
- **D-05:** The graph is **new curriculum data → owner-mother's domain**. Claude **drafts the full 19-config graph** as a clean sign-off sheet; she **reviews/adjusts at the tier level and signs**. Treat the drafted graph as **PROVISIONAL until signed** (mirror the `AUTHORED_BAA_IDS` gate).
- **D-06:** Mastery is a **deterministic on-device condition the scorer owns** — the agent can suggest `advance` but can **never declare mastery** (ADR-014). The one quiet star fires when **essential-core competencies are cleared through the mastery section** (recognize → positional forms → copy-write → fluent vowelized reading), each at **mom's per-skill clean-reps**, using the **70/30 essential-vs-enrichment** split (enrichment does NOT gate the star).
- **D-07:** Anti-gamification holds: **one** quiet star, no streaks/totals/extra stars. Exact clean-reps numbers are **owner-mother's to set**.
- **D-08:** Re-entering the baa unit restores **graph position + replays the trajectory**: persist position (cleared tiers/competencies) to **Drift** AND **replay the recent mistake/struggle trajectory to the agent**. Server stays stateless; all resume state lives **on-device**.
- **D-09:** When the agent is unavailable (offline/timeout/error), a **pure-Dart deterministic walker drives the SAME curriculum graph**: advance on a pass, remediate one tier down on a fail. Coaching lines still come from **`AuthoredFallback`**; selection no longer reverts to a non-adaptive linear walk.
- **D-10:** Build the **narrow GROUND-03 slice** (NOT the full Phase 13 harness). A **Python check over fixed scorer verdicts + a small labeled set** flags coaching that **praises a failed stroke or names the wrong fix**, and **reports a faithfulness rate**. **Model-agnostic** — does NOT pre-empt the Phase 13 Claude-vs-Gemini choice.
- **D-11:** Coaching may **reinforce baa's own dot identity** ("one dot below the line") but must **not introduce ت/ث**. Explicit cross-letter dot-contrast is **deferred**.

### Claude's Discretion

- Exact shape of the curriculum-graph schema (fields, edge representation) and how it extends the existing `assets/curriculum/` seed; the `generate.py` extension; the Dart walker's API and where it sits relative to the reshaped `TutorBrain`/`TutorDecision` seam; how the plan node's prompt is thickened to reason over the graph + recent mistakes; the Drift schema for resume position; the labeled-set format + size for the faithfulness check; Riverpod wiring.

### Deferred Ideas (OUT OF SCOPE)

- **Cross-letter ب/ت/ث contrast unit** — Phase 15 reinforces baa's own dot only.
- **Roadmap-sequencing flag:** Phases 12 (latency) and 13 (Claude-vs-Gemini bake-off) spikes have **not run**. The minimal check (D-10) covers Phase 15's slice; before Phase 16 decide whether to run 12/13 against the deployed server. (Not a Phase 15 decision.)
- **Broader national curriculum (grades 1–6, all domains)** — future curriculum work; Phase 15 uses only the grade-1 / baa-relevant slice.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **DYN-01** | The agent selects the next exercise from baa's authored configs, reasoning about recent mistakes; the curriculum rails the choices | The thickened `plan.py` (graph rail § "plan.py thickening") + the NEW `assets/curriculum/curriculum_graph.json` derived to the server via `generate.py`; G5/G6 graph guards added on top of the existing G3/G4; FACTS already carry `recentMistakes`/`struggleTags`/`trajectory` (`tutor_facts.dart`) |
| **DYN-02** | The dynamic, resume-aware flow replaces the fixed section walk end-to-end; resume works; one quiet star at mastery | Replace `LetterUnitController`'s fixed `goTo`/`advance` with a `CurriculumGraphWalker`-driven selection notifier; new Drift `LetterGraphPosition` table (schema v5) for resume position; on-device mastery condition (D-06) gates the existing `recordMastery` star write |
| **GROUND-03** | Grounding faithfulness is measurable — flags coaching that praises a failed stroke or names the wrong fix; a faithfulness rate is reported | New `server/tests/test_faithfulness.py` (`pytest.mark.code`) over a labeled `(verdict, coaching)` fixture set (`server/tests/fixtures/faithfulness_set.jsonl`); deterministic lexicon/rule check; reports a rate; model-agnostic (seeds Phase 13/16) |

## Standard Stack

### Core (all already installed and pinned — NO new installs this phase)

| Library | Version (verified) | Purpose | Why Standard |
|---------|--------------------|---------|--------------|
| `langgraph` | `1.2.6` `[VERIFIED: server/.venv pip freeze 2026-06-27]` | The `StateGraph` analyze→plan→coach DAG the plan node lives in | ADR-015 / 14-AI-SPEC framework decision (locked) |
| `langchain` | `1.3.10` `[VERIFIED: pip freeze]` | `init_chat_model` per-node model layer | Bundled with LangGraph stack |
| `langchain-anthropic` | `1.4.6` `[VERIFIED: pip freeze]` | Claude Sonnet/Haiku for plan/coach | Per-node routing (`models.py`) |
| `langchain-google-genai` | `4.2.5` `[VERIFIED: pip freeze]` | Gemini Flash for analyze; current deploy uses Vertex (keyless) | `models.py` routing table |
| `langchain-google-vertexai` | `3.2.4` `[VERIFIED: pip freeze]` | Keyless Gemini on Vertex (Technion credits) — the live deploy path | MEMORY: tutor-server-deployed |
| `pydantic` | `2.13.4` `[VERIFIED: pip freeze]` | `Plan`/`Insight`/`TutorFactsIn` structured output + `extra="forbid"` guard | Already the wire-contract spine (`schema.py`) |
| `pytest` | `9.1.1` `[VERIFIED: pip freeze]` | `pytest.mark.code` model-free checks (the faithfulness check is one) | Existing server test harness (`server/tests/`) |
| Flutter `flutter_riverpod` / `riverpod_annotation` | Riverpod 3 (project standard) `[VERIFIED: lib/data + lib/tutor imports]` | All client state (selection notifier, providers) | CLAUDE.md Decided: Riverpod only |
| `drift` / `drift_dev` | `^2.31.0` `[VERIFIED: STATE.md Phase 01 decision]` | On-device resume position + mastery rows | The established local-persistence layer (`app_database.dart`) |

### Supporting (already present — referenced, not added)

| Library | Purpose | When to Use |
|---------|---------|-------------|
| `http` (Dart) | `RemoteAgentBrain` POST to `/coach` | Already wired; selection rides the existing call |
| `firebase_admin` (`>=7.0,<8`) | ID-token + App Check verification on `/coach` | Unchanged; the faithfulness check is offline pytest, no auth |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| A new `curriculum_graph.json` asset | Inlining `competency`/`tier`/`prerequisites` fields into each `exercises.json` entry | Inlining keeps one file but mixes provisional-graph sign-off with already-signed exercise content; a SEPARATE file lets the graph carry its own `signedOff` gate and a clean sign-off sheet (D-05) without re-touching signed exercises. **Recommend the separate file.** |
| Pure-Dart walker as a new class | Reusing `LetterUnitController` with a graph injected | The controller is a 6-section index walker with an in-memory resume map; the graph walk is a different shape (tiers + prereqs + backward remediation). **Recommend a new `CurriculumGraphWalker` + a selection notifier; retire `LetterUnitController` for baa.** |
| Drift table for resume position | Extending the in-memory `_resumeByLetter` map | The in-memory map does NOT survive app restart (D-08 requires durable). **Recommend a new Drift table (schema v5).** |
| LLM judge for faithfulness | A deterministic lexicon/rule check | D-10 is explicitly model-agnostic + buildable-without-mom + verdict-driven. An LLM judge belongs to Phase 13/16. **Recommend the deterministic check.** |

**Installation:** None. All dependencies are pinned and present. The phase adds source files + one Drift schema bump + one new asset, no `pub add` / `uv pip install`.

**Version verification:** Ran `pip freeze` in `server/.venv` on 2026-06-27 — versions above are the live resolved set. Flutter packages confirmed via existing imports in `lib/data/` and `lib/tutor/`. No registry lookups were needed because nothing new is installed.

## Package Legitimacy Audit

> **Not applicable this phase — no external packages are installed.** Every library used (LangGraph stack, Pydantic, pytest, Riverpod, drift) is already a pinned, in-use dependency vetted in earlier phases (drift in Phase 01; the LangGraph stack in Phase 14 with its own legitimacy gates; `crypto` in Phase 09). Phase 15 adds only first-party source files, one JSON asset, and a Drift migration.

| Package | Registry | Disposition |
|---------|----------|-------------|
| (none added) | — | N/A — phase installs nothing |

**Packages removed due to slopcheck [SLOP] verdict:** none (slopcheck not run — nothing to check).
**Packages flagged as suspicious [SUS]:** none.

*If any plan unexpectedly proposes a new dependency (e.g. a graph library), gate it behind a `checkpoint:human-verify` task and run the Package Legitimacy Gate then — but the design here needs none: the graph is a ~19-node DAG, trivially hand-walked in pure Dart and reasoned over in the existing prompt.*

## Architecture Patterns

### System Architecture Diagram

```
                    ┌──────────────────────────────────────────────────────────────┐
                    │  assets/curriculum/  (SINGLE SOURCE OF TRUTH — D-04)          │
                    │   units.json · exercises.json · NEW curriculum_graph.json     │
                    │   (per-exercise: competency, tier, prerequisites; signedOff)  │
                    └───────────────┬───────────────────────────┬──────────────────┘
                                    │ generate.py derives        │ rootBundle reads
                                    ▼                            ▼
              ┌─────────────────────────────────┐   ┌────────────────────────────────────┐
              │ server/app/curriculum_data/      │   │  Flutter client (pure Dart)         │
              │  curriculum_graph.json (derived) │   │  CurriculumGraph (parsed asset)     │
              │  + baa_authored_ids.json (G4)    │   │   ├─ CurriculumGraphWalker (offline)│
              └───────────────┬──────────────────┘   │   └─ mastery condition (D-06)        │
                              │ loaded at import       └──────────┬─────────────────────────┘
                              ▼                                    │
   CHILD traces a letter ─► deterministic SCORER (owns verdict + star, ADR-014)
                              │ CheckResult {passed, mistakeId}     │
                              ▼                                    │
   ExerciseScaffold._onResult ──► buildTutorFacts (chokepoint, non-PII) ──► TutorFacts
                              │   (letterId, mistakeId, struggleTags, trajectory, strengthTags,
                              │    + NEW: clearedTiers/clearedCompetencies for resume replay)
                              ▼
                ┌─────────────────────────────────────────────────────────┐
                │  SELECTION SEAM (online ↔ offline router)                 │
                │   online  → RemoteAgentBrain → POST /coach                 │
                │   offline → CurriculumGraphWalker.next(facts, position)    │
                └───────────────┬───────────────────────────┬──────────────┘
        online path             │                           │  offline path
                                ▼                           ▼
   /coach LangGraph:  analyze ─needs_plan?─► plan ─► coach ─► CoachOut       deterministic:
     plan.py THICKENED: graph rail (forward-only + within-tier choice +       advance on pass /
       backward remediation) + NEW G5 (tier-reachable) / G6 (prereq) guards   remediate 1 tier on fail
       on top of existing G3 (verdict-lock) / G4 (membership)
                                │                                            │
                                └────────► next_exercise_id ◄────────────────┘
                                                  │
                                                  ▼
                       Flutter dispatcher → present that authored exercise (NOT the static walk)
                                                  │
                                                  ▼
                    on-device MASTERY CHECK (D-06): essential-core cleared through mastery
                      section at mom's clean-reps, 70/30 → recordMastery() → ONE quiet star
                                                  │
                                                  ▼
                          Drift: LetterGraphPosition (resume — D-08) + LetterMastery (star)
```

### Recommended Project Structure (new + touched files)

```
assets/curriculum/
└── curriculum_graph.json              # NEW — the graph (competency/tier/prereq; signedOff:false)

server/app/curriculum_data/
├── generate.py                        # EXTEND — also derive curriculum_graph.json
├── baa_authored_ids.json              # unchanged (G4 membership)
└── curriculum_graph.json              # NEW (derived) — the server's read-only copy

server/app/
├── curriculum.py                      # EXTEND — load the graph; reachable_tier/prereq helpers
└── nodes/plan.py                      # THICKEN — graph rail + G5/G6 guards + richer prompt

server/tests/
├── fixtures/faithfulness_set.jsonl    # NEW — labeled (verdict, coaching) cases
└── test_faithfulness.py               # NEW — model-free check, reports a rate (GROUND-03)

lib/curriculum/                        # NEW (pure Dart; no Flutter/cloud imports)
├── curriculum_graph.dart              # parse assets/curriculum/curriculum_graph.json
├── curriculum_graph_walker.dart       # deterministic offline walk (advance/remediate)
└── mastery_condition.dart             # D-06 deterministic essential-core/70-30 evaluator

lib/tutor/
└── (selection seam)                   # NEW provider/notifier routing online↔offline selection

lib/data/
├── app_database.dart                  # EXTEND — LetterGraphPosition table; schemaVersion 4→5
└── (graph_position_repository.dart)    # NEW — read/write cleared tiers/competencies

lib/features/letter_unit/
├── letter_unit_screen.dart            # EDIT — drive sections by selection, not the fixed walk
└── letter_unit_controller.dart        # RETIRE for baa (replaced by the graph-driven notifier)
```

### Pattern 1: Single-source asset → `generate.py` → server copy (mirror exactly)

**What:** The graph is authored once in Flutter assets; `generate.py` derives the server's read-only JSON; both sides parse the same shape; they provably can't drift.
**When to use:** Any curriculum data the server reasons over AND the client walks offline (D-04).
**Example (the proven mechanics to mirror — `generate.py` already does this for ids):**
```python
# Source: server/app/curriculum_data/generate.py (existing pattern — extend it)
_GRAPH = _REPO_ROOT / "assets" / "curriculum" / "curriculum_graph.json"
graph = json.loads(_GRAPH.read_text(encoding="utf-8"))
baa_nodes = [n for n in graph["nodes"] if n["exerciseId"].startswith("baa.")]
# write server/app/curriculum_data/curriculum_graph.json verbatim-derived, ensure_ascii=False
```
`curriculum.py` then loads it once at import (exactly like `_load_authored_ids()`), exposing helpers the plan node + guards call: `reachable_tiers(cleared_competencies)`, `prerequisites_met(exercise_id, cleared)`, `tier_of(exercise_id)`, `remediation_target(exercise_id)`.

### Pattern 2: Curriculum-graph schema shape (concrete)

**What:** A flat list of nodes keyed by `exerciseId`, each carrying its competency, difficulty tier, and prerequisite competency/tier edges. Flat-list-with-edges beats nested adjacency for a ~19-node graph: it diffs cleanly, signs off as a table, and parses in both languages with the existing defensive `fromJson` idiom.
**When to use:** The graph artifact (D-04). Keep it SEPARATE from `exercises.json` so its `signedOff` gate is independent.
**Example (recommended shape — Claude DRAFTS this from the national curriculum, mom signs):**
```jsonc
// assets/curriculum/curriculum_graph.json  (PROVISIONAL until mom signs, mirror AUTHORED_BAA_IDS gate)
{
  "_meta": {
    "title": "baa curriculum graph — competency + difficulty tier + prerequisites",
    "source": "docs/curriculum/national-curriculum-grade1.md (competencies + منقول→منظور→غير منظور lattice)",
    "regenerate": "cd server && uv run python -m app.curriculum_data.generate",
    "signOff": "owner-mother signs at the TIER level (D-05); signedOff stays false until then"
  },
  "letterId": "baa",
  "signedOff": false,
  "competencies": [
    // forward prerequisite chain (mom's section order, nationally endorsed)
    { "id": "recognize",      "essential": true,  "prerequisites": [] },
    { "id": "positionalForms","essential": true,  "prerequisites": ["recognize"] },
    { "id": "copyWrite",      "essential": true,  "prerequisites": ["positionalForms"] },
    { "id": "fluentReading",  "essential": true,  "prerequisites": ["copyWrite"] },
    { "id": "wordBuilding",   "essential": false, "prerequisites": ["copyWrite"] },   // enrichment (70/30)
    { "id": "grammarTransform","essential": false,"prerequisites": ["copyWrite"] }    // enrichment
  ],
  "tiers": ["manqul", "manzur", "ghayrManzur"],   // copy < look-then-write < dictation-from-memory
  "nodes": [
    { "exerciseId": "baa.teachCard.meet",      "competency": "recognize",       "tier": null,         "minCleanReps": 1 },
    { "exerciseId": "baa.traceLetter.isolated","competency": "positionalForms", "tier": null,         "minCleanReps": 3 },
    { "exerciseId": "baa.traceLetter.initial", "competency": "positionalForms", "tier": null,         "minCleanReps": 3 },
    { "exerciseId": "baa.traceLetter.medial",  "competency": "positionalForms", "tier": null,         "minCleanReps": 3 },
    { "exerciseId": "baa.writeWord.copy",      "competency": "copyWrite",       "tier": "manqul",     "minCleanReps": 2 },
    { "exerciseId": "baa.writeWord.picture",   "competency": "copyWrite",       "tier": "manzur",     "minCleanReps": 2 },
    { "exerciseId": "baa.writeWord.dictation", "competency": "copyWrite",       "tier": "ghayrManzur","minCleanReps": 2 },
    { "exerciseId": "baa.buildSentence.hear",  "competency": "fluentReading",   "tier": "ghayrManzur","minCleanReps": 1 }
    // … all 19 baa.* configs mapped; the DRAFT mapping table lives in docs/curriculum/national-curriculum-grade1.md
  ]
}
```
Notes that make this defensible:
- The forward chain = `recognize → positionalForms → copyWrite → fluentReading` is the **national curriculum's endorsed prerequisite order** (national-curriculum-grade1.md §"What this means for Qalam"), so it is pedagogically grounded, not a preference.
- The **tier** field is non-null only for writing exercises (the إملاء ramp). Backward remediation walks `ghayrManzur → manzur → manqul` *within the same competency* (D-01).
- `essential: true/false` is the **70/30 split** that gates mastery (D-06); enrichment nodes are reachable but do NOT gate the star.
- `minCleanReps` are **mom's per-skill clean-reps** (D-06/D-07) — DRAFT values; she sets them at sign-off. Keep them in the graph, not in code, so tuning is data not code (mirrors the `tolerances` "data not code" rule from Phase 04).

### Pattern 3: Thickening `plan.py` — graph rail on top of the existing guards

**What:** The plan node already emits a `Plan{next_exercise_id, intent, rationale}` validated by G4 (membership) + G3 (verdict-lock). Phase 15 (a) thickens the prompt to reason over the graph + recent mistakes, and (b) adds two NEW post-parse guards.
**When to use:** DYN-01's "curriculum rails the choices."
**Example (the two new guards, structurally identical to the existing G3/G4 in `plan.py`):**
```python
# Source: pattern from server/app/nodes/plan.py (existing G4 block) — add after G4
from app.curriculum import reachable_tiers, prerequisites_met, tier_of

# G5 — tier-reachability: the chosen exercise's tier must be unlocked for the child.
#   (cleared competencies/tiers arrive in facts; see the FACTS extension below)
if tier_of(plan_out.next_exercise_id) and \
   tier_of(plan_out.next_exercise_id) not in reachable_tiers(facts.get("clearedTiers", [])):
    raise StructuredOutputError("plan chose an unreached difficulty tier")

# G6 — prerequisite chain: forward-only. The competency's prereqs must be cleared,
#   UNLESS this is a backward remediation (a lower tier of an already-attempted competency).
if not prerequisites_met(plan_out.next_exercise_id, facts.get("clearedCompetencies", [])):
    raise StructuredOutputError("plan chose an exercise whose prerequisites are unmet")
```
Both raise `StructuredOutputError`, which the existing retry+degrade machinery already maps to the AuthoredFallback floor (test pattern in `test_grounding.py::test_endpoint_degrades_on_structured_error`). **Crucially, backward remediation is ALLOWED through G5/G6** — remediating to a lower tier of an already-reached competency is forward-legal (the prereqs are met; the tier is reachable). The prompt change (below) is what makes the agent *choose* remediation; the guards only reject illegal *forward jumps*.

The prompt thickening (in `prompts.py` `PLAN_PROMPT`) adds: (1) the reachable-tier list + cleared competencies as context, (2) the explicit rule "on a repeated struggle in tier X, remediate to the next-easier tier of the SAME competency (ghayrManzur→manzur→manqul); never jump a tier forward," and (3) "within the reachable tier, choose the exercise that targets the child's recent mistakeIds/struggleTags." FACTS still go in the `HumanMessage` (caching discipline — `analyze.py`/`plan.py` already do this).

### Pattern 4: Pure-Dart deterministic walker (offline parity)

**What:** A pure-Dart `CurriculumGraphWalker` that drives the SAME graph deterministically: advance to the next forward node on a pass; remediate one tier down (within the competency) on a fail. No LLM.
**When to use:** D-09 — when the agent is unavailable (offline/timeout/error). It produces a `next_exercise_id`; coaching lines still come from `AuthoredFallbackBrain` (unchanged).
**Where it sits relative to the Phase-14 seam:** The Phase-14 `TutorBrain` seam answers `next(facts) → TutorDecision` (the COACHING ACTION). Selection is a DIFFERENT axis — `RemoteAgentBrain` already carries a `TutorPlan{nextExerciseId, intent, rationale}` payload on its decision. So the cleanest placement is a **sibling selection seam**, not a 5th tool:
```dart
// lib/curriculum/curriculum_graph_walker.dart  (pure Dart — no Flutter, no cloud)
abstract class ExerciseSelector {
  /// Given the non-PII facts + the child's graph position, choose the next authored
  /// baa exercise id. Online: the RemoteAgent's TutorPlan.nextExerciseId. Offline: this walker.
  String? selectNext(TutorFacts facts, GraphPosition position);
}

class CurriculumGraphWalker implements ExerciseSelector {
  CurriculumGraphWalker(this.graph);
  final CurriculumGraph graph;
  @override
  String? selectNext(TutorFacts facts, GraphPosition position) {
    if (facts.passed) return graph.nextForward(position);          // advance the chain
    return graph.remediateOneTier(facts.section, position);        // drop a tier (manqul floor)
  }
}
```
The router (a Riverpod provider, mirroring `tutorBrainFactoryProvider`) picks online↔offline: if the `RemoteAgentBrain` returns a decision whose `plan.nextExerciseId` is present and graph-legal, use it; otherwise (offline/timeout/illegal) fall to `CurriculumGraphWalker`. **The graph is the shared source of truth** (D-09): the walker and the server reason over byte-identical graphs derived from the same asset.

### Pattern 5: Drift resume position (D-08) + trajectory replay

**What:** A new Drift table persists the child's graph position (cleared competencies + cleared tiers + the current node) so re-entry restores it across an app restart. The session trajectory (recent mistakes/struggles) is replayed to the agent via the existing FACTS payload.
**When to use:** DYN-02 resume.
**Example (the table + the schema bump, mirroring the existing `LetterMastery`/`LetterReps` tables):**
```dart
// Source: pattern from lib/data/app_database.dart (LetterReps table + migration)
class LetterGraphPosition extends Table {
  TextColumn get letterId => text()();
  TextColumn get currentExerciseId => text().nullable()();
  TextColumn get clearedCompetencies => text()();   // JSON-encoded List<String>
  TextColumn get clearedTiers => text()();           // JSON-encoded List<String>
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {letterId};
}
// schemaVersion 4 -> 5; in onUpgrade: if (from < 5) await m.createTable(letterGraphPosition);
```
**Migration mechanics (verified in `app_database.dart`):** bump `schemaVersion` 4→5; add `if (from < 5) await m.createTable(letterGraphPosition);` to the existing `onUpgrade` switch (version-guarded for idempotency — Pitfall 4 in that file); after editing the table set, run `dart run build_runner build` to regenerate `app_database.g.dart` (gitignored `.g.dart` files are regenerated, NOT hand-edited). **Resume the AGENT's reasoning** by replaying `recentMistakes`/`trajectory`/`strengthTags` — those already cross the wire (`tutor_facts.dart`); add `clearedTiers`/`clearedCompetencies` to `TutorFacts` + `TutorFactsIn` (the server DTO has `extra="forbid"`, so the two MUST be added in lockstep — see Pitfall below).

### Pattern 6: On-device mastery condition (D-06, scorer-owned star)

**What:** A pure-Dart `MasteryCondition.isMet(graph, position, repsByExercise)` that returns true iff **every essential competency through the mastery section is cleared at mom's per-skill clean-reps**. The star write stays the existing `recordMastery()` (no server trust — ADR-014).
**When to use:** DYN-02's "one quiet star at mastery."
**Example:**
```dart
// lib/curriculum/mastery_condition.dart  (pure Dart)
bool isMasteryMet(CurriculumGraph g, Map<String,int> cleanRepsByExercise) {
  // Essential core only (70/30): enrichment nodes never gate the star.
  for (final node in g.essentialNodes) {                 // essential==true competencies
    if ((cleanRepsByExercise[node.exerciseId] ?? 0) < node.minCleanReps) return false;
  }
  return true;   // recognize→positionalForms→copyWrite→fluentReading all cleared at mom's reps
}
```
This replaces `LetterUnitController._onEnterSection`'s "reaching Mastery records the letter mastered" (which fired on simply navigating to section 5). The new condition fires `recordMastery()` ONLY when the deterministic core is genuinely complete — and it is computed on-device from Drift clean-rep counts, never from a server response (the agent can `intent: "advance"` but cannot grant the star).

### Anti-Patterns to Avoid

- **Trusting the server for mastery.** The agent's `advance`/`intent:"advance"` is a SUGGESTION; the star is computed on-device (ADR-014, D-06). Never write `recordMastery()` off a `CoachOut`.
- **Rebuilding selection in the canvas from agent state.** The Phase-11 kill-shot (ADR-014 §3): dispatch imperatively; never make exercise selection a reactive rebuild of the `StrokeCanvas`. Selection chooses *which exercise config to present*; it does not re-render the canvas from the model.
- **Widening the client `TutorFacts` without the server DTO.** `TutorFactsIn` is `extra="forbid"`; an un-mirrored new field 422s the live `/coach`. Add `clearedTiers`/`clearedCompetencies` to BOTH `lib/tutor/tutor_facts.dart` and `server/app/schema.py` in the same change (the existing code comments this exact trap).
- **Shipping the graph unsigned.** Mirror `AUTHORED_BAA_IDS`: `signedOff: false` until mom signs at the tier level (D-05). A `signedOff:false` graph may render/walk for dev but must be gated behind the human-verify checkpoint before it's the demo path.
- **Introducing ت/ث coaching.** D-11: reinforce baa's own dot only; no cross-letter contrast.
- **A non-adaptive linear fallback offline.** D-09: offline must still walk the graph adaptively (advance/remediate), not revert to the old fixed 6-section sequence.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Membership validation (is this an authored baa id?) | A new id check | The existing `is_authored` / `AUTHORED_BAA_IDS` (G4) | Already built, tested, sign-off-gated; the graph rail sits ON TOP of it (D-02) |
| Asset→server sync | A new sync script / manual transcription | Extend `generate.py` (the proven derive-from-assets) | Provably can't drift; one command regenerates (`uv run python -m app.curriculum_data.generate`) |
| Non-PII FACTS construction | A new payload builder | The existing `buildTutorFacts` chokepoint | GROUND-02 guard already enforces no strokes/PII; just add the two cleared-* fields |
| Online↔offline routing | A new transport layer | The existing `tutorBrainFactoryProvider` + `RemoteAgentBrain` degrade-to-floor | The degrade path (timeout/offline/error → AuthoredFallback) is already correct; selection rides it |
| Degrade-on-error in the graph | New error handling | The existing `with_structured_retry` + `StructuredOutputError` → 503 → client fallback | `test_grounding.py::test_endpoint_degrades_on_structured_error` already pins this contract |
| Drift migration plumbing | A new persistence layer | Extend `app_database.dart` (version-guarded `onUpgrade`) | The table+migration+watch-stream pattern is established (`LetterReps`, `LetterMastery`) |
| Faithfulness check harness | A new eval framework / LLM judge | A `pytest.mark.code` test over a JSONL fixture | D-10 is model-free + verdict-driven; the `server/tests/` `code` marker + fixture pattern already runs in CI |

**Key insight:** Phase 15 is a thickening, not a greenfield. Almost every "how do I…" already has an answer in the Phase-14 code; the genuinely new artifacts are exactly four — the graph asset, the walker+mastery-condition Dart, the Drift position table, and the faithfulness check. Everything else extends a proven seam.

## Runtime State Inventory

> Phase 15 introduces NEW persisted state (graph position) and a NEW derived server copy. This is not a rename/refactor, but the derive-from-assets + Drift-migration surfaces warrant the same explicit audit.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **Drift on-device:** existing `LetterMastery` (star), `LetterReps` (clean-reps), `AppSettings`. NEW: `LetterGraphPosition` (cleared competencies/tiers, current node). No server-side child data (server stateless — ADR-015 §5). | **Code edit** (new table) + **schema migration** (v4→v5, version-guarded). No data backfill needed: a child with no row starts at graph root (clean default). |
| Live service config | The deployed Cloud Run `qalam-tutor` reads `baa_authored_ids.json` from the image. The NEW `curriculum_graph.json` (derived) must be COPIED INTO THE IMAGE by the Dockerfile (the existing `generate.py` note says "Flutter assets are not in the Docker image" — only the derived JSON is). | **Build/deploy step:** ensure the Dockerfile copies `app/curriculum_data/curriculum_graph.json` (it already copies the `app/` package, so a derived file under `curriculum_data/` ships automatically — verify the `.dockerignore` doesn't exclude it). Re-deploy after regenerating. |
| OS-registered state | None — no OS-level registrations touched. | None. |
| Secrets/env vars | None new. The faithfulness check is offline pytest (no keys). The `models.py` env overrides (`PLAN_MODEL`, etc.) are unchanged; the prompt thickening is code/data only. | None. |
| Build artifacts | `app_database.g.dart` (Drift codegen) is regenerated after the table change; `*.g.dart` for new Riverpod providers. `server/app/curriculum_data/curriculum_graph.json` is a generated artifact (committed, like `baa_authored_ids.json`). | **Reinstall/regenerate:** `dart run build_runner build` after the schema change; `uv run python -m app.curriculum_data.generate` after the asset is authored. |

**Nothing found in OS-registered state and Secrets categories — verified by:** the server is stateless with no scheduled jobs; the only secrets (`ANTHROPIC_API_KEY` / Vertex ADC) are unchanged from Phase 14; the faithfulness check runs offline.

## Common Pitfalls

### Pitfall 1: Client/server FACTS schema drift (the 422 trap)
**What goes wrong:** Adding `clearedTiers`/`clearedCompetencies` to the Dart `TutorFacts` but not to the server `TutorFactsIn` makes the live `/coach` reject the legit enlarged payload with a 422 (the DTO is `extra="forbid"`).
**Why it happens:** Two source-of-truth files for one wire contract; the server is deployed separately.
**How to avoid:** Add the fields to `lib/tutor/tutor_facts.dart` (`toMap`) AND `server/app/schema.py` (`TutorFactsIn`) in the same plan/task; re-deploy the server before the device test. The existing `payload_nonpii_test.dart` + `test_payload_nonpii.py` pair should be extended to assert the new fields are present and non-PII.
**Warning signs:** A device build that worked on the offline floor but 503/degrades the moment it goes online (server 422 → client falls to fallback).

### Pitfall 2: Mastery firing on navigation, not on real completion
**What goes wrong:** The old `LetterUnitController._onEnterSection` records mastery the instant the child reaches section 5 (`atMastery`), regardless of clean-reps. Carrying that into the graph flow would grant the star for merely *navigating* to a node.
**Why it happens:** The fixed-walk controller conflated "reached the last section" with "mastered."
**How to avoid:** Gate `recordMastery()` behind the NEW `isMasteryMet(...)` deterministic condition (D-06), computed from Drift clean-rep counts on essential nodes only. Retire the `atMastery` auto-write for baa.
**Warning signs:** A star appearing after a child clicks through without passing exercises; `cleanReps: 0` mastery rows (the current `_recordMastery` writes `cleanReps: 0`).

### Pitfall 3: Backward remediation rejected by the forward guards
**What goes wrong:** A naive "forward-only" guard rejects the agent's *correct* remediation move (dictation→look-write), dead-ending the child on a tier they can't pass.
**Why it happens:** Conflating "tier-reachable / prereqs-met" (the legal-forward check) with "must always go to a HIGHER tier."
**How to avoid:** G5/G6 check only that the chosen node's tier is *reachable* and its competency's prereqs are *met* — a lower tier of an already-reached competency satisfies both, so remediation passes. Forward-only means "no skipping ahead," not "no stepping back within a reached competency." Add a unit test that asserts `ghayrManzur fail → manzur` is graph-legal.
**Warning signs:** Online runs degrading to the floor specifically after a dictation fail (a guard wrongly raising `StructuredOutputError` on the remediation).

### Pitfall 4: Treating the unsigned graph as the demo path
**What goes wrong:** Shipping the model-DRAFTED graph (intro order, tier assignments, clean-reps) as if mom signed it — violating the project's never-ship-unsigned-curriculum rule.
**Why it happens:** The graph renders and walks fine before sign-off (like the draft `referenceStrokes`).
**How to avoid:** `signedOff: false` on the graph until mom signs at the tier level (D-05). Mirror the `AUTHORED_BAA_IDS` sign-off gate: a human-verify checkpoint task that flips `signedOff: true` only after her review. The DRAFT mapping table lives in `national-curriculum-grade1.md` (§"Open for owner-mother sign-off") — Claude produces the clean sign-off sheet, she confirms competency mapping + tiers + the 70/30 split + clean-reps.
**Warning signs:** A commit flipping `signedOff: true` without a corresponding human-UAT entry.

### Pitfall 5: Offline walk silently linear (D-09 regression)
**What goes wrong:** When the agent is unavailable, selection quietly reverts to the old fixed 6-section sequence instead of the adaptive graph walk.
**Why it happens:** The Phase-14 degrade path falls to `AuthoredFallbackBrain` for COACHING — but `AuthoredFallbackBrain` has no selection logic. If selection isn't separately routed to the walker, it defaults to whatever the static walk was.
**How to avoid:** Route selection through the `ExerciseSelector` seam (Pattern 4): online → `TutorPlan.nextExerciseId`, offline → `CurriculumGraphWalker`. Coaching and selection degrade independently (coaching → authored lines; selection → deterministic walk). A widget/integration test should assert that with the server unreachable, a fail still produces a *remediation* selection, not the next linear section.
**Warning signs:** Airplane-mode demo showing the same fixed order as v1.

### Pitfall 6: Riverpod 3 StreamProvider hang on the resume read
**What goes wrong:** Reading the Drift graph-position stream via a bare `StreamProvider.future` hangs (Riverpod 3 pauses unlistened StreamProviders).
**Why it happens:** Documented project gotcha (MEMORY: riverpod3-streamprovider-future-hangs).
**How to avoid:** Use the established `_bindDriftStream` AsyncNotifier bridge pattern for any live drift-stream resume data; for a one-shot resume read at unit entry, prefer a `Future`-returning repository method (`getPosition(letterId)`), not a stream `.future`.
**Warning signs:** The unit screen stuck on the "preparing" panel after a relaunch.

## Code Examples

### Loading the graph on the server (mirror `_load_authored_ids`)
```python
# Source: pattern from server/app/curriculum.py::_load_authored_ids (verified)
import json, pathlib
_GRAPH_PATH = pathlib.Path(__file__).resolve().parent / "curriculum_data" / "curriculum_graph.json"

def _load_graph() -> dict:
    return json.loads(_GRAPH_PATH.read_text(encoding="utf-8"))

CURRICULUM_GRAPH = _load_graph()   # loaded once at import, like AUTHORED_BAA_IDS
```

### The model-free faithfulness check (GROUND-03, D-10)
```python
# Source: pattern from server/tests/test_grounding.py (pytest.mark.code, model-free)
# server/tests/test_faithfulness.py
import json, pathlib
import pytest
pytestmark = pytest.mark.code

_SET = pathlib.Path(__file__).parent / "fixtures" / "faithfulness_set.jsonl"
_PRAISE = ("beautiful", "perfect", "great job", "well done", "أحسنت", "mastered")

def _contradicts(passed: bool, coaching: str, expected_fix: str | None) -> bool:
    line = coaching.lower()
    # (a) praising a FAILED stroke
    if not passed and any(p in line for p in _PRAISE):
        return True
    # (b) naming the WRONG fix: on a fail, the coaching must mention the expected-fix token
    if not passed and expected_fix and expected_fix.lower() not in line:
        return True
    return False

def test_faithfulness_rate_reported(capsys):
    cases = [json.loads(l) for l in _SET.read_text(encoding="utf-8").splitlines() if l.strip()]
    faithful = sum(
        0 if _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) else 1
        for c in cases
    )
    rate = faithful / len(cases)
    print(f"GROUND-03 faithfulness rate: {faithful}/{len(cases)} = {rate:.2%}")
    assert rate >= 1.0   # the labeled gold set is constructed faithful; a regression drops it
```
```jsonl
// server/tests/fixtures/faithfulness_set.jsonl  (10–16 labeled cases — see Reference-set sizing)
{"passed": false, "mistakeId": "shallowBowl", "expectedFix": "deeper curve", "coaching": "Your baa needs a deeper curve at the bottom — try again, slower."}
{"passed": false, "mistakeId": "noDot", "expectedFix": "dot", "coaching": "The bowl is lovely — now place the dot just below it."}
{"passed": true, "mistakeId": null, "expectedFix": null, "coaching": "Beautiful — a deep, smooth bowl. أحسنت!"}
// + adversarial faithful-vs-contradiction pairs: a fail with "Great job!" (must be flagged),
//   a fail naming the dot when the curve failed (wrong-fix, must be flagged), etc.
```
The set is model-agnostic: it scores *coaching lines against fixed verdicts*, so it works for Claude OR Gemini output (it does not call a model). Phase 13/16 grow this into the calibrated-judge harness (the AI-SPEC §5 D1/D2 dimensions); Phase 15 ships only the deterministic floor.

### The deterministic graph walk (offline, pure Dart)
```dart
// lib/curriculum/curriculum_graph_walker.dart
String? selectNext(TutorFacts facts, GraphPosition pos) {
  if (facts.passed) {
    return graph.nextForward(pos);                  // next reachable node in the chain
  }
  // remediate one tier down WITHIN the same competency (ghayrManzur→manzur→manqul);
  // at the manqul floor, re-present the same node (drill in place).
  return graph.remediateOneTier(facts.section, pos) ?? pos.currentExerciseId;
}
```

## State of the Art

| Old Approach (v1 / pre-Phase-15) | Current Approach (Phase 15) | When Changed | Impact |
|----------------------------------|-----------------------------|--------------|--------|
| Fixed `meet→…→mastery` walk via `LetterUnitController` (index + visited set) | Agent-driven selection (online) / deterministic graph walk (offline) over a curriculum graph | This phase | The child's path responds to recent mistakes (backward remediation) instead of a fixed order (DYN-01/SC-1) |
| In-memory `_resumeByLetter` map (lost on restart) | Drift `LetterGraphPosition` table (survives restart) | This phase | Resume actually persists (D-08); trajectory replayed to the agent |
| Star recorded on *reaching* the mastery section | Star recorded only when the deterministic essential-core condition is met (70/30, mom's reps) | This phase | The star means real mastery (D-06); no star for clicking through |
| Membership-only rail (`AUTHORED_BAA_IDS`, G3/G4) | Membership + order/prereq/difficulty rail (G3/G4 + new G5/G6) | This phase | The agent can't present an unreached tier or skip a prerequisite (D-02) |
| Grounding faithfulness asserted by hard checks only (advance-on-fail, etc.) | + a measured faithfulness RATE over a labeled (verdict, coaching) set | This phase | GROUND-03's "a faithfulness rate is reported"; seeds Phase 13/16 |

**Deprecated/outdated for baa:**
- `LetterUnitController`'s `atMastery` auto-write — superseded by `isMasteryMet`.
- The fixed section sequence as the *only* path — superseded by the graph (kept as the data the graph is derived from, not the runtime walk).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The baa-config→competency→tier mapping (recognize/positionalForms/copyWrite/fluentReading essential; wordBuilding/grammar enrichment) is correct | Pattern 2 schema | **Provisional by design (D-05) — mom signs.** If wrong, the wrong exercises gate the star. Mitigated: `signedOff:false` until her review; the DRAFT table in `national-curriculum-grade1.md` is the sign-off sheet. |
| A2 | `minCleanReps` draft values (3 for trace, 2 for write, 1 for teach/sentence) | Pattern 2 schema | Owner-mother's to set (D-07). Draft-only; tuned at sign-off like `tolerances`. |
| A3 | The 70/30 essential/enrichment split maps to "essential = recognize+forms+copy+fluent reading; enrichment = richer word/grammar/dictation-from-memory" | Pattern 2, mastery | The national curriculum names 70/30 but the per-exercise assignment is interpretive; mom confirms (national-curriculum-grade1.md §"Open for sign-off"). |
| A4 | The Dockerfile ships any new file under `server/app/curriculum_data/` automatically (it copies the `app/` package) | Runtime State Inventory | If `.dockerignore` excludes JSON or the file, the derived graph is missing at runtime → the rail fails closed. **Verify the Dockerfile/`.dockerignore` during planning.** |
| A5 | A separate `curriculum_graph.json` asset is preferable to inlining fields into `exercises.json` | Alternatives | Low risk — both work; the separate file is recommended for an independent sign-off gate. Planner may choose inline if simpler. |
| A6 | The faithfulness check's `_PRAISE` lexicon + expected-fix-token rule is sufficient to flag the D-10 failure modes | Code Examples | A lexicon check is coarse (could miss a paraphrased praise). Acceptable for the *minimal* slice (D-10 explicitly minimal); Phase 13/16 add the calibrated judge. Document it as a floor, not a ceiling. |

**This table is non-empty because the curriculum graph is NEW pedagogy (owner-mother's domain) — A1/A2/A3 are exactly the items her sign-off resolves (D-05). The planner must gate them behind a human-verify checkpoint, not treat them as locked.**

## Open Questions (RESOLVED)

1. **Where does selection get invoked in the section flow?**
   - What we know: `ExerciseScaffold._onResult` is the per-attempt seam where the verdict is scored and `brain.next(facts)` is called for COACHING. The fixed walk advances via `onAdvance`/`onNext` callbacks the *section* widgets fire.
   - What's unclear: whether Phase 15 drives selection at the *unit* level (replace `LetterUnitScreen._section`'s section switch with a single config-presenter fed by the selector) or threads selection through the existing section widgets.
   - Recommendation: drive at the unit level — replace the fixed `_section(index)` switch with a single "present the selected exercise config" surface fed by the `ExerciseSelector`. This is the cleanest "replace the fixed walk end-to-end" (DYN-02) and reuses `ExerciseScaffold` (already config-driven). The planner should confirm against `letter_unit_screen.dart` section wiring.
   - **RESOLVED: drive selection at the UNIT level — `letter_unit_screen.dart`'s `_section(index)` switch is replaced by a single config-presenter fed by the `ExerciseSelector` router (see plan 15-05, Task 2; the router itself is plan 15-05, Task 1).**

2. **Does the agent's `present_activity.letter_id` carry an EXERCISE id or a SECTION id?**
   - What we know: `is_authored` accepts BOTH section ids and exercise ids (`curriculum.py` docstring). The plan node emits `next_exercise_id` (an exercise id); `present_activity` takes `letter_id` (named loosely).
   - What's unclear: which the dispatcher should present in the dynamic flow.
   - Recommendation: standardize on EXERCISE ids for selection (the graph nodes are exercises). Keep section ids valid for `present_activity` for backward compatibility, but the graph rail and walker operate on exercise ids.
   - **RESOLVED: selection standardizes on EXERCISE ids — the graph nodes are exercises, the server rail keys on exercise ids (see plan 15-02), and the offline walker keys on exercise ids (see plan 15-03); section ids stay valid for `present_activity` for backward compatibility.**

3. **Clean-rep accounting per exercise for the mastery condition.**
   - What we know: `LetterReps` stores ONE `cleanReps` per `letterId` (not per exercise); `ExerciseController` tracks per-exercise reps in-memory only.
   - What's unclear: D-06 needs per-essential-exercise clean-reps to evaluate mastery; the current Drift schema is per-letter.
   - Recommendation: persist clean-reps per exercise (extend `LetterReps` to key on `(letterId, exerciseId)` or add a column) so `isMasteryMet` can read them after a restart. The planner should decide the exact shape; flag as a schema concern alongside the position table.
   - **RESOLVED: persist clean-reps PER EXERCISE in Drift (composite `(letterId, exerciseId)` key or a sibling table — the executor picks the lower-migration-risk shape and records it in the SUMMARY) so `isMasteryMet` reads them after a restart (see plan 15-04, Task 1, alongside the `LetterGraphPosition` table).**

> Assumption A4 (Dockerfile/`.dockerignore` ships the derived `curriculum_data/curriculum_graph.json`) is **CONFIRMED** in plan 15-02, Task 1 (the Dockerfile copies the whole `app/` package and `.dockerignore` does not exclude the derived graph). RESEARCH already records A4 as verified during planning.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python LangGraph stack | `plan.py` thickening + faithfulness check | ✓ | langgraph 1.2.6 / langchain 1.3.10 (`server/.venv`) | — |
| `pytest` (`code` marker) | GROUND-03 faithfulness check | ✓ | pytest 9.1.1 | — |
| Flutter SDK + `drift_dev` (build_runner) | Drift table codegen | ✓ (project builds) | drift ^2.31 | — |
| Deployed Cloud Run `qalam-tutor` | Online selection device test | ✓ (rev qalam-tutor-00003-7gv; keyless Vertex) | — | Offline walker (D-09) — selection works without the server |
| Owner-mother sign-off (graph tiers/competencies/reps) | Flipping `signedOff: true` | ✗ (human, async) | — | Ship `signedOff:false` for dev/demo-build; human-verify checkpoint gates the signed path |

**Missing dependencies with no fallback:** none blocking. The owner-mother sign-off is a human gate (mirrors every prior curriculum sign-off) — the code ships and runs against the provisional graph; only the *signed* flag waits on her.

**Missing dependencies with fallback:** the deployed server (offline walker covers selection per D-09).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework (client) | `flutter_test` (Dart) — unit + widget |
| Framework (server) | `pytest` 9.1.1 + `pytest-asyncio` 1.4.0; `pytest.mark.code` for model-free CI-gating checks |
| Config file (server) | `server/pyproject.toml` (`[tool.pytest.ini_options]`, `asyncio_mode=auto`, `markers=["code: …"]`) |
| Config file (client) | `test/flutter_test_config.dart` (loads bundled fonts for Arabic goldens) |
| Quick run command (server) | `cd server && uv run pytest tests/test_faithfulness.py -q` |
| Quick run command (client) | `flutter test test/curriculum/ test/tutor/` |
| Full suite command (server) | `cd server && uv run pytest -q` |
| Full suite command (client) | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior (observable) | Test Type | Automated Command | File Exists? |
|--------|-----------------------|-----------|-------------------|-------------|
| DYN-01 | Plan node, given a repeated `shallowBowl` struggle, selects a trace-drill within the reachable tier (not a forward jump) | server unit | `uv run pytest tests/test_plan_graph.py::test_struggle_selects_within_tier -q` | ❌ Wave 0 |
| DYN-01 | G5 rejects an exercise in an unreached tier → `StructuredOutputError` → degrade | server unit | `uv run pytest tests/test_plan_graph.py::test_unreached_tier_rejected -q` | ❌ Wave 0 |
| DYN-01 | G6 rejects an exercise whose prerequisite competency is uncleared | server unit | `uv run pytest tests/test_plan_graph.py::test_prereq_unmet_rejected -q` | ❌ Wave 0 |
| DYN-01 | Backward remediation (ghayrManzur fail → manzur) is graph-LEGAL (NOT rejected) | server unit | `uv run pytest tests/test_plan_graph.py::test_backward_remediation_allowed -q` | ❌ Wave 0 |
| DYN-01 | An unauthored/unsigned id is still rejected (G4 unchanged) | server unit | extend `tests/test_grounding.py` | ✅ (G4 covered; add graph case) |
| DYN-01 | Offline walker: pass → next forward node; fail → one tier down | client unit | `flutter test test/curriculum/curriculum_graph_walker_test.dart` | ❌ Wave 0 |
| DYN-02 | Re-entering the baa unit restores the persisted graph position across a simulated restart | client unit | `flutter test test/data/graph_position_repository_test.dart` (re-open a 2nd AppDatabase over a shared in-memory executor — the D-09 restart shape) | ❌ Wave 0 |
| DYN-02 | The dynamic flow (not the fixed section switch) drives the baa unit; a fail re-surfaces a remediation exercise | client widget | `flutter test test/features/letter_unit/dynamic_selection_test.dart` | ❌ Wave 0 |
| DYN-02 | One quiet star fires ONLY when `isMasteryMet` is true (essential core at mom's reps); NOT on navigation | client unit | `flutter test test/curriculum/mastery_condition_test.dart` | ❌ Wave 0 |
| DYN-02 | `recordMastery` is NOT called for a clicked-through unit with unmet reps | client widget | extend `test/features/letter_unit/letter_unit_screen_test.dart` | ✅ (file exists; add case) |
| GROUND-03 | The check flags coaching that praises a failed stroke | server unit | `uv run pytest tests/test_faithfulness.py::test_flags_praise_on_fail -q` | ❌ Wave 0 |
| GROUND-03 | The check flags coaching that names the wrong fix | server unit | `uv run pytest tests/test_faithfulness.py::test_flags_wrong_fix -q` | ❌ Wave 0 |
| GROUND-03 | The check reports a faithfulness RATE (printed/asserted) | server unit | `uv run pytest tests/test_faithfulness.py::test_faithfulness_rate_reported -s -q` | ❌ Wave 0 |
| GROUND-02 (regression) | The enlarged FACTS (clearedTiers/clearedCompetencies) carry no PII/strokes | client + server | extend `test/tutor/payload_nonpii_test.dart` + `server/tests/test_payload_nonpii.py` | ✅ (both exist; add fields) |

### Sampling Rate
- **Per task commit:** the relevant quick command (`uv run pytest tests/test_plan_graph.py -q` or `flutter test test/curriculum/`).
- **Per wave merge:** full server suite (`uv run pytest -q`) + full client suite (`flutter test`).
- **Phase gate:** both suites green before `/gsd-verify-work`; the deployed-server online path is a human-UAT item (device test with `--dart-define=TUTOR_BASE_URL=…`), since the live `/coach` call needs App Check + a real model — mirrors the Phase-14 UAT gate.

### Wave 0 Gaps
- [ ] `server/tests/test_plan_graph.py` — covers DYN-01 graph rail (G5/G6/remediation), monkeypatching the plan model like `test_grounding.py`
- [ ] `server/tests/test_faithfulness.py` + `server/tests/fixtures/faithfulness_set.jsonl` — covers GROUND-03
- [ ] `test/curriculum/curriculum_graph_test.dart`, `curriculum_graph_walker_test.dart`, `mastery_condition_test.dart` — covers the pure-Dart graph/walker/mastery
- [ ] `test/data/graph_position_repository_test.dart` — covers D-08 resume (simulated-restart shape, mirrors Phase 09's persisted-cooldown test)
- [ ] `test/features/letter_unit/dynamic_selection_test.dart` — covers DYN-02 end-to-end dynamic flow
- [ ] Extend `payload_nonpii_test.dart` / `test_payload_nonpii.py` for the two new FACTS fields
- [ ] Framework install: none (pytest + flutter_test both present)

## Security Domain

> `security_enforcement: true`, ASVS level 1. Phase 15 adds no auth surface and no new network endpoint — it extends the existing App-Check-gated `/coach` call and adds on-device persistence. The dominant security concern is **child-data minimization (COPPA / GROUND-02)**, which is already enforced and must be preserved as FACTS grow.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged) | `/coach` already requires Firebase ID token + App Check (`auth.py`); the faithfulness check is offline |
| V3 Session Management | no | Server stateless (ADR-015 §5); no session state added |
| V4 Access Control | no (unchanged) | Drift is app-private; no parent/child privilege boundary touched |
| V5 Input Validation | **yes** | Pydantic `extra="forbid"` on `TutorFactsIn`/`AttemptFactIn` (the non-PII chokepoint); the new `clearedTiers`/`clearedCompetencies` are validated string-lists; the graph JSON is parsed with the defensive `fromJson` idiom |
| V6 Cryptography | no | No new secrets; PIN/PBKDF2 (Phase 09) untouched; never hand-roll crypto here |
| (COPPA/data-min, project-specific) | **yes** | Only derived non-PII facts cross the wire; resume state (graph position) lives on-device only; server persists nothing child-derived |

### Known Threat Patterns for {Flutter client + LangGraph server + new on-device persistence}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Leaking child PII / raw strokes via the enlarged FACTS | Information Disclosure | The `buildTutorFacts` chokepoint accepts no stroke/profile param; `extra="forbid"` server-side; extend the non-PII tests to the two new fields (Pitfall 1) |
| Agent flipping a fail to a pass / granting a star | Tampering / Elevation | ADR-014 invariant: scorer owns the verdict + star; mastery computed on-device; G3 verdict-lock unchanged; G5/G6 only restrict selection, never the verdict |
| Server reading a missing/tampered graph file → unbounded selection | Tampering | The graph is a committed, derived artifact loaded once at import; `is_authored` (G4) still bounds every id; a missing graph fails closed to AuthoredFallback |
| Unsigned (model-DRAFTED) pedagogy reaching a child | (trust/integrity) | `signedOff:false` gate + human-verify checkpoint (D-05) — mirrors `AUTHORED_BAA_IDS` |
| Drift corruption / failed migration on the position table | Denial of Service | Version-guarded idempotent `onUpgrade`; a child with no position row defaults to graph root (no crash, clean start) |

## Sources

### Primary (HIGH confidence) — read directly this session
- `.planning/phases/15-…/15-CONTEXT.md` — the locked design (D-01..D-11)
- `.planning/REQUIREMENTS.md` — DYN-01, DYN-02, GROUND-03 full text + traceability
- `docs/architecture/ADR-014-…md` / `ADR-015-…md` — grounding invariant, topology, seam impact
- `.planning/phases/14-…/14-AI-SPEC.md` — eval strategy §5–§7 (the faithfulness check seeds from D1/D2)
- `server/app/`: `curriculum.py`, `curriculum_data/{generate.py, baa_authored_ids.json}`, `nodes/{plan.py, coach.py, analyze.py}`, `tools.py`, `graph.py`, `state.py`, `schema.py`, `models.py`, `prompts.py`
- `server/tests/`: `test_grounding.py`, `conftest.py` (the model-free `code`-marker pattern the faithfulness check mirrors)
- `lib/tutor/`: `tutor_brain.dart`, `tutor_decision.dart`, `tutor_facts.dart`, `tutor_facts_builder.dart`, `authored_fallback_brain.dart`, `remote_agent_brain.dart`, `tutor_dispatcher.dart`, `tutor_providers.dart`
- `lib/data/`: `app_database.dart` (migration mechanics + mastery/reps tables), `drift_progress_repository.dart`
- `lib/features/letter_unit/`: `letter_unit_controller.dart`, `letter_unit_screen.dart`, `exercise_controller.dart`, `widgets/exercise_scaffold.dart`
- `lib/models/`: `letter_unit.dart`, `exercise.dart`
- `assets/curriculum/{units.json, exercises.json}` — the seed extended by the graph
- `docs/curriculum/{national-curriculum-grade1.md, baa-family-authoring-sketch.md}` — the competency + difficulty lattice + sign-off framing
- `server/.venv` `pip freeze` (2026-06-27) — verified installed versions
- `.planning/config.json` — nyquist_validation on, security_enforcement on (ASVS 1)

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` + auto-MEMORY — deployment facts (Cloud Run rev, keyless Vertex), Riverpod-3 StreamProvider gotcha, l10n-gitignored, golden font drift, curriculum sign-off strategy

### Tertiary (LOW confidence)
- None — no WebSearch/Context7 needed; nothing new is installed and every seam is in-repo.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every library already pinned + in use; versions verified via `pip freeze`; no new installs.
- Architecture (the six discretion areas): HIGH — every seam (plan node, FACTS chokepoint, Drift migration, dispatcher, generate.py) read directly; the design extends proven patterns 1:1.
- Curriculum-graph pedagogy (mapping/tiers/reps/70-30): MEDIUM by design — DRAFT pending owner-mother sign-off (A1–A3); the *mechanics* are HIGH, the *values* are provisional (D-05).
- Pitfalls: HIGH — drawn from the in-repo code comments (the 422 trap, the mastery-on-navigation bug, the migration idempotency guard) and project MEMORY.

**Research date:** 2026-06-27
**Valid until:** 2026-07-27 (stable — internal seams; the only external surface, the LangGraph stack, is pinned and the deploy is frozen). Re-verify the Dockerfile/`.dockerignore` graph-copy assumption (A4) and the per-exercise clean-rep schema (Open Q3) at plan time.
