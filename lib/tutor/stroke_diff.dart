/// On-device DERIVED stroke-geometry diff (Phase 17 / STRK-01 / GROUND-04).
///
/// Pure Dart. Computes a small, POINT-FREE description of how the child's actual
/// strokes differ from the authored reference — bowl depth, which side is flat,
/// the dot's placement, a tail, the direction — so the server coach can name the
/// SPECIFIC thing this child did. It is computed at the ONE seam where the strokes
/// still exist (`write_surface._onLetterComplete`) and the strokes are STILL
/// discarded there: only this derived map propagates (GROUND-04 — raw strokes
/// never leave the device, only the diff). The map's keys mirror the server
/// `StrokeDiffIn` (`server/app/schema.py`) field-for-field; `extra="forbid"` on
/// both sides means a stray coordinate key would 422 — by construction this map
/// holds none (no `x`/`y`/`points`).
///
/// Features are SCALE- and TRANSLATION-invariant (ratios + fractions) so they do
/// not depend on where or how big the child drew — a flat bowl reads "shallower"
/// whether drawn large or small. This is the on-device port of the spike's
/// `geometric_diff` (`.planning/spikes/_lib/geometry.py`), validated in the
/// stroke-aware spike.
library;

import '../models/letter.dart';

typedef _Pt = List<double>; // [x, y]
typedef _Stroke = List<_Pt>;

/// Compute the derived diff, or null when it cannot (no body stroke / no
/// reference). A null result simply means no `strokeDiff` is sent (the coach
/// falls back to label-only coaching — no error).
Map<String, Object?>? computeStrokeDiff(
  List<List<List<double>>> childPixelStrokes,
  List<StrokeSpec> reference,
) {
  if (childPixelStrokes.isEmpty || reference.isEmpty) return null;

  final childBodies = <_Stroke>[];
  _Pt? childDot;
  _classifyChild(childPixelStrokes, childBodies, (d) => childDot = d);

  final refBodies = <_Stroke>[];
  _Pt? refDot;
  for (final s in reference) {
    final isDot = s.type == 'dot' || s.label == 'dot' || s.points.length == 1;
    if (isDot && s.points.isNotEmpty) {
      refDot = _center(s.points);
    } else if (s.points.length > 1) {
      refBodies.add(s.points);
    }
  }
  if (childBodies.isEmpty || refBodies.isEmpty) return null;

  final cb = childBodies.first;
  final rb = refBodies.first;
  final diff = <String, Object?>{};

  diff['strokeCount'] = childPixelStrokes.length;
  diff['bodySegments'] = childBodies.length;

  // --- bowl depth: aspect ratio H/W (shallow bowl = short + wide => small H/W) ---
  final cAspect = _aspect(cb);
  final rAspect = _aspect(rb);
  if (rAspect > 0 && cAspect > 0) {
    final ratio = cAspect / rAspect;
    diff['bowlDepthRatio'] = _round2(ratio);
    diff['bowlDepthVerdict'] = ratio < 0.5
        ? 'much shallower'
        : ratio < 0.8
            ? 'shallower'
            : ratio > 1.3
                ? 'deeper'
                : 'matches';
  }

  // --- symmetry: compare the dip on each half of the body ---
  final sym = _symmetry(cb);
  if (sym != null) diff['bowlSymmetry'] = sym;

  // --- direction (right-to-left for baa) ---
  diff['directionChild'] = _direction(cb);
  diff['directionReference'] = _direction(rb);

  // --- tail: the stroke flicks up past its opening at the end ---
  diff['tailPresent'] = _hasTail(cb);

  // --- dot --- (copy to plain locals so Dart promotes them non-null in the branch)
  final cDot = childDot;
  final rDot = refDot;
  if (cDot == null) {
    diff['dotPresent'] = false;
  } else {
    diff['dotPresent'] = true;
    final cbBox = _Box.of(cb);
    final dx = (cDot[0] - cbBox.minX) / (cbBox.w == 0 ? 1 : cbBox.w); // 0=left,1=right
    // reference dot fraction across the reference body (≈ centered for baa)
    final rbBox = _Box.of(rb);
    final rdx =
        rDot == null ? 0.5 : (rDot[0] - rbBox.minX) / (rbBox.w == 0 ? 1 : rbBox.w);
    final off = dx - rdx;
    diff['dotHorizontal'] = off < -0.12
        ? 'left of center'
        : off > 0.12
            ? 'right of center'
            : 'centered';
    // y increases downward: a correct baa dot sits BELOW the body (y > body maxY).
    final below = cDot[1] > cbBox.maxY;
    diff['dotVertical'] = below ? 'below the bowl' : 'above the bowl';
    diff['dotPlacementOk'] = diff['dotHorizontal'] == 'centered' && below;
  }

  diff['summary'] = _summary(diff);
  diff.removeWhere((_, v) => v == null);
  return diff;
}

// --- classification ---------------------------------------------------------

