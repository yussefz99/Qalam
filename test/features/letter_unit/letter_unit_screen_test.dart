// LetterUnitScreen (the 6-section unit shell) behavior — Plan 07-06 Task 2,
// rewired for DYN-02 in Plan 15-05.
//
// The shell hosts the 6 baa sections behind the R→L ProgressRibbon app bar and
// sequences them via the LetterUnitController, now with DURABLE Drift resume and
// the star gated strictly on the on-device `isMasteryMet` condition. These tests
// prove:
//   • the app bar renders 6 ribbon dots, R→L (dot 0 on the right);
//   • the shell starts at section 0 (Meet) and advances through all 6 sections
//     to a single-star Mastery;
//   • Pitfall 2 (the FLIPPED assertion): reaching the Mastery section by mere
//     NAVIGATION on a clicked-through unit with UNMET essential reps records
//     NOTHING — the star is no longer granted off navigation (D-06);
//   • a ribbon dot jumps to that section.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart'
    show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/features/letter_unit/sections/mastery_section.dart';
import 'package:qalam/features/letter_unit/sections/meet_section.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/word.dart';
import 'package:qalam/providers/audio_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';

import 'section_test_support.dart';

/// The single-source curriculum graph parsed straight off disk (hermetic — no
/// rootBundle, mirroring the curriculum unit tests). Overrides
/// `curriculumGraphProvider` so the mastery gate has a real graph in tests.
CurriculumGraph _loadGraph() {
  final raw = json.decode(
    File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return CurriculumGraph.fromJson(raw);
}

class _CapturingAudioPlayer implements LetterAudioPlayer {
  @override
  Future<void> playLetter(String assetPath) async {}
}

class _FakeProgressRepository implements ProgressRepository {
  final List<String> mastered = <String>[];
  @override
  Future<void> recordMastery({
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  }) async {
    mastered.add(letterId);
  }

  @override
  Future<bool> isMastered(String letterId, {required int childProfileId}) async =>
      false;
  @override
  Stream<Set<String>> watchMasteredLetterIds({required int childProfileId}) =>
      Stream.value(const <String>{});
  // D-15 fold (19-04) / ADR-018 keying (19-06): folded aggregate accessors.
  @override
  Future<int> letterCleanReps(String letterId, {required int childProfileId}) async =>
      0;
  @override
  Stream<int> watchLetterCleanReps(String letterId,
          {required int childProfileId}) =>
      Stream.value(0);
  @override
  Future<void> setLetterCleanReps(
          {required int childProfileId,
          required String letterId,
          required int cleanReps}) async {}
}

/// An in-memory fake of the durable resume cursor — round-trips the position so
/// the controller's Drift-backed resume path runs without a real database.
class _FakeGraphPositionRepository implements GraphPositionRepository {
  final Map<String, GraphPosition> _store = {};

  @override
  Future<GraphPosition?> getPosition(String letterId,
          {required int childProfileId}) async =>
      _store[letterId];

  @override
  Future<void> setPosition(GraphPosition position) async {
    _store[position.letterId] = position;
  }
}

/// The baa unit's 6 ordered sections (units.json), plus its exercises + words.
LetterUnitData _baaData() {
  final exercises = <Exercise>[
    meetExercise(),
    traceIsolatedExercise(),
    traceFormExercise('initial'),
    traceFormExercise('medial'),
    traceFormExercise('final'),
    joinExercise(),
  ];
  return LetterUnitData(
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
    letter: baaLetter(),
    exercises: {for (final e in exercises) e.id: e},
    words: const [
      Word(
        id: 'baab',
        text: 'باب',
        audio: 'word.baab',
        image: 'img.door',
        gloss: {'en': 'door'},
        letters: ['baa', 'alif', 'baa'],
      ),
    ],
  );
}

/// Pump the screen with a fresh in-memory AppDatabase (so the controller's
/// per-exercise reps read returns EMPTY — unmet essential reps), a fake durable
/// position repo, and the fake progress repo. Returns the progress repo + the db.
Future<({_FakeProgressRepository progress, AppDatabase db})> _pump(
  WidgetTester tester,
) async {
  final progress = _FakeProgressRepository();
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()).executor);
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
        progressRepositoryProvider.overrideWithValue(progress),
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider
            .overrideWithValue(_FakeGraphPositionRepository()),
        // The mastery gate reads the single-source graph; load it off disk so the
        // test is hermetic (no rootBundle dependence).
        curriculumGraphProvider
            .overrideWith((ref, letterId) async => _loadGraph()),
        letterUnitDataProvider('baa').overrideWith((ref) async => _baaData()),
      ],
      child: const MaterialApp(
        home: LetterUnitScreen(letterId: 'baa'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (progress: progress, db: db);
}

void main() {
  // Each test spins up its own in-memory AppDatabase (distinct executors, no
  // shared store) — silence drift's cross-instance race warning, which does not
  // apply here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Test 1: the app bar renders 6 R→L ribbon dots',
      (tester) async {
    await _pump(tester);

    // Six tappable ribbon dots (the 6 sections).
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey<String>('unitRibbonDot:$i')), findsOneWidget);
    }
    // The shell starts on section 0 — Meet.
    expect(find.byType(MeetSection), findsOneWidget);
  });

  testWidgets('Test 2: advancing sequences through all 6 sections to Mastery',
      (tester) async {
    await _pump(tester);

    final ctx = tester.element(find.byType(LetterUnitScreen));
    final container = ProviderScope.containerOf(ctx);
    final controller =
        container.read(letterUnitControllerProvider('baa').notifier);

    // Walk forward through every section to Mastery (index 5).
    for (var i = 0; i < 5; i++) {
      controller.advance();
      await tester.pumpAndSettle();
    }

    // The final section is Mastery — the one quiet star celebration.
    expect(find.byType(MasterySection), findsOneWidget);
    expect(find.byType(MeetSection), findsNothing);
  });

  testWidgets(
      'Test 3 (FLIPPED, D-06/Pitfall 2): a clicked-through unit with UNMET reps '
      'records NO mastery on reaching the Mastery section', (tester) async {
    final pumped = await _pump(tester);
    final progress = pumped.progress;

    final ctx = tester.element(find.byType(LetterUnitScreen));
    final container = ProviderScope.containerOf(ctx);
    // Navigate straight to the Mastery section — NO exercises actually cleaned
    // (the in-memory db has zero per-exercise reps → isMasteryMet is false).
    container.read(letterUnitControllerProvider('baa').notifier).goTo(5);
    await tester.pumpAndSettle();

    // The Mastery section is shown (navigation works) …
    expect(find.byType(MasterySection), findsOneWidget);
    // … but the star is NOT granted off navigation: with unmet essential reps,
    // recordMastery is never called (the deleted cleanReps:0 auto-write).
    expect(progress.mastered, isNot(contains('baa')),
        reason: 'the star must be gated on isMasteryMet, never on navigation '
            '(D-06 / Pitfall 2)');
  });

  testWidgets('Test 4: a ribbon dot jumps to that section',
      (tester) async {
    await _pump(tester);

    // Tap dot 5 (Mastery) — the shell jumps there.
    await tester.tap(find.byKey(const ValueKey('unitRibbonDot:5')));
    await tester.pumpAndSettle();

    expect(find.byType(MasterySection), findsOneWidget);
  });

  testWidgets(
      'Test 5 (D-06): with the essential core at the owner-mother reps, the '
      'Mastery section records exactly one quiet star', (tester) async {
    final pumped = await _pump(tester);
    final progress = pumped.progress;
    final db = pumped.db;

    // Bank enough clean-reps on EVERY essential node so isMasteryMet is true.
    // (The essential nodes are recognize/positionalForms/copyWrite/fluentReading;
    // we over-bank a high count on every authored baa.* id so all essentials
    // clear regardless of their per-node minCleanReps.)
    for (final id in const [
      'baa.teachCard.meet',
      'baa.traceLetter.isolated',
      'baa.traceLetter.initial',
      'baa.traceLetter.medial',
      // Owner amendment 2026-07-12 (19 review CR-02): the final form is a live
      // essential node in the presented mastery core — the star must not fire
      // without it, so the "every essential at reps" seed must include it.
      'baa.traceLetter.final',
      'baa.writeLetter.fromSound',
      'baa.writeLetter.fromPicture',
      'baa.writeLetter.writeForm',
      'baa.connectWord.baab',
      'baa.connectWord.kitaab',
      'baa.completeWord.middle',
      'baa.writeWord.copy',
      'baa.writeWord.picture',
      'baa.writeWord.dictation',
      'baa.buildSentence.hear',
      'baa.buildSentence.picture',
    ]) {
      await db.setExerciseCleanReps(
          childProfileId: 0, letterId: 'baa', exerciseId: id, cleanReps: 9);
    }

    final ctx = tester.element(find.byType(LetterUnitScreen));
    final container = ProviderScope.containerOf(ctx);
    container.read(letterUnitControllerProvider('baa').notifier).goTo(5);
    await tester.pumpAndSettle();

    expect(find.byType(MasterySection), findsOneWidget);
    // The on-device condition is met → exactly one quiet star recorded locally.
    expect(progress.mastered, contains('baa'));
    expect(progress.mastered.where((id) => id == 'baa').length, 1,
        reason: 'exactly ONE quiet star (anti-gamification; idempotent record)');
  });
}
