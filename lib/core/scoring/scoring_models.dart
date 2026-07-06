/// Pure Dart, no dart:ui, no Flutter imports.
///
/// Shared value types for the geometric stroke scorer (Plan 03-01).
/// Kept in a separate file so stroke_resampler.dart can stay independent of
/// the scorer and both can be imported by tests individually.
library;

import 'shape_match.dart';

// Predicate name → mistake identity mapping.
// The enum value names intentionally mirror the authored commonMistakes[].check
// strings in letters.json — breaking one requires changing the other.
enum MistakeId {
  tooShort, // check: "strokeLengthBelowThreshold"
  wrongDirection, // check: "strokeDirectionInverted"
  // Under the DTW soft verdict (Plan 17-02, D-C) `tooCurved` means "shape
  // certainly-wrong vs the reference" — the child stroke's DTW distance fell
  // past the certainly-wrong threshold ([SoftBand] tcw), whatever the actual
  // deformation (too flat, too curved, wrong arc). The enum NAME and its
  // "strokeCurvatureExceedsThreshold" check-string pairing are KEPT (Pitfall
  // 2): authored feedback in letters.json and the calibration harness
  // `_expectedRejection` both key off this exact pair.
  tooCurved, // check: "strokeCurvatureExceedsThreshold"
  // ── Whole-letter failure categories (Plan 04-01 / Plan 02 implements) ──
  wrongStrokeCount, // check: "strokeCountMismatch"
  wrongStrokeOrder, // check: "strokeOrderWrong"
  dotMisplaced, // check: "dotPositionWrong" / "dotCountWrong"
  wrongLetterIdentity, // check: "letterIdentityMismatch" — ML Kit gate (D-04)
  fallback, // no authored check matched — should not occur with signed-off data
}

/// One scored criterion of a stroke (or letter) verdict — the soft 3-zone
/// scheme's structured output (Plan 17-02, D-C).
///
/// The field is `criterion`, NEVER `name` (and no field may contain the
/// substring "point"): this record is the future coaching wire payload, and
/// the non-PII token regex guards (payload_nonpii_test.dart) forbid those
/// substrings by construction (T-17-02).
class CriterionResult {
  /// Which criterion was scored — e.g. 'shape' or 'direction'.
  final String criterion;

  /// Which soft zone the criterion's distance landed in
  /// (certainlyCorrect / fuzzy / certainlyWrong — only certainlyWrong fails).
  final ShapeZone zone;

  /// Continuous 1.0 (perfect) → 0.0 (certainly wrong) score across the band.
  final double score;

  const CriterionResult({
    required this.criterion,
    required this.zone,
    required this.score,
  });
}

/// The result of scoring one child stroke against a reference.
class StrokeResult {
  final bool passed;

  /// Null when [passed] is true; the first failing predicate otherwise.
  final MistakeId? mistakeId;

  /// Per-criterion soft-zone results (shape + direction), populated on pass
  /// AND fail so the letter-level scorer (17-03) can aggregate them. Empty
  /// only for degenerate strokes that short-circuit before geometry
  /// (the firm tooShort raw-point floor).
  final List<CriterionResult> criteria;

  const StrokeResult({
    required this.passed,
    this.mistakeId,
    this.criteria = const [],
  });
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

/// The STRUCTURED whole-letter score (Plan 17-03, D-B / the D-C amendment of
/// 2026-07-05).
///
/// Extends [LetterResult] so every existing caller stays source-compatible —
/// including practice_screen.dart's explicit `LetterResult` annotation and the
/// validator's `result.passed`/`result.mistakeId` reads: those two fields keep
/// their exact Phase-4 semantics (Pitfall 2). What [LetterScore] ADDS is the
/// coaching input D-B requires:
///   • [criteria] — the five owner-confirmed per-criterion results
///     (strokeCount / strokeOrder / shape / direction / dot). COUNT, ORDER and
///     the dot check are FIRM (categorical certainlyWrong/0.0); shape and
///     direction are the SOFT geometry criteria.
///   • [weakest]  — the lowest-score criterion, the coach's single target.
///
/// The list carries only `{criterion, zone, score}` scalars — never a
/// coordinate (T-17-06): the non-PII wire-token guards forbid a `point`
/// substring by construction.
class LetterScore extends LetterResult {
  /// The per-criterion soft-zone results. On a full evaluation this is the five
  /// entries above; on a firm short-circuit (a count/order fail) it carries the
  /// criteria that actually ran (the failing firm criterion first).
  final List<CriterionResult> criteria;

  /// The minimum-score criterion in [criteria] — the coaching target (D-B).
  /// Null only when [criteria] is empty (never, for a scored letter).
  final CriterionResult? weakest;

  const LetterScore({
    required super.passed,
    super.mistakeId,
    this.criteria = const [],
    this.weakest,
  });
}
