"""Thin per-spike analysis entrypoints (OFFLINE — read _artifacts/results.json, no model calls).

Each spike's run.py calls one of these. Re-running the model pass is `python _lib/experiment.py`.
"""
from __future__ import annotations

import json

from . import analyze


def _hdr(title):
    print("\n" + "=" * 70 + f"\n{title}\n" + "=" * 70)


def spike_001():
    data = analyze.load()
    _hdr("SPIKE 001 — representation (image / points / geo_diff): accuracy + hallucination")
    for r in analyze.representation_compare(data["runs"]):
        print(json.dumps(r, ensure_ascii=False))
    _hdr("variety content (dotMisplaced — does the rep let the model localize?)")
    print(json.dumps(analyze.variety_by_mistake(data["runs"])["dotMisplaced"], ensure_ascii=False, indent=1))


def spike_002():
    data = analyze.load()
    per_arm, detail = analyze.grounding(data["runs"])
    _hdr("SPIKE 002 — grounding under strokes (adversarial): advance-on-fail / contradicts")
    print(json.dumps(per_arm, ensure_ascii=False, indent=1))
    _hdr("detail")
    print(json.dumps(detail, ensure_ascii=False, indent=1))


def spike_003():
    data = analyze.load()
    _hdr("SPIKE 003 — quality bake-off: arm means (fails, core+variety)")
    for r in analyze.table_arm_means([x for x in data["runs"]
                                      if not x["passed"] and x["category"] in ("core", "variety")]):
        print(json.dumps(r, ensure_ascii=False))
    _hdr("variety distinctness per mistakeId group")
    for mistake, arms in analyze.variety_by_mistake(data["runs"]).items():
        print(f"\n{mistake}:")
        for arm, v in arms.items():
            print(f"  {arm:22} {v['distinct']}/{v['n']} distinct")


def spike_004():
    data = analyze.load()
    _hdr("SPIKE 004 — latency / cost per arm (presence budget ~2s warm)")
    print(json.dumps(analyze.latency(data["runs"]), ensure_ascii=False, indent=1))
