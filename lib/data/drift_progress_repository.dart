// Plan 03-02 — Drift implementation of ProgressRepository.
//
// SECURITY (T-03-01/T-01-05): delegates to AppDatabase.recordMastery which
// persists ONLY letterId/cleanReps/masteredAt. Stroke points are never
// passed to this class and are never stored.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';
import 'progress_repository.dart';

part 'drift_progress_repository.g.dart';

/// Drift-backed implementation of [ProgressRepository].
///
/// Thin delegation layer: all SQL is in [AppDatabase] (mirrors the
/// setSetting/getSetting pattern from Phase 1).
class DriftProgressRepository implements ProgressRepository {
  const DriftProgressRepository(this._db);
  final AppDatabase _db;

  @override
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  }) =>
      _db.recordMastery(letterId: letterId, cleanReps: cleanReps);

  @override
  Future<bool> isMastered(String letterId) => _db.isMastered(letterId);
}

/// Riverpod provider for [ProgressRepository] — keepAlive mirrors the
/// appDatabaseProvider and curriculumRepositoryProvider pattern (D-11).
@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) =>
    DriftProgressRepository(ref.watch(appDatabaseProvider));
