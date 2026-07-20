// Quick task 260720-up4 (Task 3) — THE baa LIVE-PATH mastery→advance PROOF.
//
// The regression this pins (both halves of the fix at once):
//   • Task 1 — the 14-node baa graph (the 4 reach-ahead grammar cards made
//     dormant) can actually be COMPLETED to the star; and
//   • Task 2 — _selectNext TERMINATES (returns null → routes to Mastery) the
//     moment presented-essential mastery is met, so the unit no longer "never
//     advances" (the walk used to re-offer every legal node forever, so
//     recordMasteryIfMet — which only fires on a null selection — never ran).
//
// It drives the REAL bundled baa graph (off disk, 14 nodes) through the REAL
// selection path — NOT a single-node graph (unlike live_selection_shell_test.dart)
// and WITHOUT calling controller.recordMasteryIfMet() directly (unlike
// mastery_progression_harness.dart). Instead it seeds the child's clean-reps to
// threshold for baa's essential core, mounts the real LetterUnitScreen, drives a
// scored PASS through the SAME seam the canvas fires (WriteSurface.onResult), and
// then taps the pass CTA — the SHELL's _advanceSelection routes to Mastery, whose
// post-frame _recordMasteryIfMet persists the row. The star + the taa advance are
// therefore proven END-TO-END through the routing, never a direct gate call.
//
// ── WHY exactly ONE testWidgets in this file (do not add a second) ────────────
// rootBundle asset fetches over the flutter/assets channel only complete reliably
// in the FIRST testWidgets of a process (the binding clears the asset cache between
// tests; a SECOND stalls forever on the identical load — verified 2026-07-18). So
// this file holds EXACTLY ONE live case, and the _awaitPumping dual-drain helper
// (copied from mastery_progression_harness.dart) bounds any rootBundle-touching
// await instead of the 10-minute wall.

import 'dart:async';
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
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/sections/mastery_section.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/providers/audio_providers.dart';
import 'package:qalam/providers/progression_providers.dart';
import 'package:qalam/providers/tts_providers.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/tutor/tutor_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_providers.dart';

// The presented essential node the child resumes ON (a legal isolated trace).
const _resumeNode = 'baa.traceLetter.isolated';

// baa's presented-essential set (units.json presentedEssentials) — handed to the
// controller by the screen. All are among the 14 essential graph nodes.
const _presented = <String>[
  'baa.teachCard.meet',
  'baa.traceLetter.isolated',
  'baa.traceLetter.initial',
  'baa.traceLetter.medial',
  'baa.traceLetter.final',
  'baa.connectWord.baab',
  'baa.writeWord.dictation',
  'baa.writeLetter.fromSound',
];

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The REAL bundled baa graph, parsed off disk (File, not rootBundle) — now 14
/// nodes after the 260720-up4 dormancy. This is the SAME graph the app ships.
CurriculumGraph _loadGraph() => CurriculumGraph.fromJson(
      _json('assets/curriculum/curriculum_graph.json').cast<String, Object?>(),
    );

/// The next letter after [letterId] by letters.json introOrder — computed from the
/// DATA (never a hardcoded successor), exactly the progression ladder's ordering.
String _nextByIntroOrder(String letterId) {
  final letters = (_json('assets/curriculum/letters.json')['letters'] as List)
      .cast<Map<String, dynamic>>();
  final sorted = [...letters]
    ..sort((a, b) => (a['introOrder'] as int).compareTo(b['introOrder'] as int));
  final index = sorted.indexWhere((l) => l['id'] == letterId);
  return sorted[index + 1]['id'] as String;
}

