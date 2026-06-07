import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/stroke_resampler.dart';

import 'scoring_fixtures.dart';

/// S1-05 — resampler and unit-box normalizer contracts.
///
/// Pins two pure-Dart functions:
///   resample(pts, n) — arc-length-equidistant resampling to exactly n points.
///   normalizeToUnitBox(pts) — translate bbox-min→0, scale longest side→1,
///                             preserve aspect ratio.
void main() {
  group('resample', () {
    test('returns exactly n points', () {
      final result = resample(cleanAlif, 32);
      expect(result.length, equals(32));
    });

    test('returns exactly n points for a different count', () {
      final result = resample(cleanAlif, 64);
      expect(result.length, equals(64));
    });

    test('single-point input returns n copies of that point', () {
      final single = [
        [10.0, 20.0],
      ];
      final result = resample(single, 8);
      expect(result.length, equals(8));
      for (final p in result) {
        expect(p[0], closeTo(10.0, 1e-9));
        expect(p[1], closeTo(20.0, 1e-9));
      }
    });
  });

  group('normalizeToUnitBox', () {
    test('maps bbox min→0 and max→1 on the dominant (longest) axis', () {
      // Vertical stroke: x fixed at 50, y from 0→200.
      // Dominant axis is y. After normalization: y should go 0→1, x→0.5.
      final pts = [
        [50.0, 0.0],
        [50.0, 100.0],
        [50.0, 200.0],
      ];
      final norm = normalizeToUnitBox(pts);

      // y: 0→1 along dominant axis
      expect(norm.first[1], closeTo(0.0, 1e-9));
      expect(norm.last[1], closeTo(1.0, 1e-9));

      // x: zero width → centered at 0.5
      for (final p in norm) {
        expect(p[0], closeTo(0.5, 1e-9));
      }
    });

    test('all output coordinates are in [0, 1]', () {
      final norm = normalizeToUnitBox(cleanAlif);
      for (final p in norm) {
        expect(p[0], inInclusiveRange(0.0, 1.0));
        expect(p[1], inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('smallCorrect — size/position invariance', () {
    test('normalizeToUnitBox brings smallCorrect into unit space', () {
      final norm = normalizeToUnitBox(smallCorrect);
      // All normalized points in [0,1]
      for (final p in norm) {
        expect(p[0], inInclusiveRange(0.0, 1.0));
        expect(p[1], inInclusiveRange(0.0, 1.0));
      }
      // First point at top, last at bottom on dominant axis
      expect(norm.first[1], closeTo(0.0, 1e-9));
      expect(norm.last[1], closeTo(1.0, 1e-9));
    });
  });
}
