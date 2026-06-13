// Immutable view model for the read-only Parent Dashboard — Phase 9 (S1-11,
// Plan 09-02). Mirrors the immutable-class-with-const-constructor style of
// `Letter` (lib/models/letter.dart) and the computed-snapshot style of
// `ProgressionSnapshot` (lib/models/lesson_progression.dart).
//
// Pure value types only — no Drift types, no providers, no widgets. Plan 09-03
// assembles `ParentProgress` from the curriculum letter list + the new
// allMastered()/allInProgress() accessors and renders it.
//
// SECURITY: holds only the child's own letter-progress display data (glyph,
// Latin name, status, clean-rep count, mastered date) — no PIN material, never
// logged.

import '../../models/letter.dart';

/// Whether a letter has been mastered or is still in progress on the dashboard.
/// An enum (not a String) so callers branch exhaustively.
enum ParentLetterStatus { mastered, inProgress }

/// One row of the read-only parent progress list: the letter's glyph + Latin
/// display name, its status, the banked clean-rep count, and (for mastered
/// letters) the date it was mastered.
class ParentLetterRow {
  /// Curriculum letter id (e.g. "alif").
  final String id;

  /// Latin display name (e.g. "Alif") — sourced from `Letter.name.display`.
  final String displayName;

  /// Arabic glyph (isolated form) — sourced from `Letter.char`.
  final String char;

  /// Mastered vs. in-progress.
  final ParentLetterStatus status;

  /// Clean reps banked toward (or at) mastery.
  final int cleanReps;

  /// When the letter was mastered; null for in-progress rows.
  final DateTime? masteredAt;

  const ParentLetterRow({
    required this.id,
    required this.displayName,
    required this.char,
    required this.status,
    required this.cleanReps,
    this.masteredAt,
  });

  /// Build a mastered row from a curriculum [letter] + its mastery record.
  factory ParentLetterRow.mastered(
    Letter letter,
    int cleanReps,
    DateTime masteredAt,
  ) =>
      ParentLetterRow(
        id: letter.id,
        displayName: letter.name.display,
        char: letter.char,
        status: ParentLetterStatus.mastered,
        cleanReps: cleanReps,
        masteredAt: masteredAt,
      );

  /// Build an in-progress row from a curriculum [letter] + its banked reps.
  factory ParentLetterRow.inProgress(Letter letter, int cleanReps) =>
      ParentLetterRow(
        id: letter.id,
        displayName: letter.name.display,
        char: letter.char,
        status: ParentLetterStatus.inProgress,
        cleanReps: cleanReps,
      );
}

/// The full read-only progress snapshot the dashboard renders: the "N of M"
/// summary counts plus the ordered per-letter rows. The denominator
/// [totalLetters] is the curriculum letter count — never hardcoded to 28
/// (Pitfall 5).
class ParentProgress {
  /// Number of mastered letters (the "N" in "N of M").
  final int masteredCount;

  /// Total curriculum letters (the "M" denominator).
  final int totalLetters;

  /// Per-letter rows in curriculum intro order (mastered + in-progress only).
  final List<ParentLetterRow> rows;

  const ParentProgress({
    required this.masteredCount,
    required this.totalLetters,
    required this.rows,
  });
}
