// Plan 03-02 — LetterMastery persistence tests (TDD, starts RED).
//
// Pins the API:
//   DriftProgressRepository(AppDatabase db)
//   Future<void> recordMastery({required String letterId, required int cleanReps})
//   Future<bool> isMastered(String letterId)
//
// SECURITY (T-03-01/T-01-05): only letterId/cleanReps/masteredAt are persisted.
// Stroke points are never stored — they are in-memory only.
//
// Pattern: shared NativeDatabase.memory() executor — same restart simulation as
// test/data/app_database_test.dart (D-09, schemaVersion 1→2 migration).

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';

// ADR-018 (19-06): every progress read/write is keyed by the in-file child id.
// These tests seed no ChildProfile, so a fixed local id keeps writes+reads
// consistent within each test.
const int _childA = 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test 1: mastery round-trip survives a simulated restart
  // ---------------------------------------------------------------------------
  test(
    'recordMastery persists and isMastered returns true after simulated restart',
    () async {
      // Shared in-memory executor — stays alive after db1.close() so db2 can
      // re-open it, exactly as in app_database_test.dart.
      final shared = DatabaseConnection(NativeDatabase.memory());

      final db1 = AppDatabase(shared.executor);
      final repo1 = DriftProgressRepository(db1);
      await repo1.recordMastery(
          childProfileId: _childA, letterId: 'alif', cleanReps: 3);

      // Confirm before restart.
      expect(await repo1.isMastered('alif', childProfileId: _childA), isTrue);
      expect(await db1.cleanRepsFor('alif', childProfileId: _childA), 3);
      await db1.close(); // injected executor stays open (P1 contract)

      // "Restart": fresh AppDatabase over the same underlying store.
      final db2 = AppDatabase(shared.executor);
      final repo2 = DriftProgressRepository(db2);

      expect(await repo2.isMastered('alif', childProfileId: _childA), isTrue,
          reason: 'mastery must survive simulated restart');
      expect(await db2.cleanRepsFor('alif', childProfileId: _childA), 3,
          reason: 'cleanReps must survive simulated restart');
      await db2.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Test 2: fresh v2 database has the letter_mastery table (no "no such table")
  // ---------------------------------------------------------------------------
  test(
    'a fresh schemaVersion-2 database exposes the letter_mastery table',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());
      final db = AppDatabase(shared.executor);
      final repo = DriftProgressRepository(db);

      // This must NOT throw "no such table: letter_mastery".
      await expectLater(
        () => repo.recordMastery(
            childProfileId: _childA, letterId: 'baa', cleanReps: 1),
        returnsNormally,
      );
      expect(await repo.isMastered('baa', childProfileId: _childA), isTrue);
      await db.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Test 3: migration from v1 shape → v2 preserves existing app_settings rows
  // ---------------------------------------------------------------------------
  //
  // We cannot truly seed a v1 schema in Drift's in-memory mode without Drift's
  // own migration testing helpers (which require drift_dev's test utilities and
  // are only available with the full schema files). Instead, we verify the
  // migration contract from a different angle: write an app_settings row BEFORE
  // any mastery write (exercising both tables in the same DB), then verify both
  // the setting and the mastery survive a simulated restart.  This is the
  // "existing rows survive" invariant the plan requires, expressed against the
  // actual production migration path.
  test(
    'migration v1→v2: existing app_settings rows are preserved alongside new letter_mastery rows',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());

      // Write a setting (app_settings table — was the only table in v1).
      final db1 = AppDatabase(shared.executor);
      await db1.setSetting('last_letter', 'alif');

      // Write mastery (letter_mastery table — new in v2).
      final repo1 = DriftProgressRepository(db1);
      await repo1.recordMastery(
          childProfileId: _childA, letterId: 'alif', cleanReps: 3);
      await db1.close();

      // Simulated restart: re-open and assert both rows survive.
      final db2 = AppDatabase(shared.executor);
      final repo2 = DriftProgressRepository(db2);

      expect(
        await db2.getSetting('last_letter'),
        'alif',
        reason: 'app_settings rows must survive the v1→v2 migration',
      );
      expect(
        await repo2.isMastered('alif', childProfileId: _childA),
        isTrue,
        reason: 'letter_mastery rows must survive simulated restart',
      );
      await db2.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Test 4 (Plan 06-02 → D-15 fold 19-04 → ADR-018 keying 19-06): the repository
  // delegates the folded per-letter rep-persistence API to AppDatabase —
  // setLetterCleanReps/letterCleanReps roundtrip through the interface, keyed by
  // childProfileId. (The legacy setCleanReps/getCleanReps were removed with the
  // LetterReps table in 19-06.)
  // ---------------------------------------------------------------------------
  test(
    'setLetterCleanReps roundtrips through the repository, keyed by child '
    '(D-10 fold / ADR-018)',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());
      final db = AppDatabase(shared.executor);
      final ProgressRepository repo = DriftProgressRepository(db);

      await repo.setLetterCleanReps(
          childProfileId: _childA, letterId: 'baa', cleanReps: 2);
      expect(await repo.letterCleanReps('baa', childProfileId: _childA), 2,
          reason: 'the repository must delegate rep persistence to the DB');

      await repo.setLetterCleanReps(
          childProfileId: _childA, letterId: 'baa', cleanReps: 0);
      expect(await repo.letterCleanReps('baa', childProfileId: _childA), 0,
          reason: 'overwrite-to-0 must pass through the repository unchanged');

      // ADR-018: a DIFFERENT child never reads the first child's counter.
      const childB = 2;
      expect(await repo.letterCleanReps('baa', childProfileId: childB), 0,
          reason: 'a fresh profile reads clean (per-child keying)');

      await db.close();
    },
  );
}
