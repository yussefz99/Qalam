"""The heavy model pass for the stroke-aware-coaching spike (THROWAWAY).

Runs every fixture through all coaching ARMS, then scores every produced line. Writes ONE rich
artifact (`_artifacts/results.json`) that all five spike analyses read offline — so the expensive
Vertex calls happen once.

ARMS:
  A  label_only            — verbatim-exemplar production prompt, NO strokes (true status quo)
  B  label_anti_parrot     — "cheap win" prompt (fresh wording), NO strokes
  Cp stroke_aware/points   — anti-parrot + resampled point arrays
  Cg stroke_aware/geo_diff — anti-parrot + precomputed geometry diff
  Ci stroke_aware/image    — anti-parrot + rendered overlay PNG (multimodal)

SCORES per line: faithfulness (model-free, D1), names_fix (D2), and the Vertex judge dims
register, correct_arabic, accuracy (vs geom_truth), specificity.

Concurrency: a thread pool (Vertex calls are I/O bound). Each call retries on transient error.
"""
from __future__ import annotations

import json
import os
import pathlib
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

REPO = pathlib.Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO / "server"))
sys.path.insert(0, str(REPO / ".planning" / "spikes"))
os.environ.setdefault("GCP_PROJECT_ID", "qalam-app-bd7d0")

from _lib import coaches, fixtures, representations as R, scoring  # noqa: E402

ART = REPO / ".planning" / "spikes" / "_artifacts"
ART.mkdir(exist_ok=True)
RESULTS = ART / "results.json"

MAX_WORKERS = 8
SEED_NOTE = "temperature=0.5 (production coach temp); single sample per (fixture, arm)."


def _retry(fn, *a, tries=4, **k):
    last = None
    for i in range(tries):
        try:
            return fn(*a, **k)
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5 * (i + 1))
    raise last


ARMS = [
    ("A_label_verbatim", lambda c, reps: coaches.label_only_coach(c)),
    ("B_label_anti_parrot", lambda c, reps: coaches.label_only_coach(c, anti_parrot=True)),
    ("C_points", lambda c, reps: coaches.stroke_aware_coach(c, "points", reps=reps)),
    ("C_geo_diff", lambda c, reps: coaches.stroke_aware_coach(c, "geo_diff", reps=reps)),
    ("C_image", lambda c, reps: coaches.stroke_aware_coach(c, "image", reps=reps)),
]


def generate(fxs) -> list[dict]:
    reps_cache = {f["id"]: R.build_all(f) for f in fxs}
    tasks = [(f, arm, fn) for f in fxs for (arm, fn) in ARMS]
    runs: list[dict] = []
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
        futs = {ex.submit(_retry, fn, f, reps_cache[f["id"]]): (f, arm) for (f, arm, fn) in tasks}
        for i, fut in enumerate(as_completed(futs), 1):
            f, arm = futs[fut]
            r = fut.result()
            r["arm"] = arm
            r["category"] = f["category"]
            r["passed"] = f["passed"]
            r["mistakeId"] = f["mistakeId"]
            r["geom_truth"] = f["geom_truth"]
            runs.append(r)
            print(f"  gen {i}/{len(tasks)}  {f['id']:30} {arm}", flush=True)
    return runs


def score(runs: list[dict], fxs_by_id: dict) -> list[dict]:
    judge = scoring.build_judge()
    rubric = scoring.load_rubric()

    def score_one(r: dict) -> dict:
        case = fxs_by_id[r["fixture_id"]]
        line = r["shipped_line"] or r["line"]
        r["faith"] = scoring.faithfulness(line, case)
        r["register"] = _retry(scoring.judge_register, judge, rubric, line, case)
        r["correct_arabic"] = _retry(scoring.judge_correct_arabic, judge, rubric, line, case)
        r["specificity"] = _retry(scoring.judge_specificity, judge, line, case)
        acc = _retry(scoring.judge_accuracy, judge, line, case)
        r["accuracy"] = acc["score"]
        r["hallucinated"] = acc["hallucinated"]
        return r

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
        futs = [ex.submit(score_one, r) for r in runs]
        for i, fut in enumerate(as_completed(futs), 1):
            fut.result()
            print(f"  score {i}/{len(runs)}", flush=True)
    return runs


def main() -> int:
    fxs = fixtures.build_fixtures()
    fxs_by_id = {f["id"]: f for f in fxs}
    t0 = time.perf_counter()
    print(f"== generating coaching ({len(fxs)} fixtures x {len(ARMS)} arms) ==", flush=True)
    runs = generate(fxs)
    print(f"== scoring {len(runs)} lines (judge=gemini-2.5-flash, temp 0) ==", flush=True)
    runs = score(runs, fxs_by_id)
    payload = {
        "meta": {
            "note": SEED_NOTE,
            "n_fixtures": len(fxs),
            "arms": [a for a, _ in ARMS],
            "judge": "gemini-2.5-flash (temp 0)",
            "coach": "gemini-2.5-flash (temp 0.5)",
            "elapsed_s": round(time.perf_counter() - t0, 1),
        },
        "runs": runs,
    }
    RESULTS.write_text(json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"\nwrote {RESULTS}  ({len(runs)} runs, {payload['meta']['elapsed_s']}s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
