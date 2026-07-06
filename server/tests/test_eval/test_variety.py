"""STRK-01 / EVAL-03 — the model-free variety detector + the regrown gold-set contract (Plan 17-04).

Two model-free surfaces, both gating every PR under `-m code`:

  * `variety_report(lines, exemplars)` — the pure duplicate/verbatim-exemplar detector. Flags
    (a) any line equal (case/whitespace-folded) to a GOLD-EXEMPLAR string (the parroting failure
    the spike caught in production), and (b) any two identical lines for DISTINCT attempts.
    Returns {distinct_ratio, verbatim_exemplar_hits, duplicate_pairs}.

  * `gold_set.jsonl` — regrown for stroke-level coaching (Phase 17): every non-`#` line parses,
    NOTHING is signed (the mother's re-sign is the 17-10 human gate, 15-07 precedent), every
    `strokeDiff` fact uses ONLY the `StrokeDiffIn` vocabulary (point-free by construction,
    GROUND-04), and the canonical `adv_broken_but_pass` no-false-geometry trap is present.

Model-free, network-free — no Vertex, no ADC. The two-arm STRK-01 baseline runner
(`run_baseline.py`) is the INTEGRATION sibling: it reaches Vertex and runs only under `make eval`;
here we only smoke-import it (lazy model imports keep the import ADC-free).
"""

from __future__ import annotations

import json
import pathlib

import pytest

pytestmark = pytest.mark.code

from tests.test_eval.run_eval import variety_report  # noqa: E402  (RED import — Task 2 implements)

_GOLD_SET = pathlib.Path(__file__).parent / "gold_set.jsonl"

_EXEMPLARS = [
    "Your baa needs a deeper curve at the bottom — try again, slower this time.",
    "The bowl is lovely — now place the dot just below it.",
    "Beautiful — a deep, smooth bowl. أحسنت!",
]


def _load_gold_cases() -> list[dict]:
    return [
        json.loads(line)
        for line in _GOLD_SET.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]


# ---------------------------------------------------------------------------
# variety_report — the pure model-free detector
# ---------------------------------------------------------------------------


def test_five_distinct_lines_score_a_perfect_ratio_with_no_hits():
    """5 distinct lines for 5 distinct attempts → distinct_ratio 1.0, 0 exemplar hits, no dupes."""
    lines = [
        "Round the bottom into a fuller bowl.",
        "The right side stayed flat — curve it down like the left.",
        "Your dot landed left of center — aim just under the middle.",
        "A little smaller this time — just a tooth.",
        "Slow down at the end so the stroke does not flick up.",
    ]
    report = variety_report(lines, _EXEMPLARS)
    assert report["distinct_ratio"] == 1.0
    assert report["verbatim_exemplar_hits"] == 0
    assert report["duplicate_pairs"] == []


def test_the_same_line_five_times_scores_point_two():
    """The same line for 5 DISTINCT attempts → distinct_ratio 0.2 (1 distinct / 5) + dup pairs."""
    lines = ["Make a deeper curve at the bottom."] * 5
    report = variety_report(lines, _EXEMPLARS)
    assert report["distinct_ratio"] == 0.2
    assert len(report["duplicate_pairs"]) > 0


def test_a_verbatim_exemplar_echo_is_flagged():
    """A line equal (case/whitespace-folded) to a GOLD EXEMPLAR counts as a verbatim hit —
    the exemplars are register to EMULATE, never lines to copy."""
    lines = [
        "The right side stayed flat — curve it down like the left.",
        "  your BAA needs a deeper curve at the bottom — try again,   slower this time. ",
    ]
    report = variety_report(lines, _EXEMPLARS)
    assert report["verbatim_exemplar_hits"] >= 1


# ---------------------------------------------------------------------------
# gold_set.jsonl — the regrown stroke-level contract
# ---------------------------------------------------------------------------


def test_gold_set_parses_and_nothing_is_signed():
    """Every non-# line is valid JSON and carries signed == false — the mother's re-sign of the
    WHOLE regrown set is the 17-10 human gate (T-17-08); nothing auto-signs here."""
    cases = _load_gold_cases()
    assert cases, "gold set must be non-empty"
    for case in cases:
        assert case.get("signed") is False, f"unsigned-only gold set violated: {case}"


def test_gold_set_is_regrown_for_stroke_level_coaching():
    """The Phase-17 regrow: stroke-level cases with strokeDiff facts exist, including the
    canonical adv_broken_but_pass no-false-geometry trap."""
    cases = _load_gold_cases()
    assert any(c.get("strokeDiff") for c in cases), "regrown set must carry strokeDiff facts"
    assert any(
        c.get("id") == "adv_broken_but_pass" for c in cases
    ), "the canonical no-false-geometry trap case must be present"
    new_cases = [c for c in cases if c.get("strokeDiff") or str(c.get("id", "")).startswith("adv")]
    assert len(new_cases) >= 8, "the regrow appends >= 8 stroke-level cases"


def test_gold_strokediff_facts_use_only_the_strokediffin_vocabulary():
    """GROUND-04 / T-17-09: every strokeDiff key on a gold case is a `StrokeDiffIn` field —
    point-free scalars only, no coordinates can even be expressed."""
    from app.schema import StrokeDiffIn

    allowed = set(StrokeDiffIn.model_fields)
    for case in _load_gold_cases():
        diff = case.get("strokeDiff")
        if diff is None:
            continue
        assert isinstance(diff, dict)
        extras = set(diff) - allowed
        assert not extras, f"strokeDiff keys outside StrokeDiffIn: {extras} in {case.get('id')}"


def test_baseline_runner_is_import_safe_offline():
    """run_baseline (the STRK-01 two-arm instrument) must import WITHOUT ADC/Vertex — model
    building stays lazy; only `make eval` actually reaches Vertex."""
    from tests.test_eval import run_baseline

    assert callable(run_baseline.main)
