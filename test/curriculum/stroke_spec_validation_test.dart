import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/models/letter.dart';

/// Builds a rectangular closed outline loop with the same geometric signature
/// as alif's original 64-point font-outline contour (first ≈ last point, total
/// perimeter ~2-3x the bbox diagonal, one vertical turnaround). This is the
/// exact shape the Phase-2 extractor wrongly wrote into letters.json.
List<List<double>> _alifOutlineLoop() {
  // A thin tall rectangle traced down the left edge, across the bottom serif,
  // up the right edge, back across the top — 64 points, returning near start.
  // Perimeter of a ~0.0..1.0 tall, ~0.0..1.0 wide loop ≈ 2*(1.0+1.0) = ~4 ...
  // we use a thin band so width is small but the serif sweeps full width,
  // matching alif: x 0.018->1.0, perimeter ≈ 3.27, bbox diagonal ≈ 1.41.
  final pts = <List<double>>[];
  // Down the left edge (x≈0.46), top->bottom: 16 pts
  for (var i = 0; i < 16; i++) {
    pts.add([0.46, i / 15.0]);
  }
  // Across the bottom serif left->right (y≈1.0): 16 pts (full width sweep)
  for (var i = 1; i < 16; i++) {
    pts.add([0.46 + (1.0 - 0.46) * (i / 15.0), 1.0]);
  }
  // Up the right edge (x≈1.0), bottom->top: 16 pts
  for (var i = 1; i < 16; i++) {
    pts.add([1.0, 1.0 - i / 15.0]);
  }
  // Back across the top right->left toward start: 16 pts
  for (var i = 1; i <= 16; i++) {
    pts.add([1.0 - (1.0 - 0.46) * (i / 16.0), 0.0]);
  }
  return pts;
}

double _distance(List<double> a, List<double> b) {
  final dx = a[0] - b[0];
  final dy = a[1] - b[1];
  return math.sqrt(dx * dx + dy * dy);
}

double _perimeter(List<List<double>> pts) {
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    total += _distance(pts[i - 1], pts[i]);
  }
  return total;
}

