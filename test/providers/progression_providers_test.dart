// Wave-0 validation scaffold — S1-09 stream-driven immediacy (Plan 06-03).
//
// INTENTIONALLY RED at Wave 0: imports
// package:qalam/providers/progression_providers.dart, which does not yet
// exist. Task 2 of this plan builds the live progression providers and turns
// this green. Do NOT add a lib/ stub here.
//
// The contract proven here (the heart of S1-09 "immediate on pass"):
//   recordMastery → the drift .watch() stream emits → masteredLetterIdsProvider
//   pushes the new set → progression/today providers recompute ON THEIR OWN.
// This file contains ZERO manual provider-refresh calls (acceptance grep) —
// the recomputation must fall out of the stream wiring, never be forced.
//
// Provider API named by this contract:
//   masteredLetterIdsProvider  — StreamProvider<Set<String>>
//   cleanRepsForLetterProvider — StreamProvider.family<int, String>
//   progressionProvider        — FutureProvider<ProgressionSnapshot>
//   todayLessonProvider        — FutureProvider<Lesson?>
//
// Precedent-setting first stream-provider test (PATTERNS "No Analog Found"):
// ProviderContainer + injected in-memory AppDatabase + the SHIPPED curriculum
// assets (real 28-lesson catalog, canonical letter ids) via
// CurriculumRepository.fromStrings.

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/models/lesson.dart';
import 'package:qalam/models/lesson_progression.dart';
import 'package:qalam/providers/profile_providers.dart';
import 'package:qalam/providers/progression_providers.dart';

// ---------------------------------------------------------------------------
// Fixtures + helpers
// ---------------------------------------------------------------------------

/// The real shipped curriculum (28 lessons, canonical letter ids) loaded from
/// disk — same idiom as the Pitfall-10 integrity tests.
CurriculumRepository _shippedCurriculum() {
  final lettersJson = File('assets/curriculum/letters.json').readAsStringSync();
  final lessonsJson = File('assets/curriculum/lessons.json').readAsStringSync();
  return CurriculumRepository.fromStrings(lettersJson, lessonsJson);
}

ChildProfile _profile(String startingLessonId) => ChildProfile(
      id: 1,
      nicknameId: 'nick_star',
      avatarId: 'avatar_1',
      grade: 'kg',
      startingLessonId: startingLessonId,
      createdAt: 0,
    );

