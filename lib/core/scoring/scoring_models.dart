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
  fallback, // no authored check matched — should not occur with signed-off data
}

/// The result of scoring one child stroke against a reference.
class StrokeResult {
  final bool passed;

  /// Null when [passed] is true; the first failing predicate otherwise.
  final MistakeId? mistakeId;

  const StrokeResult({required this.passed, this.mistakeId});
}
