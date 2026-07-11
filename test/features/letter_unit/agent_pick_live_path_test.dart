// Phase 18-07 — THE LIVE-PATH PROOF (closes the Phase-15 dead wire).
//
// Phase 15 shipped "dynamic selection" as DEAD CODE: the coach's TutorDecision
// landed in the scaffold but was only DISPLAYED, while the screen's selection call
// carried NO decision — so RouterExerciseSelector's agent-accept branch never ran
// on the live path. Unit tests on the selector/controller alone CANNOT catch that
// (that is exactly how it shipped dead). This test PUMPS the real ExerciseScaffold,
// drives a scored attempt through the SAME seam the canvas fires (WriteSurface.
// onResult == the scaffold's _onResult), stubs the brain to return a LEGAL pick
// that DIFFERS from the walker's, and asserts the durable cursor the child
// actually advances to IS the agent's pick — and, for an ILLEGAL pick, the
// walker's deterministic choice.
//
// Pure widget test: no Firebase (childModelProvider overridden empty), no network,
// an in-memory Drift db, the single-source graph loaded off disk.

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
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

// The node the child is ON at the start of the moment.
const _current = 'baa.traceLetter.isolated'; // positionalForms, tier null
// A LEGAL candidate that is NOT the walker's forward pick (which is
// baa.traceLetter.initial, the first forward node).
const _agentLegalPick = 'baa.writeLetter.fromSound'; // positionalForms, legal
// The walker's deterministic forward pick from _current on a pass.
const _walkerForward = 'baa.traceLetter.initial';
// An ILLEGAL proposal (copyWrite needs positionalForms cleared — it is NOT).
const _agentIllegalPick = 'baa.writeWord.dictation';

CurriculumGraph _loadGraph() {
  final raw = json.decode(
    File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return CurriculumGraph.fromJson(raw);
}

/// A brain that returns a coaching line PLUS a next-exercise plan proposing [pick].
class _PickBrain implements TutorBrain {
  _PickBrain(this.pick);
  final String pick;

  @override
  Future<TutorDecision> next(TutorFacts facts) async => PresentActivity(
        coachingLine: 'Nice work — keep going.',
        letterId: 'baa',
        plan: TutorPlan(nextExerciseId: pick),
      );
}

/// The durable resume cursor seeded so the child is ON _current with `recognize`
/// cleared (so the positionalForms alternatives are legal candidates).
class _SeededPositionRepo implements GraphPositionRepository {
  GraphPosition _pos = const GraphPosition(
    letterId: 'baa',
    currentExerciseId: _current,
    clearedCompetencies: ['recognize'],
    clearedTiers: [],
  );

  @override
  Future<GraphPosition?> getPosition(String letterId) async => _pos;

  @override
  Future<void> setPosition(GraphPosition position) async => _pos = position;
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

Exercise _graded() => const Exercise(
      id: 'baa.traceLetter.isolated',
      type: 'traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace baa.')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'Beautiful.', 'shallowBowl': 'Deeper curve.'},
      signedOff: false,
    );

/// Pump the scaffold with a STARTED controller (total 6, the seeded position), the
/// real graph, the [brain] stub, an in-memory db, and an empty profile mirror.
/// Returns the started controller so the test can read its durable cursor.
Future<LetterUnitController> _pumpStarted(
  WidgetTester tester, {
  required TutorBrain brain,
}) async {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider
            .overrideWithValue(_SeededPositionRepo()),
        curriculumGraphProvider.overrideWith((ref) async => _loadGraph()),
        // No Firebase in a widget test — the profile mirror is an empty snapshot.
        childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> feedback) => brain),
        ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ExerciseScaffold(
            exercise: _graded(),
            letter: _baa(),
            graphExerciseId: _current,
          ),
        ),
      ),
    ),
  );
  container = ProviderScope.containerOf(
    tester.element(find.byType(ExerciseScaffold)),
  );
  // Start the unit controller (the screen normally does this) so selection runs.
  final controller =
      container.read(letterUnitControllerProvider('baa').notifier);
  await controller.start(letterId: 'baa', total: 6);
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('the agent\'s LEGAL pick (≠ the walker\'s) is what the child '
      'advances to — the dead wire is closed', (tester) async {
    final controller =
        await _pumpStarted(tester, brain: _PickBrain(_agentLegalPick));

    // Sanity: the seeded cursor is _current before the attempt.
    expect(controller.state.currentExerciseId, _current);

    // Drive a scored PASS through the public seam (== the canvas completion path).
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle(); // brain resolves → selection threads the decision

    // The durable cursor the child ACTUALLY advances to is the AGENT's pick —
    // NOT the walker's forward default. This is the Phase-15 dead wire, closed.
    expect(controller.state.currentExerciseId, _agentLegalPick,
        reason: 'the coach decision reached the selector on the LIVE path');
    expect(controller.state.currentExerciseId, isNot(_walkerForward));
  });

  testWidgets('an ILLEGAL agent pick degrades to the walker\'s deterministic '
      'choice — the rail holds on the live path (R5)', (tester) async {
    final controller =
        await _pumpStarted(tester, brain: _PickBrain(_agentIllegalPick));

    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle();

    // The illegal proposal was rejected — the child advances to the walker's pick.
    expect(controller.state.currentExerciseId, _walkerForward,
        reason: 'an out-of-rail agent pick never reaches the child (R5)');
    expect(controller.state.currentExerciseId, isNot(_agentIllegalPick));
  });
}
