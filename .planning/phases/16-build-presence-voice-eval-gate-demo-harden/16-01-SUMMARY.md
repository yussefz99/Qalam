---
phase: 16-build-presence-voice-eval-gate-demo-harden
plan: 01
subsystem: infra
tags: [vertex-ai, langchain, gemini, claude-on-vertex, keyless-adc, flutter-tts, eval-harness, tdd, nyquist]

# Dependency graph
requires:
  - phase: 14-build-the-tutor
    provides: "per-node model routing table (server/app/models.py), the coach node + bind_tools lock (coach.py), the deploy contract (.env.example/README)"
  - phase: 15-curriculum-graph-grounding
    provides: "the model-free faithfulness check (app/faithfulness.py) + fixtures/faithfulness_set.jsonl the eval harness reuses"
provides:
  - "Keyless Gemini-on-Vertex routing locked as the live baseline for all three nodes (analyze/plan/coach) — source of truth now matches the deployed truth (D-02)"
  - "An env-swappable anthropic_vertex coach branch (ChatAnthropicVertex + COACH_LOCATION=global) so Claude-on-Vertex is a deploy-env change, not a code change (D-03)"
  - "Deploy contract stripped of all active provider API keys (keyless ADC only) — .env.example, README, pyproject annotation"
  - "Wave-0 RED contract: failing TTS segmenter test (segmentByScript + TtsCoachSpeaker) and failing eval-harness contract test (score_eval_set over 4 dimensions), both RED by missing symbol"
affects: [16-02-presence-voice, 16-03-eval-gate, demo-harden]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Keyless Vertex routing: all nodes default to google_vertexai/gemini-2.5-flash; no provider key anywhere (image/Secret-Manager/client)"
    - "Provider-branch in build_coach_model(): COACH_MODEL_PROVIDER==anthropic_vertex routes to ChatAnthropicVertex (init_chat_model can't yield Claude); returned UNbound so coach.py keeps the bind_tools lock"
    - "Nyquist Wave-0 RED: failing tests name the exact Wave-2 symbols (segmentByScript, TtsCoachSpeaker, TtsEngine, score_eval_set, run_eval) so the implementer writes zero test edits"

key-files:
  created:
    - test/tutor/tts_coach_speaker_test.dart
    - server/tests/test_eval/__init__.py
    - server/tests/test_eval/test_eval_harness.py
  modified:
    - server/app/models.py
    - server/.env.example
    - server/README.md
    - server/pyproject.toml

key-decisions:
  - "All three tutor nodes default to keyless google_vertexai/gemini-2.5-flash — matches the live qalam-tutor deploy (D-02); the stale anthropic+key path is removed from the deploy contract."
  - "Claude-on-Vertex coach is a drop-in env swap (COACH_MODEL_PROVIDER=anthropic_vertex, COACH_MODEL=claude-haiku-4-5@20251001, COACH_LOCATION=global) gated on a human Model-Garden Enable + an eval win — NOT a code change (D-03)."
  - "build_coach_model() returns the anthropic_vertex model UNbound; coach.py's build_coach_with_tools() still owns .bind_tools(ACTION_TOOLS, tool_choice=any) so the G2 action-space lock stays next to the node."
  - "langchain-anthropic annotated (not removed) as a REMOVE candidate — nothing imports it; Claude-on-Vertex uses ChatAnthropicVertex from langchain-google-vertexai. Removal deferred per plan."
  - "The Wave-0 eval RED test is a collection-error that fails the full `-m code` suite until 16-03 ships run_eval.py — this is the intended Nyquist RED state, identical to the 15-01 precedent."

patterns-established:
  - "Keyless-Vertex deploy contract: no --set-secrets, no provider key env; runtime SA ADC + roles/aiplatform.user."
  - "Per-provider branch in a model-builder, env-selected, lazy-imported (no key at import)."

requirements-completed: [PRES-02, EVAL-01, EVAL-02]

# Metrics
duration: 8min
completed: 2026-06-29
---

# Phase 16 Plan 01: Routing Table Lock + Wave-0 RED Contract Summary

**Locked all three tutor nodes to keyless Gemini-on-Vertex (the live baseline), added an env-swappable anthropic_vertex coach branch (ChatAnthropicVertex), stripped every active provider API key from the deploy contract, and laid the failing Wave-0 RED tests for the TTS segmenter and the eval harness.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-29T15:50:00+03:00 (approx)
- **Completed:** 2026-06-29T15:58:46+03:00
- **Tasks:** 2
- **Files modified:** 7 (4 modified, 3 created)

