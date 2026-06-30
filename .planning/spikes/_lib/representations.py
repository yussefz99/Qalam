"""The three stroke representations under test (H3), built from a fixture's strokes + the reference.

(a) image     — a rendered PNG overlaying the child's strokes (blue) on the faint reference (gray).
                Returned as raw PNG bytes; sent to Gemini as an inline image part (multimodal).
(b) points    — resampled normalized point arrays (child + reference) as compact JSON text.
(c) geo_diff  — a precomputed structured geometry diff (geometry.geometric_diff) as JSON text.

All three describe the SAME attempt; only the encoding the model reasons over differs.
"""
from __future__ import annotations

import io
import json
from typing import Any

from . import geometry as g

REF = g.load_baa_reference()
CANVAS = 512
PAD = 0.12  # fraction padding so the unit box doesn't touch the edges


def _to_px(p: g.Point) -> tuple[float, float]:
    span = CANVAS * (1 - 2 * PAD)
    off = CANVAS * PAD
    return off + p[0] * span, off + p[1] * span  # y down = screen down (no flip)


def render_image(strokes: g.Strokes, reference: g.Strokes | None = None) -> bytes:
    """Overlay render: reference faint gray, child blue. Returns PNG bytes."""
    from PIL import Image, ImageDraw

    reference = reference or REF["strokes"]
    img = Image.new("RGB", (CANVAS, CANVAS), "white")
    d = ImageDraw.Draw(img)

    def draw(strokes_: g.Strokes, color, width, dot_r):
        for s in strokes_:
            if len(s) == 1:
                cx, cy = _to_px(s[0])
                d.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], fill=color)
            elif len(s) > 1:
                d.line([_to_px(p) for p in s], fill=color, width=width, joint="curve")

    draw(reference, (205, 205, 205), 10, 11)      # reference: light gray, thick + soft
    draw(strokes, (30, 90, 220), 7, 9)            # child: blue
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def points_json(strokes: g.Strokes, reference: g.Strokes | None = None, n: int = 16) -> str:
    reference = reference or REF["strokes"]
    payload = {
        "coordinate_space": "normalized 0..1 unit box, origin top-left, y increases downward",
        "letter": "baa (ب): a boat-shaped body curve with ONE dot below it",
        "reference_strokes": [
            {"role": "body" if len(s) > 1 else "dot",
             "points": [[round(x, 3), round(y, 3)] for x, y in g._resample(s, n)] if len(s) > 1
                       else [[round(s[0][0], 3), round(s[0][1], 3)]]}
            for s in reference
        ],
        "child_strokes": [
            {"role": "body" if len(s) > 1 else "dot",
             "points": [[round(x, 3), round(y, 3)] for x, y in g._resample(s, n)] if len(s) > 1
                       else [[round(s[0][0], 3), round(s[0][1], 3)]]}
            for s in strokes
        ],
    }
    return json.dumps(payload, ensure_ascii=False)


def geo_diff_json(strokes: g.Strokes, reference: g.Strokes | None = None) -> str:
    reference = reference or REF["strokes"]
    diff = g.geometric_diff(strokes, reference)
    return json.dumps(
        {"letter": "baa (ب): boat body + one dot below",
         "geometry_diff_child_vs_reference": diff},
        ensure_ascii=False,
    )


def build_all(fixture: dict[str, Any]) -> dict[str, Any]:
    strokes = [[list(map(float, p)) for p in s] for s in fixture["strokes"]]
    return {
        "image": render_image(strokes),
        "points": points_json(strokes),
        "geo_diff": geo_diff_json(strokes),
    }
