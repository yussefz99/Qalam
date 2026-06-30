"""Geometry helpers for the stroke-aware-coaching spike (THROWAWAY).

Loads baa's authored reference strokes from the real curriculum (`assets/curriculum/letters.json`)
and provides:
  * deterministic synthetic perturbations of the reference (a shallow bowl, a missing dot, a
    misplaced dot, …) so the spike has stroke geometry WITHOUT any real child data, and
  * a precomputed geometric diff (child-vs-reference) used as one of the three model-input
    representations under test (image / points / geo-diff).

No model, no network. Pure math on points in a normalized 0..1 unit box (y increases downward,
matching screen coords and the authored data: the baa bowl dips to y≈0.57, the dot sits below at
y≈0.64).
"""
from __future__ import annotations

import json
import math
import pathlib
from typing import Any

REPO = pathlib.Path(__file__).resolve().parents[3]
LETTERS_JSON = REPO / "assets" / "curriculum" / "letters.json"

Point = list[float]          # [x, y]
Stroke = list[Point]         # ordered points
Strokes = list[Stroke]       # ordered strokes (body, dot, ...)


# ---------------------------------------------------------------- reference ----
def load_baa_reference() -> dict[str, Any]:
    """Return baa's authored reference as {"body": Stroke, "dot": Point, "strokes": Strokes}."""
    letters = json.loads(LETTERS_JSON.read_text(encoding="utf-8"))["letters"]
    baa = next(l for l in letters if l["id"] == "baa")
    body = [list(map(float, p)) for p in baa["referenceStrokes"][0]["points"]]
    dot = list(map(float, baa["referenceStrokes"][1]["points"][0]))
    return {"body": body, "dot": dot, "strokes": [body, [dot]]}


# ---------------------------------------------------------------- helpers ------
def _centroid(stroke: Stroke) -> Point:
    n = len(stroke)
    return [sum(p[0] for p in stroke) / n, sum(p[1] for p in stroke) / n]


def _baseline_y(body: Stroke) -> float:
    """The 'rim' of the boat — the average y of the two endpoints (top of the curve)."""
    return (body[0][1] + body[-1][1]) / 2.0


def deepen(body: Stroke, factor: float) -> Stroke:
    """Scale the bowl depth about its rim. factor<1 => shallower, >1 => deeper."""
    rim = _baseline_y(body)
    return [[x, rim + (y - rim) * factor] for x, y in body]


def scale_about_centroid(stroke: Stroke, k: float) -> Stroke:
    cx, cy = _centroid(stroke)
    return [[cx + (x - cx) * k, cy + (y - cy) * k] for x, y in stroke]


def jitter(stroke: Stroke, amt: float, seed: int = 0) -> Stroke:
    """Tiny deterministic wobble so a 'clean' attempt is not pixel-identical to the template."""
    out = []
    for i, (x, y) in enumerate(stroke):
        d = math.sin((i + 1) * 12.9898 + seed * 7.13) * 43758.5453
        f = (d - math.floor(d)) - 0.5  # in [-0.5, 0.5], deterministic
        out.append([x + f * amt, y + f * amt * 0.6])
    return out


# ---------------------------------------------------------------- geo-diff -----
def _resample(stroke: Stroke, n: int) -> Stroke:
    """Arc-length resample a polyline to n points."""
    if len(stroke) <= 1:
        return [stroke[0][:] for _ in range(n)] if stroke else []
    segs = []
    total = 0.0
    for a, b in zip(stroke, stroke[1:]):
        d = math.dist(a, b)
        segs.append(d)
        total += d
    if total == 0:
        return [stroke[0][:] for _ in range(n)]
    out = [stroke[0][:]]
    step = total / (n - 1)
    target = step
    acc = 0.0
    i = 0
    while len(out) < n - 1 and i < len(segs):
        if acc + segs[i] >= target:
            t = (target - acc) / segs[i] if segs[i] else 0.0
            ax, ay = stroke[i]
            bx, by = stroke[i + 1]
            out.append([ax + (bx - ax) * t, ay + (by - ay) * t])
            target += step
        else:
            acc += segs[i]
            i += 1
    out.append(stroke[-1][:])
    return out


def resample_strokes(strokes: Strokes, n: int = 16) -> Strokes:
    return [_resample(s, n) if len(s) > 1 else [p[:] for p in s] for s in strokes]


def _bbox(stroke: Stroke) -> tuple[float, float, float, float]:
    xs = [p[0] for p in stroke]
    ys = [p[1] for p in stroke]
    return min(xs), min(ys), max(xs), max(ys)


