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
/// key + optional DERIVED per-criterion / word facts (Phase 17, 17-06). No raw
/// strokes, no coordinates, nothing that could leak the child's in-memory
/// capture. It is the only thing that leaves the validator.
library;

/// The result of validating one captured exercise attempt.
///
/// Immutable. A pass has `passed == true` and `mistakeId == null`; a miss has
/// `passed == false` and carries the [mistakeId] whose authored fix line lives in
/// the exercise's `feedback` map.
///
/// Phase 17 (17-06, STRK-01/D-B/GROUND-04): the result may also carry DERIVED,
/// point-free coaching facts — [criteria]/[weakestCriterion] from the scorer's
/// structured `LetterScore`, and [expectedWord]/[writtenWord] from the word
/// path. All four are optional and DERIVED-only (labels/zones/scores/text —
/// never a coordinate); their serialized shape mirrors the server `TutorFactsIn`
/// (`server/app/schema.py`) via `TutorFacts` byte-for-byte (Pitfall 1 — the 422
/// trap under `extra="forbid"`).
class CheckResult {
  final bool passed;

  /// Null when [passed] is true. On a miss, the key into the exercise's
  /// `feedback` map (e.g. "shallowBowl", "missingDot", "lifted", "wrongOrder").
  /// Always one of the exercise's authored keys — never a raw scorer internal.
  final String? mistakeId;

  /// DERIVED per-criterion scoring results (Phase 17 / 17-06). Each entry is
  /// exactly `{criterion, zone, score}` — the criterion label, the soft zone's
  /// enum NAME string (`certainlyCorrect`/`fuzzy`/`certainlyWrong`), and the
  /// continuous 1.0→0.0 score — serialized from the scorer's `CriterionResult`s.
  /// Never a coordinate. Null when the check ran no criteria (word/order paths
  /// without a glyph leg, teach cards).
  final List<Map<String, Object?>>? criteria;

  /// The name of the lowest-score criterion in [criteria] — the coaching target
  /// (D-B). Null when [criteria] is null/empty.
  final String? weakestCriterion;

  /// The curriculum's expected word on the word path (F6) — DERIVED text from
  /// the exercise config, never geometry. Populated on BOTH pass and fail so
  /// the coach can praise specifically too. Null on non-word checks.
  final String? expectedWord;

  /// The recognizer's transcription of what the child wrote on the word path
  /// (F6) — DERIVED text (an ML Kit transcription of a curriculum word), never
  /// geometry. Populated on BOTH pass and fail. Null on non-word checks.
  final String? writtenWord;

  const CheckResult({
    required this.passed,
    this.mistakeId,
    this.criteria,
    this.weakestCriterion,
    this.expectedWord,
    this.writtenWord,
  });

  /// A passing verdict — the attempt met the check (FeedbackPanel shows
  /// `feedback['pass']`). May carry the derived criteria/word facts (17-06) so
  /// the coach can name what was strong (F6 specific praise).
  const CheckResult.pass({
    this.criteria,
    this.weakestCriterion,
    this.expectedWord,
    this.writtenWord,
  }) : passed = true,
       mistakeId = null;

  /// A failing verdict carrying the matched [mistakeId] (FeedbackPanel shows
  /// `feedback[mistakeId]`), plus the optional derived criteria/word facts.
  const CheckResult.fail(
    String mistakeId, {
    this.criteria,
    this.weakestCriterion,
    this.expectedWord,
    this.writtenWord,
  }) : passed = false,
       // `.fail` deliberately takes a REQUIRED, NON-NULL positional `mistakeId`
       // (a fail must name its authored key) while the field is nullable — the
       // main ctor allows null on a pass. An initializing formal would weaken
       // this factory to accept null, so the initializer-list assignment stays.
       // ignore: prefer_initializing_formals
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
