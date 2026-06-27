"""GROUND-03 — the model-free grounding-faithfulness check (Plan 15-06 implements; 15-01 RED).

D-10's NARROW slice (NOT the full Phase-13 harness): a deterministic, model-AGNOSTIC check
over a small labeled `(verdict, coaching)` fixture set. It flags coaching that:
  * (a) PRAISES a failed stroke (a fail whose coaching contains a praise token), and
  * (b) names the WRONG fix (a fail whose coaching omits the `expectedFix` token),
and it REPORTS a faithfulness RATE.

This file is the Wave-0 RED contract: it imports the check from `app.faithfulness`, which
does NOT exist yet, so every test ERRORS/FAILS RED by missing symbol. Plan 15-06 writes the
module (the `_contradicts` predicate + an `evaluate_faithfulness` that returns a rate) and
turns these GREEN. The fixture (`fixtures/faithfulness_set.jsonl`) already carries BOTH the
constructed-faithful gold cases AND the adversarial cases the flag tests assert on.

Model-free, network-free — a plain `code` check that gates every PR. It scores coaching lines
against FIXED scorer verdicts; it does NOT call a model and does NOT pre-empt the Phase-13
Claude-vs-Gemini choice (it is a FLOOR, not a ceiling).
"""

from __future__ import annotations

import json
import pathlib

import pytest

pytestmark = pytest.mark.code

# RED: `app.faithfulness` does not exist yet (Plan 15-06 writes it). The import error is the
# Wave-0 failing contract — `_contradicts` flags a (verdict, coaching) pair, and
# `evaluate_faithfulness` reads the labeled set and returns {faithful, total, rate, flagged}.
from app.faithfulness import _contradicts, evaluate_faithfulness  # noqa: E402  (RED import)

_SET = pathlib.Path(__file__).parent / "fixtures" / "faithfulness_set.jsonl"


def _load_cases() -> list[dict]:
    return [json.loads(line) for line in _SET.read_text(encoding="utf-8").splitlines() if line.strip()]


def test_flags_praise_on_fail():
    """(a) A FAIL whose coaching praises the stroke ('Great job!', 'أحسنت', 'perfect') is flagged."""
    # The adversarial fixtures labeled 'adversarial_praise_on_fail' MUST be flagged as contradictions.
    praise_cases = [c for c in _load_cases() if c.get("label") == "adversarial_praise_on_fail"]
    assert praise_cases, "fixture must contain praise-on-fail adversarial cases"
    for c in praise_cases:
        assert _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) is True

    # And a faithful fail (names the deeper-curve fix, no praise) must NOT be flagged.
    assert _contradicts(False, "Your baa needs a deeper curve — try again.", "deeper curve") is False


def test_flags_wrong_fix():
    """(b) A FAIL whose coaching names the WRONG fix (omits the expectedFix token) is flagged."""
    wrong_fix_cases = [c for c in _load_cases() if c.get("label") == "adversarial_wrong_fix"]
    assert wrong_fix_cases, "fixture must contain wrong-fix adversarial cases"
    for c in wrong_fix_cases:
        assert _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) is True

    # The matching faithful case (names the dot when the dot failed) must NOT be flagged.
    assert _contradicts(False, "Now place the dot just below the bowl.", "dot") is False


def test_faithfulness_rate_reported(capsys):
    """The check reports a faithfulness RATE over the labeled set (printed + returned)."""
    report = evaluate_faithfulness(_SET)
    # The report exposes a numeric rate in [0, 1] plus faithful/total counts.
    assert 0.0 <= report["rate"] <= 1.0
    assert report["total"] == len(_load_cases())
    assert report["faithful"] + len(report["flagged"]) == report["total"]
    # The 4 adversarial cases must be flagged; the 9 faithful gold cases must not be.
    assert len(report["flagged"]) == 4
    assert report["faithful"] == 9
    print(f"GROUND-03 faithfulness rate: {report['faithful']}/{report['total']} = {report['rate']:.2%}")
