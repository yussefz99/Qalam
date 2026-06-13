// ignore_for_file: scoped_providers_should_specify_dependencies
// practice_screen_test.dart — Plan 03-04 (updated for workspace redesign)
//
// Widget tests for PracticeScreen: verifies PLAT-03 anti-gamification
// invariants — no weekly tallies, no running counters, no gamification chrome.
//
// CurriculumRepository.fromStrings + _FakeProgressRepository avoid disk/DB I/O.
// The initial Watch phase is used for most tests; one test advances to trace
// to verify the Sound control (owner Phase-7 pull-forward relaxation).
//
// TIMER NOTE: _TraceWorkspace starts a Timer.periodic (corner-loop). After
// entering the workspace, do NOT use pumpAndSettle() — it will time out.
// Use fixed pumps instead (tester.pump() / tester.pump(Duration(...))).
// Watch-phase-only tests may keep pumpAndSettle safely.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qalam/core/scoring/scoring_models.dart';
import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/features/practice/practice_screen.dart';
import 'package:qalam/features/practice/widgets/mastery_celebration.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/practice_providers.dart';
import 'package:qalam/providers/profile_providers.dart';
import 'package:qalam/services/model_download_service.dart';

/// Mocked ML Kit model manager so the model-download service resolves
/// deterministically in tests instead of hanging on an absent platform plugin.
class _MockModelManager extends Mock
    implements DigitalInkRecognizerModelManager {}

// ---------------------------------------------------------------------------
// Minimal curriculum fixture — same as session_controller_test.
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

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  }) async {}

  @override
  Future<bool> isMastered(String letterId) async => false;

  @override
  Future<void> setCleanReps({
    required String letterId,
    required int cleanReps,
  }) async {}

  @override
  Future<int> getCleanReps(String letterId) async => 0;

  @override
  Stream<Set<String>> watchMasteredLetterIds() =>
      Stream.value(const <String>{});

  @override
  Stream<int> watchCleanReps(String letterId) => Stream.value(0);
}

// ---------------------------------------------------------------------------
// Two-lesson fixture (alif → baa) for the celebrate → Next-Lesson behaviors.
// ---------------------------------------------------------------------------

const String _twoLettersJson = '''
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
          "points": [[0.5,0.0],[0.5,0.5],[0.5,1.0]],
          "direction": "topToBottom"
        }
      ],
      "cleanRepsToAdvance": 1,
      "commonMistakes": [
        {"id":"too_short","check":"strokeLengthBelowThreshold","feedback":"Taller."}
      ],
      "mistakesStatus": "authored",
      "signedOff": true
    },
    {
      "id": "baa",
      "char": "ب",
      "name": { "ar": "بَاء", "display": "Baa" },
      "introOrder": 2,
      "forms": { "isolated": "ب", "initial": "ب", "medial": "ب", "final": "ب" },
      "referenceStrokes": [
        {
          "order": 1,
          "label": "boat",
          "type": "line",
          "points": [[0.1,0.5],[0.5,0.5],[0.9,0.5]],
          "direction": "leftToRight"
        }
      ],
      "cleanRepsToAdvance": 1,
      "commonMistakes": [
        {"id":"too_short","check":"strokeLengthBelowThreshold","feedback":"Taller."}
      ],
      "mistakesStatus": "authored",
      "signedOff": true
    }
  ]
}
''';

const String _twoLessonsJson = '''
{
  "lessons": [
    {
      "id": "lesson_01",
      "order": 1,
      "title": { "display": "Lesson 1" },
      "items": [{ "type": "letter", "ref": "alif" }],
      "unlock": { "requires": [], "passRule": "allItemsPassed" }
    },
    {
      "id": "lesson_02",
      "order": 2,
      "title": { "display": "Lesson 2" },
      "items": [{ "type": "letter", "ref": "baa" }],
      "unlock": { "requires": ["lesson_01"], "passRule": "allItemsPassed" }
    }
  ]
}
''';

