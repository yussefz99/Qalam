// The local Drift database — Phase 1's persistence seam (D-09).
//
// Schema is deliberately trivial: a single key/value `app_settings` table that
// proves a written value survives an app restart (the test opens a SECOND
// AppDatabase over the same store and reads the value back). The constructor
// accepts an optional QueryExecutor so tests inject NativeDatabase.memory().
//
// SECURITY (threat T-01-02 / T-01-04): the on-device DB lives in app-private
// storage and stores NOTHING sensitive in Phase 1 — only a non-sensitive
// sentinel. No network, no telemetry, and the value is never logged.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/auth_providers.dart';

part 'app_database.g.dart';

/// The in-file "no child yet" sentinel for [childProfileId] (ADR-018 / D-16).
///
/// `ChildProfiles.id` is an autoincrement surrogate whose real ids start at 1, so
/// `0` can never collide with a real profile. It is used as the adoption sentinel
/// in the v6→v7 migration (`SELECT id FROM child_profiles LIMIT 1` → `0` when no
/// profile exists) and as the fallback a writer caches when no profile has been
/// created yet (a child never practices before onboarding creates a profile, so
/// this is a safety floor, not a live path).
const int kUnassignedChildProfileId = 0;

/// Trivial key/value settings table — the persist-proof row (D-09).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Per-letter mastery record — Phase 3 (D-09, Plan 03-02).
///
/// SECURITY (T-03-01/T-01-05): only childProfileId, letterId, cleanReps, and
/// masteredAt are stored. Captured stroke points are NEVER persisted here or
/// anywhere else — they stay in-memory only and are discarded on dispose.
///
/// ADR-018 (D-13/D-14): re-keyed by (childProfileId, letterId) so a fresh profile
/// in the same account file never reads the prior child's mastery.
class LetterMastery extends Table {
  IntColumn get childProfileId => integer()();
  TextColumn get letterId => text()();
  IntColumn get cleanReps => integer()();
  DateTimeColumn get masteredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {childProfileId, letterId};
}

/// One child profile — Phase 5 (S1-02 / S1-03, Plan 05-02).
///
/// SECURITY (T-05-01 / S1-03): stores ONLY fixed-set IDs (nicknameId, avatarId,
/// grade) plus a resolved startingLessonId and createdAt — there is NO real-name
/// column and NO free-text identity field. Profile values are NEVER logged
/// (mirrors the AppSettings/LetterMastery no-log convention above).
class ChildProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nicknameId =>
      text()(); // "nick_star" — fixed-set ID, NO real name
  TextColumn get avatarId => text()(); // "avatar_1".."avatar_6"
  TextColumn get grade => text()(); // kg|grade1|grade2|grade3|grade4plus
  TextColumn get startingLessonId =>
      text()(); // resolved from grade (default "alif", S1-02)
  IntColumn get createdAt => integer()(); // unix epoch ms
}

// LetterReps (the legacy per-letter clean-rep counter) was RETIRED in the v6→v7
// migration (ADR-018 / D-15). Its three live readers were folded onto a
// MAX-aggregate over LetterExerciseReps in Plan 19-04; 19-06 drops the table and
// removes its class + accessors. There is now ONE way to count reps —
// LetterExerciseReps.

/// The child's durable position in a letter's curriculum graph — Phase 15
/// (DYN-02 / D-08, Plan 15-04). One row per letter the child has started.
///
/// This is the on-device resume cursor: re-entering the baa unit after an app
/// restart restores exactly where the child left off (the current node + the
/// cleared competencies/tiers the online rail and the offline walker both read).
/// The server stays stateless (COPPA posture) — resume state lives ONLY here.
///
/// [clearedCompetencies] / [clearedTiers] are JSON-encoded `List<String>` (a
/// `text` column holding `["recognize","positionalForms"]`) — Drift has no native
/// list column, so we encode/decode in the accessors (mirrors no extra package).
///
/// SECURITY (T-15-04-ID): persists ONLY ids/timestamps — the letterId, the
/// current exercise id, derived competency/tier id lists, and updatedAt. NEVER a
/// stroke point, an Offset, a child name, or any PII (mirrors the LetterReps /
/// LetterMastery no-PII convention). Values are never logged.
///
/// ADR-018 (D-13/D-14): re-keyed by (childProfileId, letterId) — this is the
/// cursor whose profile-agnostic key caused the resume leak; the child dimension
/// closes it.
class LetterGraphPosition extends Table {
  IntColumn get childProfileId => integer()(); // PK part — the child in this file
  TextColumn get letterId => text()(); // PK part — "baa"
  TextColumn get currentExerciseId => text().nullable()(); // the walk cursor
  TextColumn get clearedCompetencies => text()(); // JSON-encoded List<String>
  TextColumn get clearedTiers => text()(); // JSON-encoded List<String>
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {childProfileId, letterId};
}

