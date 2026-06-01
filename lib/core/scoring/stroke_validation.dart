import 'dart:math' as math;

import '../../models/letter.dart';

/// D-04 crown-jewel guard — pure Dart, no Flutter imports.
///
/// Validates authored reference strokes so the Phase-2 outline defect can never
/// reach `letters.json` again. The single most valuable artifact in this phase:
/// it is the regression guard that would have caught the original 64-point
/// closed-outline alif at load and in CI.
///
/// Returns a list of human-readable violation messages; an empty list means the
/// data is valid. Callers can surface these in tests, the authoring tool, or a
/// load-time assertion.
///
/// The five named checks (per STROKE-REFERENCE.md §7.4):
///   1. NOT-CLOSED — a non-dot stroke must be an open centerline, not a loop.
///   2. DIRECTION  — the `direction` string must agree with points.first→last.
///   3. DOT        — a `type == "dot"` stroke must have exactly one point.
///   4. RANGE      — every coordinate must lie in [0, 1].
///   5. ORDER      — `order` values are 1..N contiguous; dots come after bodies.

// --- Tuned thresholds (documented; this is the ONLY place they live) ----------

/// Endpoint-coincidence epsilon. If a non-dot stroke's first and last points are
/// closer than this in normalized space, the polyline returns to its start — the
/// hallmark of an outline loop. alif's original outline had first→last = 0.2234,
/// which sits comfortably below this. Chosen generously (0.30) because a closed
/// font outline always returns *near* its start, while a legitimate open
/// centerline (alif top→bottom) ends ~1.0 away.
const double kClosedLoopEpsilon = 0.30;

/// Path-length / bbox-diagonal ratio threshold. A correct open centerline has a
/// total polyline length close to its bbox diagonal (ratio ≈ 1.0–1.5). An
/// outline loop traces the full perimeter — for alif, length 3.27 vs a unit
/// bbox diagonal 1.41 ≈ a 2.31 ratio. Anything at/above this ratio AND with a
/// near-coincident endpoint is an outline sneaking back in. Chosen at 1.8 to sit
/// above any plausible single open centerline yet below the ~2.3 of the bug.
const double kLoopLengthRatio = 1.8;

/// Coordinate range tolerance — a hair of slack for floating-point authoring
/// (e.g. a dot centroid at y = 1.0000001 should not trip RANGE).
const double kCoordTolerance = 1e-9;

const Set<String> _knownDirections = {
  'topToBottom',
  'bottomToTop',
  'leftToRight',
  'rightToLeft',
  'tap',
};

double _distance(List<double> a, List<double> b) {
  final dx = a[0] - b[0];
  final dy = a[1] - b[1];
  return math.sqrt(dx * dx + dy * dy);
}

double _polylineLength(List<List<double>> pts) {
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    total += _distance(pts[i - 1], pts[i]);
  }
  return total;
}

double _bboxDiagonal(List<List<double>> pts) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final p in pts) {
    minX = math.min(minX, p[0]);
    maxX = math.max(maxX, p[0]);
    minY = math.min(minY, p[1]);
    maxY = math.max(maxY, p[1]);
  }
  final w = maxX - minX;
  final h = maxY - minY;
  return math.sqrt(w * w + h * h);
}

