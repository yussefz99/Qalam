// Wave-0 RED contract for Plan 17-03 (increment 3) — RED by missing symbol
// until 17-03 lands. Compile errors count as RED.
//
// Pure Dart, no dart:ui, no Flutter imports (flutter_test harness only) — the
// same register as lib/core/scoring/shape_match.dart.
//
// Pins the increment-3 target API BEFORE implementation (Nyquist rule; mirrors
// the 15-01/16-01 precedent), per locked decisions D-C (5 criteria + explicit
// dot check), D-B (the weakest criterion is the coaching target) and D-E
// (prove on baa forms):
//
//   1. `scoreLetter` gains an optional named `String? form` parameter and
//      returns `Future<LetterScore>` where `LetterScore extends LetterResult`
//      (existing `passed`/`mistakeId` reads and practice_screen's explicit
//      `LetterResult` annotation stay source-compatible), adding `criteria`
//      (List<CriterionResult>) and `weakest` (CriterionResult?, the
//      lowest-score criterion — the coaching target, D-B).
//   2. ONE shared resolver exists (Pitfall 7 — canvas, diff, and scorer must
//      share it): `resolveReferenceStrokes(Letter, String? form)` in
//      lib/core/scoring/reference_resolution.dart —
//      `contextualForms[form].referenceStrokes` when form is non-null AND that
//      list is non-empty, else `letter.referenceStrokes`.
//   3. The five scored criteria are strokeCount / strokeOrder / shape /
//      direction / dot — the OWNER-CONFIRMED D-C amendment of 2026-07-05
//      (17-CONTEXT.md Decisions): kinematics is DESCOPED (capture has no
//      timestamps — never fake speed from point spacing); position folds into
//      the firm dot-placement check; strokeCount is the fifth criterion.
//      ADR-017 (Plan 17-10) records the amendment plus the
//      PointerEvent.timeStamp capture follow-up.
//   4. Firm checks STAY firm (D-C / Pitfall 3): dot placement and stroke count
//      remain categorical — certainlyWrong with score 0.0, never fuzzy.
//
// Fixtures carry the REAL authored baa isolated + medial per-form points
// (assets/curriculum/letters.json baa.contextualForms), perturbed with the
// shape_match_test.dart technique. No child data, no PII (T-17-01).
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/letter_scorer.dart';
import 'package:qalam/core/scoring/reference_resolution.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/core/scoring/shape_match.dart';
import 'package:qalam/core/scoring/tolerances.dart';
import 'package:qalam/models/letter.dart';

