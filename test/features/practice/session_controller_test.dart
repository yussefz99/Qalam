// session_controller_test.dart — Plan 03-04
//
// Unit tests for PracticeSessionController state machine.
// Pure Dart — uses ProviderContainer, no widget binding, no rootBundle.
// CurriculumRepository.fromStrings avoids disk I/O; _FakeProgressRepository
// captures recordMastery calls without touching Drift / SQLite.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/providers/practice_providers.dart';

// ---------------------------------------------------------------------------
// Minimal curriculum fixture — passes the D-04 stroke validator.
// ---------------------------------------------------------------------------

const String _lettersJson = '''
{
  "letters": [
    {
      "id": "alif",
      "char": "ا",
      "name": { "ar": "اَلِف", "display": "Alif" },
      "introOrder": 1,
      "forms": { "isolated": "ا", "initial": "ا", "medial": "ا", "final": "ا" },
      "referenceStrokes": [
        {
          "order": 1,
          "label": "vertical_stroke",
          "type": "line",
          "points": [[0.5,0.0],[0.5,0.25],[0.5,0.5],[0.5,0.75],[0.5,1.0]],
          "direction": "topToBottom"
        }
      ],
      "cleanRepsToAdvance": 3,
      "commonMistakes": [
        {"id":"too_short","check":"strokeLengthBelowThreshold","feedback":"Your alif needs to be taller."},
        {"id":"wrong_direction","check":"strokeDirectionInverted","feedback":"Start at the top."},
        {"id":"too_curved","check":"strokeCurvatureExceedsThreshold","feedback":"Keep it straight."}
      ],
      "mistakesStatus": "authored",
      "signedOff": true
    }
  ]
}
''';

const String _lessonsJson = '''
{
  "lessons": [
    {
      "id": "lesson_01",
      "order": 1,
      "title": { "display": "Lesson 1" },
      "items": [{ "type": "letter", "ref": "alif" }],
      "unlock": { "requires": [], "passRule": "allItemsPassed" }
    }
  ]
}
''';

// ---------------------------------------------------------------------------
// Fake ProgressRepository — captures recordMastery calls.
// ---------------------------------------------------------------------------

class _FakeProgressRepository implements ProgressRepository {
  final List<({String letterId, int cleanReps})> calls = [];

  @override
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  }) async {
    calls.add((letterId: letterId, cleanReps: cleanReps));
  }

  @override
  Future<bool> isMastered(String letterId) async => false;

  final Map<String, int> reps = {};

  @override
  Future<void> setCleanReps({
    required String letterId,
    required int cleanReps,
  }) async {
    reps[letterId] = cleanReps;
  }

  @override
  Future<int> getCleanReps(String letterId) async => reps[letterId] ?? 0;

  @override
  Stream<Set<String>> watchMasteredLetterIds() =>
      Stream.value(const <String>{});

  @override
  Stream<int> watchCleanReps(String letterId) =>
      Stream.value(reps[letterId] ?? 0);
}

// ---------------------------------------------------------------------------
// Container factory
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(_FakeProgressRepository fakeProgress) {
  final fakeCurriculum =
      CurriculumRepository.fromStrings(_lettersJson, _lessonsJson);
  return ProviderContainer(overrides: [
    curriculumRepositoryProvider.overrideWithValue(fakeCurriculum),
    progressRepositoryProvider.overrideWithValue(fakeProgress),
  ]);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PracticeSessionController', () {
    late _FakeProgressRepository fakeProgress;
    late ProviderContainer container;

    setUp(() {
      fakeProgress = _FakeProgressRepository();
      container = _makeContainer(fakeProgress);
    });

    tearDown(() => container.dispose());

    test('initial state: watch phase, cleanReps=0, no mistakeId', () {
      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.watch);
      expect(state.cleanReps, 0);
      expect(state.lastMistakeId, isNull);
    });

    test('advanceToTrace() → trace phase', () {
      container
          .read(practiceSessionControllerProvider('lesson_01').notifier)
          .advanceToTrace();

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.trace);
    });

    test('clean pass (not yet mastery) → showPraise phase, cleanReps increments',
        () async {
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      notifier.advanceToTrace();

      await notifier.onStrokeResult(const StrokeResult(passed: true));

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.showPraise);
      expect(state.cleanReps, 1);
    });

    test('continueAfterPraise() → back to trace for the next rep', () async {
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      notifier.advanceToTrace();
      await notifier.onStrokeResult(const StrokeResult(passed: true));

      notifier.continueAfterPraise();

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.trace);
      expect(state.cleanReps, 1); // streak preserved across praise
    });

    test('3 clean passes IN A ROW → celebrate phase, cleanReps=3', () async {
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      notifier.advanceToTrace();
      const pass = StrokeResult(passed: true);

      await notifier.onStrokeResult(pass); // → showPraise (1)
      notifier.continueAfterPraise(); // → trace
      await notifier.onStrokeResult(pass); // → showPraise (2)
      notifier.continueAfterPraise(); // → trace
      await notifier.onStrokeResult(pass); // → celebrate (3)

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.celebrate);
      expect(state.cleanReps, 3);
    });

    test('3 clean passes in a row → recordMastery called once, alif, cleanReps=3',
        () async {
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      notifier.advanceToTrace();
      const pass = StrokeResult(passed: true);

      await notifier.onStrokeResult(pass);
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(pass);
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(pass);

      expect(fakeProgress.calls, hasLength(1));
      expect(fakeProgress.calls.first.letterId, 'alif');
      expect(fakeProgress.calls.first.cleanReps, 3);
    });

    test('miss → showFix phase, RESETS streak to 0, lastMistakeId set',
        () async {
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      notifier.advanceToTrace();
      const pass = StrokeResult(passed: true);
      const miss =
          StrokeResult(passed: false, mistakeId: MistakeId.tooShort);

      await notifier.onStrokeResult(pass); // cleanReps → 1
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(miss); // streak must reset to 0

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.showFix);
      expect(state.cleanReps, 0);
      expect(state.lastMistakeId, MistakeId.tooShort);
    });

    test('a miss mid-streak means mastery needs 3 fresh in a row', () async {
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      notifier.advanceToTrace();
      const pass = StrokeResult(passed: true);
      const miss =
          StrokeResult(passed: false, mistakeId: MistakeId.tooShort);

      // Two clean, then a miss — streak wiped.
      await notifier.onStrokeResult(pass);
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(pass);
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(miss); // reset to 0
      notifier.retry();

      // Now three fresh in a row are required.
      await notifier.onStrokeResult(pass);
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(pass);
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(pass);

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.celebrate);
      expect(state.cleanReps, 3);
      expect(fakeProgress.calls, hasLength(1));
    });

    test('retry() → back to trace, lastMistakeId cleared', () async {
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      notifier.advanceToTrace();
      await notifier.onStrokeResult(
        const StrokeResult(passed: false, mistakeId: MistakeId.wrongDirection),
      );

      notifier.retry();

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.trace);
      expect(state.lastMistakeId, isNull);
    });
  });
}