## Accomplishments

- **Routing table now matches the deployed truth (D-02):** `ANALYZE_/PLAN_/COACH_MODEL_PROVIDER` all default to `google_vertexai` and `..._MODEL` to `gemini-2.5-flash`. The module docstring routing table was rewritten to the keyless-Vertex truth.
- **Claude is a drop-in env swap, not a code change (D-03):** `build_coach_model()` gained an early `COACH_MODEL_PROVIDER == "anthropic_vertex"` branch building `ChatAnthropicVertex(model_name, project=GCP_PROJECT_ID, location=COACH_LOCATION, …)`, returned UNbound. Added `COACH_LOCATION = os.environ.get("COACH_LOCATION", "global")` (Claude does not serve us-central1).
- **No active Anthropic/Google API key anywhere in the deploy contract:** `.env.example` lost the `ANTHROPIC_API_KEY`/`GOOGLE_API_KEY` placeholders and the "Provider API keys" comment block; it now carries the live keyless values (`COACH_MODEL=gemini-2.5-flash`, `COACH_MODEL_PROVIDER=google_vertexai`, `COACH_TIMEOUT_SECONDS=12`) plus commented GATED-UPGRADE lines for the Claude swap. README's model-routing + Cloud Run deploy sections rewritten to keyless ADC (no `--set-secrets`, runtime SA + `roles/aiplatform.user`). `langchain-anthropic` annotated as a REMOVE candidate.
- **Wave-0 RED contract authored (Nyquist):** failing TTS segmenter test (`segmentByScript`, `TtsCoachSpeaker`, `TtsEngine`) and failing eval-harness contract test (`score_eval_set`, `DIMENSIONS`, `run_eval`), both RED by missing symbol, naming the exact symbols the Wave-2 plans (16-02/16-03) must implement with zero test edits.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lock keyless-Vertex routing + add anthropic_vertex coach branch** — `b46b06d` (feat)
2. **Task 2: Wave-0 RED — TTS segmenter + eval-harness contracts** — `7bbdf0e` (test, TDD RED)

_Note: Task 2 is a TDD RED task — it deliberately produces only failing tests; no GREEN/feat commit follows in this plan (the implementations are Wave-2, plans 16-02 and 16-03)._

## Files Created/Modified

- `server/app/models.py` (modified) — keyless google_vertexai/gemini-2.5-flash defaults for all 3 nodes; `COACH_LOCATION` env (default `global`); `anthropic_vertex` branch in `build_coach_model()` (ChatAnthropicVertex, UNbound); docstring routing table rewritten; `_provider_kwargs` (thinking_budget=0 google_vertexai-only) unchanged.
- `server/.env.example` (modified) — removed active provider-key lines + "Provider API keys" block; keyless live values; commented GATED-UPGRADE Claude lines; timeout 8→12.
- `server/README.md` (modified) — new "Model routing (keyless Gemini-on-Vertex)" section; Cloud Run deploy rewritten to keyless (no secrets, `roles/aiplatform.user`); local-dev + Files notes updated; `langchain-google-vertexai` / `langchain-anthropic` (REMOVE candidate) added to the versions table.
- `server/pyproject.toml` (modified) — `langchain-anthropic` annotated `# REMOVE candidate (D-02)`; dependency NOT removed.
- `test/tutor/tts_coach_speaker_test.dart` (created) — RED: `segmentByScript` (mixed/pure-Arabic/pure-English/empty) + `TtsCoachSpeaker` availability-degrade over an injected `TtsEngine` fake. Imports `package:qalam/tutor/tts_coach_speaker.dart` (absent → compile-fail RED).
- `server/tests/test_eval/__init__.py` (created) — empty package marker.
- `server/tests/test_eval/test_eval_harness.py` (created) — RED: `score_eval_set` over the 4 §5 dimensions; model-free faithfulness leg == 1.0 on the all-faithful subset; `pytestmark = pytest.mark.code`; Vertex-judge register/correct-Arabic assertion `@pytest.mark.skip` (integration, `make eval` only). Imports `tests.test_eval.run_eval` (absent → ModuleNotFoundError RED).

## Decisions Made

