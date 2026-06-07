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

@DriftDatabase(tables: [AppSettings, LetterMastery])
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Pitfall 4: guard by version to make the migration idempotent.
          if (from < 2) await m.createTable(letterMastery);
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
