// position_invariance_test.dart — Defect-1 regression (Phase 17.2).
//
// The bottom-edge false-fail: a well-formed baa written slightly LOW on the
// canvas read `bowlDepthRatio 0.43–0.49 / "much shallower"` on-device and failed
// on shape, while the SAME quality attempt at a normal position read 0.52–0.65
// and passed.
//
// This test locks the invariant the owner needs: **position never changes the
// shape verdict**. A good baa translated so its bowl bottom extends well BELOW
// the canvas rect must still pass shape, and its derived `bowlDepthRatio` must
// match the un-translated one — because both the geometric scorer (bbox unit-box
// normalised) and `computeStrokeDiff` (scale/translation-invariant ratios) are
// position-invariant BY CONSTRUCTION. If a future change reintroduces an
// absolute-coordinate assumption (a canvas-rect clamp before scoring), this goes
// RED.
//
// Companion guard: `test/features/practice/stroke_canvas_test.dart` proves the
// CAPTURE layer keeps below-rect points un-clamped, so the two together lock the
// whole seam end-to-end.

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/letter_scorer.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/tutor/stroke_diff.dart';
import 'package:qalam/models/letter.dart';

// The real baa reference (assets/curriculum/letters.json): a right-to-left body
// sweep + a single dot below it.
const _body = StrokeSpec(
  order: 1,
  label: 'body',
  type: 'curve',
  direction: 'rightToLeft',
  points: [
    [0.608, 0.447], [0.619, 0.486], [0.62, 0.524], [0.594, 0.552],
    [0.551, 0.565], [0.511, 0.569], [0.474, 0.57], [0.436, 0.566],
    [0.407, 0.559], [0.386, 0.53], [0.381, 0.498], [0.382, 0.46],
  ],
);
const _dot = StrokeSpec(
  order: 2,
  label: 'dot',
  type: 'dot',
  direction: 'tap',
  points: [
    [0.498, 0.644],
  ],
);

Letter _baa() => const Letter(
      id: 'baa',
      char: 'ب',
      name: LetterName(ar: 'باء', display: 'baa'),
      introOrder: 2,
      forms: LetterForms(isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
      referenceStrokes: [_body, _dot],
      cleanRepsToAdvance: 1,
      commonMistakes: [],
      mistakesStatus: 'placeholder',
      signedOff: false,
      contextualForms: {
        'isolated': Form(referenceStrokes: [_body, _dot]),
      },
    );

/// A GOOD child baa in pixel space on a 300x300 canvas, shaped straight from the
/// reference and optionally translated DOWN by [dy] pixels.
List<List<List<double>>> _goodBaa({double dy = 0}) => [
      [for (final p in _body.points) <double>[p[0] * 300, p[1] * 300 + dy]],
      [for (final p in _dot.points) <double>[p[0] * 300, p[1] * 300 + dy]],
    ];

double _shape(LetterScore s) =>
    s.criteria.firstWhere((c) => c.criterion == 'shape').score;

void main() {
  group('Defect-1: writing low/high never changes the shape verdict', () {
    // The bowl bottom of a normal-position baa sits at ~0.57*300 = 171px. A
    // +150px translation pushes it to ~321px — well BELOW the 300px canvas rect,
    // exactly the owner's "wrote it slightly low" case.
    const belowRect = 150.0;

    test('shape PASSES both at normal position and translated below the rect',
        () async {
      final baa = _baa();
      final normal = await scoreLetter(_goodBaa(), baa, form: 'isolated');
      final low =
          await scoreLetter(_goodBaa(dy: belowRect), baa, form: 'isolated');

      expect(normal.passed, isTrue, reason: 'a good baa passes at normal y.');
      expect(low.passed, isTrue,
          reason: 'the SAME good baa, bowl bottom below the canvas rect, must '
              'still pass — position must not flip the verdict (Defect-1).');
      // The shape criterion score is identical (both a clean 1.0), not merely
      // both-passing: the verdict is genuinely position-invariant.
      expect(_shape(low), equals(_shape(normal)));
    });

    test('bowlDepthRatio of the low baa MATCHES the un-translated one', () {
      final ref = _baa().referenceStrokes;
      final dNormal = computeStrokeDiff(_goodBaa(), ref);
      final dLow = computeStrokeDiff(_goodBaa(dy: belowRect), ref);

      expect(dNormal, isNotNull);
      expect(dLow, isNotNull);
      // The exact ratio must survive the downward translation — a truncated
      // (clamped) bottom would drag this toward the 0.43–0.49 "much shallower"
      // band seen in the on-device logs.
      expect(dLow!['bowlDepthRatio'], equals(dNormal!['bowlDepthRatio']));
      expect(dLow['bowlDepthVerdict'], equals(dNormal['bowlDepthVerdict']));
      expect(dLow['bowlDepthVerdict'], equals('matches'));
    });
  });
}
