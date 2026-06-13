// Immutable view model for the read-only Parent Dashboard — Phase 9 (S1-11).
// Field shape is pinned by the Wave-0 RED contract
// (test/screens/parent_dashboard_test.dart): `ParentProgress(mastered:, total:,
// rows:)` and `ParentLetterRow(letterId:, displayName:, mastered:, cleanReps:,
// masteredAtLabel:)`. The screen + provider in 09-03 build against exactly these
// names.
//
// Pure value types only — no Drift types, no providers, no widgets. Plan 09-03
// assembles `ParentProgress` from the curriculum letter list + the
// allMastered()/allInProgress() accessors and renders it.
//
// SECURITY: holds only the child's own letter-progress display data (glyph-free
// here; the dashboard sources the glyph from the curriculum Letter), Latin name,
// mastered flag, clean-rep count, pre-formatted mastered-date label — no PIN
// material, never logged.

/// One row of the read-only parent progress list: the letter's id + Latin
/// display name, whether it is mastered, the banked clean-rep count, and (for
/// mastered letters) a pre-formatted mastered-date label.
class ParentLetterRow {
  /// Curriculum letter id (e.g. "alif").
  final String letterId;

  /// Latin display name (e.g. "alif") — sourced from `Letter.name.display`.
  final String displayName;

  /// True when the letter has been mastered; false for an in-progress row.
  final bool mastered;

  /// Clean reps banked toward (or at) mastery.
  final int cleanReps;

  /// Pre-formatted device-locale short date the letter was mastered; null for
  /// in-progress rows. Formatting happens at the assembly site (the provider),
  /// not in this value type, so this stays widget/locale-free.
  final String? masteredAtLabel;

  const ParentLetterRow({
    required this.letterId,
    required this.displayName,
    required this.mastered,
    required this.cleanReps,
    this.masteredAtLabel,
  });
}

/// The full read-only progress snapshot the dashboard renders: the "N of M"
/// summary counts plus the ordered per-letter rows. The denominator [total] is
/// the curriculum letter count — never hardcoded to 28 (Pitfall 5).
class ParentProgress {
  /// Number of mastered letters (the "N" in "N of M").
  final int mastered;

  /// Total curriculum letters (the "M" denominator).
  final int total;

  /// Per-letter rows in curriculum intro order (mastered + in-progress only).
  final List<ParentLetterRow> rows;

  const ParentProgress({
    required this.mastered,
    required this.total,
    required this.rows,
  });
}
