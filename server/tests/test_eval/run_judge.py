"""Vertex LLM-judge runner — register (D5) + correct-Arabic (Plan 16-03, D-09).

Scores coaching lines on the two JUDGE dimensions (register + correct-Arabic) using a Vertex AI
Gemini judge against `JUDGE_RUBRIC.md`, then feeds the per-case scores into `run_eval.score_eval_set`
so `make eval` can gate on the ≥ 0.7 threshold. The model-free D1/D2 legs are NOT here — they live in
`run_eval.py` and gate every PR under `-m code`; this runner is the INTEGRATION leg that calls Vertex.

JUDGE ≠ COACH-UNDER-TEST (16-RESEARCH Open Q2 / threat T-16-03-03): the judge is **gemini-2.5-flash**,
distinct from the coach-under-test, to avoid self-grading bias. The Claude-vs-Gemini coach bake-off
(16-06) swaps the COACH via env (COACH_MODEL_PROVIDER=anthropic_vertex …); the JUDGE stays Gemini.

KEYLESS VERTEX (D-02 posture, mirrors `app/models.py`): the judge is built via `langchain_google_vertexai.ChatVertexAI`
with runtime SA ADC — NO provider key, NO ANTHROPIC_API_KEY. The Vertex client is imported LAZILY inside
`build_judge_model()` so importing this module needs no ADC; only an actual `make eval` run reaches Vertex.

CALIBRATION (14-AI-SPEC §5): the judge must reach ≥ 0.7 correlation with the owner's-mother gold labels
(`gold_set.jsonl`, signed in 16-05) before its score is trusted to gate. This runner reports the mean
score per dimension and is the harness the 16-05 calibration + 16-06 bake-off ride.

D-10 NO-TRAINING (14-AI-SPEC §1b): the gold set / labeled transcripts must NOT train/fine-tune models
without separate verifiable parental consent; the gold set is synthetic/authored non-PII. Vertex
request-response logging stays off / no-training-use.
"""

from __future__ import annotations

import json
import os
import pathlib
import re
from typing import Any

# The judge model — gemini-2.5-flash, NOT the coach-under-test (avoid self-grading bias). Overridable
# by env for experiments, but the DEFAULT is deliberately Gemini-on-Vertex, keyless.
JUDGE_MODEL = os.environ.get("JUDGE_MODEL", "gemini-2.5-flash")
JUDGE_LOCATION = os.environ.get("JUDGE_LOCATION", "us-central1")
JUDGE_TEMPERATURE = float(os.environ.get("JUDGE_TEMPERATURE", "0"))

_HERE = pathlib.Path(__file__).resolve().parent
_RUBRIC_PATH = _HERE / "JUDGE_RUBRIC.md"
_GOLD_SET_PATH = _HERE / "gold_set.jsonl"

# The dimensions this runner judges: the §5 D5 register + correct-Arabic legs (Plan 16-03) plus
# the Phase-17 (EVAL-03/STRK-01) semantic legs (Plan 17-04). Each has a rubric section in
# JUDGE_RUBRIC.md. The judge stays gemini-2.5-flash (judge != coach), thinking_budget=0.
JUDGE_DIMENSIONS = (
    "register",
    "correct_arabic",
    "semantic_faithfulness",
    "no_false_geometry",
    "specificity",
)


def build_judge_model():
    """Build the Vertex Gemini judge (keyless via runtime SA ADC). Lazy import — no ADC at import.

    Uses `ChatVertexAI` directly (gemini-2.5-flash), the same keyless Vertex posture as
    `app/models.py`. `thinking_budget=0` keeps the judge fast + deterministic (mirrors
    `_provider_kwargs("google_vertexai")`)."""
    from langchain_google_vertexai import ChatVertexAI

    return ChatVertexAI(
        model=JUDGE_MODEL,
        project=os.environ["GCP_PROJECT_ID"],
        location=JUDGE_LOCATION,
        temperature=JUDGE_TEMPERATURE,
        thinking_budget=0,
    )


def load_rubric() -> str:
    """The register + correct-Arabic rubric prose the judge scores against."""
    return _RUBRIC_PATH.read_text(encoding="utf-8")


def load_gold_cases(path: pathlib.Path = _GOLD_SET_PATH) -> list[dict[str, Any]]:
    """Read the (verdict → ideal-coaching) gold set. `#`-prefixed header/comment lines are skipped."""
    cases: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        cases.append(json.loads(stripped))
    return cases


def _render_case_facts(case: dict[str, Any]) -> str:
    """Render the case's DERIVED facts generically for the judge prompt (Plan 17-04).

    Any `strokeDiff` and `criteria` keys present on a case are rendered as-is (JSON), so the
    no-false-geometry / specificity legs can check every geometric claim against the facts —
    and criteria-bearing cases (Plan 17-05) need NO further harness change. Facts are derived,
    point-free, non-PII by construction (StrokeDiffIn vocabulary)."""
    parts: list[str] = []
    for key in ("strokeDiff", "criteria"):
        if case.get(key) is not None:
            parts.append(
                f"{key} (DERIVED facts of THIS attempt — frozen, the only geometry that exists): "
                f"{json.dumps(case[key], ensure_ascii=False)}"
            )
    return ("\n".join(parts) + "\n") if parts else ""


def _build_prompt(rubric: str, dimension: str, coaching: str, case: dict[str, Any]) -> str:
    """The judge prompt for ONE (dimension, coaching) pair — rubric-anchored, [0,1] output."""
    verdict = "PASS (clean)" if case.get("passed") else f"FAIL (mistakeId={case.get('mistakeId')})"
    return (
        f"{rubric}\n\n"
        f"---\nScore ONLY the `{dimension}` dimension for the coaching line below.\n"
        f"Scorer verdict (frozen FACT): {verdict}\n"
        f"{_render_case_facts(case)}"
        f"Coaching line: {coaching!r}\n\n"
        f"Return a single float in [0, 1] for `{dimension}` and one short rationale, as JSON: "
        f'{{"score": <float>, "rationale": "<one line>"}}'
    )