/// Validates a single [stroke]. Runs checks 1–4 (NOT-CLOSED, DIRECTION, DOT,
/// RANGE). Cross-stroke checks (ORDER) live in [validateReferenceStrokes].
List<String> validateStroke(StrokeSpec stroke) {
  final violations = <String>[];
  final pts = stroke.points;
  final label = stroke.label;

  if (pts.isEmpty) {
    violations.add('Stroke "$label": has no points.');
    return violations;
  }

  // --- Check 4: RANGE -------------------------------------------------------
  for (var i = 0; i < pts.length; i++) {
    final p = pts[i];
    if (p.length != 2) {
      violations.add('Stroke "$label": point $i is not an [x, y] pair.');
      continue;
    }
    final x = p[0], y = p[1];
    if (x < -kCoordTolerance ||
        x > 1 + kCoordTolerance ||
        y < -kCoordTolerance ||
        y > 1 + kCoordTolerance) {
      violations.add(
        'Stroke "$label": coordinate ($x, $y) at point $i is out of range '
        '[0, 1].',
      );
    }
  }

  // --- Check 3: DOT sanity --------------------------------------------------
  if (stroke.type == 'dot') {
    if (pts.length != 1) {
      violations.add(
        'Stroke "$label": a dot must have exactly one point, has '
        '${pts.length}.',
      );
    }
    // A dot's direction should be "tap"; flag anything else as a direction
    // disagreement rather than silently accepting it.
    if (stroke.direction != 'tap') {
      violations.add(
        'Stroke "$label": a dot must use direction "tap", got '
        '"${stroke.direction}".',
      );
    }
    // Dots are taps — the loop/direction-vs-order checks below do not apply.
    return violations;
  }

  if (!_knownDirections.contains(stroke.direction)) {
    violations.add(
      'Stroke "$label": unknown direction "${stroke.direction}".',
    );
  }

  // --- Check 1: NOT-CLOSED (the bug guard) ----------------------------------
  if (pts.length >= 3) {
    final firstToLast = _distance(pts.first, pts.last);
    final diag = _bboxDiagonal(pts);
    final lengthRatio = diag > 0 ? _polylineLength(pts) / diag : 0.0;
    if (firstToLast < kClosedLoopEpsilon && lengthRatio >= kLoopLengthRatio) {
      violations.add(
        'Stroke "$label": looks like a closed outline loop '
        '(first≈last distance ${firstToLast.toStringAsFixed(3)} < '
        '$kClosedLoopEpsilon AND path-length/diagonal ratio '
        '${lengthRatio.toStringAsFixed(2)} ≥ $kLoopLengthRatio). A teaching '
        'stroke must be an OPEN centerline, not a glyph outline.',
      );
    }
  }

  // --- Check 2: DIRECTION agrees with points.first→last ---------------------
  final first = pts.first;
  final last = pts.last;
  final dx = last[0] - first[0];
  final dy = last[1] - first[1];
  switch (stroke.direction) {
    case 'topToBottom':
      if (!(dy > 0)) {
        violations.add(
          'Stroke "$label": direction "topToBottom" disagrees with points '
          '(y goes ${first[1]} → ${last[1]}).',
        );
      }
      break;
    case 'bottomToTop':
      if (!(dy < 0)) {
        violations.add(
          'Stroke "$label": direction "bottomToTop" disagrees with points '
          '(y goes ${first[1]} → ${last[1]}).',
        );
      }
      break;
    case 'leftToRight':
      if (!(dx > 0)) {
        violations.add(
          'Stroke "$label": direction "leftToRight" disagrees with points '
          '(x goes ${first[0]} → ${last[0]}).',
        );
      }
      break;
    case 'rightToLeft':
      if (!(dx < 0)) {
        violations.add(
          'Stroke "$label": direction "rightToLeft" disagrees with points '
          '(x goes ${first[0]} → ${last[0]}).',
        );
      }
      break;
    case 'tap':
      // "tap" on a non-dot stroke is a direction/type mismatch.
      violations.add(
        'Stroke "$label": direction "tap" is only valid for a dot stroke.',
      );
      break;
  }

  return violations;
}

/// Validates a whole letter's [strokes]: runs every single-stroke check plus
/// check 5 (ORDER) across the set.
List<String> validateReferenceStrokes(List<StrokeSpec> strokes) {
  final violations = <String>[];

  // Empty referenceStrokes is valid (placeholder letters, signedOff: false).
  if (strokes.isEmpty) return violations;

  for (final stroke in strokes) {
    violations.addAll(validateStroke(stroke));
  }

  // --- Check 5: ORDER 1..N contiguous --------------------------------------
  final orders = strokes.map((s) => s.order).toList()..sort();
  for (var i = 0; i < orders.length; i++) {
    if (orders[i] != i + 1) {
      violations.add(
        'Order values must be contiguous 1..N; got ${strokes.map((s) => s.order).toList()}.',
      );
      break;
    }
  }

  // --- Check 5b: dots come after body strokes -------------------------------
  // Walk strokes in draw order; once a dot appears, no body (non-dot) stroke
  // may follow.
  final inDrawOrder = [...strokes]..sort((a, b) => a.order.compareTo(b.order));
  var seenDot = false;
  for (final stroke in inDrawOrder) {
    if (stroke.type == 'dot') {
      seenDot = true;
    } else if (seenDot) {
      violations.add(
        'Stroke "${stroke.label}" (order ${stroke.order}): a body stroke must '
        'not come after a dot — dots are drawn last.',
      );
    }
  }

  return violations;
}
