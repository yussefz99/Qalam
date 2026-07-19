// Phase 25-05 (L3) — THE LIVE-PATH GUARD PROOF (success criterion 3).
//
// Even if bad data ships to Firestore (past L0 audit / L1 lint / L2 seeder), the
// runtime selector must NEVER present a card that demands a letter the child has not
// yet seen: it SKIPs it and the walker advances to the next legal node (D-01), the
// mastery star stays reachable (D-02), and every firing is logged loudly (D-03).
//
// This is a LIVE-PATH test, NOT a selector-only unit test. It PUMPS the real
// LetterUnitScreen and drives a scored PASS through the SAME seam the canvas fires
// (WriteSurface.onResult == the scaffold's _onResult → the controller's live
// selection), because a unit test on the selector alone cannot catch a dead wire —
// that is exactly how the Phase-15 "dynamic selection" shipped as dead code
// (memories: tests-pin-progression-not-presentation; phase15-dynamic-selection-was-
// dead-code). The illegal card is seeded via the REAL data path: a graph injected
// through `curriculumGraphProvider` (the Firestore-first bypass this guard defends)
// whose node resolves to a REAL exercises.json card with a reach-ahead `letters[]`.
//
// ── WHY exactly ONE testWidgets in this file (do not add a second) ────────────
// `rootBundle` asset fetches over the flutter/assets channel only complete reliably
// in the FIRST testWidgets of a process (the binding clears the asset cache between
// tests; a SECOND testWidgets stalls forever on the identical load — verified
// 2026-07-18). So this file holds EXACTLY ONE live case. The `_awaitPumping`
// dual-drain helper (copied from mastery_progression_harness.dart) bounds any
// rootBundle-touching await instead of the 10-minute wall.

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
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
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

// The node the child is ON at the start of the moment (a legal essential trace).
const _current = 'baa.traceLetter.isolated';
// The ILLEGAL card injected on an ENRICHMENT node: a REAL exercises.json card
// (taa.traceLetter.isolated, letters ['taa']) that reaches ahead of the baa unit
// (introOrder 2 < taa's 3) and is NOT one of the 22 owner-approved exceptions.
// Enrichment (non-essential) so skipping it can never strand the star (D-02).
const _illegal = 'taa.traceLetter.isolated';
// The next LEGAL essential node — where the walker lands once L3 SKIPs the illegal.
const _legalSkipTarget = 'baa.traceLetter.initial';

// The essential core the star gates on (all legal, all baa) — seeded to threshold
// so mastery stays reachable after the illegal enrichment card is skipped.
const _essentialIds = <String>[
  'baa.teachCard.meet',
  'baa.traceLetter.isolated',
  'baa.traceLetter.initial',
];

Map<String, Object?> _json(String path) =>
    json.decode(File(path).readAsStringSync()) as Map<String, Object?>;

/// The INJECTED graph — the Firestore-first bypass this guard defends. Its middle
/// node is the illegal enrichment card; a legal essential node follows it in
/// declaration order, so the walker's forward scan lands there once L3 drops the
/// illegal one. Parsed by the SAME `CurriculumGraph.fromJson` production uses.
CurriculumGraph _injectedGraph() => CurriculumGraph.fromJson(<String, Object?>{
      'letterId': 'baa',
      'signedOff': false,
      'tiers': <String>['manqul', 'manzur', 'ghayrManzur'],
      'competencies': <Object?>[
        {'id': 'recognize', 'essential': true, 'prerequisites': <String>[]},
        {
          'id': 'positionalForms',
          'essential': true,
          'prerequisites': <String>['recognize'],
        },
        // Enrichment (essential:false) — the illegal card lives here so a SKIP can
        // never strand the essential mastery core (D-02, 70/30).
        {
          'id': 'bonusWord',
          'essential': false,
          'prerequisites': <String>['recognize'],
        },
      ],
      'nodes': <Object?>[
        {
          'exerciseId': 'baa.teachCard.meet',
          'competency': 'recognize',
          'tier': null,
          'minCleanReps': 1,
        },
        {
          'exerciseId': _current, // legal essential (the cursor)
          'competency': 'positionalForms',
          'tier': null,
          'minCleanReps': 1,
        },
        {
          'exerciseId': _illegal, // ILLEGAL enrichment card (demands taa)
          'competency': 'bonusWord',
          'tier': null,
          'minCleanReps': 1,
        },
        {
          'exerciseId': _legalSkipTarget, // legal essential (the skip target)
          'competency': 'positionalForms',
          'tier': null,
          'minCleanReps': 1,
        },
      ],
    });

