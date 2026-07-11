// Phase 18 — D-08 (the micro-drill's spotlighted criterion OWNS the verdict).
//
// A `type=='microDrill'` exercise is scored with the SAME glyph geometry scorer
// as any other formation exercise, but ONLY its spotlighted criterion decides
// pass/fail: the other four criteria are recorded as evidence and cannot fail the
// drill ("a dot drill never fails for a shaky bowl" — sketch 002 "Spotlight").
// The scorer still owns the criterion zones (ADR-017); this is a scorer-side
// re-weighting of an existing verdict, never an agent call.

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/exercise_engine/exercise_check.dart';
import 'package:qalam/core/exercise_engine/exercise_validator.dart';
import 'package:qalam/core/scoring/tolerances.dart';
import 'package:qalam/models/letter.dart';

void main() {
  // A real baa Letter (bowed body + dot below) for the glyph scorer — mirrors
  // test/core/exercise_engine/exercise_validator_test.dart's inline baa.
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

  // A good-faith baa body: a bowed line right→left (the same shape that passes
  // the full glyph check in exercise_validator_test.dart).
  List<List<double>> body() => List<List<double>>.generate(
        20,
        (i) => [180.0 - i * 8, 100.0 + (i < 10 ? i * 2.0 : (19 - i) * 2.0)],
      );
  List<List<double>> dotBelow() => [
        [90.0, 170.0],
      ]; // below the body (correct)
  List<List<double>> dotAbove() => [
        [90.0, 40.0],
      ]; // above the body (WRONG side)

  // The bowl drill: spotlights `shape` — the dot cannot fail it (D-08).
  ExerciseSpec bowlDrill() => const ExerciseSpec(
        id: 'baa.microDrill.bowl',
        type: 'microDrill',
        check: CheckSpec(base: 'glyph'),
        expected: AnswerSpec(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
        feedback: {'pass': 'Lovely bowl.', 'shallowBowl': 'Deeper curve.'},
        criteria: ['shape'],
      );

  // The start drill: spotlights `strokeOrder`.
  ExerciseSpec startDrill() => const ExerciseSpec(
        id: 'baa.microDrill.start',
        type: 'microDrill',
        check: CheckSpec(base: 'glyph'),
        expected: AnswerSpec(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
        feedback: {'pass': 'Right order.', 'wrongStart': 'Body first, then the dot.'},
        criteria: ['strokeOrder'],
      );

  // A NORMAL (non-drill) glyph exercise over the same geometry — every criterion
  // counts, so a dot on the wrong side fails it.
  ExerciseSpec plainGlyph() => const ExerciseSpec(
        id: 'baa.traceLetter.isolated',
        check: CheckSpec(base: 'glyph'),
        expected: AnswerSpec(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
        feedback: {'pass': 'Nice.', 'noDot': 'Add the dot below.', 'dotAbove': 'Dot goes below.'},
      );

  test('D-08: a bowl drill PASSES on a good bowl even when the DOT is misplaced '
      '(the non-spotlight criterion cannot fail the drill)', () async {
    final strokes = [body(), dotAbove()];

    // The same strokes fail the NORMAL glyph check (the misplaced dot is a real
    // miss) — proving the drill override is doing work, not trivially passing.
    final normal = await validateExercise(plainGlyph(), strokes, letter: baaLetter());
    expect(normal.passed, isFalse,
        reason: 'a dot on the wrong side is a genuine miss for a normal glyph');

    // The bowl drill spotlights `shape` → the good bowl passes; the dot is
    // recorded but cannot fail the drill (D-08).
    final drill = await validateExercise(bowlDrill(), strokes, letter: baaLetter());
    expect(drill.passed, isTrue,
        reason: 'D-08: the bowl drill passes because its spotlighted `shape` is good');
    // The other criteria are still RECORDED as evidence.
    expect(drill.criteria, isNotNull);
  });

  test('D-08: the drill FAILS when its OWN spotlighted criterion is certainly '
      'wrong (a strokeOrder drill on a reversed draw sequence)', () async {
    // Dot drawn FIRST, then the body → strokeOrder is certainly wrong.
    final reversed = [dotBelow(), body()];
    final drill = await validateExercise(startDrill(), reversed, letter: baaLetter());
    expect(drill.passed, isFalse,
        reason: 'D-08: the spotlighted `strokeOrder` owns the verdict — it failed');
    expect(startDrill().feedback.keys, contains(drill.mistakeId),
        reason: 'a drill miss still points at an AUTHORED feedback key');
  });

  test('a bowl drill PASSES on a clean baa (dot below, good bowl)', () async {
    final drill = await validateExercise(
      bowlDrill(),
      [body(), dotBelow()],
      letter: baaLetter(),
    );
    expect(drill.passed, isTrue);
    expect(drill.mistakeId, isNull);
  });

  test('spotlightCriterion is null for a normal exercise, set for a microDrill', () {
    expect(plainGlyph().spotlightCriterion, isNull);
    expect(bowlDrill().spotlightCriterion, 'shape');
    expect(startDrill().spotlightCriterion, 'strokeOrder');
  });

  // 18-07 Task 3: a base=='order' (buildSentence) exercise is now PASSABLE — the
  // recogniser's whitespace-split transcription flows in as writtenWords (wired in
  // write_surface.dart). Before this the order check received writtenWords==null
  // and FAILED unconditionally — a dead end the selector could route a child into.
  group('base: order (buildSentence) is passable with recogniser output', () {
    const buildSentence = ExerciseSpec(
      id: 'baa.buildSentence.hear',
      check: CheckSpec(base: 'order'),
      expected: AnswerSpec(words: ['البابُ', 'كبير']),
      feedback: {'pass': 'Nice sentence.', 'wrongOrder': 'Check the order.'},
    );

    test('a correct word order → passed=true', () async {
      final r = await validateExercise(
        buildSentence,
        const [],
        writtenWords: const ['البابُ', 'كبير'],
      );
      expect(r.passed, isTrue,
          reason: 'the ordered words match expected.words → the sentence passes');
    });

    test('a re-ordered sentence → a "wrongOrder" miss (not a blind pass)', () async {
      final r = await validateExercise(
        buildSentence,
        const [],
        writtenWords: const ['كبير', 'البابُ'],
      );
      expect(r.passed, isFalse);
      expect(r.mistakeId, 'wrongOrder');
    });
  });
}
