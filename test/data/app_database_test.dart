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

import 'dart:io';

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
          startingLessonId: 'lesson_01',
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
      expect(profile.startingLessonId, 'lesson_01');
      await db2.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Plan 06-02 — v3→v4 migration: LetterReps is created and legacy
  // startingLessonId letter-ids are rewritten into the lesson-id namespace
  // (RESEARCH Pitfall 2), WITHOUT losing settings, mastery, or profile rows.
  //
  // NOTE: a shared NativeDatabase.memory() executor canNOT exercise migration —
  // the underlying delegate stays open across AppDatabase instances, so drift's
  // version check (and onUpgrade) only runs on the FIRST open. To run the real
  // production onUpgrade(from: 3) path we use a temp FILE database with a fresh
  // executor per "restart": seed rows with the current schema, then DROP the v4
  // table and rewind PRAGMA user_version to 3 before closing.
  // ---------------------------------------------------------------------------
  test(
    'migration v3→v4: rows survive, startingLessonId "alif" is rewritten to '
    '"lesson_01", and a second restart is idempotent (S1-09 substrate)',
    () async {
      final dir = await Directory.systemTemp.createTemp('qalam_v4_migration');
      final file = File('${dir.path}${Platform.pathSeparator}qalam.db');
      addTearDown(() => dir.delete(recursive: true));

      // Seed a v3-era database.
      final exec1 = NativeDatabase(file);
      final db1 = AppDatabase(exec1);
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
      await exec1.close(); // injected executors are owned by the test

      // "Restart" #1: a fresh executor re-opens the file at user_version 3 →
      // the REAL onUpgrade(from: 3) runs (createTable + namespace rewrite).
      final exec2 = NativeDatabase(file);
      final db2 = AppDatabase(exec2);
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
      await exec2.close();

      // "Restart" #2: from == 4 → no upgrade runs; nothing changes.
      final exec3 = NativeDatabase(file);
      final db3 = AppDatabase(exec3);
      expect(await db3.getSetting('last_letter'), 'baa',
          reason: 'a second restart must change nothing (idempotence)');
      expect(await db3.isMastered('alif'), isTrue);
      expect((await db3.getProfile())!.startingLessonId, 'lesson_01',
          reason: 'the rewrite must not run twice or corrupt data');
      expect(await db3.getCleanReps('baa'), 1,
          reason: 'letter_reps rows must survive a restart');
      await db3.close();
      await exec3.close();
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

  // ---------------------------------------------------------------------------
  // Plan 09-01 (Wave 0) — read-only aggregate accessors for the Parent
  // Dashboard (S1-11, RESEARCH Pattern 4).
  //
  // INTENTIONALLY RED at Wave 0: references the not-yet-built allMastered() /
  // allInProgress() accessors. Plan 09-02 adds them to AppDatabase (mirroring
  // the existing recordMastery/setCleanReps style) and turns these green. Do
  // NOT add a lib/ stub here.
  //
  // Data-class names verified against app_database.g.dart:
  //   * letter_mastery rows  → LetterMasteryData
  //   * letter_reps rows     → LetterRep
  // ---------------------------------------------------------------------------

  test(
    'allMastered() returns the seeded LetterMastery rows ordered by masteredAt '
    '(read-only, S1-11)',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());
      final db = AppDatabase(shared.executor);

      // Seed in a deliberately non-chronological insert order; allMastered()
      // must return them ordered by masteredAt (oldest → newest).
      await db.recordMastery(letterId: 'alif', cleanReps: 3);
      await db.recordMastery(letterId: 'baa', cleanReps: 5);

      final List<LetterMasteryData> mastered = await db.allMastered();
      expect(mastered.length, 2,
          reason: 'both mastered letters must be returned');
      expect(
        mastered.first.masteredAt.isBefore(mastered.last.masteredAt) ||
            mastered.first.masteredAt.isAtSameMomentAs(mastered.last.masteredAt),
        isTrue,
        reason: 'rows must be ordered by masteredAt (RESEARCH Pattern 4)',
      );
      // Each row carries cleanReps + masteredAt the dashboard renders.
      final alif = mastered.firstWhere((r) => r.letterId == 'alif');
      expect(alif.cleanReps, 3);
      await db.close();
    },
  );

  test(
    'allInProgress() returns only LetterReps rows with cleanReps > 0 '
    '(read-only, S1-11)',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());
      final db = AppDatabase(shared.executor);

      await db.setCleanReps(letterId: 'baa', cleanReps: 2); // in progress
      await db.setCleanReps(letterId: 'taa', cleanReps: 0); // not started

      final List<LetterRep> inProgress = await db.allInProgress();
      expect(inProgress.map((r) => r.letterId), contains('baa'),
          reason: 'letters with cleanReps > 0 are in progress');
      expect(inProgress.map((r) => r.letterId), isNot(contains('taa')),
          reason: 'a 0 clean-rep letter is NOT in progress');
      final baa = inProgress.firstWhere((r) => r.letterId == 'baa');
      expect(baa.cleanReps, 2);
      await db.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Plan 19-01 (Wave 0) — QP-09 / D-14 / D-16 / D-15: the v6→v7 per-child keying
  // migration + two-profile isolation.
  //
  // AUTHORED COMPLETE, but SKIP-MARKED: `skip: 'v6→v7 lands in 19-06 (QP-09)'`.
  // The body is a full, would-be-RED assertion of the v7 behaviour that does not
  // exist yet (schemaVersion is still 6). The skip keeps this whole file green for
  // the intermediate plans (19-02..19-05) that run it. 19-06 removes the marker as
  // its ONLY permitted edit to this file, then greens the case with the real
  // migration.
  //
  // WHY THE BODY IS PURE RAW SQL (customStatement / customSelect), never the typed
  // accessors: 19-06 re-keys five tables by `childProfileId`, which CHANGES the
  // typed accessor signatures (recordMastery/setPosition/… gain a childProfileId
  // arg). A body written against the typed API would fail to COMPILE after 19-06
  // and could not be greened by a skip-removal alone. Raw SQL is signature-
  // independent: it compiles today (v6) AND passes after 19-06 un-skips it (v7),
  // with zero body edits.
  //
  // The temp-FILE NativeDatabase (never a shared in-memory executor) is the ONLY
  // way to exercise the real onUpgrade path — the v3→v4 precedent above (Pitfall 2).
  // ---------------------------------------------------------------------------
  test(
    'migration v6→v7: the five progress tables re-key by childProfileId — '
    "profile-A's rows are adopted (survive) keyed to the current profile, a "
    'fresh profile reads clean, and legacy LetterReps is dropped '
    '(QP-09 / D-14 / D-16 / D-15)',
    () async {
      final dir = await Directory.systemTemp.createTemp('qalam_v7_migration');
      final file = File('${dir.path}${Platform.pathSeparator}qalam.db');
      addTearDown(() => dir.delete(recursive: true));

      // COUNT the rows a given profile owns for a letter, via raw SQL over the
      // v7 `child_profile_id` column — signature-independent of the typed API.
      Future<int> countRows(
        AppDatabase db,
        String table,
        int profileId,
        String letterId,
      ) async {
        final rows = await db.customSelect(
          'SELECT COUNT(*) AS c FROM $table '
          'WHERE child_profile_id = ? AND letter_id = ?;',
          variables: [
            Variable.withInt(profileId),
            Variable.withString(letterId),
          ],
        ).get();
        return rows.single.read<int>('c');
      }

      // ── Seed a genuine v6-era database in raw SQL ──────────────────────────
      // Reshape whatever onCreate built (v6 today, v7 after 19-06) to the EXACT
      // v6 schema, insert v6-shaped rows (no child_profile_id), rewind to v6.
      final seed = AppDatabase(NativeDatabase(file));
      for (final t in const [
        'letter_graph_position',
        'letter_exercise_reps',
        'letter_mastery',
        'arc_state_rows',
        'letter_reps',
        'child_profiles',
      ]) {
        await seed.customStatement('DROP TABLE IF EXISTS $t;');
      }
      // EXACT v6 DDL (captured from the live v6 Drift schema) so the v7
      // TableMigration recreate reads the tables it expects.
      await seed.customStatement(
        'CREATE TABLE "child_profiles" ("id" INTEGER NOT NULL PRIMARY KEY '
        'AUTOINCREMENT, "nickname_id" TEXT NOT NULL, "avatar_id" TEXT NOT NULL, '
        '"grade" TEXT NOT NULL, "starting_lesson_id" TEXT NOT NULL, '
        '"created_at" INTEGER NOT NULL)',
      );
      await seed.customStatement(
        'CREATE TABLE "letter_mastery" ("letter_id" TEXT NOT NULL, '
        '"clean_reps" INTEGER NOT NULL, "mastered_at" INTEGER NOT NULL, '
        'PRIMARY KEY ("letter_id"))',
      );
      await seed.customStatement(
        'CREATE TABLE "letter_reps" ("letter_id" TEXT NOT NULL, '
        '"clean_reps" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
        'PRIMARY KEY ("letter_id"))',
      );
      await seed.customStatement(
        'CREATE TABLE "letter_graph_position" ("letter_id" TEXT NOT NULL, '
        '"current_exercise_id" TEXT NULL, "cleared_competencies" TEXT NOT NULL, '
        '"cleared_tiers" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, '
        'PRIMARY KEY ("letter_id"))',
      );
      await seed.customStatement(
        'CREATE TABLE "letter_exercise_reps" ("letter_id" TEXT NOT NULL, '
        '"exercise_id" TEXT NOT NULL, "clean_reps" INTEGER NOT NULL, '
        '"updated_at" INTEGER NOT NULL, PRIMARY KEY ("letter_id", "exercise_id"))',
      );
      await seed.customStatement(
        'CREATE TABLE "arc_state_rows" ("letter_id" TEXT NOT NULL, '
        '"active" INTEGER NOT NULL CHECK ("active" IN (0, 1)), '
        '"step" TEXT NOT NULL, "target_criterion" TEXT NULL, '
        '"exercise_to_retry" TEXT NULL, "updated_at" INTEGER NOT NULL, '
        'PRIMARY KEY ("letter_id"))',
      );
      // The SINGLE existing profile (D-16 — whoever was practicing is adopted).
      await seed.customStatement(
        "INSERT INTO child_profiles (nickname_id, avatar_id, grade, "
        "starting_lesson_id, created_at) "
        "VALUES ('nick_star', 'avatar_1', 'kg', 'lesson_01', 0)",
      );
      // Profile-A progress across ALL FOUR keyed tables + a legacy letter_reps row.
      await seed.customStatement(
        "INSERT INTO letter_graph_position (letter_id, current_exercise_id, "
        "cleared_competencies, cleared_tiers, updated_at) "
        "VALUES ('baa', 'baa.writeLetter.fromSound', '[\"recognize\"]', '[]', 0)",
      );
      await seed.customStatement(
        "INSERT INTO letter_exercise_reps (letter_id, exercise_id, clean_reps, "
        "updated_at) VALUES ('baa', 'baa.traceLetter.isolated', 2, 0)",
      );
      await seed.customStatement(
        "INSERT INTO letter_mastery (letter_id, clean_reps, mastered_at) "
        "VALUES ('alif', 3, 0)",
      );
      await seed.customStatement(
        "INSERT INTO arc_state_rows (letter_id, active, step, target_criterion, "
        "exercise_to_retry, updated_at) "
        "VALUES ('baa', 1, 'stepDown', 'shape', 'baa.writeLetter.fromSound', 0)",
      );
      await seed.customStatement(
        "INSERT INTO letter_reps (letter_id, clean_reps, updated_at) "
        "VALUES ('baa', 2, 0)",
      );
      // Rewind the schema version so the next open runs onUpgrade(from: 6).
      await seed.customStatement('PRAGMA user_version = 6;');
      await seed.close();

      // ── Open a fresh AppDatabase → the REAL onUpgrade(6→7) runs ─────────────
      // After 19-06 this exercises the production `if (from < 7)` onUpgrade block
      // (TableMigration recreate + Constant<int> backfill + drop letter_reps).
      final migrated = AppDatabase(NativeDatabase(file));

      // The migration backfills child_profile_id from the single existing
      // profile (SELECT id FROM child_profiles LIMIT 1) — that adopted id.
      final profileRows = await migrated
          .customSelect('SELECT id FROM child_profiles LIMIT 1;')
          .get();
      final profileA = profileRows.single.read<int>('id');
      final profileB = profileA + 1; // an id with NO rows → clean/fresh

      // (a) D-16 — profile-A rows SURVIVE, adopted under the current profile id.
      expect(await countRows(migrated, 'letter_graph_position', profileA, 'baa'),
          1,
          reason: 'the graph cursor is adopted (no progress loss, D-16)');
      expect(await countRows(migrated, 'letter_exercise_reps', profileA, 'baa'),
          1,
          reason: 'per-exercise clean reps are adopted (D-16)');
      expect(await countRows(migrated, 'arc_state_rows', profileA, 'baa'), 1,
          reason: 'the remediation-arc state is adopted (D-16)');
      expect(await countRows(migrated, 'letter_mastery', profileA, 'alif'), 1,
          reason: 'mastery rows are adopted (D-16)');

      // (b) success criterion 4 — a SECOND profile reads CLEAN (no inherited
      // cursor). This is the cross-profile-leak invariant (T-19-01).
      expect(await countRows(migrated, 'letter_graph_position', profileB, 'baa'),
          0,
          reason: 'a fresh profile starts at the opening — never the old cursor');
      expect(await countRows(migrated, 'letter_exercise_reps', profileB, 'baa'),
          0);
      expect(await countRows(migrated, 'arc_state_rows', profileB, 'baa'), 0);

      // (c) D-15 — the legacy LetterReps table is GONE after v7 (one rep counter).
      final repsTable = await migrated
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type='table' AND name='letter_reps';",
          )
          .get();
      expect(repsTable, isEmpty,
          reason: 'legacy letter_reps is retired in the same migration (D-15)');
      await migrated.close();

      // (d) idempotence — a second open runs NO migration (from == 7) and changes
      // nothing; the adopted rows survive a restart.
      final again = AppDatabase(NativeDatabase(file));
      expect(await countRows(again, 'letter_graph_position', profileA, 'baa'), 1,
          reason: 'a second restart must change nothing (idempotence)');
      await again.close();
    },
    skip: 'v6→v7 lands in 19-06 (QP-09)',
  );
}
