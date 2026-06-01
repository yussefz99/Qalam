"""
Arabic letter AUTHORING-HINT extractor for Qalam.

================================ DEPRECATION ================================
THIS TOOL NO LONGER EMITS TEACHING STROKES, AND IT NEVER WILL AGAIN.

Outlines are NOT teaching strokes. A glyph *outline* (the closed contour
around the letter's printed body) is the wrong shape for both the geometric
stroke scorer and the "watch me write" pen-tip animation (S1-04). The body
*centerline* — the path a pen actually travels — is authored by the owner in
the in-app trace screen, in the order/direction the owner's mother prescribes.
See `.planning/research/STROKE-REFERENCE.md` (§2 why outlines are wrong, §7.1
what this tool is allowed to do).

This tool was repurposed (D-05) to emit only AUTHORING HINTS:
  (a) dot centroids — one [x, y] per dot contour, normalized 0..1 in the
      shared per-letter bounding box (a hint for "how many dot marks and
      roughly where"); and
  (b) the glyph bounding box — a faint backdrop reference to trace over.

It does NOT, and must not, emit any body-outline polyline. The previous
`tools/candidate_paths.json` body-outline output is dead; the output is now
`tools/authoring_hints.json`, renamed so no one pastes outlines into the
curriculum (`letters.json`) again. The validation guard in
STROKE-REFERENCE.md §7.4 enforces that no outline reaches `letters.json`.
============================================================================

How dots are identified: the font-contour dot separation already works
(baa=2, taa=3, sheen=4 contours; the body is always the single largest
contour). We keep that separation logic, take the *centroid* of each small
dot contour, and discard the body contour entirely. Counters/holes (haa_f,
qaaf inner ring) are font artifacts, not pen strokes — heuristically, the
body is the contour with the largest bounding-box area and every other
contour is treated as a candidate dot mark for the owner to confirm.

Usage (run from the project root):
    pip install fonttools          # optional; tool degrades gracefully without it
    python tools/extract_reference_paths.py

Output: tools/authoring_hints.json — per-letter dot centroids + glyph bbox.
"""

import json
import sys
from pathlib import Path

FONT_PATH = Path("assets/fonts/NotoNaskhArabic-Regular.ttf")
# Renamed (D-05): never again a *_paths.json that could be pasted as strokes.
OUTPUT_PATH = Path("tools/authoring_hints.json")

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


def get_simple_contours(glyph):
    """Return list of raw point lists for a simple glyph's contours.

    Each contour is a list of (x, y, on_curve) tuples. NOTE: this raw point
    data is used ONLY to compute per-contour bounding boxes and centroids —
    it is never normalized into, or emitted as, a teaching-stroke polyline.
    """
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


def contour_bbox(raw_contour):
    """Return (x_min, y_min, x_max, y_max) for a raw contour."""
    xs = [x for (x, y, _) in raw_contour]
    ys = [y for (x, y, _) in raw_contour]
    return min(xs), min(ys), max(xs), max(ys)


def contour_centroid(raw_contour):
    """Return the (x, y) centroid of a raw contour's points."""
    n = len(raw_contour)
    if n == 0:
        return 0.0, 0.0
    sx = sum(x for (x, y, _) in raw_contour)
    sy = sum(y for (x, y, _) in raw_contour)
    return sx / n, sy / n


def separate_dots_and_bbox(raw_contours):
    """Separate dot contours from the body contour and compute the glyph bbox.

    Returns (dot_centroids_normalized, glyph_bbox) where:
      - dot_centroids_normalized is a list of [x, y] floats in 0..1 within the
        shared per-letter bounding box, one per dot contour (body excluded);
      - glyph_bbox is {"x_min","y_min","x_max","y_max"} in raw font units.

    The body is the contour with the largest bounding-box area; every other
    contour is treated as a candidate dot mark. This intentionally produces NO
    polyline — only centroids and the bbox (authoring hints, not strokes).
    """
    if not raw_contours:
        return [], None

    # Shared per-letter bbox across all contours.
    all_x = [x for c in raw_contours for (x, y, _) in c]
    all_y = [y for c in raw_contours for (x, y, _) in c]
    x_min, x_max = min(all_x), max(all_x)
    y_min, y_max = min(all_y), max(all_y)
    w = (x_max - x_min) or 1.0
    h = (y_max - y_min) or 1.0

    glyph_bbox = {
        "x_min": x_min,
        "y_min": y_min,
        "x_max": x_max,
        "y_max": y_max,
    }

    if len(raw_contours) == 1:
        # Only the body — no dots to hint.
        return [], glyph_bbox

    # Identify the body contour: the one with the largest bbox area.
    def area(c):
        bx0, by0, bx1, by1 = contour_bbox(c)
        return (bx1 - bx0) * (by1 - by0)

    body_index = max(range(len(raw_contours)), key=lambda i: area(raw_contours[i]))

    dot_centroids = []
    for i, c in enumerate(raw_contours):
        if i == body_index:
            continue
        cx, cy = contour_centroid(c)
        dot_centroids.append([
            round((cx - x_min) / w, 4),
            round((cy - y_min) / h, 4),
        ])

    return dot_centroids, glyph_bbox


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

    glyf_table = font.get("glyf")

    result = {
        "_note": (
            "AUTHORING HINTS ONLY — dot centroids + glyph bbox. These are NOT "
            "teaching strokes. Body centerlines are authored by the owner in the "
            "in-app trace screen. See .planning/research/STROKE-REFERENCE.md."
        ),
        "letters": {},
    }

    for codepoint, letter_id, char in LETTERS:
        glyph_name = cmap.get(codepoint)
        if glyph_name is None:
            print(f"  WARNING: codepoint U+{codepoint:04X} ({letter_id}) not in cmap — skipping")
            result["letters"][letter_id] = {
                "char": char,
                "codepoint": f"U+{codepoint:04X}",
                "contour_count": 0,
                "dot_centroids": [],
                "glyph_bbox": None,
            }
            continue

        raw_contours = []
        if glyf_table and glyph_name in glyf_table:
            glyph = glyf_table[glyph_name]
            if hasattr(glyph, 'numberOfContours') and glyph.numberOfContours is not None:
                if glyph.numberOfContours >= 0:
                    try:
                        raw_contours = get_simple_contours(glyph)
                    except Exception:
                        raw_contours = []
                else:
                    # Composite: resolve recursively using the glyf table.
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
                        contours = []
                        if hasattr(g, 'components'):
                            for comp in g.components:
                                contours.extend(resolve_via_glyf(comp.glyphName, visited.copy()))
                        return contours
                    raw_contours = resolve_via_glyf(glyph_name)

        dot_centroids, glyph_bbox = separate_dots_and_bbox(raw_contours)

        result["letters"][letter_id] = {
            "char": char,
            "codepoint": f"U+{codepoint:04X}",
            "contour_count": len(raw_contours),
            # HINTS ONLY — no body-outline polyline is ever emitted here.
            "dot_centroids": dot_centroids,
            "glyph_bbox": glyph_bbox,
        }

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"\nWrote {OUTPUT_PATH} (authoring hints) with {len(result['letters'])} letters.\n")
    print("--- Summary (contours / dot hints) ---")
    for _, letter_id, char in LETTERS:
        entry = result["letters"].get(letter_id, {})
        count = entry.get("contour_count", 0)
        dots = len(entry.get("dot_centroids", []))
        char_safe = char.encode("ascii", "backslashreplace").decode("ascii")
        print(f"  {letter_id} ({char_safe}): {count} contour(s), {dots} dot hint(s)")


if __name__ == "__main__":
    main()
