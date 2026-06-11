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

/// Same lesson but with a PER-LESSON toleranceRamp override (D-19): a
/// single-element ramp so the override AND the index clamp are both proven.
const String _lessonsJsonWithRamp = '''
{
  "lessons": [
    {
      "id": "lesson_01",
      "order": 1,
      "title": { "display": "Lesson 1" },
      "items": [{ "type": "letter", "ref": "alif" }],
      "unlock": { "requires": [], "passRule": "allItemsPassed" },
      "toleranceRamp": ["strict"]
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

/// A repository whose persistence ALWAYS fails — proves the best-effort
/// try/swallow contract (a storage failure must never interrupt the session).
class _ThrowingProgressRepository extends _FakeProgressRepository {
  @override
  Future<void> setCleanReps({
    required String letterId,
    required int cleanReps,
  }) async {
    throw StateError('disk full');
  }

  @override
  Future<int> getCleanReps(String letterId) async {
    throw StateError('disk full');
  }
}

// ---------------------------------------------------------------------------
// Container factory
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(
  _FakeProgressRepository fakeProgress, {
  String lessonsJson = _lessonsJson,
}) {
  final fakeCurriculum =
      CurriculumRepository.fromStrings(_lettersJson, lessonsJson);
  return ProviderContainer(overrides: [
    curriculumRepositoryProvider.overrideWithValue(fakeCurriculum),
    progressRepositoryProvider.overrideWithValue(fakeProgress),
  ]);
}

/// Flushes the controller's fire-and-forget `_loadLetter` async chain
/// (getLesson → getLetter → getCleanReps → getDefaultToleranceRamp). Each
/// `Future.delayed(zero)` is a timer event that drains all pending microtasks
/// first, so 20 rounds comfortably settles the load path.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Keeps the autoDispose session provider ALIVE across `_settle()`'s async
/// gaps — Riverpod 3 disposes an unlistened autoDispose provider almost
/// immediately, which would discard the seeded load. The production screen
/// always `ref.watch`es the controller, so a live listener is the faithful
/// harness (same Riverpod-3 pause/dispose landmine as 06-03).
void _keepAlive(ProviderContainer container) {
  final sub = container.listen(
    practiceSessionControllerProvider('lesson_01'),
    (_, _) {},
  );
  addTearDown(sub.close);
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

  // ───────────────────────────────────────────────────────────────────────────
  // Plan 06-04 — durable rep counts (D-10/D-20) + the tolerance ramp (D-18/D-19)
  // ───────────────────────────────────────────────────────────────────────────
  group('PracticeSessionController — rep persistence + tolerance ramp (06-04)',
      () {
    const pass = StrokeResult(passed: true);
    const miss = StrokeResult(passed: false, mistakeId: MistakeId.tooShort);

    test('seed (D-20): persisted cleanReps=2 primes state; preset is ramp[2]',
        () async {
      final fakeProgress = _FakeProgressRepository();
      fakeProgress.reps['alif'] = 2;
      final container = _makeContainer(fakeProgress);
      addTearDown(container.dispose);

      _keepAlive(container);
      await _settle();

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.cleanReps, 2,
          reason: 'a resumed session scores at the rep index the child '
              'actually reached (D-20)');
      expect(state.tolerancePreset, 'strict',
          reason: 'default ramp [loose, normal, strict] indexed by the '
              'PERSISTED rep count');
    });

    test('restart-resume: a NEW container primes from the same repository',
        () async {
      final fakeProgress = _FakeProgressRepository();

      // Session 1 — one clean rep, then the app "restarts" (dispose).
      final first = _makeContainer(fakeProgress);
      final firstSub = first.listen(
        practiceSessionControllerProvider('lesson_01'),
        (_, _) {},
      );
      final notifier =
          first.read(practiceSessionControllerProvider('lesson_01').notifier);
      await _settle();
      notifier.advanceToTrace();
      await notifier.onStrokeResult(pass);
      firstSub.close();
      first.dispose();

      // Session 2 — fresh container over the SAME persisted store.
      final second = _makeContainer(fakeProgress);
      addTearDown(second.dispose);
      _keepAlive(second);
      await _settle();

      final state =
          second.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.cleanReps, 1);
      expect(state.tolerancePreset, 'normal'); // ramp[1]
    });

    test('write-through (D-10): every clean rep persists; a miss persists 0',
        () async {
      final fakeProgress = _FakeProgressRepository();
      final container = _makeContainer(fakeProgress);
      addTearDown(container.dispose);
      _keepAlive(container);
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      await _settle();
      notifier.advanceToTrace();

      await notifier.onStrokeResult(pass);
      expect(fakeProgress.reps['alif'], 1);

      notifier.continueAfterPraise();
      await notifier.onStrokeResult(pass);
      expect(fakeProgress.reps['alif'], 2);

      notifier.continueAfterPraise();
      await notifier.onStrokeResult(miss);
      expect(fakeProgress.reps.containsKey('alif'), isTrue,
          reason: 'the reset is an explicit WRITE of 0, not a missing row '
              '(Pitfall 7)');
      expect(fakeProgress.reps['alif'], 0);
    });

    test('ramp indexing (D-18): 0→loose, 1→normal, 2→strict, clamps at end',
        () async {
      final fakeProgress = _FakeProgressRepository();
      final container = _makeContainer(fakeProgress);
      addTearDown(container.dispose);
      _keepAlive(container);
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      await _settle();

      PracticeState state() =>
          container.read(practiceSessionControllerProvider('lesson_01'));

      expect(state().tolerancePreset, 'loose'); // rep 0
      notifier.advanceToTrace();

      await notifier.onStrokeResult(pass);
      expect(state().tolerancePreset, 'normal'); // rep 1
      notifier.continueAfterPraise();

      await notifier.onStrokeResult(pass);
      expect(state().tolerancePreset, 'strict'); // rep 2
      notifier.continueAfterPraise();

      await notifier.onStrokeResult(pass); // mastery — cleanReps 3
      expect(state().cleanReps, 3);
      expect(state().tolerancePreset, 'strict',
          reason: 'index clamps at ramp.length - 1');
    });

    test('a miss resets the preset back to ramp[0]', () async {
      final fakeProgress = _FakeProgressRepository();
      final container = _makeContainer(fakeProgress);
      addTearDown(container.dispose);
      _keepAlive(container);
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      await _settle();
      notifier.advanceToTrace();

      await notifier.onStrokeResult(pass);
      notifier.continueAfterPraise();
      await notifier.onStrokeResult(miss);

      final state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.cleanReps, 0);
      expect(state.tolerancePreset, 'loose');
    });

    test('lesson.toleranceRamp overrides the global default (D-19)', () async {
      final fakeProgress = _FakeProgressRepository();
      final container =
          _makeContainer(fakeProgress, lessonsJson: _lessonsJsonWithRamp);
      addTearDown(container.dispose);
      _keepAlive(container);
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      await _settle();

      PracticeState state() =>
          container.read(practiceSessionControllerProvider('lesson_01'));

      // Single-element per-lesson ramp: rep 0 already 'strict'…
      expect(state().tolerancePreset, 'strict');

      // …and the clamp holds it there on later reps.
      notifier.advanceToTrace();
      await notifier.onStrokeResult(pass);
      expect(state().tolerancePreset, 'strict');
    });

    test('persistence failures are swallowed — the session continues',
        () async {
      final fakeProgress = _ThrowingProgressRepository();
      final container = _makeContainer(fakeProgress);
      addTearDown(container.dispose);
      _keepAlive(container);
      final notifier = container
          .read(practiceSessionControllerProvider('lesson_01').notifier);
      await _settle(); // getCleanReps throws — seed degrades to 0, no crash
      notifier.advanceToTrace();

      await notifier.onStrokeResult(pass); // setCleanReps throws — swallowed
      var state =
          container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.showPraise);
      expect(state.cleanReps, 1);

      notifier.continueAfterPraise();
      await notifier.onStrokeResult(miss); // reset write throws — swallowed
      state = container.read(practiceSessionControllerProvider('lesson_01'));
      expect(state.phase, PracticePhase.showFix);
      expect(state.cleanReps, 0);
    });
  });
}
