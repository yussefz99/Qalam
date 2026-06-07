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
}