/// The durable cursor: the child is ON `_resumeNode` with `recognize` cleared, so
/// the screen resumes straight into the presenter (selection mode) on that node.
class _SeededPositionRepo implements GraphPositionRepository {
  GraphPosition _pos = const GraphPosition(
    childProfileId: kUnassignedChildProfileId,
    letterId: 'baa',
    currentExerciseId: _resumeNode,
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

/// A coach that returns a warm line but NO next-exercise plan — the selection
/// falls to the offline walker (irrelevant here: mastery-met terminates first).
class _LineOnlyBrain implements TutorBrain {
  @override
  Future<TutorDecision> next(TutorFacts facts) async => const Say('Nice.');
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

/// The baa unit shell data — 6 sections + the isolated-trace exercise (the resume
/// node the presenter renders). Carries `presentedEssentials` so the screen hands
/// the real presented set to the controller (the scored-hot-path source, Task 2).
LetterUnitData _baaData() => LetterUnitData(
      unit: const LetterUnit(
        letterId: 'baa',
        presentedEssentials: _presented,
        sections: [
          UnitSection(id: 'meet', exercises: ['baa.teachCard.meet']),
          UnitSection(id: 'watchTrace', exercises: [_resumeNode]),
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
            id: _resumeNode,
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

/// Await [future] while draining BOTH the real event loop (isolate asset decodes)
/// and the fake clock (timeouts). Copied from mastery_progression_harness.dart —
/// bounded so a genuine stall fails loudly instead of hitting the 10-minute wall.
Future<T> _awaitPumping<T>(
  WidgetTester tester,
  Future<T> future, {
  Duration budget = const Duration(seconds: 30),
  String what = 'future',
}) async {
  var settled = false;
  late T value;
  Object? error;
  StackTrace? stack;
  unawaited(future.then((v) {
    value = v;
    settled = true;
  }, onError: (Object e, StackTrace s) {
    error = e;
    stack = s;
    settled = true;
  }));
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 500);
  while (!settled && elapsed < budget) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(step);
    elapsed += step;
  }
  if (!settled) {
    fail('$what did not resolve within ${budget.inSeconds}s of pumped fake time '
        '+ drained real async — something in its chain is genuinely stuck');
  }
  if (error != null) {
    Error.throwWithStackTrace(error!, stack!);
  }
  return value;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
      'the real 14-node baa graph reaches the star through live selection and the '
      'journey advances to taa (Task 1 + Task 2, no direct recordMasteryIfMet)',
      (tester) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      graphPositionRepositoryProvider.overrideWithValue(_SeededPositionRepo()),
      // The REAL 14-node baa graph, off disk (no rootBundle stall).
      curriculumGraphProvider.overrideWith((ref, letterId) async => _loadGraph()),
      childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
      letterUnitDataProvider('baa').overrideWith((ref) async => _baaData()),
      audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
      tutorBrainFactoryProvider
          .overrideWithValue((Map<String, String> feedback) => _LineOnlyBrain()),
      ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
    ]);
    addTearDown(container.dispose);

    final progress = container.read(progressRepositoryProvider);
    final graph = _loadGraph();
    expect(graph.nodes, hasLength(14),
        reason: 'the bundled baa graph is 14 nodes after the 260720-up4 dormancy');
    expect(graph.essentialNodes, hasLength(14),
        reason: 'all 14 remaining baa nodes are essential (the 4 enrichment cards '
            'were made dormant)');

    // Realistic progression state: alif already MASTERED (so baa is today's letter),
    // and EVERY baa essential node seeded at its owner threshold — so the child has
    // genuinely completed baa's core and the FIRST scored moment finds mastery met.
    await progress.recordMastery(
      childProfileId: kUnassignedChildProfileId,
      letterId: 'alif',
      cleanReps: 3,
    );
    for (final node in graph.essentialNodes) {
      await db.setExerciseCleanReps(
        childProfileId: kUnassignedChildProfileId,
        letterId: 'baa',
        exerciseId: node.exerciseId,
        cleanReps: node.minCleanReps,
      );
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LetterUnitScreen(letterId: 'baa')),
      ),
    );
    await tester.pumpAndSettle();

    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);
    // The seeded cursor resumes straight into the presenter on the trace node.
    expect(controller.state.currentExerciseId, _resumeNode);
    if (find.text("I'll try").evaluate().isNotEmpty) {
      await tester.tap(find.text("I'll try"));
      await tester.pumpAndSettle();
    }

    // Drive a scored PASS through the LIVE seam (== the canvas completion path).
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle();

    // (a) SELECTION TERMINATED — mastery is met, so _selectNext returned null (the
    //     Task 2 routing invariant). Prove it via the controller's own nextReady
    //     future (the SAME future _advanceSelection awaits), NOT a direct gate call.
    final pending = controller.nextReady();
    expect(pending, isNotNull,
        reason: 'the scored moment set the in-flight selection future');
    final picked = await _awaitPumping(tester, pending!, what: 'nextReady(baa)');
    expect(picked, isNull,
        reason: 'presented-essential mastery is met → selection TERMINATES '
            '(returns null → route to Mastery); the unit no longer never-advances');

    // The pass CTA runs the shell's _advanceSelection: a null pick routes to the
    // Mastery section, whose post-frame _recordMasteryIfMet persists the row.
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();

    // (a cont.) The Mastery section is REACHED via the live advance (the star
    //           renders only off a CONFIRMED persisted write — see letter_unit_screen).
    expect(find.byType(MasterySection), findsOneWidget,
        reason: 'the live advance routed to Mastery and the star rendered — the '
            '14-node baa graph reaches the star through real selection');
    expect(controller.state.index, controller.state.total - 1,
        reason: 'the shell parked on the Mastery section');

    // (b) THE WRITE PIN: the baa LetterMastery ROW exists in Drift — written by the
    //     routing's Mastery post-frame, NOT a direct recordMasteryIfMet() call here.
    final rowExists = await _awaitPumping(
      tester,
      progress.isMastered('baa', childProfileId: kUnassignedChildProfileId),
      what: 'isMastered(baa)',
    );
    expect(rowExists, isTrue,
        reason: 'the mastery ROW must exist — Home/Journey both hang off this row');

    // (c) PROGRESSION ADVANCES: the snapshot the Home card renders from now reports
    //     taa (the next letter by introOrder) as today's letter.
    final expectedNext = _nextByIntroOrder('baa'); // taa
    final snapshot = await _awaitPumping(
      tester,
      container.read(progressionProvider.future),
      what: 'progressionProvider(baa)',
    );
    expect(snapshot.masteredLetterIds, containsAll(<String>['alif', 'baa']));
    final todayLetter = snapshot.today?.items
        .where((i) => i.type == 'letter')
        .map((i) => i.ref)
        .firstOrNull;
    expect(todayLetter, expectedNext,
        reason: 'after mastering baa, today\'s lesson advances to $expectedNext');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
