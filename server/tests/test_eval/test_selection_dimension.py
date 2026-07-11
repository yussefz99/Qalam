"""Phase 18 — Req 9 (selection-policy eval dimension) — Wave-0 RED contract.

INTENTIONALLY RED at Wave 0: imports `SELECTION_THRESHOLD` and expects a
`selection_policy` dimension from `tests.test_eval.run_eval` — neither exists yet.
Plans 18-08 (register the dimension + a `selection_scores` judge leg) / 18-11
(mother-sign the gold set + threshold) turn this green with ZERO test edits.

The contract (18-SPEC.md Req 9 / RESEARCH §Validation Architecture):
  * `run_eval` registers a 5th "selection_policy" dimension ("would a teacher make
    this pick?") — a Vertex LLM-judge leg complemented by the deterministic rails
    property tests (Req 5).
  * `score_eval_set(selection_gold_set.jsonl, selection_scores=[...])` returns a
    selection score ≥ `SELECTION_THRESHOLD` (PROVISIONAL, signed:false until the
    mother signs the bar in 18-11).
  * Offline (`-m code`) the judge leg is SKIPPED (score None) like the other judge
    legs — the numeric bar is exercised only when judge scores are supplied.

Model-free / network-free: a plain `code` check that gates every PR.
"""

from __future__ import annotations

import pathlib

import pytest

pytestmark = pytest.mark.code

# RED: `selection_policy` is not registered and `SELECTION_THRESHOLD` is not defined
# yet (Plan 18-08 writes them). The ImportError is the Wave-0 failing contract.
from tests.test_eval.run_eval import (  # noqa: E402  (RED import)
    DIMENSIONS,
    SELECTION_THRESHOLD,
    score_eval_set,
)

_GOLD_SET = pathlib.Path(__file__).resolve().parent / "selection_gold_set.jsonl"


def test_selection_policy_dimension_is_registered():
    """The registry gains the 5th selection-policy dimension (would a teacher pick this?)."""
    assert "selection_policy" in DIMENSIONS


def test_selection_threshold_is_a_provisional_ratio():
    """SELECTION_THRESHOLD is a provisional [0,1] bar (signed:false until 18-11)."""
    assert 0.0 < SELECTION_THRESHOLD <= 1.0


def test_selection_scores_meet_threshold_on_the_gold_set():
    """With supplied judge scores, the selection leg reports a mean ≥ the provisional bar
    over the mother-authored (signed:false) selection gold scenarios."""
    scores = score_eval_set(_GOLD_SET, selection_scores=[0.92, 0.88, 0.95])
    leg = scores["selection_policy"]
    assert leg["score"] is not None
    assert leg["score"] >= SELECTION_THRESHOLD


def test_selection_leg_is_skipped_offline():
    """Offline (`-m code`, no judge scores) the selection leg is SKIPPED (score None) —
    it never fails the per-commit gate without a Vertex judge run (`make eval` supplies it)."""
    scores = score_eval_set(_GOLD_SET)
    assert scores["selection_policy"]["score"] is None
