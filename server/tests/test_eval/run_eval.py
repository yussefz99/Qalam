"""EVAL-01 / EVAL-02 — the two-leg eval harness (Plan 16-03; satisfies the 16-01 RED contract).

`score_eval_set(path)` scores a labeled `(verdict, learner-state)` set on the four 14-AI-SPEC §5
dimensions the Phase-16 gate cares about and returns a per-dimension score dict:

  * D1  — faithfulness    (MODEL-FREE, ZERO-TOLERANCE) — reuses `app.faithfulness`. The gate cases
            (label == "faithful") must score exactly 1.0; a single contradiction fails the build.
  * D2  — names_fix       (MODEL-FREE) — on a miss the coaching names the expected fix (the same
            substring rule the faithfulness wrong-fix leg uses). Scored as a rate over the misses.
  * D5  — register        (Vertex LLM-JUDGE, THRESHOLD) — the mother's warm/calm/specific voice.
  *       correct_arabic  (Vertex LLM-JUDGE, THRESHOLD) — أحسنت etc. used correctly.

TWO LEGS, ONE HARNESS (D-10):
  * The MODEL-FREE legs (D1/D2) run offline under `uv run pytest -m code` and gate every PR. They
    need no model, no auth, no network — pure file reads against fixed scorer verdicts.
  * The Vertex-LLM-JUDGE legs (register + correct_arabic) are INTEGRATION: they call Vertex AI
    (gemini-2.5-flash, keyless ADC), are NOT `code`-marked, and run only under `make eval`. In the
    offline `code` leg they are reported as {"score": None, "skipped": ...} so `score_eval_set`
    returns ALL FOUR dimensions in every context without a model dependency at import time.

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
from typing import Any, Optional, Union

from app.faithfulness import _contradicts, faithfulness_rate

# The four 14-AI-SPEC §5 dimensions this gate scores. D1/D2 are model-free; D5/correct_arabic are
# the Vertex LLM-judge legs. The 16-01 RED test asserts this set covers all four.
DIMENSIONS: tuple[str, ...] = (
    "faithfulness",   # D1 — model-free, zero-tolerance
    "names_fix",      # D2 — model-free, the coaching names the expected fix on a miss
    "register",       # D5 — Vertex LLM-judge, threshold (mother's voice / arabic register)
    "correct_arabic",  # correct-Arabic — Vertex LLM-judge, threshold
)

# Judge calibration / gate threshold for the LLM-judge legs (NOT zero-tolerance, unlike D1).
JUDGE_THRESHOLD = 0.7


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


def _faithful_gate_cases(cases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """The curated FAITHFUL gate subset (label == 'faithful') — the zero-tolerance D1 leg scores
    THIS, not the adversarial probes (which are SUPPOSED to contradict)."""
    return [c for c in cases if c.get("label") == "faithful"]


def _score_faithfulness(cases: list[dict[str, Any]]) -> dict[str, Any]:
    """D1 — model-free, ZERO-TOLERANCE. Rate over the FAITHFUL gate cases (must be 1.0)."""
    gate = _faithful_gate_cases(cases)
    rate = faithfulness_rate(gate)
    return {
        "rate": rate,
        "total": len(gate),
        "zero_tolerance": True,  # D-08: the gate fails the build if rate < 1.0
    }


def _score_names_fix(cases: list[dict[str, Any]]) -> dict[str, Any]:
    """D2 — model-free. On a FAITHFUL miss the coaching must NAME the expected fix token.

    Reuses the faithfulness wrong-fix rule: a miss whose coaching omits the expected-fix token
    `_contradicts`. The names-fix rate is (misses that name the fix) / (misses with an expected fix)
    over the FAITHFUL gate cases — the model-free D2 leg the 16-01 RED test asserts is present."""
    misses = [
        c
        for c in _faithful_gate_cases(cases)
        if not c["passed"] and c.get("expectedFix")
    ]
    if not misses:
        return {"rate": 1.0, "total": 0}
    named = sum(
        0 if _contradicts(c["passed"], c["coaching"], c.get("expectedFix")) else 1
        for c in misses
    )
    return {"rate": named / len(misses), "total": len(misses)}


def _score_judge_dimension(
    cases: list[dict[str, Any]],
    dimension: str,
    judge_scores: Optional[list[float]],
) -> dict[str, Any]:
    """D5 register + correct_arabic — the Vertex LLM-judge legs (threshold, NOT zero-tolerance).

    When `judge_scores` is None (the offline `code` leg) the dimension is reported SKIPPED with a
    None score so `score_eval_set` always returns all four dimensions without a model dependency.
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


def score_eval_set(
    path: Union[str, pathlib.Path],
    register_scores: Optional[list[float]] = None,
    arabic_scores: Optional[list[float]] = None,
) -> dict[str, dict[str, Any]]:
    """Score a labeled set on all four §5 dimensions and return a per-dimension score dict.

    D1 (faithfulness) + D2 (names_fix) are computed MODEL-FREE here (offline). D5 (register) +
    correct_arabic are the Vertex LLM-judge legs — pass `register_scores` / `arabic_scores`
    (each a list of [0,1] judge scores, supplied by `run_judge.py` under `make eval`) to compute
    them; leave them None for the offline `code` leg, where they are reported SKIPPED.

    Returns: `{<dimension>: {<metrics>}}` for every dimension in `DIMENSIONS`."""
    cases = _load_cases(path)
    return {
        "faithfulness": _score_faithfulness(cases),
        "names_fix": _score_names_fix(cases),
        "register": _score_judge_dimension(cases, "register", register_scores),
        "correct_arabic": _score_judge_dimension(cases, "correct_arabic", arabic_scores),
    }


def gate_passes(scores: dict[str, dict[str, Any]]) -> bool:
    """The D-07/D-08 gate condition: D1 == 100% (zero-tolerance) AND every JUDGE leg that ran meets
    the threshold. A skipped (None-score) judge leg does NOT fail the gate — it simply was not run
    in this context (the offline `code` leg). `make eval` supplies the judge scores so the live run
    enforces the register/Arabic threshold; the per-commit `-m code` run enforces only D1/D2."""
    if scores["faithfulness"]["rate"] < 1.0:  # D-08 zero-tolerance
        return False
    for dim in ("register", "correct_arabic"):
        leg = scores[dim]
        if leg.get("score") is not None and not leg.get("meets_threshold", False):
            return False
    return True


if __name__ == "__main__":  # pragma: no cover - offline convenience reporter (model-free legs)
    _default_set = pathlib.Path(__file__).resolve().parents[1] / "fixtures" / "faithfulness_set.jsonl"
    report = score_eval_set(_default_set)
    d1 = report["faithfulness"]
    d2 = report["names_fix"]
    print(
        f"EVAL model-free legs — D1 faithfulness: {d1['rate']:.2%} over {d1['total']} gate cases "
        f"(zero-tolerance); D2 names_fix: {d2['rate']:.2%} over {d2['total']} misses. "
        f"Register + correct-Arabic run under `make eval` (Vertex LLM-judge)."
    )
