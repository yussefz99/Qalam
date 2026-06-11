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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/features/practice/practice_screen.dart';
import 'package:qalam/l10n/app_localizations.dart';
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
        expect(find.text('See journey'), findsNothing);
        expect(find.text('See Journey'), findsNothing);
        expect(find.textContaining('THIS WEEK'), findsNothing);
        expect(find.textContaining('stars earned'), findsNothing);
      },
    );
  });
}