None beyond the plan — followed it exactly. The keyless-Vertex defaults, the anthropic_vertex branch shape, COACH_LOCATION=global, the UNbound return, the langchain-anthropic annotation (not removal), and the RED-by-missing-symbol contract all match the plan's `<action>` and the 16-PATTERNS/16-RESEARCH guidance verbatim.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- **Wave-0 eval RED test fails the full `-m code` suite (intended).** The eval-harness test imports the not-yet-written `tests.test_eval.run_eval`, which is a collection-time `ModuleNotFoundError` and therefore interrupts the whole `uv run pytest -m code -q` run (exit 2), not just that file. This is the inherent, intended Nyquist Wave-0 RED state — the failing test pins the contract until plan 16-03 ships `run_eval.py`, exactly as the plan's acceptance criterion states ("RED by missing eval-runner symbol — the intended Wave-0 state") and matching the 15-01 RED precedent. The Task-1 routing change itself keeps the model-free suite green (verified before the RED test was added: 72 passed); only the deliberately-RED Task-2 test reddens the gate.

## Verification Evidence

- **Task 1:**
  - `grep -n 'anthropic_vertex' server/app/models.py` → branch present (line 112).
  - `grep -n 'COACH_LOCATION' server/app/models.py` → env line default `"global"` (line 56).
  - `grep -c 'google_vertexai' server/app/models.py` → 12 (≥3 node defaults).
  - `grep -v '^#' server/.env.example | grep -c 'ANTHROPIC_API_KEY'` → 0.
  - `cd server && uv run pytest -m code -q` (before the RED test) → 72 passed, exit 0.
- **Task 2:**
  - `grep -c 'segmentByScript' / 'TtsCoachSpeaker'` in the Dart test → 8 / 8.
  - `flutter test test/tutor/tts_coach_speaker_test.dart` → Compilation failed (missing file + TtsEngine/segmentByScript/TtsCoachSpeaker not found) — RED by missing symbol.
  - `grep -n 'pytest.mark.code' server/tests/test_eval/test_eval_harness.py` → line 32.
  - `cd server && uv run pytest server/tests/test_eval/test_eval_harness.py -m code -q` → exit 2 (ModuleNotFoundError: tests.test_eval.run_eval) — RED by missing symbol.

## Threat Surface

Threat register dispositions honored:
- **T-16-01-01 (Anthropic key in deploy contract):** mitigated — grep gate confirms 0 active `ANTHROPIC_API_KEY` lines; README/`.env.example` now keyless ADC only; no `--set-secrets` in the deploy command.
- **T-16-01-02 (anthropic_vertex grounding):** accept — the branch changes only the bound model; coach.py's G3/G4 grounding guards (provider-independent) are untouched.
- **T-16-01-SC (package installs):** mitigated — NO new package installed (langchain-google-vertexai already carries ChatAnthropicVertex; langchain-anthropic only annotated). No threat flags introduced.

## User Setup Required

None for this plan. (Phase-level: the Claude-on-Vertex upgrade later needs a human Model-Garden Enable click + an eval win before the env swap — see 16-PLAN waves 2/3; not required for the Gemini-keyless demo path.)

## Next Phase Readiness

- **16-02 (presence/voice):** the Dart RED contract pins `lib/tutor/tts_coach_speaker.dart` to expose top-level `segmentByScript(String) -> List<(String locale, String text)>`, a `TtsEngine` abstract seam (isLanguageAvailable/setLanguage/speak/awaitSpeakCompletion/stop), and `TtsCoachSpeaker(TtsEngine).speak(String)` with Arabic-unavailable graceful degrade. Implementing these turns the test GREEN with zero test edits.
- **16-03 (eval gate):** the Python RED contract pins `server/tests/test_eval/run_eval.py` to expose `DIMENSIONS` (≥ {faithfulness, names_fix, register, correct_arabic}) and `score_eval_set(path) -> dict` whose `faithfulness` leg reuses `evaluate_faithfulness` (`["faithfulness"]["rate"] == 1.0` on the all-faithful subset) and `names_fix` leg is model-free; the Vertex-judge register/correct-Arabic leg stays integration (`make eval`).
- Routing table is the keyless-Vertex source of truth — the Claude coach is a documented, gated env swap.

## Self-Check: PASSED

All 8 created/modified files exist on disk; both task commits (`b46b06d`, `7bbdf0e`) exist in git history.

---
*Phase: 16-build-presence-voice-eval-gate-demo-harden*
*Completed: 2026-06-29*
