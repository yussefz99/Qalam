"""GROUND-03 — the model-free grounding-faithfulness GATE (Plan 15-06 seed; Plan 16-03 GROWS).

D-08 ZERO-TOLERANCE slice: a deterministic, model-AGNOSTIC check over a labeled
`(verdict, coaching)` fixture set that now covers EVERY signed baa mistakeId × pass/fail.
It flags coaching that:
  * (a) PRAISES a failed stroke (a fail whose coaching contains a praise token), and
  * (b) names the WRONG fix (a fail whose coaching omits the `expectedFix` token),
and it REPORTS a faithfulness RATE.

Plan 15-06 wrote the module (`_contradicts` + `evaluate_faithfulness`). Plan 16-03 GROWS the
labeled set to the full baa coverage and adds the ZERO-TOLERANCE assertion: over the curated
FAITHFUL gate cases, D1 must be exactly 100% (rate == 1.0) — a single contradiction FAILS the
build. The adversarial probes (praise-on-fail AND wrong-fix, one per mistakeId) are ALSO carried
so a regression that loosens `_contradicts` is caught (the probes stop being flagged).

Model-free, network-free — a plain `code` check that gates every PR (and the first leg of
`make eval`). It scores coaching lines against FIXED scorer verdicts; it does NOT call a model and
does NOT pre-empt the model choice (it is the FLOOR, not a ceiling — D-08).
"""

from __future__ import annotations

import json
import pathlib

import pytest

pytestmark = pytest.mark.code

from app.faithfulness import _contradicts, evaluate_faithfulness  # noqa: E402

_SET = pathlib.Path(__file__).parent / "fixtures" / "faithfulness_set.jsonl"


def _load_cases() -> list[dict]:
    return [json.loads(line) for line in _SET.read_text(encoding="utf-8").splitlines() if line.strip()]


def _by_label(label: str) -> list[dict]:
    return [c for c in _load_cases() if c.get("label") == label]


def test_flags_praise_on_fail():
    """(a) A FAIL whose coaching praises the stroke ('Great job!', 'أحسنت', 'perfect') is flagged."""
    praise_cases = _by_label("adversarial_praise_on_fail")
    assert praise_cases, "fixture must contain praise-on-fail adversarial cases"
    for c in praise_cases:
        assert _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) is True

    # And a faithful fail (names the deeper-curve fix, no praise) must NOT be flagged.
    assert _contradicts(False, "Your baa needs a deeper curve — try again.", "deeper curve") is False


def test_flags_wrong_fix():
    """(b) A FAIL whose coaching names the WRONG fix (omits the expectedFix token) is flagged."""
    wrong_fix_cases = _by_label("adversarial_wrong_fix")
    assert wrong_fix_cases, "fixture must contain wrong-fix adversarial cases"
    for c in wrong_fix_cases:
        assert _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) is True

    # The matching faithful case (names the dot when the dot failed) must NOT be flagged.
    assert _contradicts(False, "Now place the dot just below the bowl.", "dot") is False


def test_every_baa_mistake_has_faithful_and_adversarial_coverage():
    """The grown set covers EVERY signed baa mistakeId in a faithful AND both adversarial variants.

    The signed baa feedback (assets/curriculum/exercises.json) authors these six fail-side
    mistakeIds: shallowBowl, noDot, hasTail, tooBig, lifted, missingDot. Each must appear in a
    faithful case, a praise-on-fail probe, and a wrong-fix probe — so a loosened _contradicts can
    be caught on every defect, not just one."""
    signed_baa_mistakes = {"shallowBowl", "noDot", "hasTail", "tooBig", "lifted", "missingDot"}

    faithful_fail_ids = {c["mistakeId"] for c in _by_label("faithful") if not c["passed"]}
    praise_ids = {c["mistakeId"] for c in _by_label("adversarial_praise_on_fail")}
    wrong_fix_ids = {c["mistakeId"] for c in _by_label("adversarial_wrong_fix")}

    assert signed_baa_mistakes <= faithful_fail_ids, "every baa mistake needs a faithful fail case"
    assert signed_baa_mistakes <= praise_ids, "every baa mistake needs a praise-on-fail probe"
    assert signed_baa_mistakes <= wrong_fix_ids, "every baa mistake needs a wrong-fix probe"


def test_zero_tolerance_d1_is_100pct_on_the_faithful_gate(capsys):
    """D-08 ZERO-TOLERANCE: over the curated FAITHFUL gate cases, D1 == 100% (rate == 1.0).

    This is THE gate assertion — it FAILS the build the moment a single faithful case is
    contradicted (a regression that re-introduces praise-on-fail or a wrong-fix, or a loosened
    _contradicts that mislabels a faithful line). The adversarial probes are excluded here (they
    are SUPPOSED to contradict); they are gated by the flag tests above."""
    faithful = _by_label("faithful")
    assert faithful, "the faithful gate set must be non-empty"
    contradicted = [
        c for c in faithful if _contradicts(c["passed"], c["coaching"], c.get("expectedFix"))
    ]
    rate = (len(faithful) - len(contradicted)) / len(faithful)
    assert rate == 1.0, f"ZERO-TOLERANCE D1 violated — contradicted faithful cases: {contradicted}"
    print(f"D1 zero-tolerance faithfulness gate: {len(faithful)}/{len(faithful)} = 100.00%")


def test_every_adversarial_probe_is_flagged():
    """Each adversarial-labeled case (praise-on-fail OR wrong-fix) is correctly flagged.

    The probes exist so a loosened _contradicts is caught: if a future edit stops flagging them,
    this fails, surfacing the regression before it ships."""
    probes = _by_label("adversarial_praise_on_fail") + _by_label("adversarial_wrong_fix")
    assert probes, "fixture must carry adversarial probes"
    for c in probes:
        assert (
            _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) is True
        ), f"adversarial probe not flagged (loosened _contradicts?): {c}"


def test_faithfulness_rate_reported(capsys):
    """The check reports a faithfulness RATE over the FULL labeled set (printed + returned)."""
    report = evaluate_faithfulness(_SET)
    assert 0.0 <= report["rate"] <= 1.0
    assert report["total"] == len(_load_cases())
    assert report["faithful"] + len(report["flagged"]) == report["total"]

    # Label-driven (NOT hardcoded counts): every faithful case is faithful, every adversarial is
    # flagged — so the rate equals faithful / total exactly, and the flagged set IS the adversarials.
    n_faithful = len(_by_label("faithful"))
    n_adversarial = len(_by_label("adversarial_praise_on_fail")) + len(_by_label("adversarial_wrong_fix"))
    assert report["faithful"] == n_faithful
    assert len(report["flagged"]) == n_adversarial
    print(f"GROUND-03 faithfulness rate: {report['faithful']}/{report['total']} = {report['rate']:.2%}")
