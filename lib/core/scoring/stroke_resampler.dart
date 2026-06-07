import 'dart:math' as math;

/// Pure Dart — NO dart:ui, NO Flutter imports.
///
/// Two functions consumed by the geometric scorer before any predicate runs:
///   resample(pts, n)        — arc-length-equidistant resampling to n points.
///   normalizeToUnitBox(pts) — translate bbox-min→0, scale longest side→1,
///                             preserve aspect ratio (zero-width axis → 0.5).
///
/// Both operate on [List<List<double>>] ([x, y] pairs) in any coordinate space.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

double _dist(List<double> a, List<double> b) {
  final dx = a[0] - b[0];
  final dy = a[1] - b[1];
  return math.sqrt(dx * dx + dy * dy);
}

double _arcLength(List<List<double>> pts) {
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    total += _dist(pts[i - 1], pts[i]);
  }
  return total;
}

/// Linearly interpolates between [a] and [b] by [t] (0..1).
List<double> _lerp(List<double> a, List<double> b, double t) =>
    [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Resamples [pts] to exactly [n] arc-length-equidistant points.
///
/// If [pts] has fewer than 2 points (degenerate input), returns [n] copies of
/// the single point (or the origin if empty).
List<List<double>> resample(List<List<double>> pts, int n) {
  assert(n >= 2, 'resample: n must be >= 2');

  if (pts.isEmpty) {
    return List.generate(n, (_) => [0.0, 0.0]);
  }
  if (pts.length == 1) {
    return List.generate(n, (_) => [pts[0][0], pts[0][1]]);
  }

  final totalLen = _arcLength(pts);
  if (totalLen == 0.0) {
    // All points coincident — return n copies.
    return List.generate(n, (_) => [pts[0][0], pts[0][1]]);
  }

  final interval = totalLen / (n - 1);
  final result = <List<double>>[pts.first];

  var accumulated = 0.0;
  var segStart = 0;

  for (var target = 1; target < n - 1; target++) {
    final targetDist = target * interval;

    // Advance along segments until we find the one containing targetDist.
    while (segStart < pts.length - 2) {
      final segLen = _dist(pts[segStart], pts[segStart + 1]);
      if (accumulated + segLen >= targetDist) break;
      accumulated += segLen;
      segStart++;
    }

    final segLen = _dist(pts[segStart], pts[segStart + 1]);
    final t = segLen > 0 ? (targetDist - accumulated) / segLen : 0.0;
    result.add(_lerp(pts[segStart], pts[segStart + 1], t.clamp(0.0, 1.0)));
  }

  result.add(pts.last);
  return result;
}

/// Normalizes [pts] so the bounding box is translated to origin and the
/// longest side is scaled to 1.0.  Aspect ratio is preserved.
///
/// A zero-width axis (e.g. a perfectly vertical stroke) maps that axis to 0.5
/// (centered), matching the alif centerline convention in STROKE-REFERENCE §7.3.
List<List<double>> normalizeToUnitBox(List<List<double>> pts) {
  if (pts.isEmpty) return [];

  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final p in pts) {
    if (p[0] < minX) minX = p[0];
    if (p[0] > maxX) maxX = p[0];
    if (p[1] < minY) minY = p[1];
    if (p[1] > maxY) maxY = p[1];
  }

  final width = maxX - minX;
  final height = maxY - minY;
  final scale = math.max(width, height);

  return pts.map((p) {
    // Zero-width axis (e.g. a perfectly vertical stroke) is centered at 0.5.
    final x = width > 0 ? (p[0] - minX) / scale : 0.5;
    final y = height > 0 ? (p[1] - minY) / scale : 0.5;
    return [x, y];
  }).toList();
}
