import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/models/letter.dart';

/// 02.1-02 Task 1 — alif is the proven exemplar (D-06).
///
/// Loads alif straight from the SHIPPED assets/curriculum/letters.json (read off
/// disk, the same way test/flutter_test_config.dart loads fonts) and pins the
/// corrected open top→bottom centerline. These properties are what make the
/// Phase-2 outline defect impossible: a closed 64-point loop fails every one.
///
/// Tolerances (documented):
///   - straightness: max perpendicular deviation from the first→last line.
///     A handful of authored points on x=const gives ~0; allow 0.02 of slack
///     for a future slight Naskh lean approved at the human gate.
///   - length: normalized polyline length ≈ 1.0 (a full-height vertical run),
///     NOT the old ≈3.27 outline perimeter. Allow 0.1.
const double _straightnessTol = 0.02;
const double _lengthTol = 0.1;

Letter _loadAlif() {
  final raw = File('assets/curriculum/letters.json').readAsStringSync();
  final letters = (jsonDecode(raw) as Map<String, dynamic>)['letters']
      as List<dynamic>;
  final alifJson = letters
      .cast<Map<String, dynamic>>()
      .firstWhere((l) => l['id'] == 'alif');
  return Letter.fromJson(alifJson);
}

double _dist(List<double> a, List<double> b) =>
    math.sqrt(math.pow(a[0] - b[0], 2) + math.pow(a[1] - b[1], 2));

/// Perpendicular distance of point [p] from the infinite line through a→b.
double _perpDistance(List<double> p, List<double> a, List<double> b) {
  final dx = b[0] - a[0];
  final dy = b[1] - a[1];
  final len = math.sqrt(dx * dx + dy * dy);
  if (len == 0) return _dist(p, a);
  // |cross product| / |a→b|
  final cross = ((p[0] - a[0]) * dy - (p[1] - a[1]) * dx).abs();
  return cross / len;
}

void main() {
  group('alif corrected centerline (shipped letters.json)', () {
    test('has exactly one open line stroke, top→bottom', () {
      final alif = _loadAlif();
      expect(alif.referenceStrokes, hasLength(1));
      final s = alif.referenceStrokes.single;
      expect(s.type, 'line');
      expect(s.direction, 'topToBottom');
    });

    test('first point at top (y≈0), last at bottom (y≈1), y monotonic', () {
      final s = _loadAlif().referenceStrokes.single;
      final pts = s.points;
      expect(pts.first[1], closeTo(0.0, 0.05));
      expect(pts.last[1], closeTo(1.0, 0.05));
      for (var i = 1; i < pts.length; i++) {
        expect(pts[i][1], greaterThanOrEqualTo(pts[i - 1][1]),
            reason: 'y must not reverse (no closed-loop turnaround)');
      }
    });

    test('is near-straight (max perpendicular deviation ≈ 0)', () {
      final pts = _loadAlif().referenceStrokes.single.points;
      var maxDev = 0.0;
      for (final p in pts) {
        final d = _perpDistance(p, pts.first, pts.last);
        if (d > maxDev) maxDev = d;
      }
      expect(maxDev, lessThan(_straightnessTol));
    });

    test('normalized total length ≈ 1.0 (not the old ≈3.27 perimeter)', () {
      final pts = _loadAlif().referenceStrokes.single.points;
      var length = 0.0;
      for (var i = 1; i < pts.length; i++) {
        length += _dist(pts[i - 1], pts[i]);
      }
      expect(length, closeTo(1.0, _lengthTol));
    });

    test('passes the D-04 validator (not a closed loop)', () {
      final alif = _loadAlif();
      expect(validateReferenceStrokes(alif.referenceStrokes), isEmpty);
    });

    test('keeps its three commonMistakes (too_short, wrong_direction, too_curved)',
        () {
      final alif = _loadAlif();
      final ids = alif.commonMistakes.map((m) => m.id).toList();
      expect(ids, containsAll(<String>['too_short', 'wrong_direction', 'too_curved']));
    });
  });
}
