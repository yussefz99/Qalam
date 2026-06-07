// ignore_for_file: scoped_providers_should_specify_dependencies
// practice_screen_test.dart — Plan 03-04
//
// Widget tests for PracticeScreen: verifies PLAT-03 anti-gamification
// invariants — no weekly tallies, no running counters, no gamification chrome.
//
// CurriculumRepository.fromStrings + _FakeProgressRepository avoid disk/DB I/O.
// The initial Watch phase is used; navigation callbacks are never triggered.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/features/practice/practice_screen.dart';
import 'package:qalam/l10n/app_localizations.dart';

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
}

Widget _buildScreen() {
  final fakeCurriculum =
      CurriculumRepository.fromStrings(_lettersJson, _lessonsJson);

  return ProviderScope(
    overrides: [
      curriculumRepositoryProvider.overrideWithValue(fakeCurriculum),
      progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
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

      expect(find.text('Play sound'), findsNothing);
      expect(find.text('Mark correct'), findsNothing);
    });

    testWidgets('Watch phase: no premature Journey navigation', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // Journey is Phase 6 — must not appear in Phase 3
      expect(find.text('See journey'), findsNothing);
      expect(find.text('See Journey'), findsNothing);
    });
  });
}
