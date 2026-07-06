// Wave-0 RED contract for Plan 17-02 (increment 2) — RED by missing symbol
// until 17-02 lands. Compile errors count as RED.
//
// Pure Dart, no dart:ui, no Flutter imports (flutter_test harness only) — the
// same register as lib/core/scoring/shape_match.dart.
//
// Pins the increment-2 target API BEFORE implementation (Nyquist rule; mirrors
// the 15-01/16-01 precedent), per locked decisions D-C (soft 3-zone thresholds,
// DTW shape via the already-shipped `shapeDistance` core, direction STAYS a
// criterion) and D-D (thresholds are DATA):
//
//   1. `Tolerances` gains four double soft-band knobs with PROVISIONAL defaults
//      on `Tolerances.normal`: `shapeTcc == 0.10`, `shapeTcw == 0.15` (must
//      equal `SoftBand.shapeDefault`), `directionCc == 0.3`,
//      `directionCw == -0.3`; `Tolerances.fromJson` honors
//      `overrides: {"shapeTcc": ..., "shapeTcw": ...}` (the same defensive
//      idiom as `maxCurvature`).
//   2. `CriterionResult{criterion, zone, score}` lands in scoring_models. The
//      field is `criterion`, NOT `name` — `name` trips the non-PII token regex
//      in the payload guards (pattern-map warning); no field may contain the
//      substring "point".
//   3. `StrokeResult` gains `criteria` (List of CriterionResult, default
//      const []), keeping `passed`/`mistakeId` unchanged.
//   4. The verdict goes SOFT: a shaky-but-correct bowl PASSES (fuzzy passes —
//      the UAT F2 false-fail fix); a flat "line" bowl fails certainly-wrong AS
//      `MistakeId.tooCurved` (Pitfall 2: the existing enum id + check-string
//      contract is KEPT for shape failures — no new MistakeId); the raw-point
//      floor stays firm (`tooShort` unchanged).
//
// Fixtures are perturbations of the REAL authored baa isolated bowl
// (assets/curriculum/letters.json contextualForms.isolated) — the
// shape_match_test.dart technique. No child data, no PII (T-17-01).
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/geometric_stroke_scorer.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/core/scoring/shape_match.dart';
import 'package:qalam/core/scoring/tolerances.dart';
import 'package:qalam/models/letter.dart';

