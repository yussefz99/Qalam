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

import json
import pathlib

import pytest

# The model-free legs of this suite gate every PR (mirrors test_faithfulness.py line 27).
pytestmark = pytest.mark.code

# RED: `tests.test_eval.run_eval` does not exist yet (Plan 16-03 writes it). The import error is
# the Wave-0 failing contract — `score_eval_set` returns a per-dimension score dict over a labeled
# set; its model-free faithfulness leg reuses `evaluate_faithfulness`.
from tests.test_eval.run_eval import (  # noqa: E402  (RED import)
    DIMENSIONS,
    gate_passes,
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


# ---------------------------------------------------------------------------
# Phase 17 (EVAL-03) — the semantic gate upgrade (Plan 17-04 Task 1).
#
# The spike (SPIKE-FINDINGS) measured the expected-fix SUBSTRING rule false-flagging
# 0.55–0.73 of correct paraphrases with ZERO real contradictions, so:
#   * the D1 live-line leg becomes the PRAISE-LEXICON FLOOR ONLY (evaluate_praise_floor),
#   * names_fix (D2, the substring rule) is demoted to ADVISORY — reported, never gating,
#   * three JUDGE legs join (semantic_faithfulness, no_false_geometry, specificity), and
#   * a MODEL-FREE variety leg joins the gate (the detector lands in Task 2).
# ---------------------------------------------------------------------------

# All five judge dimensions after the Phase-17 extension (skipped-when-offline pattern).
_JUDGE_LEGS = (
    "register",
    "correct_arabic",
    "semantic_faithfulness",
    "no_false_geometry",
    "specificity",
)


def _passing_scores() -> dict:
    """A fully-passing scores dict in the post-17-04 shape (all judge legs skipped/offline)."""
    scores: dict = {
        "faithfulness": {"rate": 1.0, "total": 9, "zero_tolerance": True},
        "names_fix": {"rate": 1.0, "total": 3},
        "variety": {"distinct_ratio": 1.0, "verbatim_exemplar_hits": 0, "meets_threshold": True},
    }
    for dim in _JUDGE_LEGS:
        scores[dim] = {"score": None, "skipped": "offline `-m code` leg", "threshold": 0.7}
    return scores


def test_dimensions_cover_the_phase17_semantic_dimensions():
    """EVAL-03: the registry gains semantic_faithfulness, no_false_geometry, specificity (judge
    side) and variety (model-free side) — alongside the four Phase-16 dimensions."""
    assert set(DIMENSIONS) >= {
        "semantic_faithfulness",
        "no_false_geometry",
        "specificity",
        "variety",
    }


def test_judge_dimensions_cover_the_three_new_judge_legs():
    """run_judge's JUDGE_DIMENSIONS gains the three Phase-17 judge legs (judge = gemini-2.5-flash,
    judge != coach, unchanged)."""
    from tests.test_eval.run_judge import JUDGE_DIMENSIONS

    assert set(JUDGE_DIMENSIONS) >= {
        "semantic_faithfulness",
        "no_false_geometry",
        "specificity",
    }


def test_gate_ignores_a_skipped_judge_leg():
    """A skipped (score None) judge leg — including the three NEW legs — never fails the gate;
    the offline `-m code` context gates only the model-free legs."""
    scores = _passing_scores()
    assert gate_passes(scores) is True


def test_gate_fails_when_variety_is_below_threshold():
    """The MODEL-FREE variety leg gates: below threshold the gate fails, at/above it passes
    (with every judge leg skipped and D1 at 100% both times)."""
    scores = _passing_scores()
    scores["variety"] = {
        "distinct_ratio": 0.2,
        "verbatim_exemplar_hits": 3,
        "meets_threshold": False,
    }
    assert gate_passes(scores) is False

    scores["variety"] = {
        "distinct_ratio": 1.0,
        "verbatim_exemplar_hits": 0,
        "meets_threshold": True,
    }
    assert gate_passes(scores) is True


def test_names_fix_is_advisory_and_cannot_fail_the_gate(tmp_path):
    """A correct PARAPHRASE of the fix (omits the expectedFix token) scores names_fix == 0 but the
    gate still PASSES — the substring rule is retired AS THE GATE for live lines (spike: 0.55–0.73
    false-flag rate, 0 real contradictions). D1 (praise floor) stays 100% on these lines."""
    set_path = tmp_path / "paraphrase_set.jsonl"
    cases = [
        {
            "letterId": "baa",
            "section": "traceLetter.isolated",
            "passed": False,
            "mistakeId": "shallowBowl",
            "expectedFix": "deeper curve",
            "coaching": "Round the bottom into a fuller bowl — slower this time.",
            "label": "faithful",
        },
        {
            "letterId": "baa",
            "section": "connectWord.baab",
            "passed": False,
            "mistakeId": "lifted",
            "expectedFix": "join",
            "coaching": "Keep the pen down — let baa flow into the next letter in one smooth stroke.",
            "label": "faithful",
        },
    ]
    set_path.write_text(
        "\n".join(json.dumps(c, ensure_ascii=False) for c in cases), encoding="utf-8"
    )

    scores = score_eval_set(set_path)
    # names_fix (advisory) correctly reports the paraphrases as not naming the token …
    assert scores["names_fix"]["rate"] == 0.0
    # … but the D1 praise floor does NOT flag them (no praise-on-fail) …
    assert scores["faithfulness"]["rate"] == 1.0
    # … and the gate PASSES: names_fix no longer appears in the gating path.
    assert gate_passes(scores) is True


def test_praise_floor_flags_praise_on_fail_but_not_a_paraphrased_fix():
    """evaluate_praise_floor (faithfulness.py) is the retained zero-tolerance floor: it flags
    praise-on-fail (incl. the Arabic أحسنت) but does NOT flag a paraphrased fix line — the
    expected-fix substring component is deliberately absent."""
    from app.faithfulness import evaluate_praise_floor

    cases = [
        {
            "passed": False,
            "coaching": "Great job — a perfect baa!",
            "expectedFix": "deeper curve",
            "label": "adversarial_praise_on_fail",
        },
        {
            "passed": False,
            "coaching": "أحسنت! Wonderful bowl.",
            "expectedFix": "deeper curve",
            "label": "adversarial_praise_on_fail",
        },
        {
            "passed": False,
            "coaching": "Round the bottom into a fuller bowl — slower this time.",
            "expectedFix": "deeper curve",
            "label": "faithful",
        },
    ]
    report = evaluate_praise_floor(cases)
    assert report["total"] == 3
    assert len(report["flagged"]) == 2  # both praise-on-fail lines flagged
    assert report["faithful"] == 1  # the paraphrase is NOT flagged (substring rule retired)
    assert cases[2] not in report["flagged"]
