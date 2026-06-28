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

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// Trivial key/value settings table — the persist-proof row (D-09).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Per-letter mastery record — Phase 3 (D-09, Plan 03-02).
///
/// SECURITY (T-03-01/T-01-05): only letterId, cleanReps, and masteredAt are
/// stored. Captured stroke points are NEVER persisted here or anywhere else —
/// they stay in-memory only and are discarded on dispose.
class LetterMastery extends Table {
  TextColumn get letterId => text()();
  IntColumn get cleanReps => integer()();
  DateTimeColumn get masteredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {letterId};
}

/// One child profile — Phase 5 (S1-02 / S1-03, Plan 05-02).
///
/// SECURITY (T-05-01 / S1-03): stores ONLY fixed-set IDs (nicknameId, avatarId,
/// grade) plus a resolved startingLessonId and createdAt — there is NO real-name
/// column and NO free-text identity field. Profile values are NEVER logged
/// (mirrors the AppSettings/LetterMastery no-log convention above).
class ChildProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nicknameId => text()(); // "nick_star" — fixed-set ID, NO real name
  TextColumn get avatarId => text()(); // "avatar_1".."avatar_6"
  TextColumn get grade => text()(); // kg|grade1|grade2|grade3|grade4plus
  TextColumn get startingLessonId => text()(); // resolved from grade (default "alif", S1-02)
  IntColumn get createdAt => integer()(); // unix epoch ms
}

