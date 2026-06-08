import 'dart:math' as math;

import '../../models/letter.dart';
import 'scoring_models.dart';
import 'stroke_resampler.dart';
import 'tolerances.dart';

// ── Tuned thresholds (lenient first-cut — Phase 4 calibrates these) ──────────
//
// The numeric knobs no longer live as file-level `const`s here: Plan 04-01 moved
// them into the data-driven `Tolerances` class (SC#4), and Plan 04-02 threads a
// `Tolerances` argument through `scoreStroke`. The doc-comment RATIONALE for each
// value stays beside its `Tolerances.normal` field (tolerances.dart) so the
// reasoning is not lost — `Tolerances.normal` IS the behavior-preserving anchor
// (A5) equal to the former `_kMinRawPoints=10` / `_kResampleN=32` /
// `_kMaxCurvature=0.25`.
//
// `scoreStroke` defaults to `Tolerances.normal` when no per-letter block is
// supplied, so single-stroke alif callers are unaffected.

// ─────────────────────────────────────────────────────────────────────────────

/// Scores a single captured child stroke against [reference] and returns the
/// first failing predicate or a pass.
///
/// [childStroke] is a list of [x, y] pixel-coordinate pairs in capture order.
/// [reference] is the authored [StrokeSpec] in normalised 0..1 space.
/// [tolerances] supplies the per-letter scoring knobs (resample count, raw-point
/// floor, curvature ceiling); it defaults to [Tolerances.normal] — the locked
/// behavior-preserving preset — so existing single-stroke callers (alif) keep
/// scoring exactly as before (A5).
StrokeResult scoreStroke(
  List<List<double>> childStroke,
  StrokeSpec reference, [
  Tolerances tolerances = Tolerances.normal,
]) {
  // Predicate 1 — strokeLengthBelowThreshold
  // Applied to raw input before resampling: too few points = pen lifted early.
  if (strokeLengthBelowThreshold(childStroke, tolerances)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.tooShort);
  }

  // Resample and normalise for the geometric predicates.
  final normalised =
      normalizeToUnitBox(resample(childStroke, tolerances.resampleN));

  // Predicate 2 — strokeDirectionInverted
  if (strokeDirectionInverted(normalised, reference)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.wrongDirection);
  }

  // Predicate 3 — strokeCurvatureExceedsThreshold
  if (strokeCurvatureExceedsThreshold(normalised, tolerances)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.tooCurved);
  }

  return const StrokeResult(passed: true);
}

/// Maps a [MistakeId] to the exact authored feedback string from
/// [letter.commonMistakes], matching by the predicate's check-name convention.
///
/// The enum-value names in [MistakeId] intentionally parallel the
/// [CommonMistake.check] strings in `letters.json`; breaking one requires
/// updating the other.  [MistakeId.fallback] (or any unmatched id) returns a
/// calm, specific fallback — never a generic "Oops, try again".
String? feedbackForMistake(MistakeId id, Letter letter) {
  const checkNames = {
    MistakeId.tooShort: 'strokeLengthBelowThreshold',
    MistakeId.wrongDirection: 'strokeDirectionInverted',
    MistakeId.tooCurved: 'strokeCurvatureExceedsThreshold',
  };

  final checkName = checkNames[id];
  if (checkName != null) {
    for (final mistake in letter.commonMistakes) {
      if (mistake.check == checkName) return mistake.feedback;
    }
  }
  return 'Something looks off — try again, slower this time.';
}

// ── Named predicates (function names equal commonMistakes[].check strings) ───

/// Returns true if [pts] has too few raw input points to constitute a complete
/// stroke (child likely lifted the pen before finishing).
///
/// The floor comes from [tolerances] (was the file-level `_kMinRawPoints` const;
/// defaults to [Tolerances.normal]'s 10 — A5).
///
/// Named [strokeLengthBelowThreshold] to match `letters.json` check string.
bool strokeLengthBelowThreshold(
  List<List<double>> pts, [
  Tolerances tolerances = Tolerances.normal,
]) =>
    pts.length < tolerances.minRawPoints;

/// Returns true if the child stroke's direction disagrees with [reference].
///
/// Operates on the normalised stroke.  Mirrors the direction-sign logic in
/// `stroke_validation.dart` lines 162-175.
///
/// Named [strokeDirectionInverted] to match `letters.json` check string.
bool strokeDirectionInverted(
  List<List<double>> normalisedPts,
  StrokeSpec reference,
) {
  if (normalisedPts.isEmpty) return false;
  final first = normalisedPts.first;
  final last = normalisedPts.last;
  final dy = last[1] - first[1];
  final dx = last[0] - first[0];

  switch (reference.direction) {
    case 'topToBottom':
      return !(dy > 0);
    case 'bottomToTop':
      return !(dy < 0);
    case 'leftToRight':
      return !(dx > 0);
    case 'rightToLeft':
      return !(dx < 0);
    default:
      return false; // 'tap' and unknown directions are not direction-checked
  }
}

/// Returns true if the maximum perpendicular distance from the chord
/// (start→end line) through [pts] exceeds the curvature ceiling in
/// [tolerances] (was the file-level `_kMaxCurvature` const; defaults to
/// [Tolerances.normal]'s 0.25 — A5) in unit-box space.
///
/// Named [strokeCurvatureExceedsThreshold] to match `letters.json` check string.
bool strokeCurvatureExceedsThreshold(
  List<List<double>> pts, [
  Tolerances tolerances = Tolerances.normal,
]) {
  if (pts.length < 3) return false;

  final ax = pts.first[0], ay = pts.first[1];
  final bx = pts.last[0], by = pts.last[1];
  final dx = bx - ax, dy = by - ay;
  final len = math.sqrt(dx * dx + dy * dy);

  if (len < 1e-9) {
    // Degenerate: start and end coincide — no curvature check on a dot.
    return false;
  }

  var maxDist = 0.0;
  for (final p in pts) {
    final cross = (p[0] - ax) * dy - (p[1] - ay) * dx;
    final d = cross.abs() / len;
    if (d > maxDist) maxDist = d;
  }
  return maxDist > tolerances.maxCurvature;
}