void _classifyChild(
  List<List<List<double>>> strokes,
  List<_Stroke> bodiesOut,
  void Function(_Pt) setDot,
) {
  // The body is the largest-extent multi-point stroke; a much smaller stroke is
  // the dot (a tap). Robust to noise: compare bbox diagonals.
  final diags = strokes.map(_diag).toList();
  final maxDiag = diags.fold<double>(0, (m, d) => d > m ? d : m);
  if (maxDiag == 0) return;
  double? dotDiag;
  for (var i = 0; i < strokes.length; i++) {
    final s = strokes[i];
    if (s.length < 2 || diags[i] < 0.3 * maxDiag) {
      // candidate dot — pick the smallest such stroke
      if (s.isNotEmpty && (dotDiag == null || diags[i] < dotDiag)) {
        dotDiag = diags[i];
        setDot(_center(s));
      }
    } else {
      bodiesOut.add(s);
    }
  }
}

// --- geometry helpers (scale/translation invariant) -------------------------

class _Box {
  final double minX, minY, maxX, maxY;
  const _Box(this.minX, this.minY, this.maxX, this.maxY);
  double get w => maxX - minX;
  double get h => maxY - minY;
  static _Box of(_Stroke s) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in s) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }
    return _Box(minX, minY, maxX, maxY);
  }
}

_Pt _center(_Stroke s) {
  var sx = 0.0, sy = 0.0;
  for (final p in s) {
    sx += p[0];
    sy += p[1];
  }
  return [sx / s.length, sy / s.length];
}

double _diag(_Stroke s) {
  if (s.length < 2) return 0;
  final b = _Box.of(s);
  return _hypot(b.w, b.h);
}

double _aspect(_Stroke s) {
  final b = _Box.of(s);
  if (b.w == 0) return 0;
  return b.h / b.w;
}

/// 'right side flat, left side curves' (or the reverse), else null when roughly
/// symmetric. Depth on a half = how far the body dips below its opening, scaled
/// by body width (aspect-preserving).
String? _symmetry(_Stroke body) {
  final b = _Box.of(body);
  if (b.w == 0) return null;
  final midX = b.minX + b.w / 2;
  final rim = body.first[1]; // the opening (top) y
  var leftMaxY = -double.infinity, rightMaxY = -double.infinity;
  for (final p in body) {
    if (p[0] <= midX) {
      if (p[1] > leftMaxY) leftMaxY = p[1];
    } else {
      if (p[1] > rightMaxY) rightMaxY = p[1];
    }
  }
  if (leftMaxY == -double.infinity || rightMaxY == -double.infinity) return null;
  final left = (leftMaxY - rim) / b.w;
  final right = (rightMaxY - rim) / b.w;
  final hi = left > right ? left : right;
  if (hi <= 0) return null;
  if (left < 0.5 * right) return 'left side flat, right side curves';
  if (right < 0.5 * left) return 'right side flat, left side curves';
  return null;
}

String _direction(_Stroke s) {
  final dx = s.last[0] - s.first[0];
  final span = _Box.of(s).w;
  if (span == 0 || dx.abs() < 0.1 * span) return 'vertical/ambiguous';
  return dx < 0 ? 'rightToLeft' : 'leftToRight';
}

bool _hasTail(_Stroke body) {
  final b = _Box.of(body);
  if (b.h == 0) return false;
  // The opening is the top (small y). A tail flicks the END up above the start.
  final start = body.first[1];
  final end = body.last[1];
  return (start - end) > 0.25 * b.h;
}

String _summary(Map<String, Object?> d) {
  final parts = <String>[];
  if (d['bodySegments'] is int && (d['bodySegments'] as int) > 1) {
    parts.add('drawn in ${d['bodySegments']} separate pieces (pen lifted)');
  }
  final depth = d['bowlDepthVerdict'];
  if (depth != null && depth != 'matches') parts.add('bowl $depth than the reference');
  if (d['bowlSymmetry'] != null) parts.add(d['bowlSymmetry'] as String);
  if (d['tailPresent'] == true) parts.add('a tail at the end');
  if (d['dotPresent'] == false) {
    parts.add('no dot');
  } else if (d['dotPlacementOk'] == false) {
    final h = d['dotHorizontal'], v = d['dotVertical'];
    if (v == 'above the bowl') {
      parts.add('dot placed above the bowl');
    } else if (h != 'centered') {
      parts.add('dot $h');
    }
  }
  if (parts.isEmpty) return 'matches the reference well';
  return parts.join('; ');
}

double _hypot(double a, double b) {
  // avoid dart:math import churn; simple, exact enough
  final v = a * a + b * b;
  // Newton's method sqrt
  if (v == 0) return 0;
  var x = v;
  for (var i = 0; i < 24; i++) {
    x = 0.5 * (x + v / x);
  }
  return x;
}

double _round2(double v) => (v * 100).round() / 100;
