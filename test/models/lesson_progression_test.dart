// Wave-0 validation scaffold — Phase 06 progression engine contract.
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/models/lesson_progression.dart,
// which does not yet exist. Plan 06-01 Task 3 builds the pure-Dart engine and
// turns this green. Do NOT add a lib/ stub here.
//
// Encodes the decided progression semantics (06-RESEARCH Pattern 2):
//   D-02 — generic unlock: a lesson is unlocked iff every lesson listed in
//          unlock.requires[] is passed; empty requires[] = unlocked.
//   D-03 — signedOff is NOT an input: DRAFT letters pass/unlock normally and
//          the engine API does not even accept a signedOff parameter.
//   D-05 — lessons earlier than startingLessonId are unlocked-but-not-mastered,
//          regardless of their requires[] (skipped-but-unlocked).
//   D-06 — todayLesson = first non-passed lesson AT OR AFTER startingLessonId;
//          unknown startingLessonId is defensively treated as index 0.
//   D-11 — todayLesson returns null when every lesson at/after the start is
//          passed (the all-mastered state); ProgressionSnapshot.allMastered.

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/models/lesson.dart';
import 'package:qalam/models/lesson_progression.dart';

/// Builds a minimal in-test Lesson fixture (no asset loading).
Lesson makeLesson({
  required String id,
  required int order,
  required List<String> refs,
  List<String> requires = const [],
  List<LessonItem>? items,
}) {
  return Lesson(
    id: id,
    order: order,
    title: LessonTitle(display: 'Lesson $order'),
    items: items ?? refs.map((r) => LessonItem(type: 'letter', ref: r)).toList(),
    unlock: LessonUnlock(requires: requires, passRule: 'allItemsPassed'),
  );
}

