// Quick task 260720-wcs (Task 3) — THE thaa LIVE-PATH mastery→advance PROOF.
//
// F2-interim dormancy (Task 1) removed thaa's 10 reach-ahead word/grammar nodes,
// leaving 7 all-essential letter-FORM nodes. This pins that the resulting 7-node
// thaa graph can actually be COMPLETED to the star and that the journey advances to
// jeem — the SAME live-path shape the 260720-up4 baa test proves, over thaa's own
// bundled graph (off disk, 7 nodes). thaa declares NO presentedEssentials → the
// controller uses the FULL-graph essential check (all 7 nodes).
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
const _resumeNode = 'thaa.traceLetter.isolated';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The REAL bundled thaa graph, parsed off disk (File, not rootBundle) — 7 nodes
/// after the 260720-wcs F2-interim dormancy. The SAME graph the app ships.
CurriculumGraph _loadGraph() => CurriculumGraph.fromJson(
      _json('assets/curriculum/graphs/thaa.json').cast<String, Object?>(),
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
    letterId: 'thaa',
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

Letter _thaa() {
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
  const dots = StrokeSpec(
    order: 2,
    label: 'three dots',
    type: 'dot',
    points: [
      [0.4, 0.2],
    ],
    direction: 'none',
  );
  return Letter(
    id: 'thaa',
    char: 'ث',
    name: const LetterName(ar: 'ثاء', display: 'thaa'),
    introOrder: 4,
    forms: const LetterForms(
        isolated: 'ث', initial: 'ثـ', medial: 'ـثـ', final_: 'ـث'),
    referenceStrokes: const [body, dots],
    cleanRepsToAdvance: 1,
    commonMistakes: const [],
    mistakesStatus: 'placeholder',
    signedOff: false,
    contextualForms: const {'isolated': Form(referenceStrokes: [body, dots])},
  );
}

/// The thaa unit shell data — NO presentedEssentials (the controller then uses the
/// FULL-graph essential check over all 7 thaa nodes). The resume-node exercise is
/// the isolated trace the presenter renders.
LetterUnitData _thaaData() => LetterUnitData(
      unit: const LetterUnit(
        letterId: 'thaa',
        // No presentedEssentials → full-graph essential mastery check.
        sections: [
          UnitSection(id: 'meet', exercises: ['thaa.teachCard.meet']),
          UnitSection(id: 'watchTrace', exercises: [_resumeNode]),
          UnitSection(id: 'forms', exercises: ['thaa.writeLetter.writeForm']),
          UnitSection(id: 'mastery', exercises: []),
        ],
      ),
      letter: _thaa(),
      exercises: {
        for (final e in [
          Exercise(
            id: _resumeNode,
            type: 'traceLetter',
            skill: 'formation',
            prompt: const [SayPart('Trace thaa.')],
            surface: const Surface(
                mode: 'trace', unit: 'glyph', guideForm: 'isolated', demo: true),
            expected: const Answer(glyph: GlyphAnswer(char: 'ث', form: 'isolated')),
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
      'the real 7-node thaa graph reaches the star through live selection and the '
      'journey advances to jeem (F2-interim dormancy, no direct recordMasteryIfMet)',
      (tester) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      graphPositionRepositoryProvider.overrideWithValue(_SeededPositionRepo()),
      // The REAL 7-node thaa graph, off disk (no rootBundle stall).
      curriculumGraphProvider.overrideWith((ref, letterId) async => _loadGraph()),
      childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
      letterUnitDataProvider('thaa').overrideWith((ref) async => _thaaData()),
      audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
      tutorBrainFactoryProvider
          .overrideWithValue((Map<String, String> feedback) => _LineOnlyBrain()),
      ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
    ]);
    addTearDown(container.dispose);

    final progress = container.read(progressRepositoryProvider);
    final graph = _loadGraph();
    expect(graph.nodes, hasLength(7),
        reason: 'the bundled thaa graph is 7 nodes after the 260720-wcs dormancy');
    expect(graph.essentialNodes, hasLength(7),
        reason: 'all 7 remaining thaa nodes are essential (the 10 reach-ahead word '
            'cards were made dormant)');

    // Realistic progression state: alif + baa + taa already MASTERED (so thaa is
    // today's letter), and EVERY thaa essential node seeded at its owner threshold —
    // so the child has genuinely completed thaa's core and the FIRST scored moment
    // finds mastery met.
    for (final prior in ['alif', 'baa', 'taa']) {
      await progress.recordMastery(
        childProfileId: kUnassignedChildProfileId,
        letterId: prior,
        cleanReps: 3,
      );
    }
    for (final node in graph.essentialNodes) {
      await db.setExerciseCleanReps(
        childProfileId: kUnassignedChildProfileId,
        letterId: 'thaa',
        exerciseId: node.exerciseId,
        cleanReps: node.minCleanReps,
      );
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LetterUnitScreen(letterId: 'thaa')),
      ),
    );
    await tester.pumpAndSettle();

    final controller =
        container.read(letterUnitControllerProvider('thaa').notifier);
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

    // (a) SELECTION TERMINATED — mastery is met, so _selectNext returned null. Prove
    //     it via the controller's own nextReady future (the SAME future the shell
    //     awaits), NOT a direct gate call.
    final pending = controller.nextReady();
    expect(pending, isNotNull,
        reason: 'the scored moment set the in-flight selection future');
    final picked = await _awaitPumping(tester, pending!, what: 'nextReady(thaa)');
    expect(picked, isNull,
        reason: 'full-graph essential mastery is met → selection TERMINATES '
            '(returns null → route to Mastery); the 7-node thaa unit finishes');

    // The pass CTA runs the shell's _advanceSelection: a null pick routes to the
    // Mastery section, whose post-frame _recordMasteryIfMet persists the row.
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();

    // (a cont.) The Mastery section is REACHED via the live advance (the star
    //           renders only off a CONFIRMED persisted write).
    expect(find.byType(MasterySection), findsOneWidget,
        reason: 'the live advance routed to Mastery and the star rendered — the '
            '7-node thaa graph reaches the star through real selection');
    expect(controller.state.index, controller.state.total - 1,
        reason: 'the shell parked on the Mastery section');

    // (b) THE WRITE PIN: the thaa LetterMastery ROW exists in Drift — written by the
    //     routing's Mastery post-frame, NOT a direct recordMasteryIfMet() call here.
    final rowExists = await _awaitPumping(
      tester,
      progress.isMastered('thaa', childProfileId: kUnassignedChildProfileId),
      what: 'isMastered(thaa)',
    );
    expect(rowExists, isTrue,
        reason: 'the mastery ROW must exist — Home/Journey both hang off this row');

    // (c) PROGRESSION ADVANCES: the snapshot the Home card renders from now reports
    //     jeem (the next letter by introOrder) as today's letter.
    final expectedNext = _nextByIntroOrder('thaa'); // jeem
    final snapshot = await _awaitPumping(
      tester,
      container.read(progressionProvider.future),
      what: 'progressionProvider(thaa)',
    );
    expect(snapshot.masteredLetterIds,
        containsAll(<String>['alif', 'baa', 'taa', 'thaa']));
    final todayLetter = snapshot.today?.items
        .where((i) => i.type == 'letter')
        .map((i) => i.ref)
        .firstOrNull;
    expect(todayLetter, expectedNext,
        reason: 'after mastering thaa, today\'s lesson advances to $expectedNext');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
