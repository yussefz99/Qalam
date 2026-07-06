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

.PHONY: eval eval-code eval-judge eval-baseline

# The full pre-merge gate: the zero-tolerance model-free leg, THEN the Vertex LLM-judge leg,
# THEN the STRK-01 two-arm baseline (Plan 17-04). Prerequisites run in order and short-circuit —
# if the model-free gate fails (D1 < 100%), the judge/baseline runs are skipped and `make eval`
# exits non-zero (D-08). The judge run exits non-zero below the 0.7 threshold or on a missed
# trap case; the baseline exits non-zero when stroke-aware does not beat label-only on
# specificity + variety, or on ANY grounding violation (zero-tolerance, both arms).
eval: eval-code eval-judge eval-baseline

# Leg 1 — model-free, ZERO-TOLERANCE (D-08). Gates every PR too (`uv run pytest -m code`).
# Exits non-zero if the D1 praise-floor gate is below 100% or any model-free assertion fails
# (incl. the Plan 17-04 variety/gold-set contract tests — eval-code stays model-free).
eval-code:
	uv run pytest tests/test_faithfulness.py tests/test_eval/test_eval_harness.py tests/test_eval/test_variety.py -m code -q

# Leg 2 — the Vertex LLM-judge (D-09). gemini-2.5-flash (judge != coach-under-test). Reaches Vertex
# (keyless ADC); exits non-zero if a judged dimension (register / correct-Arabic /
# semantic-faithfulness / no-false-geometry / specificity) is below the 0.7 threshold, a TRAP
# case is not caught, or D1 < 100%.
eval-judge:
	uv run python tests/test_eval/run_judge.py

# Leg 3 — the STRK-01 two-arm baseline (Plan 17-04). Reaches Vertex (coach + judge, keyless ADC).
# Runs every stroke-level gold fixture through the production coach WITH (arm A) and WITHOUT
# (arm B) the derived stroke facts; exits non-zero unless arm A beats arm B on specificity AND
# variety with 0 grounding violations in BOTH arms.
eval-baseline:
	uv run python tests/test_eval/run_baseline.py
