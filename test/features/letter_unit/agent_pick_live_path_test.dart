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
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/word.dart';
import 'package:qalam/providers/audio_providers.dart';
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

  // ── The FULL-SCREEN RENDER proof (Task 3): what LOADS next is the pick ────────

  group('the shell RENDERS the selection (not only the cursor)', () {
    testWidgets('the agent\'s legal pick is the exercise the child sees next',
        (tester) async {
      await _pumpScreen(tester, brain: _PickBrain(_agentLegalPick));
      await _traceAndAdvance(tester);

      // The presenter now renders the AGENT's pick — a fresh graph:<id>#<epoch>
      // scaffold (18-12: the epoch-tolerant finder tracks WHICH node renders).
      expect(_graphNode(_agentLegalPick), findsOneWidget,
          reason: 'the selection is RENDERED — the Phase-15 dead wire is closed '
              'end-to-end, not just at the cursor');
      expect(_graphNode(_walkerForward), findsNothing);
    });

    testWidgets('an illegal pick renders the walker\'s choice instead',
        (tester) async {
      await _pumpScreen(tester, brain: _PickBrain(_agentIllegalPick));
      await _traceAndAdvance(tester);

      expect(_graphNode(_walkerForward), findsOneWidget,
          reason: 'an out-of-rail pick never renders — the rail holds on screen');
    });
  });
}

// ── full-screen harness ────────────────────────────────────────────────────────

/// Find the presented graph node by [id], tolerant of the 18-12 presentation
/// epoch suffix (`graph:<id>#<epoch>`) so the assertion tracks WHICH node renders,
/// not its epoch.
Finder _graphNode(String id) => find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> &&
          (k.value == 'graph:$id' || k.value.startsWith('graph:$id#'));
    });

class _CapturingAudioPlayer implements LetterAudioPlayer {
  @override
  Future<void> playLetter(String assetPath) async {}
}

/// The baa unit's 6 sections + the isolated-trace exercise (mirrors
/// letter_unit_screen_test._baaData).
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
            id: 'baa.traceLetter.isolated',
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

/// Pump the FULL LetterUnitScreen seeded so the child resumes on Watch&Trace with
/// `recognize` cleared (positionalForms alternatives legal), with [brain] stubbed.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required TutorBrain brain,
}) async {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider.overrideWithValue(_SeededPositionRepo()),
        curriculumGraphProvider.overrideWith((ref) async => _loadGraph()),
        childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
        letterUnitDataProvider('baa').overrideWith((ref) async => _baaData()),
        audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> feedback) => brain),
        ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
      ],
      child: const MaterialApp(home: LetterUnitScreen(letterId: 'baa')),
    ),
  );
  await tester.pumpAndSettle();
}

/// Enter the trace phase, drive a scored PASS, then tap Next — the pass/continue
/// CTA that swaps the shell to the selected node.
Future<void> _traceAndAdvance(WidgetTester tester) async {
  // Watch&Trace opens on the Watch phase — tap "I'll try" to reveal the surface.
  await tester.tap(find.text("I'll try"));
  await tester.pumpAndSettle();

  final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
  ws.onResult!(const CheckResult.pass());
  await tester.pumpAndSettle(); // brain resolves → selectNext threads the decision

  // The pass CTA — swaps the shell to the presenter (awaits nextReady).
  await tester.tap(find.text('Next exercise'));
  await tester.pumpAndSettle();
}
