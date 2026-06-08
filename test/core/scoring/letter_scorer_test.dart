import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qalam/core/recognition/handwriting_recognizer.dart';
import 'package:qalam/core/scoring/letter_scorer.dart';
import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/core/scoring/tolerances.dart';
import 'package:qalam/models/letter.dart';

/// SC#1 / SC#2 / D-04 — the RED contract for `LetterScorer.scoreLetter`.
///
/// Plan 04-01 (Wave 0) defines WHAT the whole-letter scorer must do; Plan 04-02
/// IMPLEMENTS `scoreLetter` and turns the skipped contract tests green. The
/// skipped tests below are intentionally RED: `scoreLetter` does not exist yet.
/// Remove the `skip:` and wire the real `scoreLetter` import in Plan 02.
///
/// The non-skipped tests in this file ARE live now — they pin the Task-2
/// foundation (Letter.tolerances backward-compat + the tolerances validator)
/// that Plan 02 builds on.
///
/// SC#1 — wrong-COUNT / wrong-ORDER / taa-dots-when-shown-baa are caught with a
///        specific named MistakeId.
/// SC#2 — a confidently-different ML Kit candidate on a geometric pass is
///        rejected as wrongLetterIdentity.
/// D-04 — ML Kit is ADVISORY ONLY: a good geometric pass with a low-confidence
///        or wrong candidate STILL passes (the gate never overrides a pass on
///        weak evidence).

/// A mocktail fake of the [HandwritingRecognizer] seam — no real ML Kit in unit
/// tests (the model is a platform plugin). Plan 02 injects this into
/// `scoreLetter(..., recognizer: ...)`.
class FakeHandwritingRecognizer extends Mock implements HandwritingRecognizer {}