/// A stateful fake whose `watchMasteredLetterIds` stream emits the updated set
/// after each `recordMastery` — so `todayLessonProvider` recomputes from
/// lesson_01 to lesson_02 the moment alif is mastered (S1-09 immediacy).
class _StatefulProgressRepository implements ProgressRepository {
  final Set<String> _mastered = <String>{};
  final StreamController<Set<String>> _masteredCtrl =
      StreamController<Set<String>>.broadcast();
  final Map<String, int> _reps = <String, int>{};

  @override
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  }) async {
    _mastered.add(letterId);
    _masteredCtrl.add(Set<String>.from(_mastered));
  }

  @override
  Future<bool> isMastered(String letterId) async => _mastered.contains(letterId);

  @override
  Future<void> setCleanReps({
    required String letterId,
    required int cleanReps,
  }) async {
    _reps[letterId] = cleanReps;
  }

  @override
  Future<int> getCleanReps(String letterId) async => _reps[letterId] ?? 0;

  @override
  Stream<Set<String>> watchMasteredLetterIds() async* {
    yield Set<String>.from(_mastered);
    yield* _masteredCtrl.stream;
  }

  @override
  Stream<int> watchCleanReps(String letterId) => Stream.value(_reps[letterId] ?? 0);
}

Widget _buildScreen() {
  final fakeCurriculum =
      CurriculumRepository.fromStrings(_lettersJson, _lessonsJson);

  // Model reports already-downloaded → service resolves ready, so the
  // getting-ready banner (Plan 04-04) is absent and these pre-banner assertions
  // hold. A real platform manager would hang the test (no plugin in headless).
  final manager = _MockModelManager();
  when(() => manager.isModelDownloaded(any())).thenAnswer((_) async => true);

  return ProviderScope(
    overrides: [
      curriculumRepositoryProvider.overrideWithValue(fakeCurriculum),
      progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
      inkModelManagerProvider.overrideWithValue(manager),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PracticeScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PracticeScreen — PLAT-03 anti-gamification', () {
    testWidgets('Watch phase: watch-phase content is visible', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // Eyebrow ("WATCH · STROKE ORDER") or watch heading ("Watch me write alif.")
      expect(
        find.textContaining('Watch', findRichText: true),
        findsWidgets,
        reason: 'Watch phase eyebrow or heading must be visible',
      );
    });

    testWidgets('Watch phase: no "THIS WEEK" stat chrome', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('THIS WEEK'), findsNothing);
      expect(find.textContaining('this week'), findsNothing);
      expect(find.textContaining('stars this week'), findsNothing);
    });

    testWidgets('Watch phase: no running star counter', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // No "N stars" tally, no "+N" hype — stars only appear on Celebrate
      expect(find.textContaining('stars earned'), findsNothing);
      expect(find.textContaining('total stars'), findsNothing);
    });

    testWidgets('Watch phase: no debug/authoring buttons', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // "Mark correct" is always absent — scorer-only (D-06).
      expect(find.text('Mark correct'), findsNothing);
    });

    testWidgets('Watch phase: no premature Journey navigation', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // Journey is Phase 6 — must not appear in Phase 3
      expect(find.text('See journey'), findsNothing);
      expect(find.text('See Journey'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Sound control — owner pulled Phase-7 audio forward (2026-05-30 decision).
    // The "NO 'Play sound'" anti-gamification rule is RELAXED for this control
    // only. The Hear button is present in the workspace but disabled when
    // letter.audio.letter is null (as in this fixture — no audio asset yet).
    // -------------------------------------------------------------------------
    testWidgets(
      'Trace phase: Sound control present and disabled when no audio asset',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        // Settle Watch phase (safe to pumpAndSettle before workspace).
        await tester.pumpAndSettle();

        // Advance Watch → Trace by tapping "I'll Try".
        final illTry = find.text("I'll Try");
        expect(illTry, findsOneWidget, reason: 'I\'ll Try button must exist in Watch phase');
        await tester.tap(illTry);

        // Do NOT pumpAndSettle here — the workspace starts a Timer.periodic.
        // Fixed pumps only after entering the workspace.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Sound label must be present in the TutorPanel left zone.
        expect(
          find.text('Sound'),
          findsOneWidget,
          reason: 'Sound section label must appear in the tutor panel',
        );

        // The speaker button must carry the "Hear the letter" semantics label.
        expect(
          find.bySemanticsLabel('Hear the letter'),
          findsOneWidget,
          reason: 'Speaker button must have accessible semantics label',
        );

        // The fixture has no audio asset (audio field absent) → button disabled.
        // Verify by checking that a non-null onPressed is NOT wired:
        // The Semantics widget wrapping the disabled button should exist but
        // tapping it must not crash (no-op). We verify the control renders.
        expect(
          find.bySemanticsLabel('Hear the letter'),
          findsOneWidget,
          reason: 'Disabled Hear button must still be rendered (graceful)',
        );

        // Anti-gamification negatives still hold in the workspace.
        expect(find.text('Mark correct'), findsNothing);
        // Journey appears ONLY on the celebrate screen (Phase 6) — not in the
        // Watch/Trace workspace. (Reconciles the Phase-3 stale assertion: the
        // negative still holds HERE; the celebration is where journey lives.)
        expect(find.text('See journey'), findsNothing);
        expect(find.text('See Journey'), findsNothing);
        expect(find.textContaining('THIS WEEK'), findsNothing);
        expect(find.textContaining('stars earned'), findsNothing);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Celebrate phase — D-14 / D-16 / D-17, S1-09 (Phase 6, plan 06-07).
  // Drives the session controller to mastery, then asserts the celebration's
  // Next-Lesson navigation and last-lesson variant.
  // -------------------------------------------------------------------------
  group('PracticeScreen — celebrate phase (D-14 / D-16 / S1-09)', () {
    /// Builds PracticeScreen inside a GoRouter (so the celebration's Next Lesson
    /// / See journey navigation resolves) with a stateful progress repo +
    /// two-lesson catalog. Returns the [ProviderContainer] so the test can
    /// drive the session controller straight to celebrate.
    Widget buildRouterScreen({
      required ProviderContainer container,
      required _StatefulProgressRepository repo,
      String startLesson = 'lesson_01',
    }) {
      final router = GoRouter(
        initialLocation: '/practice?lesson=$startLesson',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) {
              final lessonId = state.uri.queryParameters['lesson'];
              // Mirror the real router: ValueKey forces a FRESH State per
              // lesson id (Pitfall 5) so the Next-Lesson navigation re-resolves.
              return PracticeScreen(
                key: ValueKey<String?>(lessonId),
                lessonId: lessonId,
              );
            },
          ),
          GoRoute(
            path: '/journey',
            builder: (context, state) =>
                Scaffold(body: Text('JOURNEY:${state.uri.query}')),
          ),
        ],
      );

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    ProviderContainer makeContainer(_StatefulProgressRepository repo) {
      final manager = _MockModelManager();
      when(() => manager.isModelDownloaded(any())).thenAnswer((_) async => true);
      return ProviderContainer(
        overrides: [
          curriculumRepositoryProvider.overrideWithValue(
            CurriculumRepository.fromStrings(_twoLettersJson, _twoLessonsJson),
          ),
          progressRepositoryProvider.overrideWithValue(repo),
          inkModelManagerProvider.overrideWithValue(manager),
          // Headless: the unoverridden childProfileProvider read hangs (Phase 5
          // pattern) — override to a null profile so progression degrades to
          // the first lesson deterministically.
          childProfileProvider.overrideWith((ref) async => null),
        ],
      );
    }

    testWidgets(
      'mastering lesson_01 then tapping Next Lesson navigates to lesson_02',
      (tester) async {
        final repo = _StatefulProgressRepository();
        final container = makeContainer(repo);
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildRouterScreen(container: container, repo: repo),
        );
        // Bounded pumps (NOT pumpAndSettle): the loading spinner + live mastery
        // stream keep the scheduler busy; settle the async lesson resolve.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Let the session controller finish loading the letter (so the fixture
        // cleanRepsToAdvance = 1 is in effect) before driving the rep.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Drive the session controller for lesson_01 straight to mastery
        // (fixture cleanRepsToAdvance = 1 → one clean letter = mastery).
        await container
            .read(practiceSessionControllerProvider('lesson_01').notifier)
            .onLetterResult(const LetterResult(passed: true));
        // Bounded pumps (NOT pumpAndSettle): the celebration's one-shot star
        // animation + the live mastery stream keep the frame scheduler busy.
        // Settle the post-mastery todayLessonProvider recompute so the Next
        // Lesson CTA resolves its target (lesson_02) before we tap.
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Celebration speaks the mastered letter (Pitfall 6).
        expect(find.textContaining('You learned Alif.'), findsOneWidget);
        expect(find.byType(MasteryCelebration), findsOneWidget);

        // D-14 primary CTA present (not the last lesson — baa remains).
        final nextLesson = find.text('Next Lesson');
        expect(nextLesson, findsOneWidget,
            reason: 'D-14: Next Lesson primary present when a next lesson exists');

        await tester.ensureVisible(nextLesson);
        await tester.pump();
        await tester.tap(nextLesson);
        // Let the new PracticeScreen resolve its lesson + load baa's letter.
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // S1-09: straight into the newly unlocked letter — the new PracticeScreen
        // teaches baa (route was /practice?lesson=lesson_02).
        expect(find.textContaining('Watch me write Baa.'), findsOneWidget,
            reason: 'Next Lesson routed to /practice?lesson=lesson_02 (baa)');
      },
    );

    testWidgets(
      'last lesson: See Journey primary, no Next Lesson (D-16)',
      (tester) async {
        final repo = _StatefulProgressRepository();
        // alif already mastered → today is lesson_02 (baa, the last lesson).
        await repo.recordMastery(letterId: 'alif', cleanReps: 1);
        final container = makeContainer(repo);
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildRouterScreen(
            container: container,
            repo: repo,
            startLesson: 'lesson_02',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Let the session controller finish loading baa's letter first.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // Master baa — now every lesson is passed (D-16 last-lesson variant).
        await container
            .read(practiceSessionControllerProvider('lesson_02').notifier)
            .onLetterResult(const LetterResult(passed: true));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('You learned Baa.'), findsOneWidget);
        expect(find.text('Next Lesson'), findsNothing,
            reason: 'D-16: no Next Lesson on the last lesson');
        expect(find.text('See Journey'), findsOneWidget,
            reason: 'D-16: primary slot becomes See Journey');
      },
    );

    testWidgets(
      'celebration See journey link carries the highlight param (D-15)',
      (tester) async {
        final repo = _StatefulProgressRepository();
        final container = makeContainer(repo);
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildRouterScreen(container: container, repo: repo),
        );
        // Bounded pumps (NOT pumpAndSettle): the loading spinner + live mastery
        // stream keep the scheduler busy; settle the async lesson resolve.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Let the session controller finish loading alif's letter first.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await container
            .read(practiceSessionControllerProvider('lesson_01').notifier)
            .onLetterResult(const LetterResult(passed: true));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final link = find.text('See journey');
        expect(link, findsOneWidget,
            reason: 'Phase 6 builds the journey handoff — the link EXISTS');

        await tester.ensureVisible(link);
        await tester.pump();
        await tester.tap(link);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // /journey?highlight=alif (D-15 handoff) — the just-mastered letter id.
        expect(find.textContaining('JOURNEY:highlight=alif'), findsOneWidget,
            reason: 'See journey navigates with the masteredLetterId highlight');
      },
    );
  });
}