def _parse_score(text: str) -> float:
    """Pull the [0,1] float out of the judge reply (JSON preferred; regex fallback)."""
    try:
        return max(0.0, min(1.0, float(json.loads(text)["score"])))
    except Exception:
        m = re.search(r'"score"\s*:\s*([01](?:\.\d+)?)', text)
        if m:
            return max(0.0, min(1.0, float(m.group(1))))
        m = re.search(r"([01](?:\.\d+)?)", text)
        return max(0.0, min(1.0, float(m.group(1)))) if m else 0.0


def judge_dimension(model, rubric: str, dimension: str, cases: list[dict[str, Any]]) -> list[float]:
    """Run the judge over every case on ONE dimension; return the per-case [0,1] scores."""
    scores: list[float] = []
    for case in cases:
        coaching = case.get("idealCoaching") or case.get("coaching") or ""
        reply = model.invoke(_build_prompt(rubric, dimension, coaching, case))
        text = getattr(reply, "content", reply)
        scores.append(_parse_score(text if isinstance(text, str) else str(text)))
    return scores


def _is_adversarial(case: dict[str, Any]) -> bool:
    """Adversarial-labeled TRAP cases (e.g. `adv_broken_but_pass`) are probes the judge must
    CATCH (score below threshold on their target dimension) — they never join the gate means."""
    return str(case.get("label", "")).startswith("adversarial")


def judge_traps(model, rubric: str, cases: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Run each adversarial TRAP case on its `trapDimension` (Plan 17-04).

    A trap carries a deliberately-BAD line (e.g. the `adv_broken_but_pass` case asserts a deep
    smooth bowl over flat-bowl strokeDiff facts). The judge CATCHES the trap when it scores the
    line BELOW the threshold on the trap's dimension; a trap the judge scores high is a judge
    miscalibration and fails the gate."""
    from tests.test_eval.run_eval import JUDGE_THRESHOLD

    results: list[dict[str, Any]] = []
    for trap in cases:
        dimension = trap.get("trapDimension")
        if not dimension:
            continue
        score = judge_dimension(model, rubric, dimension, [trap])[0]
        results.append(
            {
                "id": trap.get("id"),
                "dimension": dimension,
                "score": score,
                "caught": score < JUDGE_THRESHOLD,
            }
        )
    return results


def run_judge(path: pathlib.Path = _GOLD_SET_PATH) -> dict[str, Any]:
    """Score the gold set on all five judge dimensions via the Vertex Gemini judge.

    Gate cases (non-adversarial) feed the per-dimension means; adversarial TRAP cases are judged
    individually on their `trapDimension` and must be CAUGHT (scored below threshold). Returns
    the full `score_eval_set` report (the model-free D1/D2/variety legs ride along for the gate)
    plus `_traps`. Calling this REACHES Vertex (integration; `make eval`)."""
    from tests.test_eval.run_eval import JUDGE_THRESHOLD, gate_passes, score_eval_set

    rubric = load_rubric()
    cases = load_gold_cases(path)
    gate_cases = [c for c in cases if not _is_adversarial(c)]
    trap_cases = [c for c in cases if _is_adversarial(c)]
    model = build_judge_model()

    register_scores = judge_dimension(model, rubric, "register", gate_cases)
    arabic_scores = judge_dimension(model, rubric, "correct_arabic", gate_cases)
    semantic_scores = judge_dimension(model, rubric, "semantic_faithfulness", gate_cases)
    geometry_scores = judge_dimension(model, rubric, "no_false_geometry", gate_cases)
    specificity_scores = judge_dimension(model, rubric, "specificity", gate_cases)

    report = score_eval_set(
        path,
        register_scores=register_scores,
        arabic_scores=arabic_scores,
        semantic_scores=semantic_scores,
        geometry_scores=geometry_scores,
        specificity_scores=specificity_scores,
    )
    trap_results = judge_traps(model, rubric, trap_cases)
    report["_traps"] = trap_results
    report["_judge_model"] = JUDGE_MODEL
    report["_threshold"] = JUDGE_THRESHOLD
    report["_gate_passes"] = gate_passes(report) and all(t["caught"] for t in trap_results)
    return report


def main() -> int:
    """`make eval` entrypoint for the judge leg — exits NON-ZERO if a judged dimension is below
    threshold (D-09), a TRAP case is not caught, or the model-free D1 floor is < 100% (D-08)."""
    report = run_judge()
    dims = ", ".join(
        f"{d}: {report[d].get('score')}" for d in JUDGE_DIMENSIONS
    )
    print(
        f"Vertex LLM-judge ({JUDGE_MODEL}, judge != coach) — {dims} "
        f"(threshold {report['_threshold']})"
    )
    for trap in report["_traps"]:
        status = "CAUGHT" if trap["caught"] else "MISSED"
        print(f"  trap {trap['id']!r} on `{trap['dimension']}`: score {trap['score']} — {status}")
    if not report["_gate_passes"]:
        print(
            "EVAL GATE FAILED — D1 floor < 100%, a judged dimension below threshold, "
            "the variety leg below threshold, or a trap case the judge did not catch."
        )
        return 1
    print("EVAL GATE PASSED.")
    return 0


if __name__ == "__main__":  # pragma: no cover - integration entrypoint (reaches Vertex)
    raise SystemExit(main())
