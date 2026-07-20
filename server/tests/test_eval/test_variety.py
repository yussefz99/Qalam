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

from app.prompts import COACH_PROMPT  # noqa: E402
from tests.test_eval.run_eval import exemplar_lines, variety_report  # noqa: E402

_GOLD_SET = pathlib.Path(__file__).parent / "gold_set.jsonl"

# The three ready-to-speak child-facing say-lines the OLD coach prompt embedded verbatim — the
# D-06a root cause (the model copied them word-for-word, so the on-screen feedback read static).
# Plan 26-04 REMOVED them from COACH_PROMPT (they survive as the mother's `idealCoaching` register
# ANCHORS in gold_set.jsonl, which the variety leg deliberately excludes — see run_eval._score_variety).
# They stay HERE as (a) the fixture that exercises the detector mechanism below and (b) the banned-set
# the D-06a source assertion proves is gone from the live prompt.
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
# D-06a (Plan 26-04) — the restructured prompt leaves nothing to parrot
# ---------------------------------------------------------------------------


def test_the_restructured_coach_prompt_embeds_no_copyable_child_facing_line():
    """D-06a: the GOLD EXEMPLARS block was restructured to convey REGISTER only — none of the old
    ready-to-speak say-lines survive as quotable text the model can lift, so on-screen feedback
    stops reading static. The register + anti-pattern + grounding contracts stay intact."""
    for removed in _EXEMPLARS:
        assert removed not in COACH_PROMPT, f"copyable exemplar still in the prompt: {removed!r}"
    # The ONLY quoted strings left after the GOLD EXEMPLARS anchor are the NEVER anti-patterns —
    # there is no ready-made coachable line to copy. `exemplar_lines` derives the parrot-set the live
    # variety leg guards from the prompt itself, so this asserts over the SAME shape the leg sees.
    derived = exemplar_lines(COACH_PROMPT)
    assert set(derived) <= {"Oops, try again!", "Great job!"}, derived
    # Register requirement + the forbidden cheerfulness + the grounding rails are all retained.
    assert "warm" in COACH_PROMPT.lower()
    assert "Oops, try again!" in COACH_PROMPT
    assert "GROUNDING RULE" in COACH_PROMPT
    assert "ACTION RULE" in COACH_PROMPT


def test_repeated_attempts_against_the_new_prompt_shape_stay_fresh():
    """The presentation-not-parroting contract over the NEW prompt shape: five distinctly-worded
    coach lines for the SAME shallow-bowl mistake — the varied wording the register-only prompt is
    meant to produce — score 0 verbatim-exemplar hits against the prompt's OWN derived exemplars and
    a perfect distinct ratio (D-06a)."""
    exemplars = exemplar_lines(COACH_PROMPT)
    lines = [
        "The bottom of your baa stayed a little flat — round it deeper and try once more, slower.",
        "Almost — the left side dipped but the right stayed straight; curve the right down to match.",
        "Your bowl is getting rounder; take it a touch lower at the very bottom this time.",
        "So close — start the curve sooner so the whole bottom swings down, not just the middle.",
        "Nice effort; let the stroke sink a bit more before it lifts at the end.",
    ]
    report = variety_report(lines, exemplars)
    assert report["verbatim_exemplar_hits"] == 0
    assert report["distinct_ratio"] == 1.0
    assert report["duplicate_pairs"] == []


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