/// Per-essential-EXERCISE clean-rep counter — Phase 15 (Open Q3 / D-06, Plan
/// 15-04). Keyed by the (letterId, exerciseId) composite so `isMasteryMet` can
/// read each essential node's banked reps after a relaunch.
///
/// Open Q3 resolution: a SIBLING table (not a PK change to [LetterReps]). The
/// existing [LetterReps] keys ONE cleanReps per letterId (the per-letter
/// in-progress counter the parent dashboard reads); the on-device star condition
/// needs reps PER ESSENTIAL EXERCISE. Changing [LetterReps]'s PK would force a
/// data-migrating table rebuild; a new sibling table is a clean `createTable`
/// that touches no existing rows — the lower-migration-risk option.
///
/// SECURITY (T-15-04-ID): only ids + a count + a timestamp; never stroke points
/// or PII. Values are never logged.
///
/// ADR-018 (D-13/D-14): re-keyed by (childProfileId, letterId, exerciseId) so
/// `isMasteryMet` reads only the current child's per-exercise reps.
class LetterExerciseReps extends Table {
  IntColumn get childProfileId => integer()();
  TextColumn get letterId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get cleanReps => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {childProfileId, letterId, exerciseId};
}

/// Offline per-criterion evidence accrual — Phase 18 (D-14 digest, Plan 18-03).
///
/// Every graded attempt appends ONE row: which letter, which geometric criterion,
/// pass/fail, and whether it came from an isolated-letter exercise (`"letter"`) or a
/// word attempt (`"word"`). The nightly digest (D-14) reads the accrued rows, folds
/// them into per-criterion EMAs server-side, then the client calls [clearEvidence]
/// to cap on-device growth (threat T-18-03-03).
///
/// SECURITY (T-18-03-01): only ids / a bool / a fixed `source` enum / a timestamp —
/// NEVER a stroke point, an Offset, a child name, or any PII. Values are never
/// logged (mirrors the LetterReps / LetterMastery no-PII convention).
///
/// ADR-018 (D-14 / A3): the autoincrement surrogate `id` stays the PRIMARY KEY
/// (append-only evidence rows need a stable surrogate); `childProfileId` is a
/// REQUIRED filtered COLUMN — every append stamps it and every read filters by it.
class LetterCriterionEvidence extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childProfileId => integer()(); // filtered column, not PK (A3)
  TextColumn get letterId => text()(); // "baa"
  TextColumn get criterion => text()(); // "dot" | "shape" | "strokeOrder" | ...
  BoolColumn get passed => boolean()(); // the already-derived attempt outcome
  TextColumn get source => text()(); // "letter" | "word"
  DateTimeColumn get createdAt => dateTime()();
}

/// The child's remediation-arc resume state per letter — Phase 18 (D-12, Plan
/// 18-03). One row per letter that has an active (or last-known) arc.
///
/// Mirrors the [LetterGraphPosition] resume-cursor pattern: re-entering the unit
/// after an app restart restores the arc mid-flight (entry → stepDown → rebuild →
/// retryOriginal) instead of dropping the child back to the top.
///
/// SECURITY (T-18-03-01): only ids / a bool / fixed-vocabulary step & criterion ids
/// / a timestamp — never a stroke point or PII. Values are never logged.
///
/// ADR-018 (D-13/D-14): re-keyed by (childProfileId, letterId) so a fresh profile
/// never resumes the prior child's remediation arc.
class ArcStateRows extends Table {
  IntColumn get childProfileId => integer()(); // PK part — the child in this file
  TextColumn get letterId => text()(); // PK part — "baa"
  BoolColumn get active => boolean()(); // is an arc in flight?
  TextColumn get step =>
      text()(); // entry | stepDown | rebuild | retryOriginal
  TextColumn get targetCriterion =>
      text().nullable()(); // the criterion under repair
  TextColumn get exerciseToRetry =>
      text().nullable()(); // the original exercise id to return to
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {childProfileId, letterId};
}

/// The on-device mirror of the child's compiled cross-session profile — Phase 18
/// (D-16 boot mirror, Plan 18-03). One row per Firebase account (uid PK).
///
/// The nightly Python compile (18-09) writes the child's strengths / struggles /
/// per-criterion EMAs; this table mirrors that snapshot on-device so the FIRST
/// session after a cold boot already knows the child (no round-trip). The list/map
/// columns are JSON-encoded text (Drift has no native list/map column) — the same
/// idiom as [LetterGraphPosition.clearedCompetencies].
///
/// SECURITY (T-18-03-01): only the account uid + derived id-lists / an id→double
/// EMA map / a timestamp — never a stroke point, a nickname, or any PII. The
/// `perCriterion` keys are `<letter>/<criterion>` ids (non-PII by construction).
/// Values are never logged.
class ChildProfileMirror extends Table {
  TextColumn get uid => text()(); // PK — Firebase account uid
  TextColumn get strengths => text()(); // JSON-encoded List<String>
  TextColumn get struggles => text()(); // JSON-encoded List<String>
  TextColumn get perCriterion => text()(); // JSON-encoded Map<String, double>
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uid};
}