void main() {
  // The REAL authored baa isolated "boat/bowl" reference (from
  // assets/curriculum/letters.json contextualForms.isolated.referenceStrokes).
  const bowl = <List<double>>[
    [0.608, 0.447], [0.619, 0.486], [0.620, 0.524], [0.594, 0.552],
    [0.551, 0.565], [0.511, 0.569], [0.474, 0.570], [0.436, 0.566],
    [0.407, 0.559], [0.386, 0.530], [0.381, 0.498], [0.382, 0.460],
  ];

  // The authored per-form StrokeSpec the leaf scorer scores against.
  const bowlRef = StrokeSpec(
    order: 1,
    label: 'bowl',
    type: 'curve',
    direction: 'rightToLeft',
    points: bowl,
  );

  // A shaky child bowl: the same boat with a small deterministic wobble
  // (±~0.012) — a correct attempt by an unsteady 6-year-old hand
  // (shape_match_test.dart perturbation technique).
  final shakyBowl = <List<double>>[
    for (var i = 0; i < bowl.length; i++)
      [
        bowl[i][0] + (i.isEven ? 0.012 : -0.010),
        bowl[i][1] + (i % 3 == 0 ? -0.011 : 0.009),
      ],
  ];

  // A flat line across the bowl's x-range — the "it's a line, not a boat"
  // wrong attempt (the exact case the old chord proxy mis-handled).
  final flatLine = <List<double>>[
    for (var i = 0; i < 12; i++) [0.620 - i * (0.239 / 11), 0.510],
  ];

  // The rightToLeft reference drawn LEFT-TO-RIGHT (point order reversed) —
  // direction must remain a criterion (D-C).
  final leftToRightBowl = bowl.reversed.toList();

  // A single-tap "stroke" — the firm raw-point floor must be unchanged.
  const singleTap = <List<double>>[
    [0.5, 0.5],
  ];

  group('Tolerances — soft-band knobs are DATA (D-D)', () {
    test(
        'Tolerances.normal carries the four PROVISIONAL soft-band knobs; '
        'shapeTcc/shapeTcw equal SoftBand.shapeDefault', () {
      expect(Tolerances.normal.shapeTcc, 0.10);
      expect(Tolerances.normal.shapeTcw, 0.15);
      expect(Tolerances.normal.shapeTcc, SoftBand.shapeDefault.tcc,
          reason: 'the Tolerances knob and SoftBand.shapeDefault must agree');
      expect(Tolerances.normal.shapeTcw, SoftBand.shapeDefault.tcw,
          reason: 'the Tolerances knob and SoftBand.shapeDefault must agree');
      expect(Tolerances.normal.directionCc, 0.3);
      expect(Tolerances.normal.directionCw, -0.3);
    });

    test(
        'Tolerances.fromJson honors shapeTcc/shapeTcw overrides '
        '(same defensive idiom as maxCurvature)', () {
      final t = Tolerances.fromJson(const {
        'preset': 'normal',
        'overrides': {'shapeTcc': 0.08, 'shapeTcw': 0.20},
      });
      expect(t.shapeTcc, 0.08);
      expect(t.shapeTcw, 0.20);
      // Untouched knobs keep the preset values — overrides are per-knob.
      expect(t.maxCurvature, 0.25);
      expect(t.directionCc, 0.3);
      expect(t.directionCw, -0.3);
    });

    test('fromJson with no overrides keeps the provisional soft-band defaults',
        () {
      final t = Tolerances.fromJson(const {'preset': 'normal'});
      expect(t.shapeTcc, 0.10);
      expect(t.shapeTcw, 0.15);
    });
  });

  group('CriterionResult / StrokeResult — structured criteria model', () {
    test(
        'CriterionResult carries criterion/zone/score — the field is '
        '`criterion` (wire-safe naming, never `name`, never *point*)', () {
      const c = CriterionResult(
        criterion: 'shape',
        zone: ShapeZone.certainlyCorrect,
        score: 1.0,
      );
      expect(c.criterion, 'shape');
      expect(c.zone, ShapeZone.certainlyCorrect);
      expect(c.score, 1.0);
    });

    test(
        'StrokeResult gains criteria (default const []) keeping '
        'passed/mistakeId unchanged', () {
      const r = StrokeResult(passed: true);
      expect(r.passed, isTrue);
      expect(r.mistakeId, isNull);
      expect(r.criteria, isEmpty);
    });
  });

  group('scoreStroke — soft 3-zone verdict over the REAL baa bowl (D-C)', () {
    test(
        'shaky-but-correct bowl PASSES; its shape criterion zone is '
        'certainlyCorrect or fuzzy (the F2 fix: fuzzy PASSES)', () {
      final result = scoreStroke(shakyBowl, bowlRef);
      expect(result.passed, isTrue,
          reason: 'a shaky-but-correct child bowl must not false-fail (F2)');
      expect(result.mistakeId, isNull);
      final shape =
          result.criteria.firstWhere((c) => c.criterion == 'shape');
      expect(
        shape.zone,
        anyOf(ShapeZone.certainlyCorrect, ShapeZone.fuzzy),
        reason: 'shaky-correct lands in the tolerant zones, never '
            'certainlyWrong',
      );
    });

    test(
        'a flat "line" bowl FAILS as MistakeId.tooCurved with shape zone '
        'certainlyWrong (existing enum id kept — Pitfall 2)', () {
      final result = scoreStroke(flatLine, bowlRef);
      expect(result.passed, isFalse);
      expect(result.mistakeId, MistakeId.tooCurved,
          reason: 'shape failures KEEP the existing enum id + check-string '
              'contract — no new MistakeId');
      final shape =
          result.criteria.firstWhere((c) => c.criterion == 'shape');
      expect(shape.zone, ShapeZone.certainlyWrong);
    });

    test(
        'a rightToLeft reference drawn left-to-right FAILS as wrongDirection '
        'and still carries a direction criterion (D-C: direction stays)', () {
      final result = scoreStroke(leftToRightBowl, bowlRef);
      expect(result.passed, isFalse);
      expect(result.mistakeId, MistakeId.wrongDirection);
      expect(
        result.criteria.any((c) => c.criterion == 'direction'),
        isTrue,
        reason: 'direction remains a scored criterion in the soft scheme',
      );
    });

    test('a 1-point stroke still fails FIRM as tooShort (floor unchanged)',
        () {
      final result = scoreStroke(singleTap, bowlRef);
      expect(result.passed, isFalse);
      expect(result.mistakeId, MistakeId.tooShort);
    });

    test(
        'every geometrically scored stroke carries BOTH shape and direction '
        'criteria entries — on pass and on fail', () {
      // The firm raw-point floor short-circuits BEFORE geometry, so the
      // degenerate tooShort tap is exempt; all strokes that reach the
      // geometric criteria must report both.
      for (final strokes in [shakyBowl, flatLine, leftToRightBowl]) {
        final result = scoreStroke(strokes, bowlRef);
        final names = [for (final c in result.criteria) c.criterion];
        expect(names, contains('shape'));
        expect(names, contains('direction'));
      }
    });
  });
}
