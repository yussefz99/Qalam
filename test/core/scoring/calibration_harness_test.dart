import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/letter_scorer.dart';
import 'package:qalam/core/scoring/reference_resolution.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/core/scoring/shape_match.dart';
import 'package:qalam/core/scoring/tolerances.dart';
import 'package:qalam/models/letter.dart';

import 'calibration_fixtures/calibration_fixtures.dart';

/// SC#4 — the calibration confusion-table harness (per letter × FORM, Plan 17-09).
///
/// This is the mechanism by which the owner's mother tunes per-letter × per-form
/// tolerances and by which named common mistakes become permanent regression
/// tests. It runs the REAL `scoreLetter` against the reference for the ASKED
/// positional form (`scoreLetter(strokes, letter, form:)` — the SAME per-form
/// reference the scorer resolves via `resolveReferenceStrokes`; NEVER a
/// re-implementation — RESEARCH A3 / Pitfall: no Python re-impl) over every
/// labelled fixture and reports, per letter × form:
///   * FALSE NEGATIVES — `good` attempts the scorer wrongly REJECTED.
///   * FALSE POSITIVES — named-bad attempts the scorer wrongly PASSED.
///
/// The confusion table is PRINTED (test output) so the mother + owner can read
/// per-cell FP/FN while tuning the JSON tolerances. The harness also ASSERTS the
/// regression contract: every `good` seed passes (FN == 0), every named-bad seed
/// is rejected with the expected MistakeId, and — new in 17-09 — the F5
/// FORM-CONFUSION cell is ZERO passes (an isolated bowl offered for the
/// medial/final slot is rejected AT THE SCORER, D-A, forever).
///
/// A THRESHOLD-FIT report (also new in 17-09) derives suggested soft-band
/// tcc/tcw per letter × form from the labelled distance distributions and prints
/// them labelled PROVISIONAL — it NEVER mutates production values (D-D): the
/// production bands come from the owner's-mother-labelled real-child captures,
/// a deferred production gate recorded in 17-10's HUMAN-UAT.
///
/// Tuning priority (RESEARCH step 5): lean toward minimizing FALSE NEGATIVES for
/// good-faith attempts (a child who tried should rarely be told they failed),
/// while keeping order / count / dot / identity FIRM. See the fixtures README.
///
/// ⚠ The fixtures are a SYNTHETIC seed (Plan 04-05 base + 17-09 per-form). Real-
/// tablet child captures replace them in Plan 06 / the D-D calibration; this
/// harness does not change — only the data does.

/// The expected rejection identity for each named-bad label, per the scoreLetter
/// contract (letter_scorer.dart). `good` is absent — it must PASS, not reject.
const Map<String, MistakeId> _expectedRejection = <String, MistakeId>{
  // ── base seed (form: null) — Plan 04-05 ──
  'wrong_count': MistakeId.wrongStrokeCount,
  'wrong_order': MistakeId.wrongStrokeOrder,
  'taa_when_shown_baa': MistakeId.dotMisplaced,
  // (wrong_direction / scribble / wrong_letter land with real samples in Plan 06)
  // ── per-form (Plan 17-09) ──
  'flatBody': MistakeId.tooCurved, // collinear body → shape certainly-wrong
  'dotAbove': MistakeId.dotMisplaced, // the one dot placed above the body
  'missingDot': MistakeId.wrongStrokeCount, // body only — a missing stroke
  // taa with a single dot is 2 strokes where 3 are expected: the FIRM
  // strokeCount check fires first, so the dot-count slip surfaces as
  // wrongStrokeCount (the id the scorer deterministically emits).
  'wrongDotCount': MistakeId.wrongStrokeCount,
  // the F5 trap: an isolated bowl offered for the medial/final slot is a
  // certainly-wrong SHAPE against the little tooth / final bowl_tail.
  'formConfusion': MistakeId.tooCurved,
};

