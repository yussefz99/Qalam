// Phase 18-07 Task 3 — the exercise PRESENTER renders any graph node (the seam
// that makes the unit visibly dynamic). `presentGraphExercise` must render EVERY
// config family the baa graph contains through the SAME ExerciseScaffold (never
// new UI), keyed `graph:<id>#<epoch>` so each PRESENTATION gets a fresh scaffold
// (18-12: the epoch defaults to 0 here — the presenter is called directly with no
// re-present). This test pumps one node of each family and asserts it renders
// without throwing.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/features/letter_unit/exercise_presenter.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';

Letter _baa() {
  const body = StrokeSpec(
    order: 1,
    label: 'boat',
    type: 'curve',
    points: [
      [0.2, 0.4],
      [0.5, 0.6],
      [0.8, 0.4],
    ],
    direction: 'rightToLeft',
  );
  const dot = StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    points: [
      [0.5, 0.75],
    ],
    direction: 'none',
  );
  return Letter(
    id: 'baa',
    char: 'ب',
    name: const LetterName(ar: 'باء', display: 'baa'),
    introOrder: 2,
    forms: const LetterForms(
        isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
    referenceStrokes: const [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: const [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: const {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

// One config of each family the presenter must render (surface + check shapes).
Exercise _teachCard() => const Exercise(
      id: 'baa.teachCard.meet',
      type: 'teachCard',
      skill: 'comprehension',
      prompt: [SayPart('Meet baa.')],
      signedOff: false,
    );
Exercise _glyph(String id, String type, String form) => Exercise(
      id: id,
      type: type,
      skill: 'formation',
      prompt: const [SayPart('Write baa.')],
      surface: Surface(mode: 'write', unit: 'glyph', guideForm: form),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: form)),
      check: const Check(base: 'glyph'),
      feedback: const {'pass': 'Good.'},
      signedOff: false,
    );
Exercise _seq(String id, String type) => Exercise(
      id: id,
      type: type,
      skill: 'spelling',
      prompt: const [SayPart('Write the word.')],
      surface: const Surface(mode: 'write', unit: 'word'),
      expected: const Answer(word: WordAnswer('باب')),
      check: const Check(base: 'sequence'),
      feedback: const {'pass': 'Good.'},
      signedOff: false,
    );
Exercise _order(String id) => Exercise(
      id: id,
      type: 'buildSentence',
      skill: 'syntax',
      prompt: const [SayPart('Build the sentence.')],
      surface: const Surface(mode: 'write', unit: 'word'),
      expected: const Answer(words: ['البابُ', 'كبير']),
      check: const Check(base: 'order'),
      feedback: const {'pass': 'Good.', 'wrongOrder': 'Reorder.'},
      signedOff: false,
    );
Exercise _microDrill() => const Exercise(
      id: 'baa.microDrill.bowl',
      type: 'microDrill',
      skill: 'formation',
      prompt: [SayPart('Just the bowl.')],
      surface: Surface(mode: 'write', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'Good.'},
      criteria: ['shape'],
      signedOff: false,
    );

LetterUnitData _data(List<Exercise> ex) => LetterUnitData(
      unit: const LetterUnit(letterId: 'baa', sections: []),
      letter: _baa(),
      exercises: {for (final e in ex) e.id: e},
      words: const [],
    );

Future<void> _pump(WidgetTester tester, LetterUnitData data, String id) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: presentGraphExercise(
            data: data,
            exerciseId: id,
            onNodeResult: (_) {},
            onNext: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders one node of every config family the graph contains '
      'without throwing (teachCard, traceLetter, connectWord, completeWord, '
      'writeWord, writeLetter, buildSentence, fillBlank, transformWord, microDrill)',
      (tester) async {
    final families = <String, Exercise>{
      'baa.teachCard.meet': _teachCard(),
      'baa.traceLetter.isolated': _glyph('baa.traceLetter.isolated', 'traceLetter', 'isolated'),
      'baa.writeLetter.fromSound': _glyph('baa.writeLetter.fromSound', 'writeLetter', 'isolated'),
      'baa.connectWord.baab': _seq('baa.connectWord.baab', 'connectWord'),
      'baa.completeWord.middle': _seq('baa.completeWord.middle', 'completeWord'),
      'baa.writeWord.dictation': _seq('baa.writeWord.dictation', 'writeWord'),
      'baa.buildSentence.hear': _order('baa.buildSentence.hear'),
      'baa.fillBlank.adjective': _seq('baa.fillBlank.adjective', 'fillBlank'),
      'baa.transformWord.dual': _seq('baa.transformWord.dual', 'transformWord'),
      'baa.microDrill.bowl': _microDrill(),
    };

    for (final entry in families.entries) {
      final data = _data([entry.value]);
      await _pump(tester, data, entry.key);
      // The node rendered, keyed graph:<id>#<epoch> (a fresh scaffold per node;
      // the presenter defaults presentEpoch to 0 when called directly — 18-12).
      expect(find.byKey(ValueKey('graph:${entry.key}#0')), findsOneWidget,
          reason: '${entry.key} must render through the presenter');
    }
  });

  testWidgets('a missing config falls back to a navigable surface (never a crash)',
      (tester) async {
    // No exercises supplied → the presenter builds a calm fallback per id.
    await _pump(tester, _data(const []), 'baa.writeLetter.fromSound');
    expect(find.byKey(const ValueKey('graph:baa.writeLetter.fromSound#0')),
        findsOneWidget);
    expect(find.byType(ExerciseScaffold), findsOneWidget);
  });
}