@DriftDatabase(tables: [
  AppSettings,
  LetterMastery,
  ChildProfiles,
  LetterGraphPosition,
  LetterExerciseReps,
  LetterCriterionEvidence,
  ArcStateRows,
  ChildProfileMirror,
])
class AppDatabase extends _$AppDatabase {
  /// Pass a [QueryExecutor] (e.g. `NativeDatabase.memory()`) in tests; defaults
  /// to a lazily-opened on-device file in app-private storage.
  ///
  /// When an executor is INJECTED, the caller owns its lifecycle: a shared
  /// in-memory executor must survive one AppDatabase being closed so a second
  /// instance can re-open it (the "simulated restart" of the D-09 test). So
  /// [close] does not tear down an injected executor; the owner closes it.
  AppDatabase([QueryExecutor? executor])
    : _ownsExecutor = executor == null,
      super(executor ?? _openLegacyConnection());

  /// Production database isolated to one Firebase account.
  AppDatabase.forAccount(String accountId)
    : _ownsExecutor = true,
      super(_openAccountConnection(accountId));

  static String accountDatabaseFileName(String accountId) {
    final digest = sha256.convert(utf8.encode(accountId)).toString();
    return 'qalam_account_$digest.db';
  }

  final bool _ownsExecutor;

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Pitfall 4: guard by version to make the migration idempotent.
          if (from < 2) await m.createTable(letterMastery);
          if (from < 3) await m.createTable(childProfiles);
          if (from < 4) {
            // NOTE (ADR-018 / D-15): the legacy `letter_reps` table used to be
            // created here. It is RETIRED in the v6→v7 step below, so we no longer
            // create it — a device upgrading across this boundary never gets it,
            // and the v6→v7 DROP is an IF-EXISTS no-op for such a device.
            // Namespace rewrite (RESEARCH Pitfall 2): startingLessonId moves
            // from the letter-id namespace ('alif') to the lesson-id namespace
            // ('lesson_01'). Generated names verified against app_database.g.dart
            // ($name 'child_profiles', column 'starting_lesson_id').
            await customStatement(
              "UPDATE child_profiles SET starting_lesson_id = 'lesson_01' "
              "WHERE starting_lesson_id = 'alif'",
            );
          }
          if (from < 5) {
            // Phase 15 (DYN-02 / Open Q3): the durable resume cursor + the
            // per-essential-exercise clean-rep counter. Pure createTable adds —
            // no data rewrite, no touch to existing rows. A child with no
            // position row defaults to the graph root (clean start, getPosition
            // returns null — no crash). Version-guarded for idempotency.
            await m.createTable(letterGraphPosition);
            await m.createTable(letterExerciseReps);
          }
          if (from < 6) {
            // Phase 18 (D-14 / D-12 / D-16): the offline per-criterion evidence
            // queue, the remediation-arc resume cursor, and the compiled-profile
            // boot mirror. Pure createTable adds — no data rewrite, no touch to
            // existing rows. A child with no row in any of the three defaults to
            // empty (no evidence / no active arc / no mirror — clean start, the
            // accessors return null or []). Version-guarded for idempotency.
            await m.createTable(letterCriterionEvidence);
            await m.createTable(arcStateRows);
            await m.createTable(childProfileMirror);
          }
          if (from < 7) {
            // Phase 19 (ADR-018 / D-13/D-14/D-15/D-16): the per-child keying
            // migration. Four progress tables gain childProfileId in their PRIMARY
            // KEY and LetterCriterionEvidence gains it as a filtered column; the
            // legacy LetterReps table is dropped in the same step. SQLite cannot
            // alter a primary key in place, so each PK-changed table is RECREATED
            // via `Migrator.alterTable(TableMigration(...))` (the verified drift
            // 2.31 recreate-and-copy path — ADR-018), backfilling childProfileId
            // onto every existing row with a `Constant<int>` columnTransformer.
            //
            // D-16 adoption: existing rows are adopted into the SINGLE existing
            // profile (SELECT id FROM child_profiles LIMIT 1; sentinel 0 when no
            // profile yet). A profile created AFTER this migration gets a new id,
            // so its filtered reads find no rows and it starts clean (the leak fix).
            final profileRows =
                await customSelect('SELECT id FROM child_profiles LIMIT 1;')
                    .get();
            final adoptedProfileId = profileRows.isEmpty
                ? kUnassignedChildProfileId
                : profileRows.first.read<int>('id');
            final adopted = Constant<int>(adoptedProfileId);

            // Guard each recreate so an upgrade that ALREADY created a table at the
            // current (v7) schema in an earlier `if (from < N)` block (e.g. a
            // from==5 upgrade just created arc_state_rows / letter_criterion_evidence
            // at v7) is not re-altered — the column is already present. This keeps
            // the whole chain idempotent for every `from`.
            Future<bool> alreadyKeyed(String table) async {
              final rows = await customSelect(
                "SELECT 1 AS present FROM pragma_table_info('$table') "
                "WHERE name = 'child_profile_id' LIMIT 1;",
              ).get();
              return rows.isNotEmpty;
            }

            if (!await alreadyKeyed('letter_mastery')) {
              await m.alterTable(TableMigration(
                letterMastery,
                columnTransformer: {letterMastery.childProfileId: adopted},
                newColumns: [letterMastery.childProfileId],
              ));
            }
            if (!await alreadyKeyed('letter_graph_position')) {
              await m.alterTable(TableMigration(
                letterGraphPosition,
                columnTransformer: {letterGraphPosition.childProfileId: adopted},
                newColumns: [letterGraphPosition.childProfileId],
              ));
            }
            if (!await alreadyKeyed('letter_exercise_reps')) {
              await m.alterTable(TableMigration(
                letterExerciseReps,
                columnTransformer: {letterExerciseReps.childProfileId: adopted},
                newColumns: [letterExerciseReps.childProfileId],
              ));
            }
            if (!await alreadyKeyed('arc_state_rows')) {
              await m.alterTable(TableMigration(
                arcStateRows,
                columnTransformer: {arcStateRows.childProfileId: adopted},
                newColumns: [arcStateRows.childProfileId],
              ));
            }
            if (!await alreadyKeyed('letter_criterion_evidence')) {
              await m.alterTable(TableMigration(
                letterCriterionEvidence,
                columnTransformer: {
                  letterCriterionEvidence.childProfileId: adopted
                },
                newColumns: [letterCriterionEvidence.childProfileId],
              ));
            }

            // D-15: retire the legacy per-letter rep counter (its readers were
            // folded onto LetterExerciseReps in 19-04). IF EXISTS so a device that
            // never had it (from < 4, per the note above) is a safe no-op.
            await customStatement('DROP TABLE IF EXISTS letter_reps;');
          }
        },
      );

  @override
  Future<void> close() {
    // Only close the executor we created; leave injected (shared) executors to
    // their owner so a "restart" can re-open the same underlying store.
    if (_ownsExecutor) return super.close();
    return Future<void>.value();
  }

  /// Write (or overwrite) a settings value.
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  /// Read a settings value, or null if absent.
  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> deleteSetting(String key) =>
      (delete(appSettings)..where((t) => t.key.equals(key))).go();

  // ---------------------------------------------------------------------------
  // LetterMastery accessors (mirror setSetting/getSetting pattern)
  // SECURITY: only letterId/cleanReps/masteredAt — never stroke points (T-03-01)
  // ---------------------------------------------------------------------------

  /// Record (or overwrite) a letter mastery result for [childProfileId] (ADR-018).
  Future<void> recordMastery({
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  }) => into(letterMastery).insertOnConflictUpdate(
    LetterMasteryCompanion.insert(
      childProfileId: childProfileId,
      letterId: letterId,
      cleanReps: cleanReps,
      masteredAt: DateTime.now(),
    ),
  );

  /// Returns true if the letter has a mastery record for [childProfileId].
  Future<bool> isMastered(
    String letterId, {
    required int childProfileId,
  }) async =>
      (await (select(letterMastery)
                ..where((t) =>
                    t.childProfileId.equals(childProfileId) &
                    t.letterId.equals(letterId)))
              .getSingleOrNull()) !=
      null;

  /// Returns the recorded clean-rep count for the letter, or null if absent.
  Future<int?> cleanRepsFor(
    String letterId, {
    required int childProfileId,
  }) async =>
      (await (select(letterMastery)
                ..where((t) =>
                    t.childProfileId.equals(childProfileId) &
                    t.letterId.equals(letterId)))
              .getSingleOrNull())
          ?.cleanReps;

  // ---------------------------------------------------------------------------
  // ChildProfiles accessors (Phase 5, S1-02 / S1-03)
  // SECURITY: only fixed-set IDs + grade + startingLessonId + createdAt are
  // stored — never a real name, never free text, and profile values are never
  // logged (T-05-01).
  // ---------------------------------------------------------------------------

  /// Returns true once a child profile exists.
  Future<bool> hasProfile() async =>
      (await (select(childProfiles)..limit(1)).getSingleOrNull()) != null;

  /// Returns the single child profile, or null if none has been created.
  Future<ChildProfile?> getProfile() async =>
      (select(childProfiles)..limit(1)).getSingleOrNull();

  /// Create or replace the device's single child profile from fixed-set IDs.
  ///
  /// Replacement is needed when a newly created account completes setup on a
  /// device that still has a profile from an earlier session.
  Future<int> createProfile({
    required String nicknameId,
    required String avatarId,
    required String grade,
    required String startingLessonId,
  }) async {
    return transaction(() async {
      await delete(childProfiles).go();
      return into(childProfiles).insert(
        ChildProfilesCompanion.insert(
          nicknameId: nicknameId,
          avatarId: avatarId,
          grade: grade,
          startingLessonId: startingLessonId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  Future<void> updateProfile({
    required String nicknameId,
    required String avatarId,
  }) => (update(childProfiles)..where((t) => t.id.isBiggerThanValue(0))).write(
    ChildProfilesCompanion(
      nicknameId: Value(nicknameId),
      avatarId: Value(avatarId),
    ),
  );

  // ---------------------------------------------------------------------------
  // Mastered-letter stream — Phase 6 (S1-09), re-keyed by childProfileId
  // (ADR-018). The legacy LetterReps accessors (setCleanReps/getCleanReps/
  // watchCleanReps/allInProgress) were REMOVED with the table in the v6→v7
  // migration (D-15); their live readers fold onto the LetterExerciseReps
  // aggregate accessors below (19-04).
  // SECURITY: only childProfileId/letterId — never stroke points (T-06-01).
  // ---------------------------------------------------------------------------

  /// Watch the set of mastered letter IDs for [childProfileId]; emits the current
  /// state first, then on every mastery write — the S1-09 "unlock is immediate"
  /// substrate (RESEARCH Pattern 1: first drift .watch() in the codebase).
  Stream<Set<String>> watchMasteredLetterIds({
    required int childProfileId,
  }) =>
      (select(letterMastery)
            ..where((t) => t.childProfileId.equals(childProfileId)))
          .watch()
          .map((rows) => rows.map((r) => r.letterId).toSet());

  // ---------------------------------------------------------------------------
  // LetterGraphPosition accessors — Phase 15 (DYN-02 / D-08, Plan 15-04).
  //
  // getPosition is a FUTURE, not a stream (Pitfall 6): the resume read at unit
  // entry is a one-shot read; a bare StreamProvider.future hangs under Riverpod
  // 3 (it pauses unlistened streams). The competency/tier lists are JSON-encoded
  // List<String> in a text column (Drift has no native list column).
  //
  // SECURITY: persists ONLY ids/timestamps — never stroke points / PII
  // (T-15-04-ID). Values are never logged.
  // ---------------------------------------------------------------------------

  /// Read the persisted graph position for a letter under [childProfileId], or
  /// null if this child has never started it (clean default — start at the graph
  /// root, never throws). A fresh profile reads null even if a prior profile in
  /// the same file has a cursor for the letter (ADR-018 — the leak fix).
  Future<LetterGraphPositionData?> getPosition(
    String letterId, {
    required int childProfileId,
  }) =>
      (select(letterGraphPosition)
            ..where((t) =>
                t.childProfileId.equals(childProfileId) &
                t.letterId.equals(letterId)))
          .getSingleOrNull();

  /// Write (or overwrite) the graph position for a letter under [childProfileId].
  /// The competency/tier lists are JSON-encoded into their text columns.
  Future<void> setPosition({
    required int childProfileId,
    required String letterId,
    String? currentExerciseId,
    required List<String> clearedCompetencies,
    required List<String> clearedTiers,
  }) =>
      into(letterGraphPosition).insertOnConflictUpdate(
        LetterGraphPositionCompanion.insert(
          childProfileId: childProfileId,
          letterId: letterId,
          currentExerciseId: Value(currentExerciseId),
          clearedCompetencies: jsonEncode(clearedCompetencies),
          clearedTiers: jsonEncode(clearedTiers),
          updatedAt: DateTime.now(),
        ),
      );

  // ---------------------------------------------------------------------------
  // LetterExerciseReps accessors — Phase 15 (Open Q3 / D-06, Plan 15-04). The
  // per-essential-EXERCISE clean-rep counter isMasteryMet reads after a relaunch.
  // SECURITY: only ids/counts/timestamps — never stroke points / PII.
  // ---------------------------------------------------------------------------

  /// Write (or overwrite) the banked clean-rep count for one exercise within a
  /// letter under [childProfileId] (write-through, including 0 — the reset shape).
  Future<void> setExerciseCleanReps({
    required int childProfileId,
    required String letterId,
    required String exerciseId,
    required int cleanReps,
  }) =>
      into(letterExerciseReps).insertOnConflictUpdate(
        LetterExerciseRepsCompanion.insert(
          childProfileId: childProfileId,
          letterId: letterId,
          exerciseId: exerciseId,
          cleanReps: cleanReps,
          updatedAt: DateTime.now(),
        ),
      );

  /// Read the banked clean-rep count for one exercise under [childProfileId]; 0
  /// when never practiced.
  Future<int> getExerciseCleanReps({
    required int childProfileId,
    required String letterId,
    required String exerciseId,
  }) async =>
      (await (select(letterExerciseReps)
                ..where((t) =>
                    t.childProfileId.equals(childProfileId) &
                    t.letterId.equals(letterId) &
                    t.exerciseId.equals(exerciseId)))
              .getSingleOrNull())
          ?.cleanReps ??
      0;

  /// Atomically increment the banked clean-rep count for one exercise by 1 under
  /// [childProfileId]. Reads the current count, adds 1, and writes back. Safe to
  /// call from an async context; a missing row is treated as 0 before incrementing.
  Future<void> incrementExerciseCleanReps({
    required int childProfileId,
    required String letterId,
    required String exerciseId,
  }) async {
    final current = await getExerciseCleanReps(
      childProfileId: childProfileId,
      letterId: letterId,
      exerciseId: exerciseId,
    );
    await setExerciseCleanReps(
      childProfileId: childProfileId,
      letterId: letterId,
      exerciseId: exerciseId,
      cleanReps: current + 1,
    );
  }

  /// Read every banked per-exercise clean-rep count for a letter under
  /// [childProfileId] as a `{exerciseId: cleanReps}` map — the exact shape
  /// `isMasteryMet` consumes.
  Future<Map<String, int>> exerciseCleanRepsFor(
    String letterId, {
    required int childProfileId,
  }) async {
    final rows = await (select(letterExerciseReps)
          ..where((t) =>
              t.childProfileId.equals(childProfileId) &
              t.letterId.equals(letterId)))
        .get();
    return {for (final r in rows) r.exerciseId: r.cleanReps};
  }

  // ---------------------------------------------------------------------------
  // D-15 FOLD (Plan 19-04): aggregate accessors over LetterExerciseReps that
  // reproduce the three legacy LetterReps reads (`watchCleanReps` /
  // `getCleanReps` / `allInProgress` above) WITHOUT a schema change, so 19-06
  // can DROP LetterReps once every live reader points here. The LetterReps
  // accessors above stay present-but-unused by live code this plan (19-06
  // removes them together with the table in the v6→v7 migration).
  //
  // AGGREGATION RULE — "the letter's clean-reps" = MAX(clean_reps) across the
  // letter's LetterExerciseReps rows. Rationale for MAX (the plan sanctions
  // "essential-node floor OR max across the letter's exercises"):
  //   * Purely DB-computable — no curriculum-graph dependency — so this stays a
  //     clean data-layer accessor (the graph/essential-node set is not visible
  //     here; `isMasteryMet` reads it in lib/curriculum, not in the DB layer).
  //   * Behavior-preserving for the legacy per-letter /practice counter: that
  //     path banks ONE synthetic exercise row, so MAX == that single value ==
  //     the old `LetterReps.cleanReps` it replaces.
  //   * A non-regressing "furthest progress" indicator for the home ink-fill /
  //     resume depth (never drops while any exercise still has banked reps).
  // This aggregate is a DISPLAY / RESUME indicator only — the authoritative star
  // gate remains `isMasteryMet` over the essential nodes (unchanged, D-06).
  // SECURITY: only ids/counts — never stroke points / PII (T-15-04-ID).
  // ---------------------------------------------------------------------------

  /// One-shot MAX(clean_reps) across [letterId]'s LetterExerciseReps rows for
  /// [childProfileId]; 0 when this child has no exercise rows. Folds the legacy
  /// `getCleanReps`.
  Future<int> letterCleanReps(
    String letterId, {
    required int childProfileId,
  }) async {
    final maxReps = letterExerciseReps.cleanReps.max();
    final row = await (selectOnly(letterExerciseReps)
          ..addColumns([maxReps])
          ..where(letterExerciseReps.childProfileId.equals(childProfileId) &
              letterExerciseReps.letterId.equals(letterId)))
        .getSingleOrNull();
    return row?.read(maxReps) ?? 0;
  }

  /// Watch MAX(clean_reps) across [letterId]'s LetterExerciseReps rows for
  /// [childProfileId]; emits 0 while this child has no exercise rows, then the new
  /// aggregate on every per-exercise write. Folds the legacy `watchCleanReps` —
  /// the journey-ribbon substrate (read via the `_bindDriftStream` bridge, never
  /// a bare StreamProvider.future — Pitfall 5).
  Stream<int> watchLetterCleanReps(
    String letterId, {
    required int childProfileId,
  }) {
    final maxReps = letterExerciseReps.cleanReps.max();
    return (selectOnly(letterExerciseReps)
          ..addColumns([maxReps])
          ..where(letterExerciseReps.childProfileId.equals(childProfileId) &
              letterExerciseReps.letterId.equals(letterId)))
        .watchSingleOrNull()
        .map((row) => row?.read(maxReps) ?? 0);
  }

  /// All in-progress letters for [childProfileId] keyed to their MAX aggregate
  /// clean-rep count — the letters with >=1 exercise clean-rep (> 0). Folds the
  /// legacy `allInProgress` (which returned LetterReps rows with cleanReps > 0).
  /// READ-ONLY.
  Future<Map<String, int>> allInProgressByExerciseReps({
    required int childProfileId,
  }) async {
    final maxReps = letterExerciseReps.cleanReps.max();
    final rows = await (selectOnly(letterExerciseReps)
          ..addColumns([letterExerciseReps.letterId, maxReps])
          ..where(letterExerciseReps.childProfileId.equals(childProfileId))
          ..groupBy(
            [letterExerciseReps.letterId],
            having: maxReps.isBiggerThanValue(0),
          ))
        .get();
    return {
      for (final r in rows)
        r.read(letterExerciseReps.letterId)!: r.read(maxReps) ?? 0,
    };
  }

  // ---------------------------------------------------------------------------
  // LetterCriterionEvidence accessors — Phase 18 (D-14 digest, Plan 18-03). The
  // offline per-criterion evidence queue the nightly digest drains, then caps.
  // Primitive layer: appends primitives, returns raw Drift rows (no lib/curriculum
  // type crosses the DB boundary — 15-04 precedent).
  // SECURITY: only ids/bool/source/timestamp — never stroke points / PII.
  // ---------------------------------------------------------------------------

  /// Append ONE evidence row for a graded attempt under [childProfileId]
  /// (auto-increment id, createdAt stamped now). Returns the new row id.
  Future<int> appendEvidence({
    required int childProfileId,
    required String letterId,
    required String criterion,
    required bool passed,
    required String source,
  }) =>
      into(letterCriterionEvidence).insert(
        LetterCriterionEvidenceCompanion.insert(
          childProfileId: childProfileId,
          letterId: letterId,
          criterion: criterion,
          passed: passed,
          source: source,
          createdAt: DateTime.now(),
        ),
      );

  /// Every accrued evidence row for [childProfileId] not yet cleared, oldest →
  /// newest — the batch the nightly digest reads before syncing. Returns raw
  /// Drift rows (primitive layer).
  Future<List<LetterCriterionEvidenceData>> unsyncedEvidence({
    required int childProfileId,
  }) =>
      (select(letterCriterionEvidence)
            ..where((t) => t.childProfileId.equals(childProfileId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  /// Delete the evidence rows with these [ids] after the digest has synced them —
  /// the rollup cap that bounds on-device growth (threat T-18-03-03). No-op on an
  /// empty list.
  Future<void> clearEvidence(List<int> ids) async {
    if (ids.isEmpty) return;
    await (delete(letterCriterionEvidence)..where((t) => t.id.isIn(ids))).go();
  }

  // ---------------------------------------------------------------------------
  // ArcStateRows accessors — Phase 18 (D-12 resume, Plan 18-03). One row per
  // letter's remediation arc; mirrors the getPosition/setPosition resume idiom.
  // SECURITY: only ids/bool/fixed-vocab step/timestamp — never PII.
  // ---------------------------------------------------------------------------

  /// Read the persisted arc state for a letter under [childProfileId], or null if
  /// none (clean default — no active arc, never throws). Returns the raw Drift row.
  Future<ArcStateRow?> getArcStateRow(
    String letterId, {
    required int childProfileId,
  }) =>
      (select(arcStateRows)
            ..where((t) =>
                t.childProfileId.equals(childProfileId) &
                t.letterId.equals(letterId)))
          .getSingleOrNull();

  /// Write (or overwrite) the arc state for a letter under [childProfileId].
  Future<void> setArcStateRow({
    required int childProfileId,
    required String letterId,
    required bool active,
    required String step,
    String? targetCriterion,
    String? exerciseToRetry,
  }) =>
      into(arcStateRows).insertOnConflictUpdate(
        ArcStateRowsCompanion.insert(
          childProfileId: childProfileId,
          letterId: letterId,
          active: active,
          step: step,
          targetCriterion: Value(targetCriterion),
          exerciseToRetry: Value(exerciseToRetry),
          updatedAt: DateTime.now(),
        ),
      );

  // ---------------------------------------------------------------------------
  // ChildProfileMirror accessors — Phase 18 (D-16 boot mirror, Plan 18-03). The
  // compiled cross-session profile mirrored on-device per account. The list/map
  // columns are JSON-encoded (Drift has no native list/map column) — same idiom
  // as getPosition/setPosition. The repository (18-06) JSON-decodes.
  // SECURITY: only the uid + derived id-lists / an id→double map / timestamp.
  // ---------------------------------------------------------------------------

  /// Read the mirrored compiled profile for an account, or null if none yet
  /// (clean cold-boot default — never throws). Returns the raw Drift row.
  Future<ChildProfileMirrorData?> getProfileMirror(String uid) =>
      (select(childProfileMirror)..where((t) => t.uid.equals(uid)))
          .getSingleOrNull();

  /// Write (or overwrite) the mirrored compiled profile for an account. The
  /// strengths/struggles lists and the perCriterion EMA map are JSON-encoded into
  /// their text columns.
  Future<void> setProfileMirror({
    required String uid,
    required List<String> strengths,
    required List<String> struggles,
    required Map<String, double> perCriterion,
  }) =>
      into(childProfileMirror).insertOnConflictUpdate(
        ChildProfileMirrorCompanion.insert(
          uid: uid,
          strengths: jsonEncode(strengths),
          struggles: jsonEncode(struggles),
          perCriterion: jsonEncode(perCriterion),
          updatedAt: DateTime.now(),
        ),
      );

  // ---------------------------------------------------------------------------
  // Read-only aggregate accessors for the Parent Dashboard — Phase 9 (S1-11,
  // Plan 09-02, RESEARCH Pattern 4). Read-only is a HARD constraint: there is
  // deliberately NO edit/delete/reset accessor exposed to the parent surface
  // (threat T-09-09). SECURITY: read-only; never logs values.
  // ---------------------------------------------------------------------------

  /// All mastered letters for [childProfileId], ordered oldest → newest by
  /// masteredAt. Each row carries the cleanReps + masteredAt the dashboard
  /// renders. READ-ONLY. (The legacy LetterReps `allInProgress` was removed with
  /// the table — the parent in-progress list reads `allInProgressByExerciseReps`.)
  Future<List<LetterMasteryData>> allMastered({
    required int childProfileId,
  }) =>
      (select(letterMastery)
            ..where((t) => t.childProfileId.equals(childProfileId))
            ..orderBy([(t) => OrderingTerm(expression: t.masteredAt)]))
          .get();
}

LazyDatabase _openLegacyConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory(); // app-private storage
    final file = File('${dir.path}${Platform.pathSeparator}qalam.db');
    return NativeDatabase.createInBackground(file);
  });
}

LazyDatabase _openAccountConnection(String accountId) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      '${AppDatabase.accountDatabaseFileName(accountId)}',
    );
    return NativeDatabase.createInBackground(file);
  });
}