/// A 2-stroke baa: a rightToLeft body line ("the boat") + a dot tap beneath.
/// Mirrors the letters.json baa entry (same inline builder as
/// letter_scorer_test.dart so the harness scores against the live contract),
/// EXTENDED (17-09) with the REAL authored `contextualForms` for all four
/// positional forms (built from the exported fixture consts so the reference the
/// harness resolves is the SAME data the fixtures were perturbed from).
Letter baaLetter() => const Letter(
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
          id: 'wrong_stroke_order',
          check: 'strokeOrderWrong',
          feedback: 'Draw the boat first, then the dot underneath.',
        ),
        CommonMistake(
          id: 'dot_wrong',
          check: 'dotPositionWrong',
          feedback: "Baa's dot goes under the boat, not on top.",
        ),
        CommonMistake(
          id: 'wrong_letter',
          check: 'letterIdentityMismatch',
          feedback: 'That looks like a different letter — try baa again.',
        ),
      ],
      mistakesStatus: 'authored',
      signedOff: false,
      tolerances: Tolerances(
        minRawPoints: 10,
        resampleN: 32,
        maxCurvature: 0.30,
      ),
      // The REAL authored per-form references (letters.json baa.contextualForms),
      // via the exported fixture consts — the ONE shared source of the points.
      contextualForms: {
        'isolated': Form(
          referenceStrokes: [
            StrokeSpec(
              order: 1,
              label: 'bowl',
              type: 'curve',
              direction: 'rightToLeft',
              points: kBaaIsolatedBowl,
            ),
            StrokeSpec(
              order: 2,
              label: 'dot',
              type: 'dot',
              direction: 'tap',
              points: [kBaaIsolatedDot],
            ),
          ],
        ),
        'initial': Form(
          referenceStrokes: [
            StrokeSpec(
              order: 1,
              label: 'head',
              type: 'curve',
              direction: 'rightToLeft',
              points: kBaaInitialHead,
            ),
            StrokeSpec(
              order: 2,
              label: 'dot',
              type: 'dot',
              direction: 'tap',
              points: [kBaaInitialDot],
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
              points: kBaaMedialTooth,
            ),
            StrokeSpec(
              order: 2,
              label: 'dot',
              type: 'dot',
              direction: 'tap',
              points: [kBaaMedialDot],
            ),
          ],
        ),
        'final': Form(
          referenceStrokes: [
            StrokeSpec(
              order: 1,
              label: 'bowl_tail',
              type: 'curve',
              direction: 'rightToLeft',
              points: kBaaFinalBowlTail,
            ),
            StrokeSpec(
              order: 2,
              label: 'dot',
              type: 'dot',
              direction: 'tap',
              points: [kBaaFinalDot],
            ),
          ],
        ),
      },
    );

/// taa (D-E proof) — the SAME bowl skeleton as baa isolated, but TWO dots ABOVE.
/// The isolated `contextualForms` reference is what the taa samples score against.
Letter taaLetter() => const Letter(
      id: 'taa',
      char: 'ت',
      name: LetterName(ar: 'تَاء', display: 'Taa'),
      introOrder: 3,
      forms: LetterForms(
        isolated: 'ت',
        initial: 'تـ',
        medial: 'ـتـ',
        final_: 'ـت',
      ),
      referenceStrokes: [
        StrokeSpec(
          order: 1,
          label: 'bowl',
          type: 'curve',
          direction: 'rightToLeft',
          points: kTaaIsolatedBowl,
        ),
        StrokeSpec(
          order: 2,
          label: 'dot1',
          type: 'dot',
          direction: 'tap',
          points: [kTaaDot1],
        ),
        StrokeSpec(
          order: 3,
          label: 'dot2',
          type: 'dot',
          direction: 'tap',
          points: [kTaaDot2],
        ),
      ],
      cleanRepsToAdvance: 3,
      commonMistakes: [
        CommonMistake(
          id: 'wrong_stroke_count',
          check: 'strokeCountMismatch',
          feedback: 'Taa is the boat plus two dots on top — count them: one, two.',
        ),
        CommonMistake(
          id: 'dot_wrong',
          check: 'dotPositionWrong',
          feedback: "Taa's two dots go above the boat, not below.",
        ),
      ],
      mistakesStatus: 'authored',
      signedOff: true,
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
              points: kTaaIsolatedBowl,
            ),
            StrokeSpec(
              order: 2,
              label: 'dot1',
              type: 'dot',
              direction: 'tap',
              points: [kTaaDot1],
            ),
            StrokeSpec(
              order: 3,
              label: 'dot2',
              type: 'dot',
              direction: 'tap',
              points: [kTaaDot2],
            ),
          ],
        ),
      },
    );

/// The Letter under test for each calibration letter id. Plan 06 extends this
/// map as it authors thaa/alif fixtures.
final Map<String, Letter Function()> _lettersById = <String, Letter Function()>{
  'baa': baaLetter,
  'taa': taaLetter,
};

/// The confusion-table cell key: one row per letter × asked form.
String _cell(String letterId, String? form) => '$letterId/${form ?? 'base'}';