/// Per-letter PARTIAL clean-rep counter — Phase 6 (D-10, Plan 06-02).
///
/// Distinct from [LetterMastery]: a row here means "in progress" (the child has
/// some clean reps banked toward mastery); a LetterMastery row means "passed".
///
/// SECURITY (T-03-01/T-06-01): only letterId, cleanReps, and updatedAt are
/// stored. Captured stroke points are NEVER persisted here or anywhere else —
/// they stay in-memory only and are discarded on dispose.
class LetterReps extends Table {
  TextColumn get letterId => text()();
  IntColumn get cleanReps => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {letterId};
}

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
class LetterGraphPosition extends Table {
  TextColumn get letterId => text()(); // PK — "baa"
  TextColumn get currentExerciseId => text().nullable()(); // the walk cursor
  TextColumn get clearedCompetencies => text()(); // JSON-encoded List<String>
  TextColumn get clearedTiers => text()(); // JSON-encoded List<String>
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {letterId};
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
class LetterExerciseReps extends Table {
  TextColumn get letterId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get cleanReps => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {letterId, exerciseId};
}

@DriftDatabase(tables: [
  AppSettings,
  LetterMastery,
  ChildProfiles,
  LetterReps,
  LetterGraphPosition,
  LetterExerciseReps,
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
        super(executor ?? _openConnection());

  final bool _ownsExecutor;

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Pitfall 4: guard by version to make the migration idempotent.
          if (from < 2) await m.createTable(letterMastery);
          if (from < 3) await m.createTable(childProfiles);
          if (from < 4) {
            await m.createTable(letterReps);
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
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  // ---------------------------------------------------------------------------
  // LetterMastery accessors (mirror setSetting/getSetting pattern)
  // SECURITY: only letterId/cleanReps/masteredAt — never stroke points (T-03-01)
  // ---------------------------------------------------------------------------

  /// Record (or overwrite) a letter mastery result.
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  }) =>
      into(letterMastery).insertOnConflictUpdate(
        LetterMasteryCompanion.insert(
          letterId: letterId,
          cleanReps: cleanReps,
          masteredAt: DateTime.now(),
        ),
      );

  /// Returns true if the letter has a mastery record.
  Future<bool> isMastered(String letterId) async =>
      (await (select(letterMastery)
                ..where((t) => t.letterId.equals(letterId)))
              .getSingleOrNull()) !=
      null;

  /// Returns the recorded clean-rep count for the letter, or null if absent.
  Future<int?> cleanRepsFor(String letterId) async =>
      (await (select(letterMastery)
                ..where((t) => t.letterId.equals(letterId)))
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

  /// Create the single child profile from fixed-set IDs + a resolved
  /// startingLessonId. Plain insert (not insertOnConflictUpdate) — onboarding
  /// happens once.
  Future<int> createProfile({
    required String nicknameId,
    required String avatarId,
    required String grade,
    required String startingLessonId,
  }) =>
      into(childProfiles).insert(
        ChildProfilesCompanion.insert(
          nicknameId: nicknameId,
          avatarId: avatarId,
          grade: grade,
          startingLessonId: startingLessonId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  // ---------------------------------------------------------------------------
  // LetterReps accessors + watch streams — Phase 6 (D-10 / S1-09, Plan 06-02)
  // SECURITY: only letterId/cleanReps/updatedAt — never stroke points (T-06-01)
  // ---------------------------------------------------------------------------

  /// Write (or overwrite) the partial clean-rep count for a letter (D-10).
  ///
  /// Write-through, including 0: `setCleanReps(letterId: x, cleanReps: 0)`
  /// resets the banked count (the Pitfall-7 reset shape).
  Future<void> setCleanReps({
    required String letterId,
    required int cleanReps,
  }) =>
      into(letterReps).insertOnConflictUpdate(
        LetterRepsCompanion.insert(
          letterId: letterId,
          cleanReps: cleanReps,
          updatedAt: DateTime.now(),
        ),
      );

  /// Read the banked clean-rep count for a letter; 0 when never practiced.
  Future<int> getCleanReps(String letterId) async =>
      (await (select(letterReps)..where((t) => t.letterId.equals(letterId)))
              .getSingleOrNull())
          ?.cleanReps ??
      0;

  /// Watch the set of mastered letter IDs; emits the current state first, then
  /// on every mastery write — the S1-09 "unlock is immediate" substrate
  /// (RESEARCH Pattern 1: first drift .watch() in the codebase).
  Stream<Set<String>> watchMasteredLetterIds() => select(letterMastery)
      .watch()
      .map((rows) => rows.map((r) => r.letterId).toSet());

  /// Watch the banked clean-rep count for one letter; emits 0 while no row
  /// exists, then the new count on every [setCleanReps] write.
  Stream<int> watchCleanReps(String letterId) =>
      (select(letterReps)..where((t) => t.letterId.equals(letterId)))
          .watchSingleOrNull()
          .map((row) => row?.cleanReps ?? 0);

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

  /// Read the persisted graph position for a letter, or null if the child has
  /// never started it (clean default — start at the graph root, never throws).
  Future<LetterGraphPositionData?> getPosition(String letterId) =>
      (select(letterGraphPosition)
            ..where((t) => t.letterId.equals(letterId)))
          .getSingleOrNull();

  /// Write (or overwrite) the graph position for a letter. The competency/tier
  /// lists are JSON-encoded into their text columns.
  Future<void> setPosition({
    required String letterId,
    String? currentExerciseId,
    required List<String> clearedCompetencies,
    required List<String> clearedTiers,
  }) =>
      into(letterGraphPosition).insertOnConflictUpdate(
        LetterGraphPositionCompanion.insert(
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
  /// letter (write-through, including 0 — mirrors setCleanReps' reset shape).
  Future<void> setExerciseCleanReps({
    required String letterId,
    required String exerciseId,
    required int cleanReps,
  }) =>
      into(letterExerciseReps).insertOnConflictUpdate(
        LetterExerciseRepsCompanion.insert(
          letterId: letterId,
          exerciseId: exerciseId,
          cleanReps: cleanReps,
          updatedAt: DateTime.now(),
        ),
      );

  /// Read the banked clean-rep count for one exercise; 0 when never practiced.
  Future<int> getExerciseCleanReps({
    required String letterId,
    required String exerciseId,
  }) async =>
      (await (select(letterExerciseReps)
                ..where((t) =>
                    t.letterId.equals(letterId) &
                    t.exerciseId.equals(exerciseId)))
              .getSingleOrNull())
          ?.cleanReps ??
      0;

  /// Atomically increment the banked clean-rep count for one exercise by 1.
  /// Reads the current count, adds 1, and writes back. Safe to call from an
  /// async context; a missing row is treated as 0 before incrementing.
  Future<void> incrementExerciseCleanReps({
    required String letterId,
    required String exerciseId,
  }) async {
    final current = await getExerciseCleanReps(
      letterId: letterId,
      exerciseId: exerciseId,
    );
    await setExerciseCleanReps(
      letterId: letterId,
      exerciseId: exerciseId,
      cleanReps: current + 1,
    );
  }

  /// Read every banked per-exercise clean-rep count for a letter as a
  /// `{exerciseId: cleanReps}` map — the exact shape `isMasteryMet` consumes.
  Future<Map<String, int>> exerciseCleanRepsFor(String letterId) async {
    final rows = await (select(letterExerciseReps)
          ..where((t) => t.letterId.equals(letterId)))
        .get();
    return {for (final r in rows) r.exerciseId: r.cleanReps};
  }

  // ---------------------------------------------------------------------------
  // Read-only aggregate accessors for the Parent Dashboard — Phase 9 (S1-11,
  // Plan 09-02, RESEARCH Pattern 4). Read-only is a HARD constraint: there is
  // deliberately NO edit/delete/reset accessor exposed to the parent surface
  // (threat T-09-09). SECURITY: read-only; never logs values.
  // ---------------------------------------------------------------------------

  /// All mastered letters, ordered oldest → newest by masteredAt. Each row
  /// carries the cleanReps + masteredAt the dashboard renders. READ-ONLY.
  Future<List<LetterMasteryData>> allMastered() => (select(letterMastery)
        ..orderBy([(t) => OrderingTerm(expression: t.masteredAt)]))
      .get();

  /// All in-progress letters (cleanReps > 0). A 0-rep row is "not started" and
  /// is excluded. READ-ONLY.
  Future<List<LetterRep>> allInProgress() =>
      (select(letterReps)..where((t) => t.cleanReps.isBiggerThanValue(0)))
          .get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory(); // app-private storage
    final file = File('${dir.path}${Platform.pathSeparator}qalam.db');
    return NativeDatabase.createInBackground(file);
  });
}

/// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
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
