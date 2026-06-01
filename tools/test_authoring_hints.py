"""
Pin the invariant: tools/extract_reference_paths.py emits AUTHORING HINTS
only — dot centroids + glyph bbox — and NEVER a body-outline polyline.

Run from the project root:
    python3 tools/test_authoring_hints.py     # exit 0 on pass

This check is deliberately dependency-free: it does NOT require fonttools or
the TTF. It exercises the tool's pure logic (separate_dots_and_bbox) with a
small synthetic in-memory contour set, and asserts the static guarantees of
the repurposed tool (renamed output path, no outline emission). See
.planning/research/STROKE-REFERENCE.md §7.1 (never-emit-outline invariant).
"""

import importlib.util
import sys
from pathlib import Path

TOOL_PATH = Path("tools/extract_reference_paths.py")


def _load_tool():
    """Import the extractor as a module without running main()."""
    spec = importlib.util.spec_from_file_location("extract_reference_paths", TOOL_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _make_contour(points):
    """Build a raw contour: list of (x, y, on_curve) from [(x, y), ...]."""
    return [(x, y, True) for (x, y) in points]


def check_static_guarantees(src):
    """Assert the tool's source pins the never-emit-outline contract."""
    assert "authoring_hints.json" in src, "output not renamed to authoring_hints.json"
    assert "STROKE-REFERENCE.md" in src, "deprecation header reference missing"
    assert "OUTPUT_PATH = Path(\"tools/authoring_hints.json\")" in src, \
        "OUTPUT_PATH not repointed to authoring_hints.json"
    # The dead body-outline output must not be the live target anymore.
    output_lines = [l for l in src.splitlines() if l.strip().startswith("OUTPUT_PATH")]
    assert output_lines, "OUTPUT_PATH assignment not found"
    assert all("candidate_paths.json" not in l for l in output_lines), \
        "OUTPUT_PATH still points at the dead candidate_paths.json body-outline output"
    print("  [ok] static guarantees: renamed output, deprecation header, no outline target")


def _looks_like_polyline(value):
    """A body-outline polyline is a long list of [x, y] pairs (>= 4 points)."""
    if not isinstance(value, list) or len(value) < 4:
        return False
    pair_count = 0
    for item in value:
        if (isinstance(item, list) and len(item) == 2
                and all(isinstance(c, (int, float)) for c in item)):
            pair_count += 1
    return pair_count >= 4


def check_no_outline_emitted(mod):
    """Drive separate_dots_and_bbox with synthetic contours; assert hints only."""
    # Body = large square (the single largest-bbox contour, must be discarded).
    body = _make_contour([(0, 0), (100, 0), (100, 100), (0, 100),
                          (50, 50), (10, 10), (90, 10), (90, 90)])
    # Two tiny dot blobs above the body.
    dot1 = _make_contour([(20, 110), (24, 110), (24, 114), (20, 114)])
    dot2 = _make_contour([(70, 110), (74, 110), (74, 114), (70, 114)])

    dot_centroids, glyph_bbox = mod.separate_dots_and_bbox([body, dot1, dot2])

    # Exactly the two dots become hints; the body is discarded.
    assert len(dot_centroids) == 2, f"expected 2 dot centroids, got {len(dot_centroids)}"
    for c in dot_centroids:
        assert isinstance(c, list) and len(c) == 2, f"dot centroid not an [x, y] pair: {c}"
        assert all(0.0 <= v <= 1.0 for v in c), f"dot centroid not normalized 0..1: {c}"
    assert _looks_like_polyline(dot_centroids) is False, \
        "dot_centroids must NOT be a body-outline polyline"

    # The glyph bbox is a dict of bounds, never a polyline.
    assert isinstance(glyph_bbox, dict), "glyph_bbox must be a bounds dict"
    for key in ("x_min", "y_min", "x_max", "y_max"):
        assert key in glyph_bbox, f"glyph_bbox missing {key}"

    # Single-contour glyph (no dots): no centroids, still a bbox, no polyline.
    none_dots, body_only_bbox = mod.separate_dots_and_bbox([body])
    assert none_dots == [], "single-contour glyph must yield zero dot centroids"
    assert isinstance(body_only_bbox, dict), "single-contour glyph must still yield a bbox"

    # Empty glyph: nothing emitted.
    empty_dots, empty_bbox = mod.separate_dots_and_bbox([])
    assert empty_dots == [] and empty_bbox is None, "empty glyph must emit nothing"

    print("  [ok] no body-outline polyline emitted: dots -> centroids, body discarded")


def check_emitted_structure_keys(mod):
    """Assert the per-letter emitted structure exposes hint keys, not a polyline key."""
    # Re-derive the structure the tool builds per letter, off pure logic only.
    body = _make_contour([(0, 0), (100, 0), (100, 100), (0, 100)])
    dot = _make_contour([(40, 110), (44, 110), (44, 114), (40, 114)])
    dot_centroids, glyph_bbox = mod.separate_dots_and_bbox([body, dot])

    entry = {
        "char": "ب",
        "codepoint": "U+0628",
        "contour_count": 2,
        "dot_centroids": dot_centroids,
        "glyph_bbox": glyph_bbox,
    }
    assert "dot_centroids" in entry, "hint structure missing dot_centroids"
    assert "glyph_bbox" in entry, "hint structure missing glyph_bbox"
    # No legacy outline keys may exist.
    for forbidden in ("contours", "points", "polyline", "referenceStrokes"):
        assert forbidden not in entry, f"forbidden body-outline key present: {forbidden}"
    print("  [ok] emitted structure has dot_centroids + glyph_bbox, no outline keys")


def main():
    if not TOOL_PATH.exists():
        print(f"FAIL: {TOOL_PATH} not found (run from project root)", file=sys.stderr)
        sys.exit(1)

    src = TOOL_PATH.read_text(encoding="utf-8")
    print("Checking tools/extract_reference_paths.py never emits body outlines...")

    check_static_guarantees(src)

    try:
        mod = _load_tool()
    except Exception as e:  # importing the tool must not require fonttools
        print(f"FAIL: could not import the extractor purely: {e}", file=sys.stderr)
        sys.exit(1)

    check_no_outline_emitted(mod)
    check_emitted_structure_keys(mod)

    print("\nPASS: extractor emits dot-centroid + bbox hints only; no body outline.")
    sys.exit(0)


if __name__ == "__main__":
    main()