/// A per-cell confusion tally accumulated as the harness runs.
class _Confusion {
  int goodTotal = 0;
  int falseNegatives = 0; // good rejected
  int badTotal = 0;
  int falsePositives = 0; // named-bad passed

  @override
  String toString() =>
      'good=$goodTotal FN=$falseNegatives | bad=$badTotal FP=$falsePositives';
}

void main() {
  group('Calibration harness — per letter × form confusion table (SC#4)', () {
    final tables = <String, _Confusion>{};

    for (final entry in calibrationSamplesByLetter.entries) {
      final letterId = entry.key;
      final samples = entry.value;
      final letter = _lettersById[letterId]!();

      group('letter "$letterId"', () {
        for (final sample in samples) {
          final formLabel = sample.form ?? 'base';
          test(
              '[$formLabel] ${sample.label} → '
              '${sample.isGood ? "PASS" : "reject"}', () async {
            // Score against the ASKED positional form's reference — the SAME
            // per-form resolution the scorer/canvas/diff share (Pitfall 7).
            final result =
                await scoreLetter(sample.strokes, letter, form: sample.form);
            final tally =
                tables.putIfAbsent(_cell(letterId, sample.form), _Confusion.new);

            if (sample.isGood) {
              tally.goodTotal++;
              if (!result.passed) tally.falseNegatives++;
              // Regression contract: a good-faith attempt MUST be accepted.
              expect(result.passed, isTrue,
                  reason: 'FALSE NEGATIVE: a "good" $letterId ($formLabel) was '
                      'rejected (mistakeId=${result.mistakeId})');
            } else {
              tally.badTotal++;
              if (result.passed) tally.falsePositives++;
              // Regression contract: a named common mistake MUST be rejected,
              // with the expected MistakeId when one is pinned.
              expect(result.passed, isFalse,
                  reason: 'FALSE POSITIVE: a "${sample.label}" $letterId '
                      '($formLabel) was passed by the scorer');
              final expected = _expectedRejection[sample.label];
              if (expected != null) {
                expect(result.mistakeId, equals(expected),
                    reason: '"${sample.label}" ($formLabel) should reject as '
                        '$expected');
              }
            }
          });
        }
      });
    }

    // ── F5 FORM-CONFUSION cell == ZERO (D-A: the verdict lives at the scorer) ──
    // Moves the F5 gate out of the LLM eval and into the Dart harness: an
    // isolated bowl offered for the medial/final slot is a certainly-wrong
    // SHAPE against that form's reference, so it can never pass — forever.
    group('F5 form-confusion cell is ZERO (D-A)', () {
      final f5 = <LabeledSample>[
        for (final s in calibrationSamplesByLetter['baa']!)
          if (s.label == 'formConfusion') s,
      ];

      test('isolated-bowl-for-medial and isolated-bowl-for-final are BOTH '
          'rejected — zero passes over the F5 trap', () async {
        expect(f5, isNotEmpty, reason: 'the F5 trap pairs must exist');
        final forms = {for (final s in f5) s.form};
        expect(forms, containsAll(<String>{'medial', 'final'}),
            reason: 'the trap covers the isolated-for-medial and '
                'isolated-for-final cells');

        var passes = 0;
        for (final s in f5) {
          final score =
              await scoreLetter(s.strokes, baaLetter(), form: s.form);
          if (score.passed) passes++;
          expect(score.passed, isFalse,
              reason: 'F5: an isolated bowl must NOT pass the ${s.form} slot');
          final shape =
              score.criteria.firstWhere((c) => c.criterion == 'shape');
          expect(shape.zone, ShapeZone.certainlyWrong,
              reason: 'F5: a full bowl offered as the ${s.form} form is a '
                  'certainly-wrong shape');
        }
        expect(passes, 0,
            reason: 'the F5 form-confusion cell must be EXACTLY zero passes');
      });
    });

    // Print the per-cell confusion table AFTER all samples have scored. This is
    // the artefact the mother + owner read during tuning.
    tearDownAll(() {
      // ignore: avoid_print — intentional harness report to the test console.
      print('\n=== Calibration confusion table — per letter × form (SC#4) ===');
      final keys = tables.keys.toList()..sort();
      for (final k in keys) {
        // ignore: avoid_print
        print('  $k: ${tables[k]}');
      }
      // ignore: avoid_print
      print('  (FN = good rejected; FP = named-bad passed. '
          'Tuning priority: minimize FN for good-faith, keep count/order/dot/'
          'identity firm.)\n');
    });
  });

  // ── THRESHOLD-FIT report (PROVISIONAL — Plan 17-09, D-D) ────────────────────
  // For each letter × form, compute the SHAPE-criterion distance
  // (`shapeDistance(sample body stroke, resolved reference body)`) for the
  // labelled-good vs the SHAPE-labelled-bad samples, and suggest a soft band:
  //   suggested tcc = max(good distances)   (the correct shapes sit at/below it)
  //   suggested tcw = min(shape-bad distances) (the wrong shapes sit at/above it)
  // flagging any overlap (max(good) >= min(bad)) as UNSEPARABLE (needs more
  // samples). The dot/count-defective bad samples (dotAbove / missingDot /
  // wrongDotCount) are EXCLUDED from the shape-band fit: their body shape is
  // CORRECT — they fail the dot / count criteria, not shape — so folding them in
  // would collapse min(bad) onto the good range and mask a perfectly separable
  // shape band. The report PRINTS ONLY: it never mutates Tolerances or
  // letters.json (production bands come from the mom-labelled captures, D-D).
  group('Threshold-fit report (PROVISIONAL — synthetic seed)', () {
    // The SHAPE-defective labels (expected rejection == tooCurved): only these
    // exercise the shape band.
    const shapeBadLabels = <String>{'flatBody', 'formConfusion'};

    /// The body stroke's DTW distance to the resolved per-form reference body.
    double bodyDistance(LabeledSample s, Letter letter) {
      final ref = resolveReferenceStrokes(letter, s.form);
      final refBody = ref.firstWhere((r) => r.type != 'dot').points;
      return shapeDistance(s.strokes.first, refBody);
    }

    test('prints suggested per-form tcc/tcw from the labelled distributions',
        () {
      final rows = <String>[];
      var separableCells = 0;
      var fittedCells = 0;

      for (final entry in calibrationSamplesByLetter.entries) {
        final letterId = entry.key;
        final letter = _lettersById[letterId]!();

        // Bucket by cell (letter × form).
        final byCell = <String, List<LabeledSample>>{};
        for (final s in entry.value) {
          byCell.putIfAbsent(_cell(letterId, s.form), () => []).add(s);
        }

        final cellKeys = byCell.keys.toList()..sort();
        for (final cell in cellKeys) {
          final samples = byCell[cell]!;
          final goodDs = <double>[
            for (final s in samples)
              if (s.isGood) bodyDistance(s, letter),
          ];
          final badDs = <double>[
            for (final s in samples)
              if (shapeBadLabels.contains(s.label)) bodyDistance(s, letter),
          ];

          if (goodDs.isEmpty || badDs.isEmpty) {
            rows.add('  $cell: good[${goodDs.length}] '
                'shape-bad[${badDs.length}] — insufficient samples to fit a '
                'shape band (need ≥1 good AND ≥1 shape-bad)');
            continue;
          }
          fittedCells++;
          final tccSug = goodDs.reduce((a, b) => a > b ? a : b); // max good
          final tcwSug = badDs.reduce((a, b) => a < b ? a : b); // min bad
          final separable = tccSug < tcwSug;
          if (separable) separableCells++;
          rows.add('  $cell: good max=${tccSug.toStringAsFixed(4)} '
              '(n=${goodDs.length}) | shape-bad min=${tcwSug.toStringAsFixed(4)} '
              '(n=${badDs.length}) → suggested tcc≈${tccSug.toStringAsFixed(3)} '
              'tcw≈${tcwSug.toStringAsFixed(3)} '
              '${separable ? "SEPARABLE" : "UNSEPARABLE (needs more samples)"}');
        }
      }

      // ignore: avoid_print
      print('\n=== Threshold-fit report — suggested soft bands (SC#4) ===');
      // ignore: avoid_print
      print('  PROVISIONAL — synthetic seed; production values require the '
          "owner's-mother-labelled child captures (D-D). This report PRINTS "
          'ONLY — it does not change Tolerances or letters.json.');
      // ignore: avoid_print
      print('  (shipped band for reference: tcc=${SoftBand.shapeDefault.tcc} '
          'tcw=${SoftBand.shapeDefault.tcw})');
      for (final r in rows) {
        // ignore: avoid_print
        print(r);
      }
      // ignore: avoid_print
      print('  fitted cells=$fittedCells separable=$separableCells; '
          'dot/count-defective samples are excluded from the SHAPE fit (their '
          'body shape is correct — they fail dot/count).\n');

      // Structural sanity only — the report asserts NOTHING about the values
      // (they are PROVISIONAL and mutation-free by design).
      expect(fittedCells, greaterThan(0),
          reason: 'the fit report must fit at least one letter × form cell');
    });
  });
}
