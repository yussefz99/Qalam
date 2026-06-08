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

@DriftDatabase(tables: [AppSettings, LetterMastery, ChildProfiles])
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Pitfall 4: guard by version to make the migration idempotent.
          if (from < 2) await m.createTable(letterMastery);
          if (from < 3) await m.createTable(childProfiles);
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