void main() {
  // ── REAL authored per-form points (letters.json baa.contextualForms) ───────
  // isolated: the "boat/bowl" curve (12 pts) + dot below.
  const isolatedBowl = <List<double>>[
    [0.608, 0.447], [0.619, 0.486], [0.620, 0.524], [0.594, 0.552],
    [0.551, 0.565], [0.511, 0.569], [0.474, 0.570], [0.436, 0.566],
    [0.407, 0.559], [0.386, 0.530], [0.381, 0.498], [0.382, 0.460],
  ];
  // medial: the little "tooth" between two letters (8 pts) + dot below.
  const medialTooth = <List<double>>[
    [0.628, 0.571], [0.573, 0.578], [0.518, 0.564], [0.506, 0.490],
    [0.480, 0.569], [0.433, 0.575], [0.388, 0.574], [0.342, 0.570],
  ];

  // ── Test Letter: the letter_scorer_test builder idiom, extended with the
  //    REAL authored contextualForms (isolated + medial; initial deliberately
  //    EMPTY to pin the resolver's non-empty condition; final absent). ────────
  Letter baaWithForms() => const Letter(
        id: 'baa',
        char: 'ب',
        name: LetterName(ar: 'بَاء', display: 'Baa'),
        introOrder: 2,
        forms: LetterForms(
          isolated: 'ب',
          initial: 'بـ',
          medial: 'ـبـ',
          final_: 'ـب',
        ),
        referenceStrokes: [
          StrokeSpec(
            order: 1,
            label: 'body',
            type: 'line',
            direction: 'rightToLeft',
            points: [
              [0.9, 0.4],
              [0.6, 0.55],
              [0.3, 0.55],
              [0.1, 0.4],
            ],
          ),
          StrokeSpec(
            order: 2,
            label: 'dot',
            type: 'dot',
            direction: 'tap',
            points: [
              [0.5, 0.8], // dot BELOW the body — the baa identity
            ],
          ),
        ],
        cleanRepsToAdvance: 3,
        commonMistakes: [
          CommonMistake(
            id: 'wrong_stroke_count',
            check: 'strokeCountMismatch',
            feedback: 'Baa is two parts — the boat, then one dot underneath.',
          ),
          CommonMistake(
            id: 'dot_wrong',
            check: 'dotPositionWrong',
            feedback: "Baa's dot goes under the boat, not on top.",
          ),
        ],
        mistakesStatus: 'authored',
        signedOff: false,
        tolerances: Tolerances(
          minRawPoints: 10,
          resampleN: 32,
          maxCurvature: 0.30,
        ),
        contextualForms: {
          'isolated': Form(
            referenceStrokes: [
              StrokeSpec(
                order: 1,
                label: 'bowl',
                type: 'curve',
                direction: 'rightToLeft',
                points: isolatedBowl,
              ),
              StrokeSpec(
                order: 2,
                label: 'dot',
                type: 'dot',
                direction: 'tap',
                points: [
                  [0.498, 0.644],
                ],
              ),
            ],
          ),
          'medial': Form(
            referenceStrokes: [
              StrokeSpec(
                order: 1,
                label: 'tooth',
                type: 'curve',
                direction: 'rightToLeft',
                points: medialTooth,
              ),
              StrokeSpec(
                order: 2,
                label: 'dot',
                type: 'dot',
                direction: 'tap',
                points: [
                  [0.495, 0.841],
                ],
              ),
            ],
          ),
          // Authored-empty slot: the resolver must fall back to the base
          // reference when the per-form stroke list is EMPTY.
          'initial': Form(referenceStrokes: []),
        },
      );

  // ── Fixture builders (shape_match_test.dart perturbation technique) ────────

  /// Midpoint-densifies an authored polyline so a child-capture fixture clears
  /// the firm minRawPoints floor (10) without changing the curve's shape
  /// (arc-length resampling makes the two polylines geometrically identical).
  List<List<double>> densify(List<List<double>> pts) => <List<double>>[
        for (var i = 0; i < pts.length - 1; i++) ...[
          pts[i],
          [
            (pts[i][0] + pts[i + 1][0]) / 2,
            (pts[i][1] + pts[i + 1][1]) / 2,
          ],
        ],
        pts.last,
      ];

  /// The deterministic ±~0.012 wobble of a real-but-unsteady child hand.
  List<List<double>> shake(List<List<double>> pts) => <List<double>>[
        for (var i = 0; i < pts.length; i++)
          [
            pts[i][0] + (i.isEven ? 0.012 : -0.010),
            pts[i][1] + (i % 3 == 0 ? -0.011 : 0.009),
          ],
      ];

  /// A good-faith MEDIAL baa: a shaky-but-correct tooth + the dot below.
  List<List<List<double>>> goodMedial() => [
        shake(densify(medialTooth)),
        const [
          [0.495, 0.841],
        ],
      ];

  /// The F5 trap attempt: ISOLATED-bowl-shaped strokes offered for the medial
  /// slot (dot still below, so shape — not the dot check — is the failure).
  List<List<List<double>>> isolatedShapedAttempt() => [
        shake(isolatedBowl),
        const [
          [0.498, 0.644],
        ],
      ];

  /// The existing letter_scorer_test good-baa fixture, verbatim — the
  /// form-null path must keep passing it (backward compat through the new
  /// resolution path).
  List<List<List<double>>> goodBaa() => [
        List<List<double>>.generate(
          20,
          (i) => [180.0 - i * 8, 100.0 + (i < 10 ? i * 2.0 : (19 - i) * 2.0)],
        ),
        const [
          [90.0, 170.0],
        ],
      ];

  /// The same good body with the dot ABOVE — must still fail dotMisplaced.
  List<List<List<double>>> dotAboveBaa() => [
        goodBaa()[0],
        const [
          [90.0, 40.0],
        ],
      ];

  group('resolveReferenceStrokes — ONE shared resolution function (Pitfall 7)',
      () {
    test("a non-null form with non-empty strokes resolves the per-form "
        'reference', () {
      final resolved = resolveReferenceStrokes(baaWithForms(), 'medial');
      expect(resolved, hasLength(2));
      expect(resolved.first.label, 'tooth');
      expect(resolved.first.points.first, [0.628, 0.571]);
    });

    test('form: null resolves the letter base referenceStrokes', () {
      final resolved = resolveReferenceStrokes(baaWithForms(), null);
      expect(resolved, hasLength(2));
      expect(resolved.first.label, 'body');
    });

    test('a form whose referenceStrokes are EMPTY falls back to the base '
        'reference', () {
      final resolved = resolveReferenceStrokes(baaWithForms(), 'initial');
      expect(resolved.first.label, 'body');
    });

    test('an unknown form key falls back to the base reference', () {
      final resolved = resolveReferenceStrokes(baaWithForms(), 'final');
      expect(resolved.first.label, 'body');
    });
  });

  group('scoreLetter — per-form scoring (D-E: prove on baa forms)', () {
    test("good medial-tooth strokes with form: 'medial' PASS against the "
        'medial reference; LetterScore IS-A LetterResult', () async {
      final LetterScore score =
          await scoreLetter(goodMedial(), baaWithForms(), form: 'medial');
      expect(score.passed, isTrue,
          reason: 'a shaky-but-correct medial tooth must pass its own '
              'per-form reference');
      expect(score.mistakeId, isNull);
      // Source-compat pin: LetterScore extends LetterResult, so existing
      // passed/mistakeId reads and explicit LetterResult annotations compile.
      final LetterResult asBase = score;
      expect(asBase, isA<LetterResult>());
      expect(score, isA<LetterScore>());
    });

    test('F5 trap: isolated-bowl strokes submitted for the medial slot FAIL '
        '(shape certainlyWrong at the SCORER, not the LLM)', () async {
      final LetterScore score = await scoreLetter(
        isolatedShapedAttempt(),
        baaWithForms(),
        form: 'medial',
      );
      expect(score.passed, isFalse,
          reason: 'the isolated bowl must NOT pass the medial slot (UAT F5)');
      final shape =
          score.criteria.firstWhere((c) => c.criterion == 'shape');
      expect(shape.zone, ShapeZone.certainlyWrong,
          reason: 'a full bowl offered as the little medial tooth is a '
              'certainly-wrong shape');
    });

    test('form: null (or omitted) scores against letter.referenceStrokes — '
        'the existing good-baa fixture still passes through the new path',
        () async {
      final LetterScore omitted =
          await scoreLetter(goodBaa(), baaWithForms());
      expect(omitted.passed, isTrue);
      expect(omitted.mistakeId, isNull);

      final LetterScore explicitNull =
          await scoreLetter(goodBaa(), baaWithForms(), form: null);
      expect(explicitNull.passed, isTrue);
    });
  });

  group('scoreLetter — LetterScore structured result (D-B / D-C amendment)',
      () {
    test('criteria carries exactly the five owner-confirmed entries: '
        'strokeCount, strokeOrder, shape, direction, dot', () async {
      // The five-criteria set is the OWNER-CONFIRMED D-C amendment
      // (2026-07-05): kinematics DESCOPED, position folded into the firm dot
      // check, strokeCount the fifth criterion. Recorded in ADR-017 (17-10).
      final LetterScore score =
          await scoreLetter(goodMedial(), baaWithForms(), form: 'medial');
      final entries = [for (final c in score.criteria) c.criterion];
      expect(entries, hasLength(5));
      expect(
        entries.toSet(),
        {'strokeCount', 'strokeOrder', 'shape', 'direction', 'dot'},
      );
    });

    test('weakest is non-null on a PASS and equals the minimum-score '
        'criterion (the coaching target, D-B)', () async {
      final LetterScore score =
          await scoreLetter(goodMedial(), baaWithForms(), form: 'medial');
      expect(score.passed, isTrue);
      expect(score.weakest, isNotNull);
      final minScore = score.criteria
          .map((c) => c.score)
          .reduce((a, b) => a < b ? a : b);
      expect(score.weakest!.score, minScore);
    });

    test('weakest is non-null on a FAIL and equals the minimum-score '
        'criterion', () async {
      final LetterScore score =
          await scoreLetter(dotAboveBaa(), baaWithForms());
      expect(score.passed, isFalse);
      expect(score.weakest, isNotNull);
      final minScore = score.criteria
          .map((c) => c.score)
          .reduce((a, b) => a < b ? a : b);
      expect(score.weakest!.score, minScore);
      expect(score.weakest!.criterion, 'dot',
          reason: 'the misplaced dot is the unique 0.0 criterion here — the '
              'coach must be pointed at it');
    });
  });

  group('scoreLetter — firm checks stay firm (D-C / Pitfall 3)', () {
    test('a dot-above-body baa still fails with MistakeId.dotMisplaced; its '
        'dot criterion is certainlyWrong with score 0.0 (categorical — '
        'never fuzzy)', () async {
      final LetterScore score =
          await scoreLetter(dotAboveBaa(), baaWithForms());
      expect(score.passed, isFalse);
      expect(score.mistakeId, MistakeId.dotMisplaced);
      final dot = score.criteria.firstWhere((c) => c.criterion == 'dot');
      expect(dot.zone, ShapeZone.certainlyWrong);
      expect(dot.score, 0.0);
    });

    test('a wrong-stroke-count attempt still fails with '
        'MistakeId.wrongStrokeCount; its strokeCount criterion is '
        'certainlyWrong with score 0.0', () async {
      // One stroke where baa expects two (body + dot).
      final LetterScore score =
          await scoreLetter([goodBaa()[0]], baaWithForms());
      expect(score.passed, isFalse);
      expect(score.mistakeId, MistakeId.wrongStrokeCount);
      final count =
          score.criteria.firstWhere((c) => c.criterion == 'strokeCount');
      expect(count.zone, ShapeZone.certainlyWrong);
      expect(count.score, 0.0);
      expect(score.weakest, isNotNull);
    });
  });
}
