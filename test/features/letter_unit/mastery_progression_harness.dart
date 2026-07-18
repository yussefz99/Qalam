// Finalization Lane A — the LETTER-GENERIC mastery → progression proof.
//
// The standing owner rule (burned twice — tests-pin-progression-not-presentation):
// tests must drive SCORED RESULTS through the LIVE apply path and assert what
// actually PERSISTS and what the child ADVANCES to — never presentation alone.
// The "home stuck on alif" bug shipped exactly because a child could "master"
// alif while NO mastery row was ever written (the baa-hardcoded gate + the
// silently-missing graph), so Home/Journey never moved.
//
// This harness parameterizes the FULL loop over a letter, using the REAL
// bundled content (letters.json, exercises.json, units.json,
// graphs/<letter>.json — the on-device data, not fakes) and the REAL
// Drift-backed repositories over an in-memory database:
//
//   1. seed every essential graph node at its owner threshold EXCEPT the target
//      node (one clean rep short);
//   2. drive the FINAL scored PASS through the scaffold's real apply seam
//      (`WriteSurface.onResult` — the same path the child's canvas fires),
//      wired to the SAME rep-increment + node-clear chokepoint the screen uses;
//   3. fire the SAME mastery gate the Mastery section fires
//      (`recordMasteryIfMet`) and assert (a) the mastery ROW IS WRITTEN to the
//      database (the real Drift row, not a flag);
//   4. assert (b) Home advances: `progressionProvider` (the exact provider the
//      Home card + Journey render from) now reports the NEXT letter by
//      introOrder as today's letter;
//   5. assert (c) Journey advances + routes by DATA: the next letter's node
//      computes as `current`, and `unitLetterIdsProvider` (the data-driven
//      routing source) contains it — no letter-id literals anywhere.
//
// The graph resolves through the REAL provider chain (Firestore-first → the
// bundled asset fallback; no Firebase app in tests → the bundle wins), so this
// also pins the Lane-A content-resolution order end-to-end.
//
// ── WHY one case per test FILE (do not merge these back into one file) ───────
// `rootBundle` asset fetches over the flutter/assets channel only complete
// reliably in the FIRST testWidgets of a process: the binding clears the asset
// cache between tests, and a fresh fetch issued by a SECOND testWidgets never
// receives its reply (verified empirically 2026-07-18 — test 1 loaded
// units.json fine, test 2 stalled forever on the identical load). Each
// *_test.dart file runs in its own isolate with fresh bindings, so each case
// lives in its own file and calls [runMasteryProgressionCase] exactly once.

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
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/features/letter_unit/widgets/write_surface.dart'
    show WriteSurface;
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/journey_progress.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/providers/progression_providers.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/tts_coach_speaker.dart';
import 'package:qalam/providers/tts_providers.dart';

// ── Real bundled-content loaders (the on-device data, parsed off disk) ────────

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

CurriculumGraph _loadGraph(String letterId) => CurriculumGraph.fromJson(
      _json('assets/curriculum/graphs/$letterId.json').cast<String, Object?>(),
    );

Letter _loadLetter(String letterId) {
  final letters = (_json('assets/curriculum/letters.json')['letters'] as List)
      .cast<Map<String, dynamic>>();
  return Letter.fromJson(letters.firstWhere((l) => l['id'] == letterId));
}

Exercise _loadExercise(String id) {
  final all = (_json('assets/curriculum/exercises.json')['exercises'] as List)
      .cast<Map<String, dynamic>>();
  return Exercise.fromJson(all.firstWhere((e) => e['id'] == id));
}

/// The next letter after [letterId] by letters.json `introOrder` — computed
/// from the DATA (never a hardcoded successor), exactly the ordering the
/// lesson catalog's unlock ladder follows.
String _nextByIntroOrder(String letterId) {
  final letters = (_json('assets/curriculum/letters.json')['letters'] as List)
      .cast<Map<String, dynamic>>();
  final sorted = [...letters]
    ..sort((a, b) => (a['introOrder'] as int).compareTo(b['introOrder'] as int));
  final index = sorted.indexWhere((l) => l['id'] == letterId);
  return sorted[index + 1]['id'] as String;
}

