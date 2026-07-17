// ignore_for_file: scoped_providers_should_specify_dependencies
// getting_ready_test.dart — Plan 04-04, Task 2 (D-05)
//
// When the ML Kit Arabic model is NOT yet cached, the practice flow must show a
// calm "getting ready" state — NEVER an error and NEVER a hard block. The
// geometric scorer keeps working; only the advisory ML Kit gate abstains until
// the model is ready (D-04 / D-05).
//
// The model manager is mocked via the `inkModelManagerProvider` seam (the same
// seam the model_download_service unit tests use) so isModelDownloaded → false
// leaves the service in the not-ready state deterministically, without a device.
//
// TIMER NOTE (from practice_screen_test): _TraceWorkspace starts a periodic
// corner-loop Timer. After entering the workspace do NOT use pumpAndSettle — use
// fixed pumps.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/features/practice/practice_screen.dart';
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/profile_providers.dart';
import 'package:qalam/services/model_download_service.dart';

class _MockModelManager extends Mock
    implements DigitalInkRecognizerModelManager {}

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

  // D-15 fold (19-04): folded aggregate accessors — no persisted reps here.
  @override
  Future<int> letterCleanReps(String letterId) async => 0;

  @override
  Stream<int> watchLetterCleanReps(String letterId) => Stream.value(0);

  @override
  Future<void> setLetterCleanReps({
    required String letterId,
    required int cleanReps,
  }) async {}
}

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
        {"id":"too_short","check":"strokeLengthBelowThreshold","feedback":"Your alif needs to be taller."}
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

Widget _buildScreen(DigitalInkRecognizerModelManager manager) {
  final fakeCurriculum =
      CurriculumRepository.fromStrings(_lettersJson, _lessonsJson);

  return ProviderScope(
    overrides: [
      curriculumRepositoryProvider.overrideWithValue(fakeCurriculum),
      progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
      // Model manager reports NOT downloaded → service stays not-ready.
      inkModelManagerProvider.overrideWithValue(manager),
      // PracticeScreen resolves today's lesson via todayLessonProvider →
      // progressionProvider, which reads childProfileProvider. Without an
      // override that read hangs until the 3s bounded timeout, blocking the
      // watch phase past these fixed 50ms pumps. A null profile resolves
      // immediately → today = first lesson (alif), matching this curriculum.
      childProfileProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PracticeScreen(),
    ),
  );
}

void main() {
  testWidgets(
      'model not ready → calm getting-ready banner shown in trace, not an error',
      (WidgetTester tester) async {
    final manager = _MockModelManager();
    // Not downloaded and the fetch never succeeds → service stays not-ready.
    when(() => manager.isModelDownloaded(any()))
        .thenAnswer((_) async => false);
    when(() => manager.downloadModel(any())).thenAnswer((_) async => false);

    await tester.pumpWidget(_buildScreen(manager));
    // Watch phase loads the letter + resolves the (not-ready) model state.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Advance Watch → Trace so the workspace (where the banner overlays) renders.
    await tester.tap(find.text("I'll Try"));
    // Fixed pumps — the workspace runs a periodic Timer (no pumpAndSettle) and
    // the getting-ready spinner animates forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The calm getting-ready banner is visible.
    expect(find.text('Getting ready'), findsOneWidget,
        reason: 'getting-ready state must be shown while the model downloads');

    // It is NOT an error / hard block.
    expect(find.textContaining('Error'), findsNothing);
    expect(find.textContaining('error'), findsNothing);
    expect(find.byType(StrokeCanvas), findsWidgets,
        reason: 'the lesson still runs underneath — never hard-blocked (D-05)');
  });
}
