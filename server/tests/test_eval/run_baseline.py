"""STRK-01 — the TWO-ARM baseline instrument (Plan 17-04 Task 2).

Measures whether stroke-aware coaching "measurably beats the label-only baseline on
specificity + variety with grounding intact" (STRK-01), by running EVERY stroke-level gold
fixture through the PRODUCTION coach node twice:

  * ARM A (stroke-aware) — the facts carry the case's derived `strokeDiff` (and `criteria`,
    when present — the Plan 17-05 structured result rides the same seam with no change here).
  * ARM B (label-only)   — the same facts with the `strokeDiff`/`criteria` keys STRIPPED.

Both arms are scored on:
  * specificity — the Vertex LLM-judge leg (gemini-2.5-flash, judge != coach, JUDGE_RUBRIC.md);
    both arms are judged WITH the derived facts shown, so localization claims are verifiable.
  * variety     — the MODEL-FREE duplicate/verbatim-exemplar detector (`variety_report`).
  * grounding   — ZERO-TOLERANCE, model-free: praise-on-fail (the `evaluate_praise_floor`
    lexicon), shipped advance-on-fail, and any G2/G3/G4 guard rewrite (`grounded == False` —
    the raw model tried to break grounding and the guard caught it). MUST be 0 violations in
    BOTH arms — a stroke-aware win that costs grounding is not a win.

EXIT CODE: non-zero when arm A does not beat arm B on specificity AND variety, or when
grounding violations > 0 anywhere (the zero-tolerance check).

INTEGRATION, NOT `-m code`: invoking the coach + judge REACHES Vertex (keyless ADC — set
GCP_PROJECT_ID, `gcloud auth application-default login` locally). This runner executes under
`make eval` only; importing the module stays ADC-free (model building is lazy inside the
production `coach` node and `build_judge_model`).

D-10 NO-TRAINING: fixtures are the synthetic/authored non-PII gold set; transcripts are printed
for comparison only, never emitted as training data.
"""

from __future__ import annotations

import os
import pathlib
import sys
from typing import Any

# Allow both `uv run python tests/test_eval/run_baseline.py` (script) and module import.
_SERVER_ROOT = pathlib.Path(__file__).resolve().parents[2]
if str(_SERVER_ROOT) not in sys.path:  # pragma: no cover - script-invocation path setup
    sys.path.insert(0, str(_SERVER_ROOT))

os.environ.setdefault("GCP_PROJECT_ID", "qalam-app-bd7d0")

from app.faithfulness import evaluate_praise_floor  # noqa: E402
from tests.test_eval.run_eval import (  # noqa: E402
    JUDGE_THRESHOLD,
    exemplar_lines,
    variety_report,
)
from tests.test_eval.run_judge import (  # noqa: E402
    build_judge_model,
    judge_dimension,
    load_gold_cases,
    load_rubric,
)

# The facts keys stripped from ARM B — the label-only baseline never sees derived geometry.
STROKE_FACT_KEYS = ("strokeDiff", "criteria")


def stroke_level_fixtures() -> list[dict[str, Any]]:
    """The two-arm inputs: every NON-adversarial gold case carrying derived stroke facts.

    Adversarial trap cases are judge-calibration probes, not coach inputs; label-only gold
    cases (no strokeDiff) have no arm-A/arm-B distinction to measure."""
    return [
        c
        for c in load_gold_cases()
        if not str(c.get("label", "")).startswith("adversarial")
        and any(c.get(k) for k in STROKE_FACT_KEYS)
    ]


def _facts_for(case: dict[str, Any], *, with_stroke_facts: bool) -> dict[str, Any]:
    """The non-PII frozen FACTS the production coach receives (wire-whitelist keys only)."""
    facts: dict[str, Any] = {
        "letterId": case["letterId"],
        "section": case["section"],
        "passed": case["passed"],
        "mistakeId": case.get("mistakeId"),
        "struggleTags": [],
        "recentMistakes": [],
        "strengthTags": [],
        "trajectory": [],
    }
    if with_stroke_facts:
        for key in STROKE_FACT_KEYS:
            if case.get(key) is not None:
                facts[key] = case[key]
    return facts


def _coach_line(facts: dict[str, Any]) -> dict[str, Any]:
    """Invoke the PRODUCTION coach node (prompt + addendum trigger + G2/G3/G4 guards) once.

    Imported lazily — this is the call that builds the Vertex model (ADC required)."""
    from app.nodes.coach import coach  # lazy: model building happens inside the node

    out = coach({"facts": facts, "insight": {}, "plan": None})
    decision = out.get("decision", {})
    args = decision.get("args", {}) or {}
    return {
        "tool": decision.get("name", "say"),
        "line": str(args.get("text") or args.get("coaching_line") or ""),
        "grounded": bool(out.get("grounded", False)),
    }


def run_arm(cases: list[dict[str, Any]], *, with_stroke_facts: bool) -> list[dict[str, Any]]:
    """Produce one coach line per fixture for one arm."""
    results: list[dict[str, Any]] = []
    for case in cases:
        produced = _coach_line(_facts_for(case, with_stroke_facts=with_stroke_facts))
        results.append({**produced, "case": case})
    return results


