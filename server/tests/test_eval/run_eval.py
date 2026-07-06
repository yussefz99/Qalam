"""EVAL-01/02/03 — the two-leg eval harness (Plan 16-03; upgraded semantic by Plan 17-04).

`score_eval_set(path)` scores a labeled `(verdict, learner-state)` set and returns a
per-dimension score dict over the `DIMENSIONS` registry:

  * D1  — faithfulness    (MODEL-FREE, ZERO-TOLERANCE) — Phase 17: the PRAISE-LEXICON FLOOR only
            (`app.faithfulness.evaluate_praise_floor`). The expected-fix SUBSTRING rule is RETIRED
            as the gate for live lines — the spike (SPIKE-FINDINGS) measured it false-flagging
            0.55–0.73 of correct paraphrases with ZERO real contradictions.
  * D2  — names_fix       (MODEL-FREE, **ADVISORY**) — still computed and reported, but it can no
            longer fail the gate (see `gate_passes`). Its substring rule stays valid over the
            pinned fixture set (`test_faithfulness.py`), never over varied live lines.
  * D5  — register        (Vertex LLM-JUDGE, THRESHOLD) — the mother's warm/calm/specific voice.
  *       correct_arabic  (Vertex LLM-JUDGE, THRESHOLD) — أحسنت etc. used correctly.
  *       semantic_faithfulness (Vertex LLM-JUDGE, THRESHOLD) — does the line's MEANING contradict
            the frozen verdict / fail to address the failed criterion? Paraphrases are FAITHFUL.
  *       no_false_geometry (Vertex LLM-JUDGE, THRESHOLD) — is EVERY geometric claim supported by
            the strokeDiff/criteria facts shown? Inventing a feature scores 0.
  *       specificity     (Vertex LLM-JUDGE, THRESHOLD) — names a localized geometric fact about
            THIS attempt, not a generic instruction (STRK-01).
  *       variety         (MODEL-FREE, THRESHOLD) — duplicate/verbatim-exemplar detector over LIVE
            coaching lines: distinct lines for distinct attempts, zero GOLD-EXEMPLAR echoes.

TWO LEGS, ONE HARNESS (D-10):
  * The MODEL-FREE legs (D1 / D2-advisory / variety) run offline under `uv run pytest -m code`
    and gate every PR. They need no model, no auth, no network.
  * The Vertex-LLM-JUDGE legs are INTEGRATION: they call Vertex AI (gemini-2.5-flash, keyless
    ADC), are NOT `code`-marked, and run only under `make eval`. In the offline `code` leg they
    are reported as {"score": None, "skipped": ...} so `score_eval_set` returns EVERY dimension
    in every context without a model dependency at import time.

JUDGE ≠ COACH (16-RESEARCH Open Q2 / threat T-16-03-03): the judge is gemini-2.5-flash, distinct
from the coach-under-test, to avoid self-grading bias. The judge runner lives in `run_judge.py`;
it is IMPORTED LAZILY here so importing this module needs no Vertex client / ADC.

D-10 NO-TRAINING CONSTRAINT (14-AI-SPEC §1b): the labeled set / transcripts must NOT be used to
train or fine-tune models without separate verifiable parental consent. The gold set
(`gold_set.jsonl`) is synthetic/authored non-PII; this harness only READS it for scoring/calibration
and never emits it for training. See the header note in `gold_set.jsonl`.
"""

from __future__ import annotations

import json
import pathlib
import re
from typing import Any, Optional, Union

from app.faithfulness import _contradicts, evaluate_praise_floor
from app.prompts import COACH_PROMPT