def _direction(stroke: Stroke) -> str:
    dx = stroke[-1][0] - stroke[0][0]
    if abs(dx) < 0.04:
        return "vertical/ambiguous"
    return "rightToLeft" if dx < 0 else "leftToRight"


def geometric_diff(child: Strokes, reference: Strokes) -> dict[str, Any]:
    """Precomputed child-vs-reference geometry — representation (c) under test.

    Heuristic by convention: the FIRST multi-point stroke is the body; any single-point stroke is a
    dot. Returns a compact, human-readable structured diff (no raw point arrays).
    """
    def split(strokes: Strokes):
        body_parts = [s for s in strokes if len(s) > 1]
        dots = [s[0] for s in strokes if len(s) == 1]
        return body_parts, dots

    c_body_parts, c_dots = split(child)
    r_body_parts, r_dots = split(reference)

    diff: dict[str, Any] = {}
    diff["stroke_count"] = {"child": len(child), "reference": len(reference)}
    diff["body_segments"] = {"child": len(c_body_parts), "reference": len(r_body_parts)}

    if c_body_parts and r_body_parts:
        cb = c_body_parts[0]
        rb = r_body_parts[0]
        # rim = the body's STARTING y (top-right of the boat). Robust to a tail flicking up at the
        # end (which would corrupt an endpoint-average rim). Depth = how far the bowl dips below it.
        def depth(stroke: Stroke, lo: float = 0.0, hi: float = 1.0) -> float:
            rim = stroke[0][1]
            xs = [p[0] for p in stroke]
            xmid_lo = min(xs) + (max(xs) - min(xs)) * lo
            xmid_hi = min(xs) + (max(xs) - min(xs)) * hi
            sel = [p for p in stroke if xmid_lo <= p[0] <= xmid_hi] or stroke
            return max(p[1] for p in sel) - rim

        c_depth = depth(cb)
        r_depth = depth(rb)
        diff["bowl_depth"] = {
            "child": round(c_depth, 3),
            "reference": round(r_depth, 3),
            "ratio": round(c_depth / r_depth, 2) if r_depth else None,
            "verdict": (
                "much shallower" if c_depth < 0.45 * r_depth
                else "shallower" if c_depth < 0.8 * r_depth
                else "deeper" if c_depth > 1.2 * r_depth
                else "matches"
            ),
        }
        # left/right depth so an ASYMMETRIC bowl (one side flat) is visible, not averaged away.
        cl, cr = depth(cb, 0.0, 0.5), depth(cb, 0.5, 1.0)
        if r_depth and (cl < 0.5 * r_depth) != (cr < 0.5 * r_depth):
            diff["bowl_symmetry"] = {
                "left_depth": round(cl, 3), "right_depth": round(cr, 3),
                "detail": ("left side flat, right side curves" if cl < cr
                           else "right side flat, left side curves"),
            }
        cminx, cminy, cmaxx, cmaxy = _bbox(cb)
        rminx, rminy, rmaxx, rmaxy = _bbox(rb)
        c_w, r_w = cmaxx - cminx, rmaxx - rminx
        wr = c_w / r_w if r_w else 1
        diff["size"] = {
            "width_ratio": round(wr, 2),
            "verdict": "too big" if wr > 1.25 else "too small" if wr < 0.75 else "matches",
        }
        diff["direction"] = {"child": _direction(cb), "reference": _direction(rb)}
        # a "tail": the stroke ENDS well above the rim (flicks up past where the boat should close).
        rim = cb[0][1]
        end_above_rim = rim - cb[-1][1]
        diff["tail"] = {
            "present": end_above_rim > 0.05,
            "detail": ("the stroke flicks up into a tail at the end"
                       if end_above_rim > 0.05 else "no tail"),
        }

    # dot analysis
    if r_dots:
        rdx, rdy = r_dots[0]
        if not c_dots:
            diff["dot"] = {"present": False, "detail": "no dot drawn"}
        else:
            cdx, cdy = c_dots[0]
            rb = r_body_parts[0] if r_body_parts else None
            body_bottom = max(p[1] for p in rb) if rb else rdy
            horiz = (
                "left of center" if cdx < rdx - 0.06
                else "right of center" if cdx > rdx + 0.06
                else "centered"
            )
            vert = "above the bowl" if cdy < body_bottom else "below the bowl"
            diff["dot"] = {
                "present": True,
                "offset_x": round(cdx - rdx, 3),
                "offset_y": round(cdy - rdy, 3),
                "horizontal": horiz,
                "vertical": vert,
                "placement_ok": horiz == "centered" and vert == "below the bowl",
            }
    return diff
