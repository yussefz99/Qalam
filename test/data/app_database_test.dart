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

  // ---------------------------------------------------------------------------
  // Plan 06-02 — v3→v4 migration: LetterReps is created and legacy
  // startingLessonId letter-ids are rewritten into the lesson-id namespace
  // (RESEARCH Pitfall 2), WITHOUT losing settings, mastery, or profile rows.
  //
  // Seeding a true v3-era store: we write rows with the current schema, then
  // DROP the v4 table and rewind PRAGMA user_version to 3, so the next open
  // runs the REAL production onUpgrade(from: 3) path — including the
  // customStatement namespace rewrite on child_profiles.starting_lesson_id.
  // ---------------------------------------------------------------------------
  test(
    'migration v3→v4: rows survive, startingLessonId "alif" is rewritten to '
    '"lesson_01", and a second restart is idempotent (S1-09 substrate)',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());

      // Seed a v3-era database.
      final db1 = AppDatabase(shared.executor);
      await db1.setSetting('last_letter', 'baa');
      await db1.recordMastery(letterId: 'alif', cleanReps: 3);
      await db1.createProfile(
        nicknameId: 'nick_star',
        avatarId: 'avatar_1',
        grade: 'kg',
        startingLessonId: 'alif', // legacy LETTER-id namespace (pre-v4)
      );
      // Rewind to a v3 shape: no letter_reps table, user_version = 3.
      await db1.customStatement('DROP TABLE IF EXISTS letter_reps;');
      await db1.customStatement('PRAGMA user_version = 3;');
      await db1.close();

      // "Restart" #1: opens at schemaVersion 4 → onUpgrade(from: 3) runs.
      final db2 = AppDatabase(shared.executor);
      expect(
        await db2.getSetting('last_letter'),
        'baa',
        reason: 'app_settings rows must survive the v3→v4 migration',
      );
      expect(
        await db2.isMastered('alif'),
        isTrue,
        reason: 'letter_mastery rows must survive the v3→v4 migration',
      );
      final migrated = await db2.getProfile();
      expect(migrated, isNotNull,
          reason: 'the child profile must survive the v3→v4 migration');
      expect(migrated!.nicknameId, 'nick_star');
      expect(
        migrated.startingLessonId,
        'lesson_01',
        reason: 'v4 must rewrite legacy letter-id startingLessonId rows into '
            'the lesson-id namespace (RESEARCH Pitfall 2)',
      );
      // The new letter_reps table must exist and be usable post-migration.
      await db2.setCleanReps(letterId: 'baa', cleanReps: 1);
      expect(await db2.getCleanReps('baa'), 1,
          reason: 'letter_reps must be created by the v3→v4 migration');
      await db2.close();

      // "Restart" #2: from == 4 → no upgrade runs; nothing changes.
      final db3 = AppDatabase(shared.executor);
      expect(await db3.getSetting('last_letter'), 'baa',
          reason: 'a second restart must change nothing (idempotence)');
      expect(await db3.isMastered('alif'), isTrue);
      expect((await db3.getProfile())!.startingLessonId, 'lesson_01',
          reason: 'the rewrite must not run twice or corrupt data');
      expect(await db3.getCleanReps('baa'), 1,
          reason: 'letter_reps rows must survive a restart');
      await db3.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Plan 06-02 — D-10: partial clean reps persist across an app restart in the
  // LetterReps table, including the overwrite-to-0 write-through reset shape
  // (Pitfall 7) and a 0 default for letters never practiced.
  // ---------------------------------------------------------------------------
  test(
    'setCleanReps persists across a simulated restart, overwrites to 0, and '
    'getCleanReps of an unknown letter returns 0 (D-10)',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());

      final db1 = AppDatabase(shared.executor);
      await db1.setCleanReps(letterId: 'baa', cleanReps: 2);
      expect(await db1.getCleanReps('baa'), 2);
      await db1.close();

      // "Restart": the partial count must survive (D-10).
      final db2 = AppDatabase(shared.executor);
      expect(await db2.getCleanReps('baa'), 2,
          reason: 'partial clean reps must survive an app restart (D-10)');

      // Write-through reset: overwriting to 0 must stick (Pitfall 7 shape).
      await db2.setCleanReps(letterId: 'baa', cleanReps: 0);
      expect(await db2.getCleanReps('baa'), 0,
          reason: 'setCleanReps(0) must overwrite, not be ignored');

      // Letters never practiced read as 0, never null/throw.
      expect(await db2.getCleanReps('seen'), 0,
          reason: 'unknown letters must read as 0 clean reps');
      await db2.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Plan 06-02 — drift .watch() streams: the S1-09 "unlock is immediate on
  // pass" substrate. The first emission may be the current state; subsequent
  // emissions fire on write with no manual invalidation.
  // ---------------------------------------------------------------------------
  test(
    'watchMasteredLetterIds emits a set containing "alif" after recordMastery',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());
      final db = AppDatabase(shared.executor);

      final Stream<Set<String>> stream = db.watchMasteredLetterIds();
      final expectation = expectLater(stream, emitsThrough(contains('alif')));

      await db.recordMastery(letterId: 'alif', cleanReps: 3);

      await expectation;
      await db.close();
    },
  );

  test(
    'watchCleanReps emits the new count after setCleanReps',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());
      final db = AppDatabase(shared.executor);

      final Stream<int> stream = db.watchCleanReps('baa');
      final expectation = expectLater(stream, emitsThrough(2));

      await db.setCleanReps(letterId: 'baa', cleanReps: 2);

      await expectation;
      await db.close();
    },
  );
}
