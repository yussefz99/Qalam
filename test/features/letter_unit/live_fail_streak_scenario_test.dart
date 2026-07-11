// Phase 18-07 Task 3 — the END-TO-END composition proof (fail-streak → arc).
//
// 18-04's policy tests prove the anti-boredom / arc logic in isolation; Tasks 1–2
// prove the wire; Task 3 proves the RENDER. THIS test closes the compositional gap
// between them: it drives TWO same-criterion fails through the LIVE screen and
// asserts the child is NOT shown the identical exercise a third time — the
// anti-boredom rule (R1) manifests on screen, not just in a unit test. This is the
// exact class of bug Phase 15 shipped (a perfect selection that changed nothing).
//
// Pure widget test: no Firebase, no network, an in-memory Drift db, graph off disk.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/providers/audio_providers.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

const _start = 'baa.traceLetter.isolated';
const _failNode = 'baa.traceLetter.initial'; // the walker pick after the 1st pass

CurriculumGraph _loadGraph() {
  final raw = json.decode(
    File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return CurriculumGraph.fromJson(raw);
}

/// A brain with a coaching line but NO next-exercise plan — the offline walker /
/// policy drives selection (the arc is a client-side, offline-parity behavior).
class _LineOnlyBrain implements TutorBrain {
  @override
  Future<TutorDecision> next(TutorFacts facts) async =>
      const Say('Deeper curve — try again, slower.');
}

class _SeededPositionRepo implements GraphPositionRepository {
  GraphPosition _pos = const GraphPosition(
    letterId: 'baa',
    currentExerciseId: _start,
    clearedCompetencies: ['recognize'],
    clearedTiers: [],
  );
  @override
  Future<GraphPosition?> getPosition(String letterId) async => _pos;
  @override
  Future<void> setPosition(GraphPosition position) async => _pos = position;
}

class _CapturingAudioPlayer implements LetterAudioPlayer {
  @override
  Future<void> playLetter(String assetPath) async {}
}

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

LetterUnitData _baaData() => LetterUnitData(
      unit: const LetterUnit(
        letterId: 'baa',
        sections: [
          UnitSection(id: 'meet', exercises: ['baa.teachCard.meet']),
          UnitSection(id: 'watchTrace', exercises: ['baa.traceLetter.isolated']),
          UnitSection(id: 'forms', exercises: ['baa.traceLetter.initial']),
          UnitSection(id: 'words', exercises: ['baa.connectWord.baab']),
          UnitSection(id: 'listenWrite', exercises: ['baa.writeWord.dictation']),
          UnitSection(id: 'mastery', exercises: []),
        ],
      ),
      letter: _baa(),
      exercises: {
        for (final e in [
          Exercise(
            id: _start,
            type: 'traceLetter',
            skill: 'formation',
            prompt: const [SayPart('Trace baa.')],
            surface: const Surface(
                mode: 'trace', unit: 'glyph', guideForm: 'isolated', demo: true),
            expected: const Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
            check: const Check(base: 'glyph'),
            feedback: const {'pass': 'Beautiful.', 'shallowBowl': 'Deeper curve.'},
            signedOff: false,
          ),
        ])
          e.id: e,
      },
      words: const [],
    );

/// A fail on the shape criterion (the bowl geometry) — carries the weakest
/// criterion so the policy counts a SAME-criterion streak.
CheckResult _shapeFail() => const CheckResult.fail(
      'shallowBowl',
      weakestCriterion: 'shape',
      criteria: [
        {'criterion': 'shape', 'zone': 'certainlyWrong', 'score': 0.0},
      ],
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('two same-criterion fails on the LIVE screen → the child is NOT '
      'shown the identical exercise a third time (anti-boredom renders)',
      (tester) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          graphPositionRepositoryProvider
              .overrideWithValue(_SeededPositionRepo()),
          curriculumGraphProvider.overrideWith((ref) async => _loadGraph()),
          childModelProvider
              .overrideWith((ref) async => ChildModelSnapshot.empty()),
          letterUnitDataProvider('baa').overrideWith((ref) async => _baaData()),
          audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
          tutorBrainFactoryProvider
              .overrideWithValue((Map<String, String> f) => _LineOnlyBrain()),
          ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
        ],
        child: const MaterialApp(home: LetterUnitScreen(letterId: 'baa')),
      ),
    );
    await tester.pumpAndSettle();

    // Enter the trace phase, PASS once → advance INTO the presenter on _failNode.
    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();
    tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(
          const CheckResult.pass(),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('graph:$_failNode')), findsOneWidget,
        reason: 'the presenter drives after the first pass');

    // FAIL the same criterion (shape) TWICE on the presented node.
    for (var i = 0; i < 2; i++) {
      tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(_shapeFail());
      await tester.pumpAndSettle();
    }
    // Continue (the fix CTA advances to the SELECTED node in selection mode).
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    // The THIRD render is NOT the identical failed exercise — anti-boredom (R1)
    // manifested end-to-end on the live screen (the compositional proof).
    expect(find.byKey(const ValueKey('graph:$_failNode')), findsNothing,
        reason: 'a child who fails the same criterion twice never sees the '
            'identical exercise a third time — RENDERED, not just selected');
    // …and the child is on SOME other graph node (a live remediation, never a
    // null dead-end).
    expect(
      find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('graph:')),
      findsWidgets,
      reason: 'the selector routed the child to a real graph node',
    );
  });
}
