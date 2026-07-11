// Phase 18-07 — selection runs on the FAIL feedback moment (not only on a pass).
//
// The Phase-15 wire ran selection ONLY inside the pass-only `_onNodePassed` path,
// so a FAIL never reached the selector from the live screen — a fail could not
// enter the arc / trigger remediation. This test drives a FAILED scored attempt
// through the LIVE scaffold seam (WriteSurface.onResult) and asserts that (a) the
// controller's criterion-tagged session store gained the failed attempt, and
// (b) selection ran on the fail (the durable cursor moved to a remediation).
//
// Pure widget test: no Firebase, no network, an in-memory Drift db, the graph off
// disk.

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

const _current = 'baa.traceLetter.isolated';

CurriculumGraph _loadGraph() {
  final raw = json.decode(
    File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return CurriculumGraph.fromJson(raw);
}

/// A brain that answers with a coaching line but proposes NO next-exercise plan —
/// so the offline walker drives the fail-path remediation.
class _LineOnlyBrain implements TutorBrain {
  @override
  Future<TutorDecision> next(TutorFacts facts) async =>
      const Say('Deeper curve — try again, slower.');
}

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

Future<LetterUnitController> _pumpStarted(WidgetTester tester) async {
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
        tutorBrainFactoryProvider
            .overrideWithValue((Map<String, String> feedback) => _LineOnlyBrain()),
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
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ExerciseScaffold)),
  );
  final controller =
      container.read(letterUnitControllerProvider('baa').notifier);
  await controller.start(letterId: 'baa', total: 6);
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a FAILED scored attempt runs selection and appends to the '
      'criterion-tagged session store (the fail path is live)', (tester) async {
    final controller = await _pumpStarted(tester);

    // Before the attempt the session store is empty.
    expect(controller.sessionHistory(), isEmpty);

    // Drive a scored FAIL through the public seam (== the canvas completion path).
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.fail('shallowBowl'));
    await tester.pumpAndSettle();

    // The failed attempt was recorded in the CONTROLLER-owned session store — the
    // fail-streak source that survives scaffold key swaps (audit finding 1.4).
    expect(controller.sessionHistory().length, 1,
        reason: 'selection ran on the FAIL moment and appended the attempt');
    expect(controller.sessionHistory().single.passed, isFalse);
    expect(controller.sessionHistory().single.exerciseId, _current);

    // Selection ran (the pass-CTA await handle resolved) — a fail is not a dead end.
    expect(controller.nextReady(), isNotNull);
    final picked = await controller.nextReady()!;
    expect(picked, isNotNull,
        reason: 'a FAIL re-surfaces a remediation, never a null dead-end');
  });
}
