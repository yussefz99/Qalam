// Quick task 260720-wcs (Task 3) — the jeem STARTER-unit smoke.
//
// jeem is promoted (Task 2) as an isolated-form-only STARTER unit: a 3-node
// all-essential graph (meet → trace isolated → write isolated). This smoke proves
// the starter is FINISHABLE — the graph loads as 3 all-essential nodes, the unit
// routes, and a scored PASS with the 3 nodes at threshold reaches the Mastery
// section (the star) and advances the journey to haa_c (the 6th finishable letter).
// jeem declares NO presentedEssentials → the controller uses the FULL-graph
// essential check (all 3 nodes).
//
// ── WHY exactly ONE testWidgets in this file (do not add a second) ────────────
// rootBundle asset fetches over the flutter/assets channel only complete reliably
// in the FIRST testWidgets of a process (a SECOND stalls forever on the identical
// load). So this file holds EXACTLY ONE live case, and the _awaitPumping dual-drain
// helper bounds any rootBundle-touching await instead of the 10-minute wall.

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
const _resumeNode = 'jeem.traceLetter.isolated';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The REAL bundled jeem STARTER graph, parsed off disk (File, not rootBundle) —
/// 3 all-essential nodes (the 260720-wcs isolated-form starter). Same as shipped.
CurriculumGraph _loadGraph() => CurriculumGraph.fromJson(
      _json('assets/curriculum/graphs/jeem.json').cast<String, Object?>(),
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
    letterId: 'jeem',
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

Letter _jeem() {
  const body = StrokeSpec(
    order: 1,
    label: 'jeem body',
    type: 'curve',
    points: [
      [0.3, 0.3],
      [0.6, 0.5],
      [0.3, 0.7],
    ],
    direction: 'rightToLeft',
  );
  const dot = StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    points: [
      [0.45, 0.75],
    ],
    direction: 'none',
  );
  return Letter(
    id: 'jeem',
    char: 'ج',
    name: const LetterName(ar: 'جِيم', display: 'Jeem'),
    introOrder: 5,
    forms: const LetterForms(
        isolated: 'ج', initial: 'جـ', medial: 'ـجـ', final_: 'ـج'),
    referenceStrokes: const [body, dot],
    cleanRepsToAdvance: 1,
    commonMistakes: const [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: const {'isolated': Form(referenceStrokes: [body, dot])},
  );
}

/// The jeem STARTER unit shell — NO presentedEssentials (full-graph essential check
/// over all 3 nodes) and NO words/listenWrite sections (isolated-form only).
LetterUnitData _jeemData() => LetterUnitData(
      unit: const LetterUnit(
        letterId: 'jeem',
        // No presentedEssentials → full-graph essential mastery check.
        sections: [
          UnitSection(id: 'meet', exercises: ['jeem.teachCard.meet']),
          UnitSection(id: 'watchTrace', exercises: [_resumeNode]),
          UnitSection(id: 'forms', exercises: ['jeem.writeLetter.writeForm']),
          UnitSection(id: 'mastery', exercises: []),
        ],
      ),
      letter: _jeem(),
      exercises: {
        for (final e in [
          Exercise(
            id: _resumeNode,
            type: 'traceLetter',
            skill: 'formation',
            prompt: const [SayPart('Trace jeem.')],
            surface: const Surface(
                mode: 'trace', unit: 'glyph', guideForm: 'isolated', demo: true),
            expected: const Answer(glyph: GlyphAnswer(char: 'ج', form: 'isolated')),
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
/// and the fake clock (timeouts). Bounded so a genuine stall fails loudly instead
/// of hitting the 10-minute wall.
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
      'the jeem isolated-form starter (3 all-essential nodes) reaches the star '
      'through live selection and the journey advances to haa_c',
      (tester) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      graphPositionRepositoryProvider.overrideWithValue(_SeededPositionRepo()),
      // The REAL 3-node jeem starter graph, off disk (no rootBundle stall).
      curriculumGraphProvider.overrideWith((ref, letterId) async => _loadGraph()),
      childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
      letterUnitDataProvider('jeem').overrideWith((ref) async => _jeemData()),
      audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
      tutorBrainFactoryProvider
          .overrideWithValue((Map<String, String> feedback) => _LineOnlyBrain()),
      ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
    ]);
    addTearDown(container.dispose);

    final progress = container.read(progressRepositoryProvider);
    final graph = _loadGraph();
    expect(graph.nodes, hasLength(3),
        reason: 'the bundled jeem starter graph is 3 nodes (isolated-form only)');
    expect(graph.essentialNodes, hasLength(3),
        reason: 'all 3 jeem starter nodes are essential (recognize + '
            'positionalForms) — so the star is reachable by clean-repping them');

    // alif+baa+taa+thaa already MASTERED (so jeem is today's letter), and EVERY jeem
    // essential node seeded at its owner threshold — the FIRST scored moment finds
    // mastery met.
    for (final prior in ['alif', 'baa', 'taa', 'thaa']) {
      await progress.recordMastery(
        childProfileId: kUnassignedChildProfileId,
        letterId: prior,
        cleanReps: 3,
      );
    }
    for (final node in graph.essentialNodes) {
      await db.setExerciseCleanReps(
        childProfileId: kUnassignedChildProfileId,
        letterId: 'jeem',
        exerciseId: node.exerciseId,
        cleanReps: node.minCleanReps,
      );
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LetterUnitScreen(letterId: 'jeem')),
      ),
    );
    await tester.pumpAndSettle();

    final controller =
        container.read(letterUnitControllerProvider('jeem').notifier);
    // The seeded cursor resumes straight into the presenter on the trace node — the
    // walker railed to a legal jeem node.
    expect(controller.state.currentExerciseId, _resumeNode);
    if (find.text("I'll try").evaluate().isNotEmpty) {
      await tester.tap(find.text("I'll try"));
      await tester.pumpAndSettle();
    }

    // Drive a scored PASS through the LIVE seam (== the canvas completion path).
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle();

    // SELECTION TERMINATED — mastery is met, so _selectNext returned null.
    final pending = controller.nextReady();
    expect(pending, isNotNull,
        reason: 'the scored moment set the in-flight selection future');
    final picked = await _awaitPumping(tester, pending!, what: 'nextReady(jeem)');
    expect(picked, isNull,
        reason: 'full-graph essential mastery is met → selection TERMINATES '
            '(returns null → route to Mastery); the 3-node jeem starter finishes');

    // The pass CTA routes to Mastery, whose post-frame _recordMasteryIfMet persists.
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();

    expect(find.byType(MasterySection), findsOneWidget,
        reason: 'the live advance routed to Mastery and the star rendered — the '
            'jeem starter reaches the star through real selection');
    expect(controller.state.index, controller.state.total - 1,
        reason: 'the shell parked on the Mastery section');

    // THE WRITE PIN: the jeem LetterMastery ROW exists in Drift.
    final rowExists = await _awaitPumping(
      tester,
      progress.isMastered('jeem', childProfileId: kUnassignedChildProfileId),
      what: 'isMastered(jeem)',
    );
    expect(rowExists, isTrue,
        reason: 'the mastery ROW must exist — Home/Journey both hang off this row');

    // PROGRESSION ADVANCES to haa_c (the 6th finishable letter).
    final expectedNext = _nextByIntroOrder('jeem'); // haa_c
    final snapshot = await _awaitPumping(
      tester,
      container.read(progressionProvider.future),
      what: 'progressionProvider(jeem)',
    );
    expect(snapshot.masteredLetterIds,
        containsAll(<String>['alif', 'baa', 'taa', 'thaa', 'jeem']));
    final todayLetter = snapshot.today?.items
        .where((i) => i.type == 'letter')
        .map((i) => i.ref)
        .firstOrNull;
    expect(todayLetter, expectedNext,
        reason: 'after mastering jeem, today\'s lesson advances to $expectedNext');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
