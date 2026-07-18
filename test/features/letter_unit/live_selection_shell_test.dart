// Phase 18-07 Task 3 — the shell's selection-mode contract:
//   • the ribbon is DISPLAY-ONLY while the presenter drives (a tap must not fight
//     the selection override);
//   • graph exhausted (selectNext → null) routes to the Mastery section, where the
//     quiet star stays reachable via the NEW selection-driven path.
//
// Pure widget test: no Firebase, no network, in-memory Drift, graph off disk / a
// minimal in-memory graph for the exhaustion case.

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
import 'package:qalam/features/letter_unit/sections/mastery_section.dart';
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

CurriculumGraph _fullGraph() => CurriculumGraph.fromJson(
      json.decode(
        File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
      ) as Map<String, Object?>,
    );

/// A single-node graph — any pass EXHAUSTS it (no legal forward node), so the
/// selection returns null and the shell must route to Mastery.
CurriculumGraph _oneNodeGraph() => CurriculumGraph.fromJson(<String, Object?>{
      'letterId': 'baa',
      'signedOff': true,
      'tiers': ['manqul', 'manzur', 'ghayrManzur'],
      'competencies': [
        {'id': 'positionalForms', 'essential': true, 'prerequisites': <String>[]},
      ],
      'nodes': [
        {
          'exerciseId': _start,
          'competency': 'positionalForms',
          'tier': null,
          'minCleanReps': 1,
        },
      ],
    });

class _LineOnlyBrain implements TutorBrain {
  @override
  Future<TutorDecision> next(TutorFacts facts) async => const Say('Nice.');
}

class _SeededPositionRepo implements GraphPositionRepository {
  GraphPosition _pos = const GraphPosition(
    childProfileId: 0,
    letterId: 'baa',
    currentExerciseId: _start,
    clearedCompetencies: ['recognize'],
    clearedTiers: [],
  );
  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      _pos;
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
          UnitSection(id: 'watchTrace', exercises: [_start]),
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
            feedback: const {'pass': 'Beautiful.'},
            signedOff: false,
          ),
        ])
          e.id: e,
      },
      words: const [],
    );

Future<void> _pumpAndEnterTrace(
  WidgetTester tester, {
  required CurriculumGraph graph,
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
        curriculumGraphProvider.overrideWith((ref) async => graph),
        childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
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
  // 18-15: a seeded real-node cursor now RESUMES straight into the presenter
  // (selection mode), so the trace WriteSurface is already on screen — the legacy
  // Watch&Trace "I'll try" gate is bypassed. Guarded so the helper still works for
  // any setup that routes through the legacy watch-first step.
  if (find.text("I'll try").evaluate().isNotEmpty) {
    await tester.tap(find.text("I'll try"));
    await tester.pumpAndSettle();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('the ribbon is DISPLAY-ONLY once selection drives — a dot tap does '
      'not change the presented exercise', (tester) async {
    await _pumpAndEnterTrace(tester, graph: _fullGraph());
    // PASS → advance INTO the presenter (the selector picks the next node).
    tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(
          const CheckResult.pass(),
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();

    // Whatever the presenter is showing now, a ribbon-dot tap must NOT swap it.
    final presented = find
        .byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('graph:'))
        .evaluate()
        .map((e) => (e.widget.key as ValueKey<String>).value)
        .toSet();
    expect(presented, isNotEmpty);

    await tester.tap(find.byKey(const ValueKey('unitRibbonDot:0')));
    await tester.pumpAndSettle();

    final afterTap = find
        .byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('graph:'))
        .evaluate()
        .map((e) => (e.widget.key as ValueKey<String>).value)
        .toSet();
    expect(afterTap, presented,
        reason: 'in selection mode the ribbon is display-only (goTo would fight '
            'the presenter override)');
    // Still NOT the legacy Meet section (the ribbon tap did not jump sections).
    expect(find.byType(MasterySection), findsNothing);
  });

  testWidgets('graph exhausted (selectNext → null) routes to the Mastery section — '
      'the star stays reachable via the selection-driven path', (tester) async {
    // A single-node graph: the first pass exhausts it → the selection returns null.
    await _pumpAndEnterTrace(tester, graph: _oneNodeGraph());

    tester.widget<WriteSurface>(find.byType(WriteSurface)).onResult!(
          const CheckResult.pass(),
        );
    await tester.pumpAndSettle();
    // The pass CTA advances — with the graph exhausted the shell routes to Mastery.
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();

    expect(find.byType(MasterySection), findsOneWidget,
        reason: 'a null selection (graph exhausted) routes to Mastery, where '
            '_recordMasteryIfMet fires — the star stays reachable');
  });
}