void main() {
  group('validateStroke — single stroke', () {
    test('a valid open top->bottom centerline passes', () {
      const stroke = StrokeSpec(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        points: [
          [0.5, 0.0],
          [0.5, 0.25],
          [0.5, 0.5],
          [0.5, 0.75],
          [0.5, 1.0],
        ],
        direction: 'topToBottom',
      );

      expect(validateStroke(stroke), isEmpty);
    });

    test('a closed-loop non-dot stroke is REJECTED', () {
      final loop = _alifOutlineLoop();
      final stroke = StrokeSpec(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        points: loop,
        direction: 'topToBottom',
      );

      final violations = validateStroke(stroke);
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.toLowerCase().contains('loop')),
        isTrue,
        reason: 'a closed outline loop must be flagged as a loop',
      );
    });

    test('direction topToBottom that disagrees with point order is REJECTED',
        () {
      // points actually go bottom->top, but direction claims topToBottom
      const stroke = StrokeSpec(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        points: [
          [0.5, 1.0],
          [0.5, 0.5],
          [0.5, 0.0],
        ],
        direction: 'topToBottom',
      );

      final violations = validateStroke(stroke);
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.toLowerCase().contains('direction')),
        isTrue,
      );
    });

    test('each direction string is checked against first->last order', () {
      // bottomToTop with descending y is wrong
      const bad = StrokeSpec(
        order: 1,
        label: 's',
        type: 'line',
        points: [
          [0.5, 0.0],
          [0.5, 1.0],
        ],
        direction: 'bottomToTop',
      );
      expect(validateStroke(bad).any((v) => v.contains('direction')), isTrue);

      // leftToRight with decreasing x is wrong
      const badLr = StrokeSpec(
        order: 1,
        label: 's',
        type: 'line',
        points: [
          [1.0, 0.5],
          [0.0, 0.5],
        ],
        direction: 'leftToRight',
      );
      expect(validateStroke(badLr).any((v) => v.contains('direction')), isTrue);

      // rightToLeft with decreasing x is correct
      const goodRl = StrokeSpec(
        order: 1,
        label: 's',
        type: 'line',
        points: [
          [1.0, 0.5],
          [0.0, 0.5],
        ],
        direction: 'rightToLeft',
      );
      expect(validateStroke(goodRl), isEmpty);
    });

    test('a dot with exactly one point and direction "tap" passes', () {
      const dot = StrokeSpec(
        order: 2,
        label: 'dot',
        type: 'dot',
        points: [
          [0.5, 0.9],
        ],
        direction: 'tap',
      );

      expect(validateStroke(dot), isEmpty);
    });

    test('a dot with more than one point is REJECTED', () {
      const dot = StrokeSpec(
        order: 2,
        label: 'dot',
        type: 'dot',
        points: [
          [0.5, 0.9],
          [0.6, 0.95],
        ],
        direction: 'tap',
      );

      final violations = validateStroke(dot);
      expect(violations, isNotEmpty);
      expect(violations.any((v) => v.toLowerCase().contains('dot')), isTrue);
    });

    test('an out-of-range coordinate is REJECTED', () {
      const stroke = StrokeSpec(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        points: [
          [0.5, -0.1],
          [0.5, 1.0],
        ],
        direction: 'topToBottom',
      );

      final violations = validateStroke(stroke);
      expect(violations, isNotEmpty);
      expect(violations.any((v) => v.toLowerCase().contains('range')), isTrue);
    });
  });

  group('validateReferenceStrokes — whole letter', () {
    test('a correct alif (one open centerline) passes', () {
      const alif = [
        StrokeSpec(
          order: 1,
          label: 'vertical_stroke',
          type: 'line',
          points: [
            [0.5, 0.0],
            [0.5, 0.25],
            [0.5, 0.5],
            [0.5, 0.75],
            [0.5, 1.0],
          ],
          direction: 'topToBottom',
        ),
      ];

      expect(validateReferenceStrokes(alif), isEmpty);
    });

    test('a correct baa (body then dot) passes', () {
      const baa = [
        StrokeSpec(
          order: 1,
          label: 'bowl',
          type: 'curve',
          points: [
            [1.0, 0.5],
            [0.5, 0.8],
            [0.0, 0.5],
          ],
          direction: 'rightToLeft',
        ),
        StrokeSpec(
          order: 2,
          label: 'dot',
          type: 'dot',
          points: [
            [0.5, 1.0],
          ],
          direction: 'tap',
        ),
      ];

      expect(validateReferenceStrokes(baa), isEmpty);
    });

    test('non-contiguous order values are REJECTED', () {
      const strokes = [
        StrokeSpec(
          order: 1,
          label: 'a',
          type: 'line',
          points: [
            [0.5, 0.0],
            [0.5, 1.0],
          ],
          direction: 'topToBottom',
        ),
        StrokeSpec(
          order: 3, // gap — should be 2
          label: 'b',
          type: 'line',
          points: [
            [0.0, 0.5],
            [1.0, 0.5],
          ],
          direction: 'leftToRight',
        ),
      ];

      final violations = validateReferenceStrokes(strokes);
      expect(violations, isNotEmpty);
      expect(violations.any((v) => v.toLowerCase().contains('order')), isTrue);
    });

    test('a dot ordered before a body stroke is REJECTED', () {
      const strokes = [
        StrokeSpec(
          order: 1,
          label: 'dot',
          type: 'dot',
          points: [
            [0.5, 1.0],
          ],
          direction: 'tap',
        ),
        StrokeSpec(
          order: 2,
          label: 'body',
          type: 'line',
          points: [
            [0.5, 0.0],
            [0.5, 1.0],
          ],
          direction: 'topToBottom',
        ),
      ];

      final violations = validateReferenceStrokes(strokes);
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.toLowerCase().contains('dot')),
        isTrue,
        reason: 'dots must come after body strokes',
      );
    });
  });

  group('REGRESSION — alif original 64-point outline is permanently caught',
      () {
    test('alif old outline loop signature is rejected', () {
      final loop = _alifOutlineLoop();

      // Sanity: this fixture reproduces the original loop signature.
      expect(loop.length, greaterThanOrEqualTo(60));
      final firstToLast = _distance(loop.first, loop.last);
      final perimeter = _perimeter(loop);
      final bboxDiag = math.sqrt(1.0 * 1.0 + 1.0 * 1.0); // unit bbox diagonal
      expect(firstToLast, lessThan(0.3),
          reason: 'first≈last (a closed loop), like alif 0.2234');
      expect(perimeter / bboxDiag, inInclusiveRange(1.8, 3.2),
          reason: 'perimeter ~2-3x diagonal, like alif 3.27/1.41');

      final alifBadStroke = StrokeSpec(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        points: loop,
        direction: 'topToBottom',
      );

      // The crown-jewel guard: this MUST be rejected so the Phase-2 outline
      // bug can never be reintroduced into letters.json.
      expect(validateReferenceStrokes([alifBadStroke]), isNotEmpty);
      expect(validateStroke(alifBadStroke), isNotEmpty);
    });
  });
}
