/// Pure Dart, no dart:ui, no Flutter imports.
///
/// THE VALIDATOR → FEEDBACKPANEL CONTRACT (Plan 07-03).
///
/// `validateExercise` (exercise_validator.dart) turns a child's raw strokes into
/// a pass-or-specific-fix verdict for EVERY baa question type. That verdict is a
/// [CheckResult]: a `passed` flag plus, on a miss, the matched `mistakeId`.
///
/// The `mistakeId` is the bridge to the AUTHORED feedback line: Plan 07-04's
/// FeedbackPanel resolves it against the exercise's own `feedback` map —
/// `feedback[mistakeId]` for a miss, `feedback['pass']` for a pass — so the child
/// always sees the owner's-mother's specific wording (the tutor's voice), never a
/// generic "try again" (CLAUDE.md — the heart of the app).
///
/// SECURITY (T-07-03-01): this type carries ONLY a bool + an optional authored
/// key. No raw strokes, no coordinates, nothing that could leak the child's
/// in-memory capture. It is the only thing that leaves the validator.
library;

/// The result of validating one captured exercise attempt.
///
/// Immutable. A pass has `passed == true` and `mistakeId == null`; a miss has
/// `passed == false` and carries the [mistakeId] whose authored fix line lives in
/// the exercise's `feedback` map.
class CheckResult {
  final bool passed;

  /// Null when [passed] is true. On a miss, the key into the exercise's
  /// `feedback` map (e.g. "shallowBowl", "missingDot", "lifted", "wrongOrder").
  /// Always one of the exercise's authored keys — never a raw scorer internal.
  final String? mistakeId;

  const CheckResult({required this.passed, this.mistakeId});

  /// A passing verdict — the attempt met the check (FeedbackPanel shows
  /// `feedback['pass']`).
  const CheckResult.pass() : passed = true, mistakeId = null;

  /// A failing verdict carrying the matched [mistakeId] (FeedbackPanel shows
  /// `feedback[mistakeId]`).
  const CheckResult.fail(String mistakeId)
    : passed = false,
      mistakeId = mistakeId;

  @override
  bool operator ==(Object other) =>
      other is CheckResult &&
      other.passed == passed &&
      other.mistakeId == mistakeId;

  @override
  int get hashCode => Object.hash(passed, mistakeId);

  @override
  String toString() =>
      passed ? 'CheckResult.pass()' : 'CheckResult.fail($mistakeId)';
}
