import 'dart:math' as math;

import '../../models/letter.dart';
import 'scoring_models.dart';
import 'stroke_resampler.dart';

// ── Tuned thresholds (lenient first-cut — Phase 4 calibrates these) ──────────
//
// Keep ALL scoring knobs here with doc comments explaining the chosen value.

/// Minimum number of raw input points for a stroke to be considered complete.
/// A gesture ending below this count likely means the child lifted the pen
/// before finishing.  This is a proxy for "arc-length below threshold" — Phase 4
/// replaces it with a canvas-size-aware arc-length check once canvas dimensions
/// flow into the scorer alongside the stroke points.
const int _kMinRawPoints = 10;

/// Number of equidistant points the child stroke is resampled to before the
/// direction and curvature predicates run.  32 gives stable geometry well
/// within the sub-300 ms latency budget.
const int _kResampleN = 32;

/// Maximum perpendicular distance from the best-fit chord (start→end line)
/// in the normalised 0..1 unit box.  A child with a modest natural bow still
/// passes at this lenient value; the curved-alif fixture peaks at ~0.3.
const double _kMaxCurvature = 0.25;

// ─────────────────────────────────────────────────────────────────────────────

/// Scores a single captured child stroke against [reference] and returns the
/// first failing predicate or a pass.
///
/// [childStroke] is a list of [x, y] pixel-coordinate pairs in capture order.
/// [reference] is the authored [StrokeSpec] in normalised 0..1 space.
StrokeResult scoreStroke(
  List<List<double>> childStroke,
  StrokeSpec reference,
) {
  // Predicate 1 — strokeLengthBelowThreshold
  // Applied to raw input before resampling: too few points = pen lifted early.
  if (strokeLengthBelowThreshold(childStroke)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.tooShort);
  }

  // Resample and normalise for the geometric predicates.
  final normalised = normalizeToUnitBox(resample(childStroke, _kResampleN));

  // Predicate 2 — strokeDirectionInverted
  if (strokeDirectionInverted(normalised, reference)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.wrongDirection);
  }

  // Predicate 3 — strokeCurvatureExceedsThreshold
  if (strokeCurvatureExceedsThreshold(normalised)) {
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
/// Named [strokeLengthBelowThreshold] to match `letters.json` check string.
bool strokeLengthBelowThreshold(List<List<double>> pts) =>
    pts.length < _kMinRawPoints;

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
/// (start→end line) through [pts] exceeds [_kMaxCurvature] in unit-box space.
///
/// Named [strokeCurvatureExceedsThreshold] to match `letters.json` check string.
bool strokeCurvatureExceedsThreshold(List<List<double>> pts) {
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
  return maxDist > _kMaxCurvature;
}
