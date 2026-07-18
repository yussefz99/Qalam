// Phase 19-06 Task 3 — the LetterUnitController threads childProfileId through
// every keyed DB write, cached ONCE at start() (ADR-018 / D-13 / Pitfall 4).
//
// Two guards:
//   (1) BEHAVIOR — start() resolves the in-file child from childProfileProvider,
//       caches it (exposed via controller.childProfileId()), and keys its durable
//       graph-position write by it: a DIFFERENT profile reads the cursor as null
//       (the profile-resume leak this plan closes — QP-09 success criterion 4).
//   (2) SOURCE ASSERTION — the controller reads childProfileProvider.future EXACTLY
//       ONCE (in start()), never inline on a scored-feedback write path (Pitfall 4:
//       an async FutureProvider read mid-feedback would stall the pass CTA).
//
// Controller-level (no widget): a ProviderContainer over a REAL in-memory
// AppDatabase + the REAL DriftGraphPositionRepository, so the per-child keying is
// exercised against the actual schema, not a fake.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/curriculum/child_model_snapshot.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/graph_position_repository.dart';
import 'package:qalam/features/letter_unit/letter_unit_controller.dart';
import 'package:qalam/tutor/child_model_providers.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';

CurriculumGraph _loadGraph() => CurriculumGraph.fromJson(
      json.decode(
        File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
      ) as Map<String, Object?>,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'start() caches the created profile id and keys the durable cursor by it — '
    'a DIFFERENT profile reads the cursor clean (QP-09 / ADR-018)',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // A real profile lives in the same db childProfileProvider reads from.
      final childA = await db.createProfile(
        nicknameId: 'nick_star',
        avatarId: 'avatar_1',
        grade: 'kg',
        startingLessonId: 'lesson_01',
      );

      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        graphPositionRepositoryProvider
            .overrideWithValue(DriftGraphPositionRepository(db)),
        curriculumGraphProvider.overrideWith((ref) async => _loadGraph()),
        // No Firebase in a unit test — an empty compiled-profile snapshot.
        childModelProvider
            .overrideWith((ref) async => ChildModelSnapshot.empty()),
      ]);
      addTearDown(container.dispose);

      final controller =
          container.read(letterUnitControllerProvider('baa').notifier);
      await controller.start(letterId: 'baa', total: 6);

      // (1) The controller cached the created profile id (not the sentinel).
      expect(controller.childProfileId(), childA,
          reason: 'start() must cache the resolved childProfileProvider id');

      // (2) start() persisted the cursor keyed by that child.
      final underA = await db.getPosition('baa', childProfileId: childA);
      expect(underA, isNotNull,
          reason: 'the durable cursor is written under the current child');

      // (3) A fresh/other profile reads the cursor CLEAN — the leak is closed.
      expect(await db.getPosition('baa', childProfileId: childA + 1), isNull,
          reason: 'a different profile never inherits the prior child cursor');
    },
  );

  test(
    'source assertion: the controller reads childProfileProvider.future EXACTLY '
    'ONCE (cached in start(), never inline on a write path — Pitfall 4)',
    () async {
      final src = File(
        'lib/features/letter_unit/letter_unit_controller.dart',
      ).readAsStringSync();
      final reads =
          'ref.read(childProfileProvider.future)'.allMatches(src).length;
      expect(reads, 1,
          reason: 'childProfileId must be resolved once at start() and cached — '
              'never re-read inline on the scored-feedback hot path');
    },
  );
}