# The full dimension registry. D1/D2/variety are model-free; the rest are Vertex LLM-judge legs.
# The 16-01 RED test asserts the Phase-16 four are covered; the 17-04 tests assert the Phase-17
# four (semantic_faithfulness / no_false_geometry / specificity / variety) joined.
DIMENSIONS: tuple[str, ...] = (
    "faithfulness",           # D1 — model-free, zero-tolerance (praise-lexicon floor)
    "names_fix",              # D2 — model-free, ADVISORY (reported, never gates — see gate_passes)
    "register",               # D5 — Vertex LLM-judge, threshold (mother's voice / arabic register)
    "correct_arabic",         # correct-Arabic — Vertex LLM-judge, threshold
    # --- Phase 17 (EVAL-03 / STRK-01) ---
    "semantic_faithfulness",  # Vertex LLM-judge — meaning-level verdict agreement (paraphrase-safe)
    "no_false_geometry",      # Vertex LLM-judge — every geometric claim supported by the facts
    "specificity",            # Vertex LLM-judge — localized, THIS-attempt geometric fact (STRK-01)
    "variety",                # model-free — duplicate/verbatim-exemplar detector (gates every PR)
)

# Judge calibration / gate threshold for the LLM-judge legs (NOT zero-tolerance, unlike D1).
JUDGE_THRESHOLD = 0.7

# The five judge legs `gate_passes` checks when they RAN (score is not None). Skipped legs
# (the offline `-m code` context) never fail the gate.
JUDGE_GATED_DIMENSIONS: tuple[str, ...] = (
    "register",
    "correct_arabic",
    "semantic_faithfulness",
    "no_false_geometry",
    "specificity",
)

# The model-free variety leg's gate bar: the distinct-lines ratio over DISTINCT attempts must
# reach this, AND there must be ZERO verbatim GOLD-EXEMPLAR echoes.
VARIETY_THRESHOLD = 0.8


def _load_cases(path: Union[str, pathlib.Path]) -> list[dict[str, Any]]:
    """Read a labeled JSONL set. Blank lines and `#`-prefixed header/comment lines are skipped."""
    set_path = pathlib.Path(path)
    cases: list[dict[str, Any]] = []
    for line in set_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        cases.append(json.loads(stripped))
    return cases


def _is_adversarial(case: dict[str, Any]) -> bool:
    """Adversarial-labeled probes are SUPPOSED to violate a dimension — they never join a
    gate-scored subset (they are checked individually, e.g. the trap legs in `run_judge.py`)."""
    return str(case.get("label", "")).startswith("adversarial")


