import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/lesson.dart';

/// A letter whose single non-dot stroke is a CLOSED loop (first ≈ last, long
/// perimeter) — the exact shape the load-time D-04 guard must reject.
const _loopLetterJson = '''
{
  "id": "alif",
  "char": "ا",
  "name": {"ar": "x", "display": "Alif"},
  "introOrder": 1,
  "forms": {"isolated": "ا", "initial": "ا", "medial": "ا", "final": "ا"},
  "referenceStrokes": [
    {
      "order": 1,
      "label": "vertical_stroke",
      "type": "line",
      "points": [[0.1, 0.1], [0.9, 0.1], [0.5, 0.9], [0.1, 0.1]],
      "direction": "topToBottom"
    }
  ],
  "cleanRepsToAdvance": 3,
  "commonMistakes": [],
  "mistakesStatus": "authored",
  "signedOff": true,
  "audio": {"letter": null, "examples": []}
}
''';

String _loopLettersJson() => '{"letters": [$_loopLetterJson]}';

// Minimal valid alif letter JSON string for fixtures
const _alifEntry = '''
{
  "id": "alif",
  "char": "ا",
  "name": {"ar": "اَلِف", "display": "Alif"},
  "introOrder": 1,
  "forms": {"isolated": "ا", "initial": "ا", "medial": "ا", "final": "ا"},
  "referenceStrokes": [],
  "cleanRepsToAdvance": 3,
  "commonMistakes": [],
  "mistakesStatus": "placeholder",
  "signedOff": false,
  "audio": {"letter": null, "examples": []}
}
''';

const _lesson01Json = '''
{
  "lessons": [
    {
      "id": "lesson_01",
      "order": 1,
      "title": {"display": "Lesson 1"},
      "items": [{"type": "letter", "ref": "alif"}],
      "unlock": {"requires": [], "passRule": "allItemsPassed"}
    }
  ]
}
''';

/// Wraps n minimal letter entries (with unique ids/introOrders) into a
/// {"letters": [...]} JSON string for the length test.
String _make28LettersJson() {
  const ids = [
    'alif','baa','taa','thaa','jeem','haa_c','khaa','daal','dhaal','raa',
    'zaay','seen','sheen','saad','daad','taa_h','zhaa','ayn','ghayn','faa',
    'qaaf','kaaf','laam','meem','noon','haa_f','waaw','yaa',
  ];
  final entries = ids.asMap().entries.map((e) => '''
    {
      "id": "${e.value}",
      "char": "ا",
      "name": {"ar": "x", "display": "${e.value}"},
      "introOrder": ${e.key + 1},
      "forms": {"isolated": "ا", "initial": "ا", "medial": "ا", "final": "ا"},
      "referenceStrokes": [],
      "cleanRepsToAdvance": 3,
      "commonMistakes": [],
      "mistakesStatus": "placeholder",
      "signedOff": false,
      "audio": {"letter": null, "examples": []}
    }''').join(',');
  return '{"letters": [$entries]}';
}

String _singleLetterJson() => '{"letters": [$_alifEntry]}';

