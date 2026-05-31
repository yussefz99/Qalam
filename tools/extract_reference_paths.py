"""
Arabic letter contour extraction tool for Qalam.

Reads assets/fonts/NotoNaskhArabic-Regular.ttf, extracts per-letter glyph
contours as normalized 0..1 polylines (N=64 points per contour), and writes
tools/candidate_paths.json for the owner to inspect and map to teaching strokes.

Usage (run from the project root):
    pip install fonttools
    python tools/extract_reference_paths.py
"""

import json
import math
import sys
from pathlib import Path

FONT_PATH = Path("assets/fonts/NotoNaskhArabic-Regular.ttf")
OUTPUT_PATH = Path("tools/candidate_paths.json")
POINTS_PER_CONTOUR = 64

# 28 Arabic letters: (codepoint, id, char)
LETTERS = [
    (0x0627, "alif",  "ا"),
    (0x0628, "baa",   "ب"),
    (0x062A, "taa",   "ت"),
    (0x062B, "thaa",  "ث"),
    (0x062C, "jeem",  "ج"),
    (0x062D, "haa_c", "ح"),
    (0x062E, "khaa",  "خ"),
    (0x062F, "daal",  "د"),
    (0x0630, "dhaal", "ذ"),
    (0x0631, "raa",   "ر"),
    (0x0632, "zaay",  "ز"),
    (0x0633, "seen",  "س"),
    (0x0634, "sheen", "ش"),
    (0x0635, "saad",  "ص"),
    (0x0636, "daad",  "ض"),
    (0x0637, "taa_h", "ط"),
    (0x0638, "zhaa",  "ظ"),
    (0x0639, "ayn",   "ع"),
    (0x063A, "ghayn", "غ"),
    (0x0641, "faa",   "ف"),
    (0x0642, "qaaf",  "ق"),
    (0x0643, "kaaf",  "ك"),
    (0x0644, "laam",  "ل"),
    (0x0645, "meem",  "م"),
    (0x0646, "noon",  "ن"),
    (0x0647, "haa_f", "ه"),
    (0x0648, "waaw",  "و"),
    (0x064A, "yaa",   "ي"),
]


