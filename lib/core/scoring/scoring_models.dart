/// Pure Dart, no dart:ui, no Flutter imports.
///
/// Shared value types for the geometric stroke scorer (Plan 03-01).
/// Kept in a separate file so stroke_resampler.dart can stay independent of
/// the scorer and both can be imported by tests individually.
library;

// Predicate name → mistake identity mapping.
// The enum value names intentionally mirror the authored commonMistakes[].check
// strings in letters.json — breaking one requires changing the other.
enum MistakeId {
  tooShort, // check: "strokeLengthBelowThreshold"
  wrongDirection, // check: "strokeDirectionInverted"
  tooCurved, // check: "strokeCurvatureExceedsThreshold"
  // ── Whole-letter failure categories (Plan 04-01 / Plan 02 implements) ──
  wrongStrokeCount, // check: "strokeCountMismatch"
  wrongStrokeOrder, // check: "strokeOrderWrong"
  dotMisplaced, // check: "dotPositionWrong" / "dotCountWrong"
  wrongLetterIdentity, // check: "letterIdentityMismatch" — ML Kit gate (D-04)
  fallback, // no authored check matched — should not occur with signed-off data
}

/// The result of scoring one child stroke against a reference.
class StrokeResult {
  final bool passed;

  /// Null when [passed] is true; the first failing predicate otherwise.
  final MistakeId? mistakeId;

  const StrokeResult({required this.passed, this.mistakeId});
}

/// The result of scoring a whole letter (all of its strokes together).
///
/// Mirrors [StrokeResult] one level up: a [passed] flag plus the first failing
/// whole-letter predicate. The `.fail`/`.pass` factories keep the orchestrator
/// (Plan 02 `scoreLetter`) readable.
class LetterResult {
  final bool passed;

  /// Null when [passed] is true; the first failing whole-letter predicate
  /// otherwise (count / order / dot / identity, or a propagated per-stroke id).
  final MistakeId? mistakeId;

  const LetterResult({required this.passed, this.mistakeId});

  /// A failing letter result carrying the offending [id].
  const LetterResult.fail(MistakeId id) : passed = false, mistakeId = id;

  /// A passing letter result (no mistake).
  const LetterResult.pass() : passed = true, mistakeId = null;
}
