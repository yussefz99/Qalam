// Plan 03-02 — ProgressRepository interface.
//
// SECURITY (T-03-01/T-01-05): implementations persist ONLY letterId, cleanReps,
// and masteredAt. Captured stroke points are NEVER stored — they stay in-memory
// only and are discarded on dispose.
//
// ADR-018 (D-13/D-14, Plan 19-06): every method that reads or writes a child's
// progress carries a required [childProfileId] — the in-file child dimension that
// keeps a fresh profile from reading the prior child's rows. It is a LOCAL int
// (ChildProfiles.id); it NEVER enters TutorFacts / the coach payload (the ADR-017
// wire boundary). The legacy `setCleanReps` / `getCleanReps` / `watchCleanReps`
// members were REMOVED with the LetterReps table (their live readers folded onto
// the LetterExerciseReps aggregate in 19-04).

/// Repository for letter mastery persistence (D-09, Plan 03-02).
///
/// The interface decouples the session controller from Drift so tests can
/// inject fakes without spinning up a real database.
abstract interface class ProgressRepository {
  /// Record (or overwrite) a mastery result for [letterId] under
  /// [childProfileId] (ADR-018).
  ///
  /// SECURITY: only [childProfileId], [letterId] and [cleanReps] are persisted —
  /// never stroke points (T-03-01/T-01-05).
  Future<void> recordMastery({
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  });

  /// Returns true if [letterId] has a mastery record for [childProfileId].
  Future<bool> isMastered(String letterId, {required int childProfileId});

  /// Watch the set of mastered letter IDs for [childProfileId]; emits the current
  /// state first, then on every mastery write — the S1-09 "unlock is immediate"
  /// substrate.
  ///
  /// SECURITY: emits only letter IDs — never stroke points or timestamps
  /// (T-03-01/T-06-01).
  Stream<Set<String>> watchMasteredLetterIds({required int childProfileId});

  // ---------------------------------------------------------------------------
  // D-15 FOLD (Plan 19-04): the folded per-letter aggregate over
  // LetterExerciseReps that replaced the retired LetterReps reads. Re-keyed by
  // [childProfileId] in 19-06 (ADR-018). See AppDatabase for the MAX aggregation
  // rule.
  // ---------------------------------------------------------------------------

  /// Read the folded per-letter clean-reps aggregate for [letterId] over its
  /// LetterExerciseReps rows under [childProfileId] (D-15); 0 when never
  /// practiced.
  ///
  /// SECURITY: returns only an int count — never stroke points (T-06-01).
  Future<int> letterCleanReps(String letterId, {required int childProfileId});

  /// Watch the folded per-letter clean-reps aggregate for [letterId] under
  /// [childProfileId] (D-15); emits 0 while no exercise row exists, then the new
  /// aggregate on every per-exercise write. The live ribbon path.
  ///
  /// SECURITY: emits only an int count — never stroke points (T-06-01).
  Stream<int> watchLetterCleanReps(String letterId,
      {required int childProfileId});

  /// Write the per-letter clean-rep count for [letterId] under [childProfileId]
  /// THROUGH to the LetterExerciseReps table (D-15 fold of the legacy /practice
  /// write-through). Absolute write, including 0 (the reset shape).
  ///
  /// SECURITY: only [childProfileId] + [letterId] + an int count are persisted —
  /// never stroke points (T-06-01).
  Future<void> setLetterCleanReps({
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  });
}