/// The stable account-identity key for the local database — the uid for a real
/// (non-anonymous) account, else a shared `signed-out-guest` namespace.
///
/// This recomputes on every `authStateProvider` (`userChanges()`) emission, but
/// because it returns a plain String, Riverpod only NOTIFIES [appDatabase] when
/// the value actually changes (`==`). A plain token refresh that keeps the same
/// uid — e.g. the Forgot-PIN `reauthenticateWithPassword` step — therefore does
/// NOT churn the database. Watching `authStateProvider` directly here would
/// recreate (and `close()`) the DB on that refresh, tearing down the live DB and
/// its Drift `.watch()` streams mid-interaction and crashing the widget tree
/// (`_dependents.isEmpty`).
@Riverpod(keepAlive: true)
String accountDatabaseId(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final user =
      authState.asData?.value ?? ref.read(authServiceProvider).currentUser;
  return user != null && !user.isAnonymous ? user.uid : 'signed-out-guest';
}

/// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).
/// Rebuilds ONLY when [accountDatabaseId] changes (account identity), never on a
/// bare token refresh — see that provider's note.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final accountId = ref.watch(accountDatabaseIdProvider);
  final db = AppDatabase.forAccount(accountId);
  ref.onDispose(db.close);
  return db;
}

/// The visible persistence seam (D-09): on first read, write a trivial
/// non-sensitive sentinel to the DB, then read it back. Home displays the
/// round-tripped value to prove persistence end-to-end. Stores NOTHING
/// sensitive (threat T-01-02) and the value is never logged (T-01-04).
@riverpod
Future<String> skeletonProof(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  const key = 'skeletonProof';
  final existing = await db.getSetting(key);
  if (existing != null) return existing;
  final sentinel = 'saved ${DateTime.now().toIso8601String()}';
  await db.setSetting(key, sentinel);
  return (await db.getSetting(key))!;
}
