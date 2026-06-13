// Shared combined-bbox stroke normalization (plan 06-08).
//
// The single home for the STROKE-REFERENCE.md §5 normalization: ALL strokes are
// normalized TOGETHER against the combined bounding box of every point, so
// relative positions (e.g. a baa dot sitting BELOW the body, vs a taa dot
// ABOVE) are preserved through the 0..1 mapping (Pitfall 2 — dot position).
//
// Pure Dart — NO Flutter widget imports. Operates on plain
// `List<List<List<double>>>` (per stroke → per point → [x, y]) so it serves
// BOTH:
//   - authoring (CapturedStroke → StrokeSpec, via lib/dev/authoring_export.dart)
//   - the child's in-memory captured strokes (the ghost comparison, D-21)
// without re-deriving the bbox math in two places.
//
// SECURITY (T-03-01 / T-06-04): this helper never logs, prints, or persists any
// point data — it only transforms in-memory values and returns new lists. The
// child's stroke coordinates pass through here on the way to the replay UI and
// are never written anywhere.

/// Coordinate rounding precision for normalized output (4 dp — plenty for 0..1
/// data, keeps authored letters.json legible).
const int _precision = 4;

double _round(double v) {
  // 10^_precision without dart:math.pow to keep deps minimal.
  var p = 1.0;
  for (var i = 0; i < _precision; i++) {
    p *= 10;
  }
  return (v * p).round() / p;
}

class _Bounds {
  final double minX, minY, maxX, maxY;
  const _Bounds(this.minX, this.minY, this.maxX, this.maxY);

  double get width => maxX - minX;
  double get height => maxY - minY;
}

_Bounds _combinedBounds(List<List<List<double>>> strokes) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final stroke in strokes) {
    for (final p in stroke) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }
  }
  return _Bounds(minX, minY, maxX, maxY);
}

/// Normalizes a single coordinate against [range], guarding a zero range.
///
/// A perfectly vertical downstroke has zero WIDTH — every x is identical — so
/// there is no meaningful left/right spread; we map it to the center (0.5),
/// matching the STROKE-REFERENCE §7.3 alif centerline (x ≈ 0.5). Likewise a
/// perfectly horizontal stroke maps y to 0.5.
double _norm(double value, double lo, double range) {
  if (range == 0) return 0.5;
  return (value - lo) / range;
}

/// Normalizes [strokes] (per stroke → per point → `[x, y]`) TOGETHER against
/// their combined bounding box into 0..1 coordinates, rounded to 4 dp.
///
/// Stroke ORDER is preserved exactly as given — the caller is responsible for
/// ordering (authoring sorts by `order`; the child's strokes arrive in pen
/// order). Returns an empty list for empty input. Empty inner strokes are
/// passed through as empty.
///
/// This is the one source of the combined-bbox math; authoring and the ghost
/// comparison both delegate here (no duplicated bbox derivation).
List<List<List<double>>> normalizeStrokesToUnitBox(
  List<List<List<double>>> strokes,
) {
  if (strokes.isEmpty) return const <List<List<double>>>[];
  // Guard: a set of strokes with no points at all has no bbox.
  final hasAnyPoint = strokes.any((s) => s.isNotEmpty);
  if (!hasAnyPoint) {
    return strokes.map((s) => <List<double>>[]).toList();
  }
  final b = _combinedBounds(strokes);
  return strokes
      .map((stroke) => stroke
          .map((p) => <double>[
                _round(_norm(p[0], b.minX, b.width)),
                _round(_norm(p[1], b.minY, b.height)),
              ])
          .toList())
      .toList();
}
