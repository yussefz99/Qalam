// Pure-Dart export helper for the dev authoring screen (D-02, plan 02.1-04).
//
// Turns the owner's traced + tagged strokes into a normalized `referenceStrokes`
// JSON fragment, shaped exactly like an entry in assets/curriculum/letters.json,
// ready to paste in. Pure Dart — NO Flutter widget imports — so the whole
// normalize/serialize path is unit-testable and reusable.
//
// Normalization (STROKE-REFERENCE.md §5): ALL strokes are normalized TOGETHER
// against the combined bounding box of every point, so relative positions (e.g.
// a dot sitting below a body stroke) are preserved. Output coordinates are 0..1
// and the fragment passes the D-04 validator (stroke_validation.dart) when the
// trace is a real open centerline.
//
// SECURITY (T-02.1-06 / T-01-05): this helper never logs, prints, or persists
// any point data — it only transforms in-memory values and returns a String.

import 'dart:convert';

import '../models/letter.dart';

/// One stroke as captured by the authoring screen, BEFORE normalization.
///
/// [points] are raw local coordinates in any space (the screen passes pixel
/// coordinates from its capture canvas); `[x, y]` pairs. The export normalizes
/// them. A `type == "dot"` stroke carries exactly one point.
class CapturedStroke {
  final int order;
  final String label;
  final String type; // line | curve | dot
  final String direction; // topToBottom | bottomToTop | leftToRight | rightToLeft | tap
  final List<List<double>> points;

  const CapturedStroke({
    required this.order,
    required this.label,
    required this.type,
    required this.direction,
    required this.points,
  });
}

/// Coordinate rounding precision for the exported fragment (4 dp is plenty for
/// normalized 0..1 authoring data and keeps letters.json legible).
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

_Bounds _combinedBounds(List<CapturedStroke> strokes) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final s in strokes) {
    for (final p in s.points) {
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

/// Normalizes all [strokes] together (combined bbox) into validator-shaped
/// [StrokeSpec]s, ordered by their `order` field.
List<StrokeSpec> normalizeToStrokeSpecs(List<CapturedStroke> strokes) {
  if (strokes.isEmpty) return const <StrokeSpec>[];
  final b = _combinedBounds(strokes);
  final ordered = [...strokes]..sort((a, c) => a.order.compareTo(c.order));
  return ordered.map((s) {
    final points = s.points
        .map((p) => <double>[
              _round(_norm(p[0], b.minX, b.width)),
              _round(_norm(p[1], b.minY, b.height)),
            ])
        .toList();
    return StrokeSpec(
      order: s.order,
      label: s.label,
      type: s.type,
      direction: s.direction,
      points: points,
    );
  }).toList();
}

/// Builds the normalized `referenceStrokes` JSON fragment (a pretty-printed JSON
/// array of `{order, label, type, points, direction}`) ready to paste into
/// letters.json. Returns `[]` for no strokes.
String exportReferenceStrokesJson(List<CapturedStroke> strokes) {
  final specs = normalizeToStrokeSpecs(strokes);
  final list = specs
      .map((s) => <String, dynamic>{
            'order': s.order,
            'label': s.label,
            'type': s.type,
            'points': s.points,
            'direction': s.direction,
          })
      .toList();
  return const JsonEncoder.withIndent('  ').convert(list);
}