/// Container over an injected in-memory AppDatabase, the shipped curriculum,
/// and a profile with the given startingLessonId.
ProviderContainer _makeContainer({
  required AppDatabase db,
  required CurriculumRepository curriculum,
  required String startingLessonId,
}) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      curriculumRepositoryProvider.overrideWithValue(curriculum),
      childProfileProvider
          .overrideWith((ref) async => _profile(startingLessonId)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Completes with today's lesson once [predicate] holds — driven purely by
/// provider recomputation (no manual refresh anywhere in this file).
Future<Lesson?> _todayWhen(
  ProviderContainer container,
  bool Function(Lesson?) predicate,
) {
  final completer = Completer<Lesson?>();
  final sub = container.listen<AsyncValue<Lesson?>>(
    todayLessonProvider,
    (previous, next) {
      // Riverpod 3: `.value` returns the latest data (or null while none).
      if (!completer.isCompleted && next.hasValue && predicate(next.value)) {
        completer.complete(next.value);
      }
    },
    fireImmediately: true,
  );
  return completer.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(sub.close);
}

/// Completes with the progression snapshot once [predicate] holds.
Future<ProgressionSnapshot> _snapshotWhen(
  ProviderContainer container,
  bool Function(ProgressionSnapshot) predicate,
) {
  final completer = Completer<ProgressionSnapshot>();
  final sub = container.listen<AsyncValue<ProgressionSnapshot>>(
    progressionProvider,
    (previous, next) {
      final snapshot = next.value;
      if (!completer.isCompleted && snapshot != null && predicate(snapshot)) {
        completer.complete(snapshot);
      }
    },
    fireImmediately: true,
  );
  return completer.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(sub.close);
}

/// Completes once the family stream for [letterId] emits [expected].
Future<int> _repsWhen(
  ProviderContainer container,
  String letterId,
  int expected,
) {
  final completer = Completer<int>();
  final sub = container.listen<AsyncValue<int>>(
    cleanRepsForLetterProvider(letterId),
    (previous, next) {
      if (!completer.isCompleted && next.hasValue && next.value == expected) {
        completer.complete(expected);
      }
    },
    fireImmediately: true,
  );
  return completer.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(sub.close);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late NativeDatabase executor;
  late CurriculumRepository curriculum;

  setUp(() {
    executor = NativeDatabase.memory();
    db = AppDatabase(executor);
    curriculum = _shippedCurriculum();
    // The injected executor is owned by the test (AppDatabase.close is a no-op
    // for injected executors).
    addTearDown(() => executor.close());
  });

  test('initial state: today resolves to lesson_01 with empty mastery (S1-01)',
      () async {
    final container = _makeContainer(
      db: db,
      curriculum: curriculum,
      startingLessonId: 'lesson_01',
    );

    final mastered = await container.read(masteredLetterIdsProvider.future);
    expect(mastered, isEmpty,
        reason: 'a fresh database has no mastered letters');

    final today = await container.read(todayLessonProvider.future);
    expect(today, isNotNull);
    expect(today!.id, 'lesson_01',
        reason: 'with empty mastery, today is the first lesson (D-06)');

    final snapshot = await container.read(progressionProvider.future);
    expect(snapshot.unlockedLessonIds, contains('lesson_01'));
    expect(snapshot.unlockedLessonIds, isNot(contains('lesson_02')),
        reason: 'lesson_02 requires lesson_01 to be passed (D-02)');
    expect(snapshot.allMastered, isFalse);
  });

  test(
      'S1-09 immediacy: recordMastery(alif) → masteredLetterIdsProvider emits '
      '{alif} → today recomputes to lesson_02 with no manual refresh',
      () async {
    final container = _makeContainer(
      db: db,
      curriculum: curriculum,
      startingLessonId: 'lesson_01',
    );

    // Keep the chain alive for the duration of the test.
    final keepAliveSub =
        container.listen<AsyncValue<Lesson?>>(todayLessonProvider, (_, _) {});
    addTearDown(keepAliveSub.close);

    final before = await container.read(todayLessonProvider.future);
    expect(before!.id, 'lesson_01');

    // The pass. Nothing else — no provider is touched after this line.
    await db.recordMastery(letterId: 'alif', cleanReps: 3);

    final after = await _todayWhen(container, (l) => l?.id == 'lesson_02');
    expect(after!.id, 'lesson_02',
        reason: 'passing alif must unlock and surface baa as today (S1-09)');

    final mastered = await container.read(masteredLetterIdsProvider.future);
    expect(mastered, contains('alif'));

    final snapshot = await container.read(progressionProvider.future);
    expect(snapshot.unlockedLessonIds, contains('lesson_02'),
        reason: 'lesson_02 unlocks the moment lesson_01 is passed (D-02)');
  });

  test(
      'D-06 entry point: startingLessonId lesson_03 → today is lesson_03; '
      'mastering an EARLIER skipped letter (alif) does not change today',
      () async {
    final container = _makeContainer(
      db: db,
      curriculum: curriculum,
      startingLessonId: 'lesson_03',
    );

    final keepAliveSub =
        container.listen<AsyncValue<Lesson?>>(todayLessonProvider, (_, _) {});
    addTearDown(keepAliveSub.close);

    final initial = await container.read(todayLessonProvider.future);
    expect(initial!.id, 'lesson_03',
        reason: 'today starts AT the profile entry point (D-06)');

    // Master the skipped earlier letter (alif = lesson_01's letter).
    await db.recordMastery(letterId: 'alif', cleanReps: 3);

    // Wait until the recomputation has consumed the new mastery set, then
    // assert today did NOT march backward or forward.
    final snapshot = await _snapshotWhen(
      container,
      (s) => s.masteredLetterIds.contains('alif'),
    );
    expect(snapshot.today, isNotNull);
    expect(snapshot.today!.id, 'lesson_03',
        reason: 'skipped earlier letters never become (or move) today (D-06)');
  });

  test(
      'cleanRepsForLetterProvider(baa) emits the persisted count after '
      'setCleanReps and updates on overwrite (D-10)', () async {
    final container = _makeContainer(
      db: db,
      curriculum: curriculum,
      startingLessonId: 'lesson_01',
    );

    final keepAliveSub = container.listen<AsyncValue<int>>(
        cleanRepsForLetterProvider('baa'), (_, _) {});
    addTearDown(keepAliveSub.close);

    // Never practiced → 0, never null/throw.
    expect(await _repsWhen(container, 'baa', 0), 0);

    await db.setCleanReps(letterId: 'baa', cleanReps: 2);
    expect(await _repsWhen(container, 'baa', 2), 2,
        reason: 'the family stream must emit the persisted count');

    // Overwrite semantics: a new write replaces the count.
    await db.setCleanReps(letterId: 'baa', cleanReps: 3);
    expect(await _repsWhen(container, 'baa', 3), 3,
        reason: 'an overwrite must surface through the same stream');
  });

  test(
      'all-mastered: with every lesson\'s letter mastered, todayLesson '
      'resolves null and the snapshot says allMastered (D-11)', () async {
    // Master every letter referenced by the shipped catalog BEFORE reading.
    final lessons = await curriculum.getLessons();
    for (final lesson in lessons) {
      for (final item in lesson.items.where((i) => i.type == 'letter')) {
        await db.recordMastery(letterId: item.ref, cleanReps: 3);
      }
    }

    final container = _makeContainer(
      db: db,
      curriculum: curriculum,
      startingLessonId: 'lesson_01',
    );

    final today = await _todayWhen(container, (l) => l == null);
    expect(today, isNull,
        reason: 'every lesson passed → no today lesson (D-11)');

    final snapshot = await container.read(progressionProvider.future);
    expect(snapshot.allMastered, isTrue);
    expect(snapshot.unlockedLessonIds.length, lessons.length,
        reason: 'everything is unlocked when everything is passed');
  });
}
