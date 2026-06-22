---
phase: 14-build-tutorbrain-spine-grounding-invariant
plan: 02
subsystem: tutor-server
tags: [langgraph, grounding-invariant, structured-output, curriculum-guard, per-node-routing, conditional-edge]
status: complete
requires:
  - "Plan 01: the server/ FastAPI+LangGraph sub-project, TutorFactsIn wire contract, TutorState, the 4 ACTION tools, the one-node stub graph"
provides:
  - "The full analyze -> {plan|coach} -> coach grounding graph (conditional edge: clean pass = 1 hop, struggle = 3)"
  - "Per-node init_chat_model routing table (app/models.py), env-driven + eval-tunable, explicit max_tokens"
  - "Insight + Plan internal Pydantic schemas with a bounded 2-retry structured helper (fail-closed -> StructuredOutputError)"
  - "AUTHORED_BAA_IDS curriculum-membership guard (G4) loaded from the owner-signed bundled seed"
  - "Server-side grounding invariant: G3 advance-on-fail rewrite/downgrade (plan intent AND coach action), G2 action-space lock"
affects:
  - "Plan 03 (Flutter client wires /coach; the CoachOut.grounded flag + the 4 ACTION names are the consumed contract)"
  - "Plan 04 (GROUND-02 build-failing guard builds on this DTO; unchanged here)"
  - "Phase 16 eval harness (the routing table is the Claude-vs-Gemini bake-off surface; Insight/Plan are the structured-judge inputs)"
tech-stack:
  added: []
  patterns:
    - "LangGraph add_conditional_edges(needs_plan) as the cost lever (skip plan on a clean pass)"
    - "init_chat_model per node, built lazily + env-driven so import needs no provider key and eval can retune routing"
    - "with_structured_output(Pydantic) wrapped in a bounded 2-retry-then-fail-closed helper"
    - "post-parse grounding guards (G3 verdict lock, G4 curriculum membership) as code, not prompt-only"
    - "bind_tools(ACTION_TOOLS, tool_choice='any') as the structural action-space lock, online-guarded for advance-on-fail + unauthored ids"
    - "bundled JSON seed (app/curriculum_data) regenerated from the canonical Flutter assets so the Docker image carries the signed id set without the whole assets tree"
key-files:
  created:
    - server/app/models.py
    - server/app/curriculum.py
    - server/app/curriculum_data/__init__.py
    - server/app/curriculum_data/generate.py
    - server/app/curriculum_data/baa_authored_ids.json
    - server/app/nodes/__init__.py
    - server/app/nodes/_retry.py
    - server/app/nodes/analyze.py
    - server/app/nodes/plan.py
    - server/app/nodes/coach.py
    - server/tests/test_graph.py
    - server/tests/test_grounding.py
  modified:
    - server/app/graph.py
    - server/app/main.py
    - server/app/prompts.py
    - server/tests/test_endpoint.py
decisions:
  - "AUTHORED_BAA_IDS sourced from a bundled JSON seed (app/curriculum_data/baa_authored_ids.json) generated VERBATIM from the canonical assets/curriculum/{units,exercises}.json — not a planner guess. The Dockerfile copies only app/, so reading the Flutter assets at runtime is impractical; the bundled copy + a generate.py that rebuilds it from the canonical source keeps it drift-proof."
  - "TutorState (insight/plan fields) and CoachOut.grounded were ALREADY present from Plan 01 — the plan's 'extend' steps were no-ops, so state.py and schema.py are unmodified. Documented as a non-deviation."
  - "The curriculum guard accepts the 19 baa.* exercise ids + the 6 baa section ids + the 'baa' family token (26 total) — present_activity may name a concrete exercise, a section, or the family."
  - "build_coach_model lives in app/models.py; the coach node owns the bind_tools(tool_choice='any') call (build_coach_with_tools) so the action-space lock sits next to the node that needs it. The Plan-01 endpoint test was updated to patch the new node seam."
metrics:
  tasks_completed: 2
  tasks_total: 2
  files_created: 12
  files_modified: 4
  tests: "45 passed (15 Plan-01 + 30 new)"
  completed: 2026-06-22
---

# Phase 14 Plan 02: TutorBrain analyze→plan→coach Grounding Graph Summary

Deepened the Plan-01 one-node stub into the full grounded agent: an `analyze → {plan | coach} → coach` LangGraph with a conditional edge (a clean pass is one cheap hop, a struggle is three), per-node `init_chat_model` routing, structured `Insight`/`Plan` outputs with a bounded 2-retry-then-fail-closed helper, the 4 ACTION tools forced via `tool_choice="any"`, and the server-side grounding invariant — the agent structurally cannot flip a fail to a pass (G3) or reference an unauthored exercise (G4), and any error fails closed to the client's AuthoredFallback floor (G5).

