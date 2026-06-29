"""EVAL-01 / EVAL-02 — the eval-harness contract (Plan 16-01 RED; Plan 16-03 implements).

The Wave-0 RED contract (Nyquist) for the Phase-16 eval gate. It imports the eval runner from
`tests.test_eval.run_eval`, which does NOT exist yet, so every test ERRORS/FAILS RED by missing
symbol. Plan 16-03 writes `run_eval.py` (the two-leg harness + the `make eval` gate) and turns the
model-free leg GREEN — with ZERO test edits, because the symbol names below ARE the Wave-2
contract.

The harness scores a labeled `(verdict, learner-state)` set on the four 14-AI-SPEC §5 dimensions:

  * D1 — faithfulness   (model-FREE, zero-tolerance) — reuses `app.faithfulness.evaluate_faithfulness`
  * D2 — names-fix      (model-FREE) — the coaching names the expected fix on a miss
  * D5 — register       (Vertex LLM-judge, threshold) — the mother's warm/calm/specific voice
  *      correct-Arabic (Vertex LLM-judge, threshold) — أحسنت etc. used correctly

`score_eval_set(path)` returns a per-dimension score dict keyed by those dimensions. The MODEL-FREE
legs (D1/D2) run under `uv run pytest -m code` (offline, gates every PR). The Vertex-LLM-JUDGE legs
(register/correct-Arabic) are INTEGRATION — they call Vertex, are NOT `code`-marked, and run under
`make eval`; the assertion that touches them is SKIPPED in the `code` leg below.

RED-by-missing-symbol is the INTENDED Wave-0 state — do NOT implement the runner here. Only the
failing tests live in this file.
"""

from __future__ import annotations

import pathlib

import pytest

# The model-free legs of this suite gate every PR (mirrors test_faithfulness.py line 27).
pytestmark = pytest.mark.code

# RED: `tests.test_eval.run_eval` does not exist yet (Plan 16-03 writes it). The import error is
# the Wave-0 failing contract — `score_eval_set` returns a per-dimension score dict over a labeled
# set; its model-free faithfulness leg reuses `evaluate_faithfulness`.
from tests.test_eval.run_eval import (  # noqa: E402  (RED import)
    DIMENSIONS,
    score_eval_set,
)

# Reuse the existing all-faithful gold subset of the 15-06 fixture (the model-free D1 leg scores
# this to exactly 1.0). The fixture carries 9 `faithful` cases + 4 adversarial cases.
_FAITHFUL_SET = (
    pathlib.Path(__file__).resolve().parents[1] / "fixtures" / "faithfulness_set.jsonl"
)


def test_dimensions_cover_the_four_spec_dimensions():
    """The harness scores all four 14-AI-SPEC §5 dimensions (D1 faithfulness, D2 names-fix,
    D5 register, correct-Arabic)."""
    assert set(DIMENSIONS) >= {
        "faithfulness",
        "names_fix",
        "register",
        "correct_arabic",
    }


def test_model_free_faithfulness_leg_is_perfect_on_the_faithful_subset():
    """D1 (model-free, zero-tolerance) reuses evaluate_faithfulness and is exactly 1.0 (100%) on
    the all-faithful subset of the labeled set."""
    scores = score_eval_set(_FAITHFUL_SET)
    # The model-free faithfulness dimension is reported as a rate in [0, 1].
    assert scores["faithfulness"]["rate"] == 1.0


def test_names_fix_leg_is_model_free_and_present():
    """D2 (names-fix) is also a model-free dimension scored over the labeled set."""
    scores = score_eval_set(_FAITHFUL_SET)
    assert "names_fix" in scores
    assert 0.0 <= scores["names_fix"]["rate"] <= 1.0


@pytest.mark.skip(
    reason="Vertex LLM-judge leg (register + correct-Arabic) is INTEGRATION — it calls Vertex and "
    "runs under `make eval`, not the model-free `-m code` per-commit gate (16-RESEARCH Test Map)."
)
def test_vertex_judge_legs_register_and_arabic():
    """D5 register + correct-Arabic are scored by a Vertex LLM-judge against a threshold (NOT
    zero-tolerance). Skipped in the `code` leg — exercised only under `make eval`."""
    scores = score_eval_set(_FAITHFUL_SET)
    assert scores["register"]["score"] >= 0.7
    assert scores["correct_arabic"]["score"] >= 0.7