/// The REAL seen-letters filter for baa, built off disk (File, not rootBundle) from
/// the SAME letters.json / exercises.json the app ships — so `_illegal` genuinely
/// reads as reaching ahead. This is the guard's learned-set data via the real
/// content, not a mock verdict.
SeenLettersFilter _diskFilter() => SeenLettersFilter.fromAssets(
      letterId: 'baa',
      lettersJson: _json('assets/curriculum/letters.json'),
      exercisesJson: _json('assets/curriculum/exercises.json'),
    );

/// The durable cursor: the child is ON `_current` with `recognize` cleared (so the
/// positionalForms + bonusWord forward nodes are legal candidates).
class _SeededPositionRepo implements GraphPositionRepository {
  GraphPosition _pos = const GraphPosition(
    childProfileId: kUnassignedChildProfileId,
    letterId: 'baa',
    currentExerciseId: _current,
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

/// A coach that returns a warm line but NO next-exercise plan — so the pick falls
/// to the offline walker over the L3-filtered candidate set (the exact offline
/// floor; no agent pick to confound the SKIP proof).
class _NoPickBrain implements TutorBrain {
  @override
  Future<TutorDecision> next(TutorFacts facts) async =>
      const PresentActivity(coachingLine: 'Keep going.', letterId: 'baa');
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

Exercise _graded() => const Exercise(
      id: _current,
      type: 'traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace baa.')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {'pass': 'Beautiful.', 'shallowBowl': 'Deeper curve.'},
      signedOff: false,
    );

LetterUnitData _unitData() => LetterUnitData(
      unit: const LetterUnit(
        letterId: 'baa',
        sections: [
          UnitSection(id: 'meet', exercises: ['baa.teachCard.meet']),
          UnitSection(id: 'watchTrace', exercises: [_current]),
          UnitSection(id: 'forms', exercises: [_legalSkipTarget]),
          UnitSection(id: 'words', exercises: ['baa.connectWord.baab']),
          UnitSection(id: 'listenWrite', exercises: ['baa.writeWord.dictation']),
          UnitSection(id: 'mastery', exercises: []),
        ],
      ),
      letter: _baa(),
      exercises: {for (final e in [_graded()]) e.id: e},
      words: const [],
    );

/// Find a presented graph node by [id], tolerant of the 18-12 epoch suffix
/// (`graph:<id>#<epoch>`) — asserts WHICH node renders, not its epoch.
Finder _graphNode(String id) => find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> &&
          (k.value == 'graph:$id' || k.value.startsWith('graph:$id#'));
    });

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
      'an illegal card injected via the data path is NEVER presented — the walker '
      'SKIPs to the next legal node (D-01), the star stays reachable (D-02), and '
      'the guard logs loudly (D-03)', (tester) async {
    // Capture debugPrint so we can prove the loud L3 log fired (D-03).
    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      graphPositionRepositoryProvider.overrideWithValue(_SeededPositionRepo()),
      // Seed the ILLEGAL card via the REAL data path — the Firestore-first bypass.
      curriculumGraphProvider
          .overrideWith((ref, letterId) async => _injectedGraph()),
      childModelProvider.overrideWith((ref) async => ChildModelSnapshot.empty()),
      // The REAL seen-letters filter over the REAL bundled content (off disk, so no
      // rootBundle stall) — `_illegal` genuinely reaches ahead of the baa unit.
      seenLettersFilterProvider('baa').overrideWith((ref) async => _diskFilter()),
      // No-units repo → the mastery gate falls back to the full-graph essential
      // check over the injected fixture (and no units.json rootBundle read).
      curriculumRepositoryProvider.overrideWithValue(
          CurriculumRepository.fromStrings('{"letters":[]}', '{"lessons":[]}')),
      letterUnitDataProvider('baa').overrideWith((ref) async => _unitData()),
      audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
      tutorBrainFactoryProvider
          .overrideWithValue((Map<String, String> feedback) => _NoPickBrain()),
      ttsCoachSpeakerProvider.overrideWithValue(const NoopTtsCoachSpeaker()),
    ]);
    addTearDown(container.dispose);

    // Seed every essential node at its threshold, so the star is reachable via the
    // LEGAL essentials the moment the illegal enrichment card is skipped (D-02).
    for (final id in _essentialIds) {
      await db.setExerciseCleanReps(
        childProfileId: kUnassignedChildProfileId,
        letterId: 'baa',
        exerciseId: id,
        cleanReps: 1,
      );
    }
    // WARM the seen filter so the runtime guard has its data BEFORE the scored pass
    // (the controller reads it non-blocking — it must be loaded to fire).
    await _awaitPumping(
      tester,
      container.read(seenLettersFilterProvider('baa').future),
      what: 'seenLettersFilter(baa)',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LetterUnitScreen(letterId: 'baa')),
      ),
    );
    await tester.pumpAndSettle();

    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);
    // Sanity: the child is ON the legal cursor before the attempt.
    expect(controller.state.currentExerciseId, _current);

    // Drive a scored PASS through the LIVE seam (== the canvas completion path).
    if (find.text("I'll try").evaluate().isNotEmpty) {
      await tester.tap(find.text("I'll try"));
      await tester.pumpAndSettle();
    }
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle();
    // The pass CTA swaps the shell to the SELECTED node (awaits the fresh cursor).
    await tester.tap(find.text('Next exercise'));
    await tester.pumpAndSettle();

    // Snapshot the loud guard logs, then RESTORE debugPrint BEFORE any assertion —
    // a foundation debug var must be unset when the framework verifies invariants
    // (restoring in addTearDown runs too late and trips the binding).
    final guardLogs = logs.where((l) => l.contains('L3 guard')).toList();
    debugPrint = originalDebugPrint;

    // (a) The illegal card is NEVER what the child advances to, and NEVER renders;
    //     the walker skipped it to the next LEGAL node (D-01 SKIP).
    expect(controller.state.currentExerciseId, _legalSkipTarget,
        reason: 'the walker must SKIP the illegal card to the next legal node');
    expect(controller.state.currentExerciseId, isNot(_illegal));
    expect(_graphNode(_legalSkipTarget), findsOneWidget,
        reason: 'the legal skip target is what RENDERS next (end-to-end, not just '
            'the cursor)');
    expect(_graphNode(_illegal), findsNothing,
        reason: 'the illegal card never reaches the screen — the rail held live');

    // (b) The star stays reachable (D-02): mastery still fires over the legal
    //     essentials even though the illegal enrichment card was skipped.
    final mastered = await _awaitPumping(
      tester,
      controller.recordMasteryIfMet(),
      what: 'recordMasteryIfMet',
    );
    expect(mastered, isTrue,
        reason: 'skipping the illegal enrichment card must NOT strand the star');

    // (c) The guard logged LOUDLY (D-03) — naming the id + the demanded letter, and
    //     NO child data / strokes (T-25-05-I). (guardLogs snapshotted above.)
    expect(guardLogs, isNotEmpty,
        reason: 'every guard firing must be logged loudly (never a silent swallow)');
    expect(
        guardLogs.any((l) => l.contains(_illegal) && l.contains('taa')), isTrue,
        reason: 'the log names the skipped card id + the unseen letter it demands');
    expect(
        guardLogs.every((l) =>
            !l.contains('childProfileId') && !l.toLowerCase().contains('stroke')),
        isTrue,
        reason: 'the L3 log carries no child identifiers or strokes (T-25-05-I)');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
