# Qalam tutor-server — local developer tasks (Plan 16-03, D-07/D-08/D-09).
#
# `make eval` is the LOCAL DOCUMENTED PRE-MERGE GATE — it is NOT CI (D-07). Run it by hand
# before merging a wave/phase (16-VALIDATION: `make eval` at wave merge + phase gate). It wraps:
#
#   (1) the ZERO-TOLERANCE model-free faithfulness + names-fix gate (D-08) — fails on D1 < 100%;
#   (2) the Vertex LLM-judge run (D-09) — fails on register/correct-Arabic below the 0.7 threshold.
#
# Everything runs via `uv run` (the project's runner). The server is a deployed app, NOT an
# installable package (`[tool.uv] package = false` in pyproject.toml), so the targets never assume
# an installed package — `uv run` resolves only the dependencies + the in-tree `app/`/`tests/`.
#
# CLAUDE-VS-GEMINI COACH BAKE-OFF (16-06) reuses this SAME target by env-swap — the JUDGE stays
# Gemini (judge != coach), only the COACH model is swapped:
#   GEMINI coach (baseline):  make eval
#   CLAUDE-on-Vertex coach:   COACH_MODEL_PROVIDER=anthropic_vertex COACH_MODEL=claude-haiku-4-5@20251001 COACH_LOCATION=global make eval
# Run both and compare the register/correct-Arabic scores to pick the coach.

.PHONY: eval eval-code eval-judge

# The full pre-merge gate: the zero-tolerance model-free leg, THEN the Vertex LLM-judge leg.
# `&&` short-circuits — if the model-free gate fails (D1 < 100%), the judge run is skipped and
# `make eval` exits non-zero (D-08). The judge run exits non-zero below the 0.7 threshold (D-09).
eval: eval-code eval-judge

# Leg 1 — model-free, ZERO-TOLERANCE (D-08). Gates every PR too (`uv run pytest -m code`).
# Exits non-zero if the faithfulness D1 gate is below 100% or any model-free assertion fails.
eval-code:
	uv run pytest tests/test_faithfulness.py tests/test_eval/test_eval_harness.py -m code -q

# Leg 2 — the Vertex LLM-judge (D-09). gemini-2.5-flash (judge != coach-under-test). Reaches Vertex
# (keyless ADC); exits non-zero below the register/correct-Arabic 0.7 threshold OR if D1 < 100%.
eval-judge:
	uv run python tests/test_eval/run_judge.py