def grounding_violations(results: list[dict[str, Any]]) -> list[str]:
    """ZERO-TOLERANCE grounding check (model-free) — returns violation descriptions.

    Counts: (a) praise-on-fail in the shipped line (praise-lexicon floor incl. أحسنت);
    (b) a shipped `advance` on a failed attempt (structurally prevented by G3 — any hit is a
    hard bug); (c) any guard rewrite (`grounded == False`): the raw model attempted an
    ungrounded action and a G2/G3/G4 guard had to catch it."""
    violations: list[str] = []
    for r in results:
        case_id = r["case"].get("id") or r["case"].get("section")
        passed = r["case"]["passed"]
        floor = evaluate_praise_floor([{"passed": passed, "coaching": r["line"]}])
        if floor["flagged"]:
            violations.append(f"praise-on-fail on {case_id!r}: {r['line']!r}")
        if r["tool"] == "advance" and not passed:
            violations.append(f"advance-on-fail SHIPPED on {case_id!r} (G3 breach)")
        if not r["grounded"]:
            violations.append(f"guard rewrite (raw ungrounded action) on {case_id!r}")
    return violations


def specificity_scores(results: list[dict[str, Any]], model, rubric: str) -> list[float]:
    """Judge each produced line on `specificity` — the facts are shown for BOTH arms so the
    judge can verify localization claims against the same ground truth."""
    judged_cases = [
        {**r["case"], "coaching": r["line"], "idealCoaching": None} for r in results
    ]
    return judge_dimension(model, rubric, "specificity", judged_cases)


def _mean(xs: list[float]) -> float:
    return round(sum(xs) / len(xs), 3) if xs else 0.0


def main() -> int:
    cases = stroke_level_fixtures()
    if not cases:
        print("STRK-01 baseline: no stroke-level fixtures in gold_set.jsonl — nothing to compare.")
        return 1

    print(f"STRK-01 two-arm baseline over {len(cases)} stroke-level fixtures …")
    arm_a = run_arm(cases, with_stroke_facts=True)   # stroke-aware (geo-facts arm)
    arm_b = run_arm(cases, with_stroke_facts=False)  # label-only baseline

    # --- grounding: ZERO-TOLERANCE in BOTH arms (0 grounding violations required) ---
    viol_a = grounding_violations(arm_a)
    viol_b = grounding_violations(arm_b)

    # --- specificity: the Vertex judge leg ---
    model = build_judge_model()
    rubric = load_rubric()
    spec_a = _mean(specificity_scores(arm_a, model, rubric))
    spec_b = _mean(specificity_scores(arm_b, model, rubric))

    # --- variety: the model-free detector ---
    exemplars = exemplar_lines()
    var_a = variety_report([r["line"] for r in arm_a], exemplars)
    var_b = variety_report([r["line"] for r in arm_b], exemplars)

    print("\n  metric                       ARM A (stroke-aware)   ARM B (label-only)")
    print(f"  specificity (judge mean)     {spec_a:<22} {spec_b}")
    print(f"  variety distinct_ratio       {round(var_a['distinct_ratio'], 3):<22} {round(var_b['distinct_ratio'], 3)}")
    print(f"  verbatim exemplar hits       {var_a['verbatim_exemplar_hits']:<22} {var_b['verbatim_exemplar_hits']}")
    print(f"  grounding violations         {len(viol_a):<22} {len(viol_b)}")
    print(f"  (judge threshold {JUDGE_THRESHOLD}; judge != coach)")

    failures: list[str] = []

    # ZERO-TOLERANCE: grounding violations must be 0 in BOTH arms.
    if viol_a or viol_b:
        for v in viol_a:
            failures.append(f"ARM A grounding violation: {v}")
        for v in viol_b:
            failures.append(f"ARM B grounding violation: {v}")

    # STRK-01: arm A must beat arm B on specificity …
    if not spec_a > spec_b:
        failures.append(f"specificity: arm A ({spec_a}) does not beat arm B ({spec_b})")

    # … AND on variety: arm A echoes NO exemplar and its distinct ratio is not worse; at the
    # 1.0/0-hits ceiling a tie counts as a win (both arms fully varied — A is not worse).
    a_at_ceiling = var_a["distinct_ratio"] == 1.0 and var_a["verbatim_exemplar_hits"] == 0
    variety_beats = (
        var_a["verbatim_exemplar_hits"] == 0
        and var_a["distinct_ratio"] >= var_b["distinct_ratio"]
        and (
            var_a["distinct_ratio"] > var_b["distinct_ratio"]
            or var_b["verbatim_exemplar_hits"] > 0
            or a_at_ceiling
        )
    )
    if not variety_beats:
        failures.append(
            f"variety: arm A ({var_a['distinct_ratio']}, {var_a['verbatim_exemplar_hits']} hits) "
            f"does not beat arm B ({var_b['distinct_ratio']}, {var_b['verbatim_exemplar_hits']} hits)"
        )

    if failures:
        print("\nSTRK-01 BASELINE GATE FAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1

    print("\nSTRK-01 BASELINE GATE PASSED — stroke-aware beats label-only, grounding intact (0 violations in both arms).")
    return 0


if __name__ == "__main__":  # pragma: no cover - integration entrypoint (reaches Vertex)
    raise SystemExit(main())