def quadratic_bezier_polyline(pts, n=POINTS_PER_CONTOUR):
    """
    Convert a closed TrueType quadratic-bezier contour to an n-point polyline.

    pts: list of (x, y, on_curve) from fonttools GlyphCoordinates.
    Returns list of [x, y] floats.
    """
    # Build explicit segment list: each segment is a list of control points
    # (on-curve endpoints with any off-curve points between them).
    # TrueType: consecutive off-curve points imply an implicit on-curve midpoint.
    n_pts = len(pts)
    if n_pts == 0:
        return []

    # Expand implicit on-curve points between consecutive off-curve points
    expanded = []
    for i, (x, y, on) in enumerate(pts):
        expanded.append((x, y, on))
        nx, ny, non = pts[(i + 1) % n_pts]
        if not on and not non:
            expanded.append(((x + nx) / 2, (y + ny) / 2, True))

    # Build segments: each segment = [p0_on, ...off-curves..., p1_on]
    segments = []
    start = None
    seg = []
    for x, y, on in expanded:
        if on:
            if start is None:
                start = (x, y)
                seg = [(x, y)]
            else:
                seg.append((x, y))
                segments.append(seg)
                seg = [(x, y)]
        else:
            seg.append((x, y))
    # Close: connect last point back to start
    if start is not None and seg and seg[-1] != start:
        seg.append(start)
        segments.append(seg)

    if not segments:
        return []

    # Sample each segment proportionally to get n total points
    def eval_quad(p0, ctrl, p1, t):
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * ctrl[0] + t ** 2 * p1[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * ctrl[1] + t ** 2 * p1[1]
        return x, y

    def eval_linear(p0, p1, t):
        return p0[0] + t * (p1[0] - p0[0]), p0[1] + t * (p1[1] - p0[1])

    def segment_length_approx(seg, steps=8):
        length = 0.0
        prev = None
        for i in range(steps + 1):
            t = i / steps
            pt = sample_segment(seg, t)
            if prev is not None:
                length += math.hypot(pt[0] - prev[0], pt[1] - prev[1])
            prev = pt
        return max(length, 1e-9)

    def sample_segment(seg, t):
        if len(seg) == 2:
            return eval_linear(seg[0], seg[1], t)
        elif len(seg) == 3:
            return eval_quad(seg[0], seg[1], seg[2], t)
        else:
            # Degree-reduce multi-off-curve: split into quadratics
            # For now treat as a chain of quadratics
            # n_quads = len(seg) - 2 ... not typical but handle gracefully
            # Just sample the linear fallback
            return eval_linear(seg[0], seg[-1], t)

    lengths = [segment_length_approx(s) for s in segments]
    total_len = sum(lengths)
    points = []
    accumulated = 0.0
    for seg, seg_len in zip(segments, lengths):
        seg_share = seg_len / total_len
        seg_n = max(1, round(n * seg_share))
        for i in range(seg_n):
            t = i / seg_n
            pt = sample_segment(seg, t)
            points.append(pt)
    # Trim or pad to exactly n
    while len(points) < n:
        points.append(points[-1])
    return [[x, y] for x, y in points[:n]]


def get_simple_contours(glyph):
    """Return list of raw point lists for a simple glyph's contours."""
    coords = glyph.coordinates
    flags = glyph.flags
    endpoints = glyph.endPtsOfContours

    contours = []
    start = 0
    for end in endpoints:
        raw = []
        for i in range(start, end + 1):
            x, y = coords[i]
            on_curve = bool(flags[i] & 0x01)
            raw.append((x, y, on_curve))
        contours.append(raw)
        start = end + 1
    return contours


def resolve_glyph_contours(glyph_set, glyph_name, visited=None):
    """
    Recursively resolve a glyph (simple or composite) to a flat list of
    raw TrueType contours. Each contour is a list of (x, y, on_curve).
    """
    if visited is None:
        visited = set()
    if glyph_name in visited:
        return []
    visited.add(glyph_name)

    if glyph_name not in glyph_set:
        return []

    g = glyph_set[glyph_name]
    # Access the underlying glyph object
    if hasattr(g, '_glyph'):
        glyph = g._glyph
    else:
        glyph = g

    if not hasattr(glyph, 'numberOfContours') or glyph.numberOfContours is None:
        return []

    if glyph.numberOfContours >= 0:
        # Simple glyph
        try:
            return get_simple_contours(glyph)
        except Exception:
            return []
    else:
        # Composite glyph — resolve each component
        all_contours = []
        if hasattr(glyph, 'components'):
            for comp in glyph.components:
                sub = resolve_glyph_contours(glyph_set, comp.glyphName, visited.copy())
                all_contours.extend(sub)
        return all_contours


def normalize_contours(raw_contours):
    """
    Normalize all contour points to 0..1 using the shared per-letter bounding box.
    Returns (normalized_polylines, contour_count).
    """
    if not raw_contours:
        return [], 0

    all_x = [x for c in raw_contours for (x, y, _) in c]
    all_y = [y for c in raw_contours for (x, y, _) in c]
    x_min, x_max = min(all_x), max(all_x)
    y_min, y_max = min(all_y), max(all_y)

    w = x_max - x_min or 1.0
    h = y_max - y_min or 1.0

    polylines = []
    for raw in raw_contours:
        pts = quadratic_bezier_polyline(raw)
        normalized = [
            [round((x - x_min) / w, 4), round((y - y_min) / h, 4)]
            for x, y in pts
        ]
        polylines.append(normalized)

    return polylines, len(polylines)


def main():
    if not FONT_PATH.exists():
        print(f"ERROR: Font not found at {FONT_PATH}", file=sys.stderr)
        print("Run this script from the project root.", file=sys.stderr)
        sys.exit(1)

    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        print("ERROR: fonttools not installed. Run: pip install fonttools", file=sys.stderr)
        sys.exit(1)

    print(f"Loading {FONT_PATH} ...")
    font = TTFont(str(FONT_PATH))
    cmap = font.getBestCmap()
    glyph_set = font.getGlyphSet()

    # Also grab the raw glyf table for composite resolution
    glyf_table = font.get("glyf")

    result = {}

    for codepoint, letter_id, char in LETTERS:
        glyph_name = cmap.get(codepoint)
        if glyph_name is None:
            print(f"  WARNING: codepoint U+{codepoint:04X} ({letter_id}) not in cmap — skipping")
            result[letter_id] = {
                "char": char,
                "codepoint": f"U+{codepoint:04X}",
                "contour_count": 0,
                "contours": [],
            }
            continue

        # Use raw glyf table for reliable composite resolution
        raw_contours = []
        if glyf_table and glyph_name in glyf_table:
            glyph = glyf_table[glyph_name]
            if hasattr(glyph, 'numberOfContours') and glyph.numberOfContours is not None:
                if glyph.numberOfContours >= 0:
                    try:
                        raw_contours = get_simple_contours(glyph)
                    except Exception as e:
                        raw_contours = []
                else:
                    # Composite: resolve recursively using glyf table
                    def resolve_via_glyf(name, visited=None):
                        if visited is None:
                            visited = set()
                        if name in visited or name not in glyf_table:
                            return []
                        visited.add(name)
                        g = glyf_table[name]
                        if not hasattr(g, 'numberOfContours') or g.numberOfContours is None:
                            return []
                        if g.numberOfContours >= 0:
                            try:
                                return get_simple_contours(g)
                            except Exception:
                                return []
                        else:
                            contours = []
                            if hasattr(g, 'components'):
                                for comp in g.components:
                                    contours.extend(resolve_via_glyf(comp.glyphName, visited.copy()))
                            return contours
                    raw_contours = resolve_via_glyf(glyph_name)

        polylines, count = normalize_contours(raw_contours)

        contours_out = []
        for i, pts in enumerate(polylines):
            contours_out.append({
                "index": i,
                "label": f"contour_{i}",
                "point_count": len(pts),
                "points": pts,
            })

        result[letter_id] = {
            "char": char,
            "codepoint": f"U+{codepoint:04X}",
            "contour_count": count,
            "contours": contours_out,
        }

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"\nWrote {OUTPUT_PATH} with {len(result)} letters.\n")
    print("--- Summary ---")
    for _, letter_id, char in LETTERS:
        entry = result.get(letter_id, {})
        count = entry.get("contour_count", 0)
        char_safe = char.encode("ascii", "backslashreplace").decode("ascii")
        print(f"  {letter_id} ({char_safe}): {count} contour(s)")


if __name__ == "__main__":
    main()