## What was built

**Task 1 — analyze + plan nodes, routing table, curriculum guard (commit `bbb0ed2`):**
- `app/models.py`: the per-node routing table. `build_analyze_model` (gemini-2.5-flash, temp 0, max_tokens 512), `build_plan_model` (claude-sonnet-4-6, temp 0.2, 512), `build_coach_model` (claude-haiku-4-5, temp 0.5, 256) — every node has an explicit `max_tokens`, all env-overridable for the Phase-16 bake-off. Built lazily so import needs no provider key.
- `app/curriculum.py` + `app/curriculum_data/`: `AUTHORED_BAA_IDS` (26 ids) loaded from a bundled JSON seed generated verbatim from the canonical owner-signed assets. `is_authored()` is the G4 membership check. `generate.py` rebuilds the seed from `assets/curriculum/{units,exercises}.json`.
- `app/nodes/_retry.py`: `with_structured_retry` — 2 retries on `ValidationError`/`None`, then a typed `StructuredOutputError` (no infinite loop; logs node/model/attempt each retry).
- `app/nodes/analyze.py`: the `Insight` schema (struggle_tags/strength_tags/pattern_note) + the `analyze` node (FACTS as text, retry-wrapped).
- `app/nodes/plan.py`: the `Plan` schema (next_exercise_id/intent/rationale) + the `plan` node with the two post-parse guards — **G4** (unauthored `next_exercise_id` → `StructuredOutputError`) and **G3** (`intent=="advance"` on a fail → downgraded to `retest_whole`, `grounded=False`).
- `app/prompts.py`: real `ANALYZE_PROMPT`/`PLAN_PROMPT` (were Plan-01 stubs) + gold mother's-voice few-shot exemplars added to `COACH_PROMPT`.

**Task 2 — coach node, conditional-edge graph, online guards, degradation (commit `ffdcfdf`):**
- `app/nodes/coach.py`: the `coach` node binds the 4 ACTION tools `tool_choice="any"` (G2), injects `{facts, insight, plan}` as text, and applies the online guards — **G3** (forced `advance` on a fail → grounded `say`, `grounded=False`), **G4** (`present_activity` with an unauthored `letter_id` → `say`), plus a defensive out-of-set-name rejection.
- `app/graph.py`: the full `START → analyze → {plan|coach} → coach → END` DAG via `add_conditional_edges("analyze", needs_plan)` (a passed attempt with no struggle shortcuts to coach). Compiled with `InMemorySaver` (stateless). The one-node stub is gone.
- `app/main.py`: `StructuredOutputError` → `503 coach_degraded` so the client degrades to AuthoredFallback (the generic 503 path already covered other failures; this makes the fail-closed path explicit).

## AUTHORED_BAA_IDS — source + exact id set (for owner sign-off)

**Source (canonical, owner-signed):** `assets/curriculum/units.json` (baa section ids) + `assets/curriculum/exercises.json` (every `baa.`-prefixed exercise id) — the same bundled seed `CurriculumRepository.getUnit/getExercises` reads. Transcribed verbatim into `server/app/curriculum_data/baa_authored_ids.json` by `generate.py` (re-runnable; idempotent against the current assets). NOT a planner guess.

**6 baa section ids:** `meet`, `watchTrace`, `forms`, `words`, `listenWrite`, `mastery`

**19 baa exercise ids:** `baa.buildSentence.hear`, `baa.buildSentence.picture`, `baa.completeWord.middle`, `baa.connectWord.baab`, `baa.connectWord.kitaab`, `baa.fillBlank.adjective`, `baa.teachCard.meet`, `baa.traceLetter.initial`, `baa.traceLetter.isolated`, `baa.traceLetter.medial`, `baa.transformWord.dual`, `baa.transformWord.opposite`, `baa.transformWord.plural`, `baa.writeLetter.fromPicture`, `baa.writeLetter.fromSound`, `baa.writeLetter.writeForm`, `baa.writeWord.copy`, `baa.writeWord.dictation`, `baa.writeWord.picture`

Plus the `baa` family token → **26 ids total** in `AUTHORED_BAA_IDS`.

> **Owner sign-off needed:** confirm this id set matches the signed baa curriculum. If the seed changes, re-run `cd server && uv run python -m app.curriculum_data.generate` to refresh the bundled copy.

## Per-node model assignments (AI-SPEC §4 defaults; env-tunable)

