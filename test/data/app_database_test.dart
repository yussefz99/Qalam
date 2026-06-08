// Wave-0 validation scaffold — D-09 (Drift persistence survives a restart).
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/data/app_database.dart,
// which does not yet exist. A later plan builds the Drift AppDatabase and turns
// this green. Do NOT add a lib/ stub here.
//
// Proof: write a key/value through the settings API, then simulate an app
// restart by closing the DB and opening a SECOND AppDatabase over the same
// in-memory file, and assert the value survived. NativeDatabase.memory() keeps
// the test hermetic (no on-disk file, no path_provider).

// Hide the Drift query-builder matchers that collide with flutter_test's
// `isNull`/`isNotNull` expectation matchers (used by the v2→v3 migration test).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a persisted value survives a simulated restart (D-09)', () async {
    // A shared in-memory database file lets a "second" AppDatabase instance
    // re-open the same data — the closest analog to an app restart in a test.
    final shared = DatabaseConnection(NativeDatabase.memory());

    final db1 = AppDatabase(shared.executor);
    await db1.setSetting('last_letter', 'baa');
    expect(await db1.getSetting('last_letter'), 'baa');
    await db1.close();

    // "Restart": a fresh AppDatabase over the same underlying store.
    final db2 = AppDatabase(shared.executor);
    expect(await db2.getSetting('last_letter'), 'baa');
    await db2.close();
  });

  // ---------------------------------------------------------------------------
  // Plan 05-01 (Wave 0) — v2→v3 migration: ChildProfiles is added WITHOUT
  // losing existing AppSettings or LetterMastery rows.
  //
  // INTENTIONALLY RED at Wave 0: references the not-yet-built ChildProfiles
  // table and the createProfile/getProfile/hasProfile accessors. A later wave
  // bumps schemaVersion to 3, creates the table in onUpgrade, and adds the
  // accessors — turning this green. Do NOT add a lib/ stub here.
  //
  // We cannot truly seed a v2 schema in Drift's in-memory mode without
  // drift_dev's schema-file test helpers, so — exactly like
  // progress_repository_test.dart's v1→v2 test — we verify the migration
  // contract from the "existing rows survive" angle: write an AppSettings row
  // AND a LetterMastery row, then assert a ChildProfiles insert succeeds and all
  // three survive a simulated restart, against the real production migration
  // path.
  // ---------------------------------------------------------------------------
  test(
    'migration v2→v3: ChildProfiles insert works and AppSettings + LetterMastery rows are preserved (S1-02)',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());

      // Write an app_settings row (v1 table).
      final db1 = AppDatabase(shared.executor);
      await db1.setSetting('last_letter', 'alif');

      // Write a letter_mastery row (v2 table).
      await db1.recordMastery(letterId: 'alif', cleanReps: 3);

      // Insert a child_profiles row (v3 table) — must NOT throw
      // "no such table: child_profiles".
      await expectLater(
        () => db1.createProfile(
          nicknameId: 'nick_star',
          avatarId: 'avatar_1',
          grade: 'kg',
          startingLessonId: 'alif',
        ),
        returnsNormally,
      );
      expect(await db1.hasProfile(), isTrue);
      await db1.close();

      // Simulated restart: re-open and assert all three tables' rows survive.
      final db2 = AppDatabase(shared.executor);

      expect(
        await db2.getSetting('last_letter'),
        'alif',
        reason: 'app_settings rows must survive the v2→v3 migration',
      );
      expect(
        await db2.isMastered('alif'),
        isTrue,
        reason: 'letter_mastery rows must survive the v2→v3 migration',
      );
      final profile = await db2.getProfile();
      expect(profile, isNotNull,
          reason: 'the child profile must survive a simulated restart');
      expect(profile!.nicknameId, 'nick_star');
      expect(profile.startingLessonId, 'alif');
      await db2.close();
    },
  );
}
