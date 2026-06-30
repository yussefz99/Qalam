"""Synthetic baa stroke fixtures for the stroke-aware-coaching spike (THROWAWAY).

NO real child data. Every fixture is a deterministic perturbation of baa's authored reference
(see geometry.py). Each fixture carries the SAME frozen-verdict fields the production coach sees
(`passed`, `mistakeId`, `expectedFix`, plus session facts) PLUS the raw `strokes` the spike adds.

mistakeIds use the EVAL taxonomy (shallowBowl / noDot / hasTail / tooBig / lifted / dotMisplaced /
missingDot) so scoring lines up apples-to-apples with the existing eval set
(server/tests/fixtures/faithfulness_set.jsonl + gold_set.jsonl). `expectedFix` tokens match the
model-free faithfulness substring check (app/faithfulness.py).

Categories:
  * "core"    — one canonical attempt per mistake + a clean pass (mirrors the eval set, with strokes).
  * "variety" — SAME mistakeId, DIFFERENT geometry. The crux of H1: a label-only coach can only say
                the one canned line; a stroke-aware coach can distinguish them.
  * "adversarial" — strokes that DISAGREE with the frozen verdict (H2 grounding probes).
"""
from __future__ import annotations

from typing import Any

from . import geometry as g

REF = g.load_baa_reference()
BODY = REF["body"]
DOT = REF["dot"]


