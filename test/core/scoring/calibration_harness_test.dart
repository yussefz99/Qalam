import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/letter_scorer.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/core/scoring/tolerances.dart';
import 'package:qalam/models/letter.dart';

import 'calibration_fixtures/calibration_fixtures.dart';

/// SC#4 — the calibration confusion-table harness.
///
/// This is the mechanism by which the owner's mother tunes per-letter tolerances
/// and by which named common mistakes become permanent regression tests. It runs
/// the REAL `scoreLetter` (NOT a re-implementation — RESEARCH A3 / Pitfall: no
/// Python re-impl) over every labeled fixture and reports, per letter:
///   * FALSE NEGATIVES — `good` attempts the scorer wrongly REJECTED.
///   * FALSE POSITIVES — named-bad attempts the scorer wrongly PASSED.
///
/// The confusion table is PRINTED (test output) so the mother + owner can read
/// per-letter FP/FN while tuning the JSON tolerances. The harness also ASSERTS
/// the regression contract: every `good` seed passes, and every named-bad seed
/// is rejected with the expected MistakeId.
///
/// Tuning priority (RESEARCH step 5): lean toward minimizing FALSE NEGATIVES for
/// good-faith attempts (a child who tried should rarely be told they failed),
/// while keeping order / count / identity FIRM. See the fixtures README.
///
/// ⚠ The fixtures are a SYNTHETIC seed (Plan 04-05). Real-tablet child captures
/// replace them in Plan 06; this harness does not change — only the data does.

/// The expected rejection identity for each named-bad label, per the scoreLetter
/// contract (letter_scorer.dart). `good` is absent — it must PASS, not reject.
const Map<String, MistakeId> _expectedRejection = <String, MistakeId>{
  'wrong_count': MistakeId.wrongStrokeCount,
  'wrong_order': MistakeId.wrongStrokeOrder,
  'taa_when_shown_baa': MistakeId.dotMisplaced,
  // (wrong_direction / scribble / wrong_letter land with real samples in Plan 06)
};

/// A 2-stroke baa: a rightToLeft body line ("the boat") + a dot tap beneath.
/// Mirrors the letters.json baa entry (same inline builder as
/// letter_scorer_test.dart so the harness scores against the live contract).
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
    );

/// The Letter under test for each calibration letter id. Plan 06 extends this
/// map as it authors taa/thaa/alif fixtures.
final Map<String, Letter Function()> _lettersById = <String, Letter Function()>{
  'baa': baaLetter,
};

/// A per-letter confusion tally accumulated as the harness runs.
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
  group('Calibration harness — per-letter confusion table (SC#4)', () {
    final tables = <String, _Confusion>{};

    for (final entry in calibrationSamplesByLetter.entries) {
      final letterId = entry.key;
      final samples = entry.value;
      final letter = _lettersById[letterId]!();

      group('letter "$letterId"', () {
        for (final sample in samples) {
          test('${sample.label} → ${sample.isGood ? "PASS" : "reject"}',
              () async {
            final result = await scoreLetter(sample.strokes, letter);
            final tally = tables.putIfAbsent(letterId, _Confusion.new);

            if (sample.isGood) {
              tally.goodTotal++;
              if (!result.passed) tally.falseNegatives++;
              // Regression contract: a good-faith attempt MUST be accepted.
              expect(result.passed, isTrue,
                  reason: 'FALSE NEGATIVE: a "good" $letterId was rejected '
                      '(mistakeId=${result.mistakeId})');
            } else {
              tally.badTotal++;
              if (result.passed) tally.falsePositives++;
              // Regression contract: a named common mistake MUST be rejected,
              // with the expected MistakeId when one is pinned.
              expect(result.passed, isFalse,
                  reason: 'FALSE POSITIVE: a "${sample.label}" $letterId '
                      'was passed by the scorer');
              final expected = _expectedRejection[sample.label];
              if (expected != null) {
                expect(result.mistakeId, equals(expected),
                    reason: '"${sample.label}" should reject as $expected');
              }
            }
          });
        }
      });
    }

    // Print the per-letter confusion table AFTER all samples have scored. This
    // is the artefact the mother + owner read during tuning.
    tearDownAll(() {
      // ignore: avoid_print — intentional harness report to the test console.
      print('\n=== Calibration confusion table (SC#4) ===');
      for (final e in tables.entries) {
        // ignore: avoid_print
        print('  ${e.key}: ${e.value}');
      }
      // ignore: avoid_print
      print('  (FN = good rejected; FP = named-bad passed. '
          'Tuning priority: minimize FN for good-faith, keep count/order/'
          'identity firm.)\n');
    });
  });
}