| Node | Model | Provider | temperature | max_tokens |
|------|-------|----------|-------------|------------|
| analyze | `gemini-2.5-flash` | `google_genai` | 0.0 | 512 |
| plan | `claude-sonnet-4-6` | `anthropic` | 0.2 | 512 |
| coach | `claude-haiku-4-5` | `anthropic` | 0.5 | 256 |

Each is overridable via env (`ANALYZE_MODEL`, `PLAN_MODEL`, `COACH_MODEL`, `*_PROVIDER`, `*_TEMPERATURE`, `*_MAX_TOKENS`). Confirm exact model strings at deploy.

## Grounding test coverage

- **test_graph.py (Task 1, `code`):** analyze struggle detection; clean-pass empty-struggle; `needs_plan` routing (struggle→plan, clean-pass→coach, pass-with-struggle→plan); plan authored-id pass; plan unauthored-id raise (3 fabricated ids); advance-on-fail downgrade; advance-on-pass allowed; `is_authored` on real seed ids / section ids / family / fabricated / empty; 19-baa-exercise count; retry success / recover-on-2nd / exhaust-then-raise / None-fails-closed; model routing builds with explicit `max_tokens`.
- **test_grounding.py (Task 2, `code`):** D7 exactly one in-set tool; out-of-set name rejected; no-tool-call degrade; D1/G3 advance-on-fail rewritten + never emitted; advance-on-pass allowed; G4 unauthored `present_activity` rejected + authored allowed; full-graph routing (clean pass skips plan, struggle runs plan); D9/G5 `StructuredOutputError` → 503.

## Deviations from Plan

**1. [Non-deviation] `state.py` and `schema.py` unmodified — fields already present from Plan 01.**
- The plan listed `server/app/state.py` (add insight/plan) and a `CoachOut.grounded` extension in `schema.py`. Plan 01 had already added `insight: dict` / `plan: dict` to `TutorState` AND `grounded: bool` to `CoachOut`. Both "extend" steps were no-ops; the files are unchanged. Verified by reading both at start.

**2. [Rule 3 - Blocking] Bundled curriculum seed instead of reading Flutter assets at runtime.**
- **Found during:** Task 1 (curriculum guard source).
- **Issue:** The plan offered "read the two Flutter assets at build" as preferred, but the server Dockerfile copies only `app/` — the `assets/` tree is not in the image, so a runtime read would `FileNotFoundError` in production.
- **Fix:** Bundled `app/curriculum_data/baa_authored_ids.json`, generated VERBATIM from the canonical assets by `generate.py` (re-runnable, drift-proof). `curriculum.py` loads the bundled copy. The exact id set is recorded above for owner sign-off (the plan's required fallback path).
- **Files:** `server/app/curriculum_data/*`, `server/app/curriculum.py`. **Commit:** `bbb0ed2`.

**3. [Rule 3 - Blocking] Updated `tests/test_endpoint.py` to patch the new node seam.**
- **Issue:** The Plan-01 endpoint test patched `app.graph.build_coach_model` and only the coach; the full graph now runs analyze→plan→coach and the coach binding moved to `app/nodes/coach.py` (`build_coach_with_tools`). The old patch target no longer exists.
- **Fix:** Updated `_patch_coach` to monkeypatch all three node model builders offline (analyze returns a struggle Insight, plan an authored Plan, coach the configured forced call). All 5 Plan-01 endpoint assertions still pass unchanged.
- **Files:** `server/tests/test_endpoint.py`. **Commit:** `ffdcfdf`.

## Verification

- `cd server && uv run pytest -q` → **45 passed** (15 Plan-01 + 30 new), ~0.4s, model-free.
- Imports succeed with `ANTHROPIC_API_KEY`/`GOOGLE_API_KEY` unset (lazy model construction) — verified.
- `python -m app.curriculum_data.generate` regenerates the seed idempotently from the canonical assets — verified (6 sections, 19 exercises).
- `is_authored("baa.traceLetter.isolated")` True; `is_authored("baa.notreal.x")` / non-baa / None / "" False — asserted in tests.
- No new dependencies (T-14-SC accept): reuses Plan-01's pinned deps.

## Manual / deferred (not in this plan's automated scope)

- The live-model smoke check (a sample struggle FACTS through a real Claude/Gemini with keys set) is a manual step — the full eval harness is Phase 16. All automated grounding hard-checks (D1/D7/D9) are green and run model-free in CI.
- The G4 id set requires **owner sign-off** that the bundled seed matches the signed curriculum (flagged above).

## Self-Check: PASSED
- All 12 created files exist on disk (verified).
- Commits `bbb0ed2` (Task 1) and `ffdcfdf` (Task 2) exist in git log.
- 45 tests pass; imports need no provider key; the curriculum seed regenerates from the canonical source.