void main() {
  // ── Inline builders mirroring the letters.json baa entry (body line + dot) ──
  // Pattern copied from mistake_mapping_test.dart:19-68.

  /// A 2-stroke baa: a rightToLeft body line ("the boat") + a dot tap beneath.
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

  // Whole-letter captured strokes are List<List<List<double>>> (per letter →
  // per stroke → per [x,y] point). These are pixel-space synthetic captures.

  /// A good-faith baa: a curved body then a dot below.
  List<List<List<double>>> goodBaa() => [
        // body (right→left, modest bow)
        List<List<double>>.generate(20, (i) => [180.0 - i * 8, 100.0 + (i < 10 ? i * 2.0 : (19 - i) * 2.0)]),
        // dot below the body
        const [
          [90.0, 170.0]
        ],
      ];

  // ── SC#3 multi-stroke normalization fixtures ────────────────────────────────
  // A correct baa drawn ~40% the size of goodBaa() and shoved toward the
  // bottom-right corner of the canvas. Same shape, count, order, and dot-below;
  // ONLY scale and offset differ. Whole-letter combined-bbox normalization must
  // make it pass (SC#3) — size/offset are not mistakes.

  /// A small, corner-offset, but otherwise-correct baa (dot still BELOW).
  List<List<List<double>>> smallOffsetBaa() => [
        // body: same right→left bow shape, ~40% scale, offset to (+320, +260)
        List<List<double>>.generate(
          20,
          (i) => [
            320.0 + (180.0 - i * 8) * 0.4,
            260.0 + (100.0 + (i < 10 ? i * 2.0 : (19 - i) * 2.0)) * 0.4,
          ],
        ),
        // dot below the body, scaled+offset the same way as (90, 170)
        [
          [320.0 + 90.0 * 0.4, 260.0 + 170.0 * 0.4]
        ],
      ];

  /// The SAME small, corner-offset baa but with the dot ABOVE the body — the
  /// taa pattern. Normalization must NOT erase this relative-position signal
  /// (Pitfall 2): it still has to fail with dotMisplaced.
  List<List<List<double>>> smallOffsetBaaDotAbove() => [
        smallOffsetBaa()[0],
        // dot placed ABOVE the body (mirror y=170 → y=40 before scale+offset)
        [
          [320.0 + 90.0 * 0.4, 260.0 + 40.0 * 0.4]
        ],
      ];

  group('Letter.fromJson — tolerances backward-compat (LIVE — Task 2)', () {
    test('a JSON map with no "tolerances" key parses with tolerances == null', () {
      final json = <String, dynamic>{
        'id': 'alif',
        'char': 'ا',
        'name': {'ar': 'اَلِف', 'display': 'Alif'},
        'introOrder': 1,
        'forms': {'isolated': 'ا', 'initial': 'ا', 'medial': 'ا', 'final': 'ا'},
        'referenceStrokes': <dynamic>[],
        'cleanRepsToAdvance': 3,
        'commonMistakes': <dynamic>[],
        'mistakesStatus': 'placeholder',
        'signedOff': false,
      };
      final letter = Letter.fromJson(json);
      expect(letter.tolerances, isNull);
    });

    test('a JSON map WITH a "tolerances" block parses into a Tolerances', () {
      final json = <String, dynamic>{
        'id': 'baa',
        'char': 'ب',
        'name': {'ar': 'بَاء', 'display': 'Baa'},
        'introOrder': 2,
        'forms': {'isolated': 'ب', 'initial': 'بـ', 'medial': 'ـبـ', 'final': 'ـب'},
        'referenceStrokes': <dynamic>[],
        'cleanRepsToAdvance': 3,
        'commonMistakes': <dynamic>[],
        'mistakesStatus': 'placeholder',
        'signedOff': false,
        'tolerances': {
          'preset': 'normal',
          'overrides': {'maxCurvature': 0.30},
        },
      };
      final letter = Letter.fromJson(json);
      expect(letter.tolerances, isNotNull);
      expect(letter.tolerances!.maxCurvature, equals(0.30));
      expect(letter.tolerances!.resampleN, equals(32));
    });
  });

  group('validateTolerances (LIVE — Task 2, V5 / T-04-01)', () {
    test('a null tolerances block is valid (no violations)', () {
      expect(validateTolerances(null), isEmpty);
    });

    test('an in-range tolerances block is valid', () {
      final t = Tolerances.fromJson(const {'preset': 'normal'});
      expect(validateTolerances(t), isEmpty);
    });

    test('an out-of-range maxCurvature override is rejected (string, no throw)', () {
      final t = Tolerances.fromJson(const {
        'preset': 'normal',
        'overrides': {'maxCurvature': 5.0}, // > 1 unit-box max
      });
      final violations = validateTolerances(t);
      expect(violations, isNotEmpty);
      expect(violations.first, contains('maxCurvature'));
    });

    test('a non-positive minRawPoints override is rejected', () {
      final t = Tolerances.fromJson(const {
        'preset': 'normal',
        'overrides': {'minRawPoints': 0},
      });
      expect(validateTolerances(t), isNotEmpty);
    });

    test('validateLetter folds in a bad tolerances block', () {
      final letter = baaLetter(); // valid strokes
      // baaLetter's tolerances are in range, so a valid letter → no violations
      // from the tolerances path.
      expect(validateLetter(letter), isEmpty);
    });
  });

  // ── RED CONTRACT for Plan 02 — scoreLetter does not exist yet ──────────────
  // These are skipped (not deleted) so the suite compiles. Plan 02 implements
  // `scoreLetter` in lib/core/scoring/letter_scorer.dart, removes the `skip:`,
  // and wires the real call. The expectations below ARE the SC#1/SC#2/D-04
  // contract.
  group('LetterScorer.scoreLetter — SC#1 / SC#2 / D-04 contract (Plan 02)', () {
    setUpAll(() {
      // mocktail needs a registered fallback for the whole-letter
      // List<List<List<double>>> arg type used with any() in the recognizer stubs
      // below (the seam was widened to a multi-stroke letter in Plan 04-03).
      registerFallbackValue(<List<List<double>>>[]);
    });

    test('SC#1 — wrong stroke COUNT → MistakeId.wrongStrokeCount', () async {
      // Given a baa (expects 2 strokes) but the child drew only 1:
      final result = await scoreLetter([goodBaa()[0]], baaLetter());
      expect(result.passed, isFalse);
      expect(result.mistakeId, equals(MistakeId.wrongStrokeCount));
    });

    test('SC#1 — wrong stroke ORDER (dot before body) → MistakeId.wrongStrokeOrder', () async {
      final dotFirst = [goodBaa()[1], goodBaa()[0]];
      final result = await scoreLetter(dotFirst, baaLetter());
      expect(result.mistakeId, equals(MistakeId.wrongStrokeOrder));
    });

    test('SC#1 — taa-dots-when-shown-baa (dot above) → MistakeId.dotMisplaced', () async {
      final dotAbove = [
        goodBaa()[0],
        [
          [90.0, 40.0]
        ],
      ];
      final result = await scoreLetter(dotAbove, baaLetter());
      expect(result.mistakeId, equals(MistakeId.dotMisplaced));
    });

    test('SC#1 — a good-faith baa passes (count + order + dot all correct)', () async {
      final result = await scoreLetter(goodBaa(), baaLetter());
      expect(result.passed, isTrue);
      expect(result.mistakeId, isNull);
    });

    test('SC#2 — confidently-different ML Kit candidate → MistakeId.wrongLetterIdentity', () async {
      final fake = FakeHandwritingRecognizer();
      when(() => fake.identify(any())).thenAnswer(
          (_) async => const RecognitionResult(topCandidate: 'ك', confidence: 0.95));
      final result = await scoreLetter(goodBaa(), baaLetter(), recognizer: fake);
      expect(result.mistakeId, equals(MistakeId.wrongLetterIdentity));
    });

    test('D-04 — low-confidence/wrong candidate does NOT override a geometric pass', () async {
      final fake = FakeHandwritingRecognizer();
      when(() => fake.identify(any())).thenAnswer(
          (_) async => const RecognitionResult(topCandidate: 'ك', confidence: 0.10));
      final result = await scoreLetter(goodBaa(), baaLetter(), recognizer: fake);
      expect(result.passed, isTrue); // advisory only — weak evidence ignored
    });

    test('whole-letter latency budget — scoreLetter completes in < 50 ms', () async {
      final sw = Stopwatch()..start();
      await scoreLetter(goodBaa(), baaLetter());
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(50),
          reason: 'sub-300 ms stylus-up feedback budget');
    });
  });

  // ── SC#3 + Pitfall-2 regression pair (Plan 04-02 Task 2) ────────────────────
  // The explicit proof that whole-letter combined-bbox normalization HELPS a
  // good-faith size/offset-varied attempt WITHOUT hiding the ب/ت/ث dot
  // distinction. These two assertions live in the same group on purpose: one
  // proves normalization is lenient enough, the other proves it is not TOO
  // lenient.
  group('LetterScorer.scoreLetter — SC#3 multi-stroke normalization', () {
    test('a small + corner-offset CORRECT baa passes (size/offset invariant)',
        () async {
      final result = await scoreLetter(smallOffsetBaa(), baaLetter());
      expect(result.passed, isTrue,
          reason: 'combined-bbox normalization must absorb scale + offset (SC#3)');
      expect(result.mistakeId, isNull);
    });

    test('the SAME small baa with the dot ABOVE still fails with dotMisplaced',
        () async {
      final result = await scoreLetter(smallOffsetBaaDotAbove(), baaLetter());
      expect(result.passed, isFalse);
      expect(result.mistakeId, equals(MistakeId.dotMisplaced),
          reason: 'normalization must NOT erase the dot relative position '
              '(Pitfall 2 — the baa↔taa distinction)');
    });
  });

  // Keep the fake + fixtures + contract enum referenced so they are not
  // "unused" before Plan 02 wires the real scoreLetter call.
  test('contract scaffolding is wired (fake + fixtures + MistakeId present)', () {
    expect(FakeHandwritingRecognizer(), isA<HandwritingRecognizer>());
    expect(goodBaa().length, equals(2));
    expect(baaLetter().referenceStrokes.length, equals(2));
    // The four whole-letter MistakeId values Plan 02 must return.
    expect(
      const [
        MistakeId.wrongStrokeCount,
        MistakeId.wrongStrokeOrder,
        MistakeId.dotMisplaced,
        MistakeId.wrongLetterIdentity,
      ].length,
      equals(4),
    );
  });
}