def _faithful_gate_cases(cases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """The curated FAITHFUL gate subset (label == 'faithful') — the advisory D2 leg scores THIS,
    not the adversarial probes (which are SUPPOSED to contradict)."""
    return [c for c in cases if c.get("label") == "faithful"]


def _praise_gate_cases(cases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Every NON-adversarial case gates the D1 praise floor (Phase 17). Broader than the
    label=='faithful' subset so gold-set lines (label 'gold_*') are floor-checked too — the
    praise-on-fail rule is well-defined for any (verdict, line) pair."""
    return [c for c in cases if not _is_adversarial(c)]


def _score_faithfulness(cases: list[dict[str, Any]]) -> dict[str, Any]:
    """D1 — model-free, ZERO-TOLERANCE. Phase 17: the PRAISE-LEXICON FLOOR only.

    Routed through `evaluate_praise_floor` (praise-on-fail incl. أحسنت) — the expected-fix
    SUBSTRING component is deliberately absent for live lines (spike: 0.55–0.73 false-flag rate
    on correct paraphrases, 0 real contradictions). `evaluate_faithfulness` (both rules) still
    pins the fixture set in `test_faithfulness.py` — the floor stays green throughout."""
    gate = _praise_gate_cases(cases)
    report = evaluate_praise_floor(gate)
    return {
        "rate": report["rate"],
        "total": report["total"],
        "zero_tolerance": True,  # D-08: the gate fails the build if rate < 1.0
    }


def _score_names_fix(cases: list[dict[str, Any]]) -> dict[str, Any]:
    """D2 — model-free, **ADVISORY** (Phase 17 demotion — reported, never gating).

    On a FAITHFUL miss the coaching names the expected-fix token (the substring rule). The spike
    measured this rule false-flagging 0.55–0.73 of correct paraphrases with ZERO real
    contradictions, so it is DEMOTED: still computed and reported here for observability, but
    `gate_passes` no longer reads it. The semantic_faithfulness judge leg replaces it as the
    meaning-level gate for live lines."""
    misses = [
        c
        for c in _faithful_gate_cases(cases)
        if not c["passed"] and c.get("expectedFix")
    ]
    if not misses:
        return {"rate": 1.0, "total": 0, "advisory": True}
    named = sum(
        0 if _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) else 1
        for c in misses
    )
    return {"rate": named / len(misses), "total": len(misses), "advisory": True}


def _score_judge_dimension(
    cases: list[dict[str, Any]],
    dimension: str,
    judge_scores: Optional[list[float]],
) -> dict[str, Any]:
    """The Vertex LLM-judge legs (threshold, NOT zero-tolerance).

    When `judge_scores` is None (the offline `code` leg) the dimension is reported SKIPPED with a
    None score so `score_eval_set` always returns every dimension without a model dependency.
    Under `make eval` the judge runner supplies real [0,1] scores and this returns the mean +
    a `meets_threshold` flag against `JUDGE_THRESHOLD` (0.7, the ≥0.7 calibration bar)."""
    if judge_scores is None:
        return {
            "score": None,
            "skipped": "Vertex LLM-judge leg — runs under `make eval`, not the `-m code` gate",
            "threshold": JUDGE_THRESHOLD,
        }
    mean = sum(judge_scores) / len(judge_scores) if judge_scores else 0.0
    return {
        "score": mean,
        "threshold": JUDGE_THRESHOLD,
        "meets_threshold": mean >= JUDGE_THRESHOLD,
        "n": len(judge_scores),
    }


def _fold(line: str) -> str:
    """Case/whitespace-fold a line for duplicate/exemplar comparison."""
    return re.sub(r"\s+", " ", line.strip().lower())


def exemplar_lines(prompt: str = COACH_PROMPT) -> list[str]:
    """The GOLD-EXEMPLAR strings from the coach prompt — the verbatim lines the variety leg
    flags when a live coach line echoes one word-for-word (the parroting failure the
    COACH_STROKE_ADDENDUM forbids)."""
    section = prompt.split("GOLD EXEMPLARS", 1)[-1]
    return re.findall(r'"([^"]+)"', section)


def variety_report(lines: list[str], exemplars: list[str]) -> dict[str, Any]:
    """The pure MODEL-FREE duplicate/verbatim-exemplar detector (STRK-01, Plan 17-04 Task 2).

    Over coach lines produced for DISTINCT attempts, flags:
      * any line equal (case/whitespace-folded) to a GOLD-EXEMPLAR string — the parroting
        failure the spike caught in production (exemplars are register to EMULATE, never copy);
      * any two identical lines for distinct attempts (`duplicate_pairs`, index pairs).

    Returns `{distinct_ratio, verbatim_exemplar_hits, duplicate_pairs}` — pure, no model,
    no file reads."""
    folded = [_fold(line) for line in lines if isinstance(line, str) and line.strip()]
    exemplar_set = {_fold(e) for e in exemplars}
    hits = sum(1 for f in folded if f in exemplar_set)
    duplicate_pairs = [
        [i, j]
        for i in range(len(folded))
        for j in range(i + 1, len(folded))
        if folded[i] == folded[j]
    ]
    return {
        "distinct_ratio": len(set(folded)) / len(folded) if folded else 0.0,
        "verbatim_exemplar_hits": hits,
        "duplicate_pairs": duplicate_pairs,
    }


def _score_variety(cases: list[dict[str, Any]]) -> dict[str, Any]:
    """The MODEL-FREE variety leg (STRK-01) — distinct lines for distinct attempts, zero
    verbatim GOLD-EXEMPLAR echoes.

    Scores LIVE coach lines only (`coaching` key). Authored gold labels (`idealCoaching`) are
    reference data, not coach output — a gold line that deliberately mirrors an exemplar is the
    mother's register anchor, not a parroting failure — so sets without live lines report the
    leg as not-run (None ratio) and never fail the gate. Adversarial probes are excluded."""
    lines = [
        c["coaching"]
        for c in cases
        if not _is_adversarial(c)
        and isinstance(c.get("coaching"), str)
        and c["coaching"].strip()
    ]
    if not lines:
        return {
            "distinct_ratio": None,
            "verbatim_exemplar_hits": 0,
            "skipped": "no live coaching lines in this set (authored idealCoaching only)",
            "threshold": VARIETY_THRESHOLD,
        }
    report = variety_report(lines, exemplar_lines())
    return {
        **report,
        "n": len(lines),
        "threshold": VARIETY_THRESHOLD,
        "meets_threshold": (
            report["distinct_ratio"] >= VARIETY_THRESHOLD
            and report["verbatim_exemplar_hits"] == 0
        ),
    }


def score_eval_set(
    path: Union[str, pathlib.Path],
    register_scores: Optional[list[float]] = None,
    arabic_scores: Optional[list[float]] = None,
    semantic_scores: Optional[list[float]] = None,
    geometry_scores: Optional[list[float]] = None,
    specificity_scores: Optional[list[float]] = None,
) -> dict[str, dict[str, Any]]:
    """Score a labeled set on every registry dimension and return a per-dimension score dict.

    D1 (faithfulness, praise floor), D2 (names_fix, advisory) and variety are computed MODEL-FREE
    here (offline). The five judge legs are the Vertex LLM-judge side — pass their score lists
    (each a list of [0,1] judge scores, supplied by `run_judge.py` under `make eval`) to compute
    them; leave them None for the offline `code` leg, where they are reported SKIPPED.

    Returns: `{<dimension>: {<metrics>}}` for every dimension in `DIMENSIONS`."""
    cases = _load_cases(path)
    return {
        "faithfulness": _score_faithfulness(cases),
        "names_fix": _score_names_fix(cases),
        "register": _score_judge_dimension(cases, "register", register_scores),
        "correct_arabic": _score_judge_dimension(cases, "correct_arabic", arabic_scores),
        "semantic_faithfulness": _score_judge_dimension(cases, "semantic_faithfulness", semantic_scores),
        "no_false_geometry": _score_judge_dimension(cases, "no_false_geometry", geometry_scores),
        "specificity": _score_judge_dimension(cases, "specificity", specificity_scores),
        "variety": _score_variety(cases),
    }


def gate_passes(scores: dict[str, dict[str, Any]]) -> bool:
    """The gate condition (Phase 17 shape):

      * D1 (praise-lexicon floor) == 100% — ZERO-TOLERANCE, model-free, gates every context.
      * names_fix (D2) is **ADVISORY** and deliberately ABSENT from this gating path — the spike
        measured the substring rule false-flagging 0.55–0.73 of correct paraphrases with 0 real
        contradictions; the semantic_faithfulness judge leg is its meaning-level replacement.
      * Every JUDGE leg that RAN (score is not None) must meet JUDGE_THRESHOLD. A skipped
        (None-score) judge leg does NOT fail the gate — it simply was not run in this context
        (the offline `code` leg); `make eval` supplies the judge scores.
      * The MODEL-FREE variety leg must meet its threshold whenever it ran (distinct_ratio is
        not None): distinct lines for distinct attempts, zero verbatim exemplar echoes."""
    if scores["faithfulness"]["rate"] < 1.0:  # D-08 zero-tolerance
        return False
    for dim in JUDGE_GATED_DIMENSIONS:
        leg = scores.get(dim)
        if leg is None:
            continue
        if leg.get("score") is not None and not leg.get("meets_threshold", False):
            return False
    variety = scores.get("variety")
    if (
        variety is not None
        and variety.get("distinct_ratio") is not None
        and not variety.get("meets_threshold", False)
    ):
        return False
    return True


if __name__ == "__main__":  # pragma: no cover - offline convenience reporter (model-free legs)
    _default_set = pathlib.Path(__file__).resolve().parents[1] / "fixtures" / "faithfulness_set.jsonl"
    report = score_eval_set(_default_set)
    d1 = report["faithfulness"]
    d2 = report["names_fix"]
    variety = report["variety"]
    print(
        f"EVAL model-free legs — D1 faithfulness (praise floor): {d1['rate']:.2%} over "
        f"{d1['total']} gate cases (zero-tolerance); D2 names_fix (ADVISORY): {d2['rate']:.2%} "
        f"over {d2['total']} misses; variety: {variety.get('distinct_ratio')}. "
        f"Judge legs (register/correct-Arabic/semantic/no-false-geometry/specificity) run under "
        f"`make eval` (Vertex LLM-judge)."
    )
