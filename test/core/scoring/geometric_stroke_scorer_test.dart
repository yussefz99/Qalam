import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/geometric_stroke_scorer.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/models/letter.dart';

import 'scoring_fixtures.dart';

/// S1-05 — geometric stroke scorer for alif.
///
/// These tests pin the three named predicates and the pass case.
/// The predicate names (strokeLengthBelowThreshold, strokeDirectionInverted,
/// strokeCurvatureExceedsThreshold) must match the authored commonMistakes[].check
/// strings in letters.json — the data↔code contract.
void main() {
  // Alif reference stroke built inline, matching letters.json referenceStrokes[0].
  StrokeSpec alifRefStroke() => const StrokeSpec(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        direction: 'topToBottom',
        points: [
          [0.5, 0.0],
          [0.5, 0.25],
          [0.5, 0.5],
          [0.5, 0.75],
          [0.5, 1.0],
        ],
      );

  group('GeometricStrokeScorer — alif pass cases', () {
    test('cleanAlif scores as passed with no mistakeId', () {
      final result = scoreStroke(cleanAlif, alifRefStroke());
      expect(result.passed, isTrue);
      expect(result.mistakeId, isNull);
    });

    test('smallCorrect scores as passed after normalization (size/position invariant)', () {
      final result = scoreStroke(smallCorrect, alifRefStroke());
      expect(result.passed, isTrue);
      expect(result.mistakeId, isNull);
    });
  });

  group('GeometricStrokeScorer — alif failure cases', () {
    test('tooShort → passed false, mistakeId == MistakeId.tooShort', () {
      final result = scoreStroke(tooShort, alifRefStroke());
      expect(result.passed, isFalse);
      expect(result.mistakeId, equals(MistakeId.tooShort));
    });

    test('inverted → passed false, mistakeId == MistakeId.wrongDirection', () {
      final result = scoreStroke(inverted, alifRefStroke());
      expect(result.passed, isFalse);
      expect(result.mistakeId, equals(MistakeId.wrongDirection));
    });

    test('curved → passed false, mistakeId == MistakeId.tooCurved', () {
      final result = scoreStroke(curved, alifRefStroke());
      expect(result.passed, isFalse);
      expect(result.mistakeId, equals(MistakeId.tooCurved));
    });
  });

  group('GeometricStrokeScorer — latency', () {
    test('scoreStroke(cleanAlif) completes in < 50 ms', () {
      final sw = Stopwatch()..start();
      scoreStroke(cleanAlif, alifRefStroke());
      sw.stop();
      expect(
        sw.elapsedMilliseconds,
        lessThan(50),
        reason: 'Scorer must be fast enough for sub-300 ms stylus-up feedback '
            '(got ${sw.elapsedMilliseconds} ms)',
      );
    });
  });
}