/// Await [future] while draining BOTH async worlds a `testWidgets` body has:
///
/// 1. `tester.runAsync` slices let the REAL event loop run — required because
///    `rootBundle.loadString` decodes assets larger than 50KB (letters.json is
///    104KB) on a background `compute` ISOLATE, and an isolate response can
///    never arrive inside the fake-async zone. A bare `await` on any chain
///    that touches `CurriculumRepository._ensureLoaded` therefore deadlocks —
///    this is exactly the silent 10-minute-wall hang that ate the first
///    finalization run of this test.
/// 2. `tester.pump` advances the FAKE clock — required for the 3-second
///    child-profile `.timeout` rescue in progression_providers.dart (the
///    documented headless-env degradation).
///
/// Bounded: fails LOUDLY after [budget] instead of the 10-minute wall.
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
    // Drain real async work (isolate decode responses, real I/O)...
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    // ...then fire any due fake-zone timers.
    await tester.pump(step);
    elapsed += step;
  }
  if (!settled) {
    fail('$what did not resolve within ${budget.inSeconds}s of pumped '
        'fake time + drained real async — something in its chain is '
        'genuinely stuck');
  }
  if (error != null) {
    Error.throwWithStackTrace(error!, stack!);
  }
  return value;
}

class _NoopCoachSpeaker implements CoachSpeaker {
  @override
  Future<void> speak(String line) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

/// Registers THE letter-generic mastery→progression proof for one letter.
///
/// [letter] — the letter under test; [preMastered] — the letters already
/// mastered BEFORE this session (its introOrder predecessors — the realistic
/// progression state); [target] — the graded graph node the final live pass
/// lands on. Call exactly ONCE per test file (see the header for why).
void runMasteryProgressionCase({
  required String letter,
  required List<String> preMastered,
  required String target,
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final label = preMastered.isEmpty
      ? 'fresh child'
      : 'after ${preMastered.join('+')}';

  testWidgets(
      '$letter: a live scored pass WRITES the mastery row and Home/'
      'Journey advance to the next letter by introOrder '
      '($label)', (tester) async {
    final db =
        AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      childModelProvider
          .overrideWith((ref) async => ChildModelSnapshot.empty()),
      ttsCoachSpeakerProvider.overrideWithValue(_NoopCoachSpeaker()),
    ]);
    addTearDown(container.dispose);

    final graph = _loadGraph(letter);
    final essentials = graph.essentialNodes;
    expect(essentials, isNotEmpty,
        reason: '$letter must have an essential core to gate the star');
    final targetNode = essentials.firstWhere((n) => n.exerciseId == target);

    // 1) Seed the realistic progression state: prior letters MASTERED via the
    //    real repository write, and every essential node of THIS letter at
    //    its threshold EXCEPT the target (one clean rep short) — so the live
    //    pass below is the act that completes mastery.
    final progress = container.read(progressRepositoryProvider);
    for (final prior in preMastered) {
      await progress.recordMastery(
        childProfileId: kUnassignedChildProfileId,
        letterId: prior,
        cleanReps: 3,
      );
    }
    for (final node in essentials) {
      final reps = node.exerciseId == target
          ? targetNode.minCleanReps - 1
          : node.minCleanReps;
      await db.setExerciseCleanReps(
        childProfileId: kUnassignedChildProfileId,
        letterId: letter,
        exerciseId: node.exerciseId,
        cleanReps: reps,
      );
    }
    // The durable cursor parks the child ON the target node with its
    // prerequisites cleared (recognize → the positionalForms target is legal).
    await container.read(graphPositionRepositoryProvider).setPosition(
          GraphPosition(
            childProfileId: kUnassignedChildProfileId,
            letterId: letter,
            currentExerciseId: target,
            clearedCompetencies: const ['recognize'],
            clearedTiers: const [],
          ),
        );

    // 2) Pump the REAL scaffold on the target node, wired to the SAME
    //    rep-increment + node-clear chokepoint the screen's _onNodePassed
    //    uses. The graph loads through the REAL provider chain (Firestore
    //    attempt → bundled graphs/<letter>.json fallback — no overrides).
    final controller =
        container.read(letterUnitControllerProvider(letter).notifier);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseScaffold(
              exercise: _loadExercise(target),
              letter: _loadLetter(letter),
              graphExerciseId: target,
              onGraphNodePassed: (id) {
                // Mirror of _UnitShellState._onNodePassed (the live screen
                // chokepoint): increment the Drift clean-rep count, then grow
                // cleared state once the threshold is met.
                db
                    .incrementExerciseCleanReps(
                      childProfileId: controller.childProfileId(),
                      letterId: letter,
                      exerciseId: id,
                    )
                    .then((_) => controller.markNodeCleared(id))
                    .catchError((_) {});
              },
              advanceOnFix: true,
            ),
          ),
        ),
      ),
    );
    await controller.start(letterId: letter, total: 6);
    await tester.pumpAndSettle();

    // 3) Drive the FINAL scored PASS through the live apply seam — the same
    //    `WriteSurface.onResult` the child's canvas fires.
    final ws = tester.widget<WriteSurface>(find.byType(WriteSurface));
    ws.onResult!(const CheckResult.pass());
    await tester.pumpAndSettle();

    final targetReps = await db.getExerciseCleanReps(
      childProfileId: kUnassignedChildProfileId,
      letterId: letter,
      exerciseId: target,
    );
    expect(targetReps, targetNode.minCleanReps,
        reason: 'the live pass must increment the target to its threshold '
            'through the real chokepoint');

    // The walker ran for this letter (letter-generic selection — the old
    // baa-only gate is dead): selection is active after the scored moment.
    expect(controller.state.selectionActive, isTrue,
        reason: '$letter must be graph-railed — selection hands over on '
            'the first scored moment, never the static walk');

    // 4) Fire the SAME gate the Mastery section fires. (a) THE WRITE PIN:
    //    the mastery row is PERSISTED — true means "the row is in the DB",
    //    never a UI flag.
    final written = await _awaitPumping(
      tester,
      controller.recordMasteryIfMet(),
      what: 'recordMasteryIfMet($letter)',
    );
    expect(written, isTrue,
        reason: '$letter met every essential threshold — the gate must '
            'record mastery (the old baa-hardcoded set returned {} overlap '
            'and froze exactly here)');
    final rowExists = await _awaitPumping(
      tester,
      progress.isMastered(
        letter,
        childProfileId: kUnassignedChildProfileId,
      ),
      what: 'isMastered($letter)',
    );
    expect(rowExists, isTrue,
        reason: 'the mastery ROW must exist in the database — celebration '
            'and Home/Journey both hang off this row');

    // 5) (b) HOME ADVANCES: progressionProvider (the exact provider the Home
    //    card renders from) reports the NEXT letter by introOrder as today.
    final expectedNext = _nextByIntroOrder(letter);
    final snapshot = await _awaitPumping(
      tester,
      container.read(progressionProvider.future),
      what: 'progressionProvider($letter)',
    );
    expect(snapshot.masteredLetterIds, contains(letter));
    final todayLetter = snapshot.today?.items
        .where((i) => i.type == 'letter')
        .map((i) => i.ref)
        .firstOrNull;
    expect(todayLetter, expectedNext,
        reason: 'after mastering $letter, today\'s lesson must advance '
            'to $expectedNext (the next letter by introOrder)');

    // (c) JOURNEY ADVANCES + routes by DATA: the next node computes as
    // `current`, and the data-driven routing source knows whether it opens a
    // Letter Unit — no letter-id literals anywhere in the logic.
    final nextState = JourneyNodeState.compute(
      expectedNext,
      snapshot.masteredLetterIds,
      todayLetter ?? '',
    );
    expect(nextState, JourneyNodeState.current,
        reason: 'the Journey node for $expectedNext must light as current');
    final unitLetters = await _awaitPumping(
      tester,
      container.read(unitLetterIdsProvider.future),
      what: 'unitLetterIdsProvider($letter)',
    );
    expect(unitLetters, contains(expectedNext),
        reason: '$expectedNext has live unit content in units.json — the '
            'data-driven router must send it to /unit');
  },
      // A wiring regression must fail in minutes, never sit at the silent
      // 10-minute default wall (the first finalization run died there).
      timeout: const Timeout(Duration(minutes: 3)));
}
