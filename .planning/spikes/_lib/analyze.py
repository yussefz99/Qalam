"""Offline analysis of _artifacts/results.json — produces the per-spike tables. No model calls."""
from __future__ import annotations

import json
import pathlib
from collections import defaultdict

REPO = pathlib.Path(__file__).resolve().parents[3]
RESULTS = REPO / ".planning" / "spikes" / "_artifacts" / "results.json"

ARM_ORDER = ["A_label_verbatim", "B_label_anti_parrot", "C_points", "C_geo_diff", "C_image"]


def load():
    return json.loads(RESULTS.read_text(encoding="utf-8"))


def _mean(xs):
    return round(sum(xs) / len(xs), 3) if xs else None


def by_arm(runs):
    d = defaultdict(list)
    for r in runs:
        d[r["arm"]].append(r)
    return d


def table_arm_means(runs, categories=None):
    """Mean scores per arm over the chosen categories."""
    sel = [r for r in runs if (categories is None or r["category"] in categories)]
    d = by_arm(sel)
    rows = []
    for arm in ARM_ORDER:
        rs = d.get(arm, [])
        if not rs:
            continue
        fails = [r for r in rs if not r["passed"]]
        rows.append({
            "arm": arm,
            "n": len(rs),
            "accuracy": _mean([r["accuracy"] for r in rs]),
            "specificity": _mean([r["specificity"] for r in rs]),
            "register": _mean([r["register"] for r in rs]),
            "correct_arabic": _mean([r["correct_arabic"] for r in rs]),
            "faithful_rate": _mean([1.0 if r["faith"]["faithful"] else 0.0 for r in rs]),
            "names_fix_rate": _mean([1.0 if r["faith"]["names_fix"] else 0.0
                                     for r in fails if r["faith"]["names_fix"] is not None]),
            "hallucination_rate": _mean([1.0 if r["hallucinated"] else 0.0 for r in rs]),
        })
    return rows


def variety_by_mistake(runs):
    """For each (mistakeId group with >1 fixture), distinct lines per arm."""
    groups = defaultdict(lambda: defaultdict(list))
    by_mistake_fixtures = defaultdict(set)
    for r in runs:
        if r["mistakeId"]:
            groups[r["mistakeId"]][r["arm"]].append(r)
            by_mistake_fixtures[r["mistakeId"]].add(r["fixture_id"])
    out = {}
    for mistake, fixset in by_mistake_fixtures.items():
        if len(fixset) < 2:
            continue
        out[mistake] = {}
        for arm in ARM_ORDER:
            lines = [(r["shipped_line"] or r["line"]).strip().lower() for r in groups[mistake][arm]]
            out[mistake][arm] = {"n": len(lines), "distinct": len(set(lines)),
                                 "lines": [r["shipped_line"] or r["line"]
                                           for r in groups[mistake][arm]]}
    return out


def representation_compare(runs):
    """C arms only: accuracy + specificity + hallucination per representation."""
    return table_arm_means([r for r in runs if r["arm"].startswith("C_")])


def grounding(runs):
    """Faithfulness on adversarial fixtures, per arm + per fixture."""
    adv = [r for r in runs if r["category"] == "adversarial"]
    per_arm = {}
    for arm in ARM_ORDER:
        rs = [r for r in adv if r["arm"] == arm]
        per_arm[arm] = {
            "n": len(rs),
            "raw_advance_on_fail": sum(1 for r in rs if r["raw_advance_on_fail"]),
            "contradicts": sum(1 for r in rs if r["faith"]["contradicts"]),
            "faithful_shipped": sum(1 for r in rs if r["grounded"] and r["faith"]["faithful"]),
            "hallucinated": sum(1 for r in rs if r["hallucinated"]),
        }
    detail = defaultdict(dict)
    for r in adv:
        detail[r["fixture_id"]][r["arm"]] = {
            "line": r["shipped_line"] or r["line"], "contradicts": r["faith"]["contradicts"],
            "raw_advance_on_fail": r["raw_advance_on_fail"], "hallucinated": r["hallucinated"],
        }
    return per_arm, dict(detail)


def latency(runs):
    out = {}
    for arm in ARM_ORDER:
        lats = [r["latency_s"] for r in runs if r["arm"] == arm]
        toks = [r["tokens"]["input"] for r in runs if r["arm"] == arm and r.get("tokens")]
        outt = [r["tokens"]["output"] for r in runs if r["arm"] == arm and r.get("tokens")]
        out[arm] = {"n": len(lats), "p50_s": _med(lats), "max_s": max(lats) if lats else None,
                    "mean_input_tok": int(_mean(toks) or 0), "mean_output_tok": int(_mean(outt) or 0)}
    return out


def _med(xs):
    if not xs:
        return None
    s = sorted(xs)
    n = len(s)
    return round(s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2, 3)


def _pp(title, rows):
    print(f"\n### {title}")
    if isinstance(rows, list):
        for r in rows:
            print(" ", json.dumps(r, ensure_ascii=False))
    else:
        print(json.dumps(rows, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    data = load()
    runs = data["runs"]
    print("META:", json.dumps(data["meta"], ensure_ascii=False))
    _pp("ARM MEANS — all fixtures", table_arm_means(runs))
    _pp("ARM MEANS — fails only (core+variety)", table_arm_means(
        [r for r in runs if not r["passed"] and r["category"] in ("core", "variety")]))
    _pp("VARIETY by mistakeId", variety_by_mistake(runs))
    pa, det = grounding(runs)
    _pp("GROUNDING — adversarial per arm", pa)
    _pp("GROUNDING — adversarial detail", det)
    _pp("LATENCY per arm", latency(runs))