void main() {
  group('CurriculumRepository', () {
    test('getLetters() returns 28 Letters when fixture has 28 entries', () async {
      final repo = CurriculumRepository.fromStrings(
        _make28LettersJson(),
        _lesson01Json,
      );

      final letters = await repo.getLetters();

      expect(letters.length, 28);
    });

    test('getLetters() returns Letters sorted by introOrder ascending (alif first)', () async {
      final repo = CurriculumRepository.fromStrings(
        _make28LettersJson(),
        _lesson01Json,
      );

      final letters = await repo.getLetters();

      expect(letters.first.id, 'alif');
      expect(letters.first.introOrder, 1);
    });

    test('getLetter returns the matching Letter on hit', () async {
      final repo = CurriculumRepository.fromStrings(
        _singleLetterJson(),
        _lesson01Json,
      );

      final letter = await repo.getLetter('alif');

      expect(letter, isA<Letter>());
      expect(letter!.id, 'alif');
    });

    test('getLetter returns null on miss', () async {
      final repo = CurriculumRepository.fromStrings(
        _singleLetterJson(),
        _lesson01Json,
      );

      final letter = await repo.getLetter('nonexistent');

      expect(letter, isNull);
    });

    test('getLesson returns the matching Lesson on hit', () async {
      final repo = CurriculumRepository.fromStrings(
        _singleLetterJson(),
        _lesson01Json,
      );

      final lesson = await repo.getLesson('lesson_01');

      expect(lesson, isA<Lesson>());
      expect(lesson!.id, 'lesson_01');
      expect(lesson.items.length, 1);
    });

    test('getLesson returns null on miss', () async {
      final repo = CurriculumRepository.fromStrings(
        _singleLetterJson(),
        _lesson01Json,
      );

      final lesson = await repo.getLesson('nonexistent');

      expect(lesson, isNull);
    });

    test('getExercises() returns empty list when no exercises file (test mode)', () async {
      final repo = CurriculumRepository.fromStrings(
        _singleLetterJson(),
        _lesson01Json,
      );

      final exercises = await repo.getExercises();

      expect(exercises.isEmpty, true);
    });

    test('getLetters() called twice returns same List instance (memory cache)', () async {
      final repo = CurriculumRepository.fromStrings(
        _singleLetterJson(),
        _lesson01Json,
      );

      final first = await repo.getLetters();
      final second = await repo.getLetters();

      expect(identical(first, second), true);
    });
  });

  group('CurriculumRepository — shipped catalog integrity (Pitfall 10, T-06-05)', () {
    // Load BOTH shipped assets off disk through the repository — this is the
    // integrity gate: a typo'd ref in lessons.json must fail here, on every
    // suite run, not silently break practice at runtime.
    late CurriculumRepository repo;

    setUp(() {
      final shippedLetters =
          File('assets/curriculum/letters.json').readAsStringSync();
      final shippedLessons =
          File('assets/curriculum/lessons.json').readAsStringSync();
      repo = CurriculumRepository.fromStrings(shippedLetters, shippedLessons);
    });

    test('getLessons() returns exactly 28 lessons (D-01)', () async {
      final lessons = await repo.getLessons();

      expect(lessons.length, 28);
    });

    test('every lesson.items[].ref resolves to a letter id in letters.json',
        () async {
      final lessons = await repo.getLessons();
      final letterIds = (await repo.getLetters()).map((l) => l.id).toSet();

      for (final lesson in lessons) {
        for (final item in lesson.items) {
          expect(letterIds, contains(item.ref),
              reason: '${lesson.id} references unknown letter "${item.ref}"');
        }
      }
    });

    test('every unlock.requires[] entry resolves to a lesson id', () async {
      final lessons = await repo.getLessons();
      final lessonIds = lessons.map((l) => l.id).toSet();

      for (final lesson in lessons) {
        for (final req in lesson.unlock.requires) {
          expect(lessonIds, contains(req),
              reason: '${lesson.id} requires unknown lesson "$req"');
        }
      }
    });

    test('orders are exactly 1..28 with no duplicates', () async {
      final lessons = await repo.getLessons();
      final orders = lessons.map((l) => l.order).toList()..sort();

      expect(orders, List<int>.generate(28, (i) => i + 1));
    });

    test('lesson IDs are unique', () async {
      final lessons = await repo.getLessons();
      final ids = lessons.map((l) => l.id).toSet();

      expect(ids.length, lessons.length);
    });

    test('lesson_01 has empty requires and ref alif', () async {
      final lesson01 = await repo.getLesson('lesson_01');

      expect(lesson01, isNotNull);
      expect(lesson01!.unlock.requires, isEmpty);
      expect(lesson01.items.single.ref, 'alif');
    });

    test('defaultToleranceRamp parses as [loose, normal, strict] (D-19)',
        () async {
      final ramp = await repo.getDefaultToleranceRamp();

      expect(ramp, ['loose', 'normal', 'strict']);
    });

    test('getDefaultToleranceRamp() falls back to the decided default when '
        'the key is absent', () async {
      final fallbackRepo = CurriculumRepository.fromStrings(
        _singleLetterJson(),
        _lesson01Json, // fixture has no defaultToleranceRamp key
      );

      final ramp = await fallbackRepo.getDefaultToleranceRamp();

      expect(ramp, ['loose', 'normal', 'strict']);
    });
  });

  group('CurriculumRepository — load-time D-04 guard (T-02.1-03)', () {
    test('the SHIPPED letters.json passes the validator at load', () async {
      // Read the real shipped asset off disk (not a fixture) and load it through
      // the repository — no outline may ship, so this must not throw.
      final shipped =
          File('assets/curriculum/letters.json').readAsStringSync();
      final repo = CurriculumRepository.fromStrings(shipped, _lesson01Json);

      final letters = await repo.getLetters();

      expect(letters.length, 28);
      expect(letters.first.id, 'alif');
    });

    test('a closed-loop reference stroke makes load throw (NOT-CLOSED fires)',
        () async {
      final repo = CurriculumRepository.fromStrings(
        _loopLettersJson(),
        _lesson01Json,
      );

      // Assert on the message so the test proves the closed-loop guard fired —
      // not merely that SOME validation error was raised.
      await expectLater(
        repo.getLetters(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('closed outline loop'),
          ),
        ),
      );
    });

    // Fix A (06-09): at the lowered kClosedLoopEpsilon = 0.10, the 9 legitimate
    // curl letters — whose pen genuinely loops back near the start over a
    // winding path (0.12–0.29 from start), NOT a ≈0.0 closed outline — must now
    // load through the validator without throwing. This proves the D-04 guard
    // no longer false-positives on them.
    test('the 9 curl letters all load (Fix A — D-04 no longer false-positives)',
        () async {
      final shipped =
          File('assets/curriculum/letters.json').readAsStringSync();
      final repo = CurriculumRepository.fromStrings(shipped, _lesson01Json);

      final loadedIds = (await repo.getLetters()).map((l) => l.id).toSet();

      const curlLetters = [
        'jeem',
        'haa_c',
        'khaa',
        'saad',
        'daad',
        'taa_h',
        'ayn',
        'ghayn',
        'faa',
      ];
      for (final id in curlLetters) {
        expect(loadedIds, contains(id),
            reason: 'curl letter "$id" was rejected at load by the D-04 guard');
      }
    });
  });

  group('curl-letter centerline sanity (Fix A confirm-before-shipping)', () {
    // The automated half of Fix A's confirm-before-shipping check: each of the
    // 9 curl letters must be a genuine OPEN centerline (pen-tip path down the
    // middle, looping back NEAR the start) — NOT a closed edge-trace around the
    // letter's outline that the 0.10 threshold would merely mask. A real
    // centerline ends ≥ 0.10 from its start; a return-to-start edge-trace ends
    // ≈ 0.0. If any letter's first→last distance comes back < 0.10, the test
    // fails LOUDLY: that letter is an edge-trace needing owner / owner's-mother
    // re-authoring (OUT OF SCOPE here — surface it, do not patch the data).
    //
    // Expected lower bound per letter from 06-FIXES.md (taa_h tightest, 0.121).
    const expectedFirstToLast = <String, double>{
      'jeem': 0.289,
      'haa_c': 0.270,
      'khaa': 0.272,
      'saad': 0.193,
      'daad': 0.189,
      'taa_h': 0.121,
      'ayn': 0.268,
      'ghayn': 0.258,
      'faa': 0.265,
    };

    late Map<String, Letter> byId;

    setUp(() async {
      final shipped =
          File('assets/curriculum/letters.json').readAsStringSync();
      final repo = CurriculumRepository.fromStrings(shipped, _lesson01Json);
      byId = {for (final l in await repo.getLetters()) l.id: l};
    });

    for (final entry in expectedFirstToLast.entries) {
      final id = entry.key;
      final expectedMin = entry.value;

      test('$id first reference stroke is an open centerline '
          '(first→last ≥ 0.10, not an edge-trace)', () {
        final letter = byId[id];
        expect(letter, isNotNull, reason: 'curl letter "$id" did not load');

        // The first NON-DOT reference stroke is the body centerline.
        final body = letter!.referenceStrokes
            .firstWhere((s) => s.type != 'dot');
        final first = body.points.first;
        final last = body.points.last;
        final firstToLast = math.sqrt(
          math.pow(first[0] - last[0], 2) + math.pow(first[1] - last[1], 2),
        );

        // ≥ 0.10: admitted by the lowered D-04 guard AND not a ≈0.0 outline.
        expect(firstToLast, greaterThanOrEqualTo(0.10),
            reason: 'curl letter "$id" first→last distance '
                '${firstToLast.toStringAsFixed(3)} < 0.10 — this looks like an '
                'edge-trace (return-to-start outline), NOT an open centerline. '
                'It must be RE-AUTHORED by the owner / owner\'s mother, not '
                'masked by the threshold (OUT OF SCOPE for 06-09).');

        // Cross-check against 06-FIXES.md's recorded number so a future stroke
        // re-author that quietly drops the centerline below its documented
        // value is caught here too (small tolerance for authoring jitter).
        expect(firstToLast, closeTo(expectedMin, 0.02),
            reason: 'curl letter "$id" first→last distance '
                '${firstToLast.toStringAsFixed(3)} drifted from the '
                '06-FIXES.md value $expectedMin');
      });
    }
  });
}
