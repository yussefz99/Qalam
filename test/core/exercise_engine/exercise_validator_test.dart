import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/core/exercise_engine/exercise_check.dart';
import 'package:qalam/core/exercise_engine/exercise_validator.dart';
import 'package:qalam/core/scoring/tolerances.dart';
import 'package:qalam/models/letter.dart';

/// Plan 07-03 — the validator contract, pinned RED first.
///
/// `validateExercise(exercise, strokes, {letter})` must turn a child's strokes
/// into a pass-or-specific-fix [CheckResult] for EVERY baa question type, all
/// data-driven from the exercise config, REUSING the Phase-4 geometric scorer
/// for the glyph case (COMPONENT-SYSTEM.md §6 / SCHEMA-V2.md §3).
///
/// Every fail-case assertion below checks a mistakeId that is an ACTUAL key in
/// the corresponding EXERCISE-CONFIGS.json `feedback` map — no invented ids —
/// so the contract stays honest against the authored content.
///
/// Test groups cover all three bases (glyph / sequence / order) and all three
/// modifiers (positionalForm / joinContinuity / transformRule).

void main() {
  // ── Load the real 19 baa configs as validator-facing ExerciseSpec views ────
  final configs = _loadConfigs();
  ExerciseSpec spec(String id) => ExerciseSpec.fromJson(configs[id]!);

  // ── A real baa Letter (body line + dot below) for the glyph scorer ──────────
  // Mirrors test/core/scoring/letter_scorer_test.dart's inline baa.
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
          [0.5, 0.8],
        ],
      ),
    ],
    cleanRepsToAdvance: 3,
    commonMistakes: [],
    mistakesStatus: 'authored',
    signedOff: false,
    tolerances: Tolerances(minRawPoints: 10, resampleN: 32, maxCurvature: 0.30),
  );

  // ── Synthetic captures (pixel-space, per stroke → per [x,y] point) ──────────

  /// A good-faith baa: a bowed body right→left, then a dot below.
  List<List<List<double>>> goodBaa() => [
    List<List<double>>.generate(
      20,
      (i) => [180.0 - i * 8, 100.0 + (i < 10 ? i * 2.0 : (19 - i) * 2.0)],
    ),
    const [
      [90.0, 170.0],
    ],
  ];

  /// A baa missing its dot — only the body stroke (wrong stroke count).
  List<List<List<double>>> baaNoDot() => [goodBaa()[0]];

  group('CheckResult contract', () {
    test('pass result carries no mistakeId', () {
      const r = CheckResult.pass();
      expect(r.passed, isTrue);
      expect(r.mistakeId, isNull);
    });

    test('fail result carries the matched mistakeId', () {
      const r = CheckResult.fail('shallowBowl');
      expect(r.passed, isFalse);
      expect(r.mistakeId, 'shallowBowl');
    });
  });

  group('base: glyph', () {
    test('good strokes on baa.traceLetter.isolated pass', () async {
      final r = await validateExercise(
        spec('baa.traceLetter.isolated'),
        goodBaa(),
        letter: baaLetter(),
      );
      expect(r.passed, isTrue);
      expect(r.mistakeId, isNull);
    });

    test('a miss returns an authored feedback key (not pass)', () async {
      final s = spec('baa.traceLetter.isolated');
      final r = await validateExercise(s, baaNoDot(), letter: baaLetter());
      expect(r.passed, isFalse);
      // mistakeId MUST be one of the exercise's authored feedback keys.
      expect(s.feedback.keys, contains(r.mistakeId));
      expect(r.mistakeId, isNot('pass'));
    });
  });

  group('modifier: positionalForm', () {
    test('baa.traceLetter.initial carries the positionalForm modifier', () {
      expect(spec('baa.traceLetter.initial').check!.hasPositionalForm, isTrue);
    });

    test('wrong contextual form flags an authored key', () async {
      // A correctly-traced glyph whose form does not match expected.form.
      final s = spec('baa.writeLetter.writeForm'); // expects form "initial"
      final r = await validateExercise(
        s,
        goodBaa(),
        letter: baaLetter(),
        writtenForm: 'isolated', // wrong contextual form
      );
      expect(r.passed, isFalse);
      expect(s.feedback.keys, contains(r.mistakeId));
    });
  });

  group('base: sequence', () {
    test('baa.writeWord.dictation validates the word باب in order', () async {
      final s = spec('baa.writeWord.dictation');
      expect(s.check!.base, 'sequence');
      // A missing/wrong letter glyph fails with an authored key (e.g. missingDot).
      final r = await validateExercise(
        s,
        baaNoDot(),
        letter: baaLetter(),
        writtenWord: 'بب', // missing the alif → wrong sequence
      );
      expect(r.passed, isFalse);
      expect(s.feedback.keys, contains(r.mistakeId));
    });
  });

  group('modifier: joinContinuity', () {
    test('baa.connectWord.baab carries the joinContinuity modifier', () {
      expect(spec('baa.connectWord.baab').check!.hasJoinContinuity, isTrue);
    });

    test('lifted pen between letters flags "lifted"', () async {
      final s = spec('baa.connectWord.baab');
      // Strokes lifted between every letter (each letter its own stroke run)
      // instead of one connected run.
      final r = await validateExercise(
        s,
        goodBaa(),
        letter: baaLetter(),
        writtenWord: 'باب',
        penLiftedBetweenLetters: true,
      );
      expect(r.passed, isFalse);
      expect(r.mistakeId, 'lifted');
    });
  });

  group('base: order', () {
    test('baa.buildSentence.hear validates word order', () async {
      final s = spec('baa.buildSentence.hear');
      expect(s.check!.base, 'order');
      final r = await validateExercise(
        s,
        const [],
        letter: baaLetter(),
        writtenWords: const ['كبير', 'البابُ'], // out of order
      );
      expect(r.passed, isFalse);
      expect(r.mistakeId, 'wrongOrder');
    });
  });

  group('modifier: transformRule', () {
    test('baa.transformWord.dual carries the transformRule modifier', () {
      expect(spec('baa.transformWord.dual').check!.hasTransformRule, isTrue);
    });

    test('missing dual ending flags an authored key', () async {
      final s = spec('baa.transformWord.dual'); // expects "بابان"
      final r = await validateExercise(
        s,
        const [],
        letter: baaLetter(),
        writtenWord: 'باب', // the base, not the dual
      );
      expect(r.passed, isFalse);
      expect(s.feedback.keys, contains(r.mistakeId));
    });
  });
}

/// Loads EXERCISE-CONFIGS.json and indexes the 19 baa configs by id.
Map<String, Map<String, dynamic>> _loadConfigs() {
  final file = File(
    'docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json',
  );
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final exercises = decoded['exercises'] as List<dynamic>;
  return {
    for (final e in exercises)
      (e as Map<String, dynamic>)['id'] as String: e,
  };
}
