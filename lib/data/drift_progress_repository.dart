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
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  }) =>
      _db.recordMastery(
        childProfileId: childProfileId,
        letterId: letterId,
        cleanReps: cleanReps,
      );

  @override
  Future<bool> isMastered(String letterId, {required int childProfileId}) =>
      _db.isMastered(letterId, childProfileId: childProfileId);

  @override
  Stream<Set<String>> watchMasteredLetterIds({required int childProfileId}) =>
      _db.watchMasteredLetterIds(childProfileId: childProfileId);

  // ---------------------------------------------------------------------------
  // D-15 FOLD (Plan 19-04): delegate the folded per-letter aggregate to the
  // LetterExerciseReps accessors on [AppDatabase]. Re-keyed by childProfileId
  // in 19-06 (ADR-018).
  // ---------------------------------------------------------------------------

  /// The synthetic LetterExerciseReps exercise id under which the legacy
  /// per-letter /practice counter banks its single row (D-15 fold). Chosen so it
  /// NEVER collides with a real curriculum-graph exercise id (those are
  /// `<letter>.<config>`, e.g. `baa.traceLetter.isolated`); and only NON-unit
  /// letters use the /practice loop (unit letters — alif/baa/taa — route to
  /// /unit and write real graph rows), so a letter never mixes this row with
  /// graph rows. MAX over one row == that row, so the ribbon/resume value is
  /// behavior-identical to the old LetterReps counter.
  static const String wholeLetterExerciseId = '__whole_letter__';

  @override
  Future<int> letterCleanReps(String letterId, {required int childProfileId}) =>
      _db.letterCleanReps(letterId, childProfileId: childProfileId);

  @override
  Stream<int> watchLetterCleanReps(String letterId,
          {required int childProfileId}) =>
      _db.watchLetterCleanReps(letterId, childProfileId: childProfileId);

  @override
  Future<void> setLetterCleanReps({
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  }) =>
      _db.setExerciseCleanReps(
        childProfileId: childProfileId,
        letterId: letterId,
        exerciseId: wholeLetterExerciseId,
        cleanReps: cleanReps,
      );
}

/// Riverpod provider for [ProgressRepository] — keepAlive mirrors the
/// appDatabaseProvider and curriculumRepositoryProvider pattern (D-11).
@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) =>
    DriftProgressRepository(ref.watch(appDatabaseProvider));
