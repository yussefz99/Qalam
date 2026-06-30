"""Scoring for the spike (THROWAWAY) — reuses the PRODUCTION eval primitives so results line up
with `make eval`:

* faithfulness — app.faithfulness._contradicts (the model-free, zero-tolerance D1 gate).
* names_fix    — the D2 substring check (does a FAIL line name the expected fix?).
* register / correct_arabic — the Vertex LLM-judge against the production JUDGE_RUBRIC.md.

Plus two spike-specific judge dimensions:
* accuracy     — does the line correctly describe what the strokes ACTUALLY show (geom_truth),
                 with NO hallucinated detail? (H3 — which representation the model reads best.)
* specificity  — does the line name a concrete, THIS-attempt detail vs a generic fix? (H1.)
"""
from __future__ import annotations

import json
import re
from typing import Any

from app.faithfulness import _contradicts
from tests.test_eval.run_judge import load_rubric, _build_prompt, _parse_score

from . import vertex


def faithfulness(line: str, case: dict[str, Any]) -> dict[str, Any]:
    passed = case["passed"]
    ef = case.get("expectedFix")
    contradicts = _contradicts(passed, line, ef)
    names_fix = None
    if not passed and ef:
        names_fix = ef.lower() in line.lower()
    return {"faithful": not contradicts, "contradicts": contradicts, "names_fix": names_fix}


def build_judge():
    return vertex.build_gemini(model="gemini-2.5-flash", temperature=0.0, max_tokens=256)


def _ask(judge, prompt: str) -> dict[str, Any]:
    reply = judge.invoke(prompt)
    text = getattr(reply, "content", reply)
    text = text if isinstance(text, str) else str(text)
    return {"score": _parse_score(text), "raw": text[:300]}


def judge_register(judge, rubric: str, line: str, case: dict[str, Any]) -> float:
    return _ask(judge, _build_prompt(rubric, "register", line, case))["score"]


def judge_correct_arabic(judge, rubric: str, line: str, case: dict[str, Any]) -> float:
    return _ask(judge, _build_prompt(rubric, "correct_arabic", line, case))["score"]


def judge_accuracy(judge, line: str, case: dict[str, Any]) -> dict[str, Any]:
    """Does the coaching line correctly describe the ACTUAL stroke error (geom_truth), no hallucination?"""
    verdict = "PASS (clean)" if case.get("passed") else f"FAIL (mistakeId={case.get('mistakeId')})"
    prompt = (
        "You are grading whether a handwriting coach's line ACCURATELY describes a child's actual "
        "baa (ب) attempt. Baa is a boat-shaped body curve with ONE dot below.\n\n"
        f"GROUND TRUTH — what the strokes actually show: {case.get('geom_truth')!r}\n"
        f"Scorer verdict (frozen): {verdict}\n"
        f"Coach's line: {line!r}\n\n"
        "Score `accuracy` in [0,1]: 1.0 = the line's description of the shape/dot is consistent with "
        "the ground truth and invents NOTHING; 0.0 = it describes a defect that isn't there, names "
        "the wrong feature, or hallucinates a detail (a dot/tail that isn't present). A correct, "
        "grounded line that simply coaches the fix without a false detail scores high.\n"
        'Also set "hallucinated": true if the line asserts any concrete detail absent from the ground '
        "truth.\n"
        'Return JSON: {"score": <float>, "hallucinated": <bool>, "rationale": "<one line>"}'
    )
    reply = judge.invoke(prompt)
    text = getattr(reply, "content", reply)
    text = text if isinstance(text, str) else str(text)
    hall = bool(re.search(r'"hallucinated"\s*:\s*true', text, re.I))
    return {"score": _parse_score(text), "hallucinated": hall, "raw": text[:300]}


def judge_specificity(judge, line: str, case: dict[str, Any]) -> float:
    """Does the line name a concrete, THIS-attempt geometric detail vs a generic/canned fix?"""
    verdict = "PASS (clean)" if case.get("passed") else f"FAIL (mistakeId={case.get('mistakeId')})"
    prompt = (
        "Grade the SPECIFICITY of a handwriting coach's line for a baa (ب) attempt.\n"
        f"Scorer verdict: {verdict}\n"
        f"Coach's line: {line!r}\n\n"
        "Score `specificity` in [0,1]: 1.0 = names a concrete, attempt-specific detail (e.g. WHICH "
        "side is flat, WHERE the dot landed, which direction the stroke went); 0.0 = a generic line "
        "that could apply to any attempt with this mistake ('try again', 'make a deeper curve'). "
        "A correct PASS celebration that is warm but generic scores in the middle.\n"
        'Return JSON: {"score": <float>, "rationale": "<one line>"}'
    )
    return _ask(judge, prompt)["score"]


def variety(lines: list[str]) -> dict[str, Any]:
    """Distinctness across lines that share a mistakeId (the H1 crux)."""
    norm = [re.sub(r"\s+", " ", l.strip().lower()) for l in lines if l.strip()]
    distinct = len(set(norm))
    return {"n": len(norm), "distinct": distinct,
            "distinct_ratio": round(distinct / len(norm), 2) if norm else 0.0,
            "lines": lines}


def mean(xs: list[float]) -> float:
    return round(sum(xs) / len(xs), 3) if xs else 0.0