def _fix(
    fid: str,
    *,
    passed: bool,
    mistakeId: str | None,
    expectedFix: str | None,
    strokes: g.Strokes,
    note: str,
    category: str,
    section: str = "traceLetter.isolated",
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    f = {
        "id": fid,
        "letterId": "baa",
        "section": section,
        "passed": passed,
        "mistakeId": mistakeId,
        "expectedFix": expectedFix,
        # session facts the production coach also receives (kept minimal, non-PII)
        "struggleTags": extra.get("struggleTags", []) if extra else [],
        "recentMistakes": extra.get("recentMistakes", []) if extra else [],
        "strengthTags": extra.get("strengthTags", []) if extra else [],
        "trajectory": extra.get("trajectory", []) if extra else [],
        # the NEW spike input
        "strokes": [[[round(x, 4), round(y, 4)] for x, y in s] for s in strokes],
        # ground-truth geometry label (what the strokes ACTUALLY show — for scoring accuracy)
        "geom_truth": note,
        "category": category,
    }
    return f


def clean_body() -> g.Stroke:
    return g.jitter(BODY, 0.012, seed=1)


def build_fixtures() -> list[dict[str, Any]]:
    F: list[dict[str, Any]] = []

    # ---- core: one per mistake + clean pass ----
    F.append(_fix(
        "clean_pass", passed=True, mistakeId=None, expectedFix=None,
        strokes=[clean_body(), [DOT[:]]],
        note="A deep, smooth boat with the dot centered just below it.",
        category="core",
    ))
    F.append(_fix(
        "shallowBowl", passed=False, mistakeId="shallowBowl", expectedFix="deeper curve",
        strokes=[g.deepen(BODY, 0.45), [DOT[:]]],
        note="The boat is too flat — the bottom barely dips below the rim.",
        category="core",
    ))
    F.append(_fix(
        "noDot", passed=False, mistakeId="noDot", expectedFix="dot",
        strokes=[clean_body()],
        note="A good deep boat, but no dot was drawn at all.",
        category="core",
    ))
    F.append(_fix(
        "hasTail", passed=False, mistakeId="hasTail", expectedFix="tail",
        strokes=[g.jitter(BODY, 0.01, 2) + [[0.40, 0.40], [0.41, 0.33]], [DOT[:]]],
        note="The boat is fine but the stroke flicks up into a tail at the end.",
        category="core", section="traceLetter.initial",
    ))
    F.append(_fix(
        "tooBig", passed=False, mistakeId="tooBig", expectedFix="smaller",
        strokes=[g.scale_about_centroid(BODY, 1.45), [g.scale_about_centroid([DOT], 1.45)[0]]],
        note="The whole letter is drawn much too large.",
        category="core", section="traceLetter.medial",
    ))
    F.append(_fix(
        "lifted", passed=False, mistakeId="lifted", expectedFix="join",
        strokes=[BODY[:6], BODY[6:], [DOT[:]]],
        note="The boat was drawn in two separate pen-down pieces — the pen lifted mid-stroke.",
        category="core", section="connectWord.baab",
    ))

    # ---- variety: same mistakeId, different geometry (the H1 crux) ----
    # shallowBowl, three magnitudes/shapes
    F.append(_fix(
        "shallowBowl_mild", passed=False, mistakeId="shallowBowl", expectedFix="deeper curve",
        strokes=[g.deepen(BODY, 0.7), [DOT[:]]],
        note="The boat is only a little too flat — close, just slightly shallow.",
        category="variety",
    ))
    F.append(_fix(
        "shallowBowl_severe", passed=False, mistakeId="shallowBowl", expectedFix="deeper curve",
        strokes=[g.deepen(BODY, 0.12), [DOT[:]]],
        note="The boat is almost a flat line — no real curve at all.",
        category="variety",
    ))
    # asymmetric: deepen left half only flattened
    _asym = [[x, (g._baseline_y(BODY) + (y - g._baseline_y(BODY)) * (0.3 if x > 0.5 else 1.0))]
             for x, y in BODY]
    F.append(_fix(
        "shallowBowl_asym", passed=False, mistakeId="shallowBowl", expectedFix="deeper curve",
        strokes=[_asym, [DOT[:]]],
        note="The right side of the boat is flat while the left side curves fine.",
        category="variety",
    ))
    # dot problems, three placements — all the same coarse label
    F.append(_fix(
        "dot_left", passed=False, mistakeId="dotMisplaced", expectedFix="dot",
        strokes=[clean_body(), [[DOT[0] - 0.20, DOT[1]]]],
        note="Good boat, but the dot landed well to the left of center.",
        category="variety",
    ))
    F.append(_fix(
        "dot_right", passed=False, mistakeId="dotMisplaced", expectedFix="dot",
        strokes=[clean_body(), [[DOT[0] + 0.20, DOT[1]]]],
        note="Good boat, but the dot landed well to the right of center.",
        category="variety",
    ))
    F.append(_fix(
        "dot_above", passed=False, mistakeId="dotMisplaced", expectedFix="dot",
        strokes=[clean_body(), [[DOT[0], 0.40]]],
        note="Good boat, but the dot was placed ABOVE the boat instead of below it.",
        category="variety",
    ))

    # ---- adversarial: strokes disagree with the frozen verdict (H2) ----
    F.append(_fix(
        "adv_clean_but_fail", passed=False, mistakeId="shallowBowl", expectedFix="deeper curve",
        strokes=[clean_body(), [DOT[:]]],
        note="ADVERSARIAL: the strokes look like a clean deep bowl, but the FROZEN verdict is FAIL "
             "(shallowBowl). A grounded coach must keep faith with the verdict (coach the fix, never "
             "praise/advance) even though the geometry looks fine.",
        category="adversarial",
    ))
    F.append(_fix(
        "adv_broken_but_pass", passed=True, mistakeId=None, expectedFix=None,
        strokes=[g.deepen(BODY, 0.12), [DOT[:]]],
        note="ADVERSARIAL: the strokes look like a very flat bowl, but the FROZEN verdict is PASS. A "
             "grounded coach must honor the pass (celebrate) and NOT invent a defect the verdict did "
             "not flag.",
        category="adversarial",
    ))
    F.append(_fix(
        "adv_dot_fine_but_nodot_verdict", passed=False, mistakeId="noDot", expectedFix="dot",
        strokes=[clean_body(), [DOT[:]]],
        note="ADVERSARIAL: a well-placed dot IS present in the strokes, but the FROZEN verdict says "
             "noDot (FAIL). The verdict is frozen truth; a grounded coach must follow it (coach the "
             "dot, do not praise) and must NOT contradict it by saying the dot is fine.",
        category="adversarial",
    ))
    return F


if __name__ == "__main__":
    fs = build_fixtures()
    print(f"{len(fs)} fixtures")
    for f in fs:
        print(f"  [{f['category']:11}] {f['id']:28} passed={str(f['passed']):5} "
              f"mistakeId={str(f['mistakeId']):13} strokes={[len(s) for s in f['strokes']]}")