void main() {
  // A small 5-lesson linear chain mirroring the real catalog shape:
  // lesson_01(alif) <- lesson_02(baa) <- lesson_03(taa) <- lesson_04(thaa)
  // <- lesson_05(jeem).
  final l1 = makeLesson(id: 'lesson_01', order: 1, refs: ['alif']);
  final l2 = makeLesson(
      id: 'lesson_02', order: 2, refs: ['baa'], requires: ['lesson_01']);
  final l3 = makeLesson(
      id: 'lesson_03', order: 3, refs: ['taa'], requires: ['lesson_02']);
  final l4 = makeLesson(
      id: 'lesson_04', order: 4, refs: ['thaa'], requires: ['lesson_03']);
  final l5 = makeLesson(
      id: 'lesson_05', order: 5, refs: ['jeem'], requires: ['lesson_04']);
  final chain = [l1, l2, l3, l4, l5];
  final byId = {for (final l in chain) l.id: l};

  group('lessonPassed — passRule allItemsPassed', () {
    test('passes when every letter item ref is in masteredLetterIds', () {
      expect(lessonPassed(l1, {'alif'}), isTrue);
    });

    test('does not pass when a letter item ref is missing from mastered', () {
      expect(lessonPassed(l1, <String>{}), isFalse);
      expect(lessonPassed(l1, {'baa'}), isFalse);
    });

    test('multi-letter lesson requires ALL letter items mastered', () {
      final multi = makeLesson(
          id: 'lesson_x', order: 9, refs: ['alif', 'baa']);
      expect(lessonPassed(multi, {'alif'}), isFalse);
      expect(lessonPassed(multi, {'alif', 'baa'}), isTrue);
    });

    test('non-letter items are ignored by allItemsPassed', () {
      final mixed = makeLesson(
        id: 'lesson_m',
        order: 9,
        refs: const [],
        items: const [
          LessonItem(type: 'letter', ref: 'alif'),
          LessonItem(type: 'exercise', ref: 'ex_01'),
        ],
      );
      // 'ex_01' is never in masteredLetterIds — the exercise item must not
      // block the pass.
      expect(lessonPassed(mixed, {'alif'}), isTrue);
    });
  });

  group('lessonUnlocked — D-02 generic requires[] evaluation', () {
    test('D-02: empty requires[] means unlocked', () {
      expect(lessonUnlocked(l1, byId, <String>{}), isTrue);
    });

    test('D-02: locked until the single prerequisite lesson is passed', () {
      expect(lessonUnlocked(l2, byId, <String>{}), isFalse);
      expect(lessonUnlocked(l2, byId, {'alif'}), isTrue);
    });

    test('D-02 multi-prerequisite: requires [a, b] stays locked until BOTH '
        'are passed', () {
      final a = makeLesson(id: 'lesson_a', order: 1, refs: ['alif']);
      final b = makeLesson(id: 'lesson_b', order: 2, refs: ['baa']);
      final c = makeLesson(
        id: 'lesson_c',
        order: 3,
        refs: ['taa'],
        requires: ['lesson_a', 'lesson_b'],
      );
      final map = {'lesson_a': a, 'lesson_b': b, 'lesson_c': c};

      expect(lessonUnlocked(c, map, <String>{}), isFalse);
      expect(lessonUnlocked(c, map, {'alif'}), isFalse, // only a passed
          reason: 'one of two prerequisites passed must NOT unlock');
      expect(lessonUnlocked(c, map, {'baa'}), isFalse, // only b passed
          reason: 'one of two prerequisites passed must NOT unlock');
      expect(lessonUnlocked(c, map, {'alif', 'baa'}), isTrue);
    });

    test('D-02: a requires[] entry that resolves to no lesson keeps it locked '
        '(defensive)', () {
      final orphan = makeLesson(
        id: 'lesson_o',
        order: 9,
        refs: ['yaa'],
        requires: ['lesson_missing'],
      );
      expect(lessonUnlocked(orphan, byId, {'alif', 'baa', 'taa'}), isFalse);
    });
  });

  group('D-03 — signedOff is never an input', () {
    test('D-03: a lesson over a DRAFT (unsigned) letter passes and unlocks '
        'normally from mastery alone', () {
      // 'baa' is signedOff: false in the real catalog. The engine sees only
      // masteredLetterIds — Lesson carries no signedOff and the API accepts
      // none (compile-level guarantee: these calls take only lessons + the
      // mastered set).
      expect(lessonPassed(l2, {'baa'}), isTrue);
      expect(lessonUnlocked(l3, byId, {'baa'}), isTrue);
    });
  });

  group('D-05 — lessons before startingLessonId are skipped-but-unlocked', () {
    test('D-05: with start = lesson_03, lessons 01-02 are unlocked but NOT '
        'passed', () {
      final snap = ProgressionSnapshot.compute(chain, 'lesson_03', <String>{});

      expect(snap.unlockedLessonIds, contains('lesson_01'));
      expect(snap.unlockedLessonIds, contains('lesson_02'));
      expect(lessonPassed(l1, <String>{}), isFalse);
      expect(lessonPassed(l2, <String>{}), isFalse);
    });

    test('D-05: index < startIndex forces unlocked regardless of requires[]',
        () {
      // lesson_02 requires lesson_01, which is NOT passed — yet with start at
      // lesson_03 it must still compute as unlocked.
      final snap = ProgressionSnapshot.compute(chain, 'lesson_03', <String>{});

      expect(lessonUnlocked(l2, byId, <String>{}), isFalse,
          reason: 'generically (D-02) lesson_02 is locked with nothing passed');
      expect(snap.unlockedLessonIds, contains('lesson_02'),
          reason: 'D-05 overrides requires[] for lessons before the start');
    });

    test('D-05/D-06: skipped earlier lessons are never today', () {
      final snap = ProgressionSnapshot.compute(chain, 'lesson_03', <String>{});

      expect(snap.today, isNotNull);
      expect(snap.today!.id, 'lesson_03');
      expect(todayLesson(chain, 'lesson_03', <String>{})!.id, 'lesson_03');
    });
  });

  group('D-06 — todayLesson = first non-passed at/after startingLessonId', () {
    test('D-06: mastered = {} with start at lesson_01 → today is lesson_01',
        () {
      expect(todayLesson(chain, 'lesson_01', <String>{})!.id, 'lesson_01');
    });

    test('D-06: first NON-passed wins — a passed gap is skipped over', () {
      // lesson_01 passed, lesson_02 not, lesson_03 (taa) also mastered:
      // today must be lesson_02, the first non-passed at/after start.
      expect(
        todayLesson(chain, 'lesson_01', {'alif', 'taa'})!.id,
        'lesson_02',
      );
    });

    test('D-06: today starts AT startingLessonId, not after it', () {
      expect(todayLesson(chain, 'lesson_04', <String>{})!.id, 'lesson_04');
    });

    test('D-06: unknown startingLessonId is defensively treated as index 0',
        () {
      expect(todayLesson(chain, 'lesson_99', <String>{})!.id, 'lesson_01');
      final snap = ProgressionSnapshot.compute(chain, 'lesson_99', <String>{});
      expect(snap.today!.id, 'lesson_01');
    });
  });

  group('D-11 — all-mastered state', () {
    test('D-11: today is null when every lesson at/after the start is passed',
        () {
      final allMastered = {'alif', 'baa', 'taa', 'thaa', 'jeem'};
      expect(todayLesson(chain, 'lesson_01', allMastered), isNull);

      final snap = ProgressionSnapshot.compute(chain, 'lesson_01', allMastered);
      expect(snap.today, isNull);
      expect(snap.allMastered, isTrue);
    });

    test('D-11: only lessons at/after the start count — unpassed skipped '
        'lessons do not block the all-mastered state', () {
      // Start at lesson_03; only taa/thaa/jeem mastered. lessons 01-02 are
      // skipped (D-05) and must not prevent today == null.
      final snap = ProgressionSnapshot.compute(
          chain, 'lesson_03', {'taa', 'thaa', 'jeem'});

      expect(snap.today, isNull);
      expect(snap.allMastered, isTrue);
    });

    test('allMastered is false while a lesson at/after the start remains',
        () {
      final snap = ProgressionSnapshot.compute(chain, 'lesson_01', {'alif'});
      expect(snap.allMastered, isFalse);
    });
  });

  group('ProgressionSnapshot.compute — full snapshot shape', () {
    test('phase happy path: mastered = {} → today is lesson_01 (S1-01)', () {
      final snap = ProgressionSnapshot.compute(chain, 'lesson_01', <String>{});

      expect(snap.today!.id, 'lesson_01');
      expect(snap.unlockedLessonIds, contains('lesson_01'));
      expect(snap.unlockedLessonIds, isNot(contains('lesson_02')));
      expect(snap.allMastered, isFalse);
    });

    test('phase happy path: mastered = {alif} → lesson_01 passed, lesson_02 '
        'unlocked AND today (S1-09)', () {
      final snap = ProgressionSnapshot.compute(chain, 'lesson_01', {'alif'});

      expect(lessonPassed(l1, {'alif'}), isTrue);
      expect(snap.unlockedLessonIds, contains('lesson_02'));
      expect(snap.today!.id, 'lesson_02');
      expect(snap.unlockedLessonIds, isNot(contains('lesson_03')),
          reason: 'lesson_03 stays locked until lesson_02 is passed');
    });

    test('masteredLetterIds echoes the input mastery set', () {
      final snap = ProgressionSnapshot.compute(chain, 'lesson_01', {'alif'});
      expect(snap.masteredLetterIds, {'alif'});
    });

    test('lessonIdByLetterId maps every letter ref to its lesson id', () {
      final snap = ProgressionSnapshot.compute(chain, 'lesson_01', <String>{});

      expect(snap.lessonIdByLetterId['alif'], 'lesson_01');
      expect(snap.lessonIdByLetterId['baa'], 'lesson_02');
      expect(snap.lessonIdByLetterId['jeem'], 'lesson_05');
      expect(snap.lessonIdByLetterId.length, 5);
    });
  });
}
