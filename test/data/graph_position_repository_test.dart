// DYN-02 (Wave 0, RED) — graph resume position survives a simulated restart (D-08).
//
// INTENTIONALLY RED at Wave 0: references the not-yet-built LetterGraphPosition table +
// setPosition/getPosition accessors on AppDatabase (schema v4→v5) and the
// GraphPositionRepository (package:qalam/data/graph_position_repository.dart). Plan 15-04
// builds them and turns this green. Do NOT add a lib/ stub here.
//
// Shape copied from app_database_test.dart's temp-file real-onUpgrade restart test
// (the Phase-09 persisted-cooldown shape D-08 references): seed with the current schema,
// write a position on db1, close, re-open a SECOND AppDatabase over the SAME store, and
// assert the persisted clearedCompetencies/clearedTiers/currentExerciseId survived.

import 'dart:io';

// Hide the Drift query-builder matchers that collide with flutter_test's
// isNull/isNotNull expectation matchers (same idiom as app_database_test.dart).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
// RED: lib/data/graph_position_repository.dart does not exist yet (Plan 15-04 writes it).
// It defines DriftGraphPositionRepository + the GraphPosition value type the repo reads/writes.
import 'package:qalam/data/graph_position_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a graph position survives a simulated restart (D-08): cleared tiers/competencies + '
    'currentExerciseId persist across re-opening the same store',
    () async {
      final dir = await Directory.systemTemp.createTemp('qalam_graph_pos');
      final file = File('${dir.path}${Platform.pathSeparator}qalam.db');
      addTearDown(() => dir.delete(recursive: true));

      // db1: write a non-trivial graph position via the repository seam.
      final exec1 = NativeDatabase(file);
      final db1 = AppDatabase(exec1);
      final repo1 = DriftGraphPositionRepository(db1);
      await repo1.setPosition(
        const GraphPosition(
          letterId: 'baa',
          currentExerciseId: 'baa.writeWord.copy',
          clearedCompetencies: ['recognize', 'positionalForms'],
          clearedTiers: ['manqul', 'manzur'],
        ),
      );
      await db1.close();
      await exec1.close();

      // "Restart": a fresh AppDatabase over the same file — the persisted position survives.
      final exec2 = NativeDatabase(file);
      final db2 = AppDatabase(exec2);
      final repo2 = DriftGraphPositionRepository(db2);

      final restored = await repo2.getPosition('baa');
      expect(restored, isNotNull, reason: 'the graph position must survive an app restart');
      expect(restored!.currentExerciseId, 'baa.writeWord.copy');
      expect(restored.clearedCompetencies, ['recognize', 'positionalForms'],
          reason: 'cleared competencies must persist (JSON-encoded list round-trips)');
      expect(restored.clearedTiers, ['manqul', 'manzur'],
          reason: 'cleared tiers must persist across the restart');
      await db2.close();
      await exec2.close();
    },
  );

  test('a letter with no stored position reads as null (clean default, never throws)',
      () async {
    final shared = DatabaseConnection(NativeDatabase.memory());
    final db = AppDatabase(shared.executor);
    final repo = DriftGraphPositionRepository(db);

    expect(await repo.getPosition('baa'), isNull,
        reason: 'an unstarted letter has no position — start at the graph root');
    await db.close();
  });
}
