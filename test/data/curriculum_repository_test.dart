import 'dart:io';

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
  });
}
