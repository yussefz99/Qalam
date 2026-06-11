// Plan 03-02 — ProgressRepository interface.
//
// SECURITY (T-03-01/T-01-05): implementations persist ONLY letterId, cleanReps,
// and masteredAt. Captured stroke points are NEVER stored — they stay in-memory
// only and are discarded on dispose.

/// Repository for letter mastery persistence (D-09, Plan 03-02).
///
/// The interface decouples the session controller from Drift so tests can
/// inject fakes without spinning up a real database.
abstract interface class ProgressRepository {
  /// Record (or overwrite) a mastery result for [letterId].
  ///
  /// SECURITY: only [letterId] and [cleanReps] are persisted — never stroke
  /// points (T-03-01/T-01-05).
  Future<void> recordMastery({
    required String letterId,
    required int cleanReps,
  });

  /// Returns true if [letterId] has a mastery record.
  Future<bool> isMastered(String letterId);

  /// Write (or overwrite) the PARTIAL clean-rep count for [letterId] (D-10).
  ///
  /// Write-through, including 0: `setCleanReps(letterId: x, cleanReps: 0)`
  /// resets the banked count.
  ///
  /// SECURITY: only [letterId] and an int count are persisted — never stroke
  /// points (T-03-01/T-06-01).
  Future<void> setCleanReps({
    required String letterId,
    required int cleanReps,
  });

  /// Read the banked clean-rep count for [letterId]; 0 when never practiced.
  ///
  /// SECURITY: returns only an int count — stroke data is never stored, so
  /// none can be read back (T-03-01/T-06-01).
  Future<int> getCleanReps(String letterId);

  /// Watch the set of mastered letter IDs; emits the current state first, then
  /// on every mastery write — the S1-09 "unlock is immediate" substrate.
  ///
  /// SECURITY: emits only letter IDs — never stroke points or timestamps
  /// (T-03-01/T-06-01).
  Stream<Set<String>> watchMasteredLetterIds();

  /// Watch the banked clean-rep count for [letterId]; emits 0 while no row
  /// exists, then the new count on every [setCleanReps] write.
  ///
  /// SECURITY: emits only an int count — never stroke points (T-03-01/T-06-01).
  Stream<int> watchCleanReps(String letterId);
}
