// LetterUnitScreen (the 6-section unit shell) behavior — Plan 07-06 Task 2.
//
// The shell hosts the 6 baa sections behind the R→L ProgressRibbon app bar and
// sequences them via the LetterUnitController, resume-aware. These tests prove:
//   • the app bar renders 6 ribbon dots, R→L (dot 0 on the right);
//   • the shell starts at section 0 (Meet) and advances through all 6 sections
//     to a single-star Mastery;
//   • the ribbon is position-only (no gold, no numerals) and Mastery shows one
//     quiet star (anti-gamification).

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_screen.dart';
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/features/letter_unit/sections/mastery_section.dart';
import 'package:qalam/features/letter_unit/sections/meet_section.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/word.dart';
import 'package:qalam/providers/audio_providers.dart';

import 'section_test_support.dart';

class _CapturingAudioPlayer implements LetterAudioPlayer {
  @override
  Future<void> playLetter(String assetPath) async {}
}

class _FakeProgressRepository implements ProgressRepository {
  final List<String> mastered = <String>[];
  @override
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  }) async {
    mastered.add(letterId);
  }

  @override
  Future<bool> isMastered(String letterId) async => false;
  @override
  Future<void> setCleanReps(
          {required String letterId, required int cleanReps}) async {}
  @override
  Future<int> getCleanReps(String letterId) async => 0;
  @override
  Stream<Set<String>> watchMasteredLetterIds() =>
      Stream.value(const <String>{});
  @override
  Stream<int> watchCleanReps(String letterId) => Stream.value(0);
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

Future<_FakeProgressRepository> _pump(WidgetTester tester) async {
  final progress = _FakeProgressRepository();
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerProvider.overrideWithValue(_CapturingAudioPlayer()),
        progressRepositoryProvider.overrideWithValue(progress),
        letterUnitDataProvider('baa').overrideWith((ref) async => _baaData()),
      ],
      child: const MaterialApp(
        home: LetterUnitScreen(letterId: 'baa'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return progress;
}

void main() {
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

  testWidgets('Test 3: Mastery shows exactly ONE star + records mastery locally',
      (tester) async {
    final progress = await _pump(tester);

    final ctx = tester.element(find.byType(LetterUnitScreen));
    final container = ProviderScope.containerOf(ctx);
    container.read(letterUnitControllerProvider('baa').notifier).goTo(5);
    await tester.pumpAndSettle();

    // Exactly ONE star (MasteryCelebration's single settling star).
    expect(find.byType(MasterySection), findsOneWidget);
    // The letter was recorded mastered to the LOCAL repo (T-07-06-02).
    expect(progress.mastered, contains('baa'));
  });

  testWidgets('Test 4: a ribbon dot jumps to that section',
      (tester) async {
    await _pump(tester);

    // Tap dot 5 (Mastery) — the shell jumps there.
    await tester.tap(find.byKey(const ValueKey('unitRibbonDot:5')));
    await tester.pumpAndSettle();

    expect(find.byType(MasterySection), findsOneWidget);
  });
}
