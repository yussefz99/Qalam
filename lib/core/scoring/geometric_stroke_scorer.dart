/// Pure Dart, no dart:ui, no Flutter imports.
///
/// THE PER-STROKE LEAF SCORER — soft 3-zone verdict (Plan 17-02, D-C).
///
/// `scoreStroke` evaluates one captured child stroke against its authored
/// [StrokeSpec] reference:
///   1. FIRM raw-point floor (`strokeLengthBelowThreshold` → tooShort) — a pen
///      lifted early short-circuits BEFORE any geometry.
///   2. DIRECTION criterion — the stroke's net displacement projected on the
///      reference direction axis, scored against a soft band
///      (`Tolerances.directionCc`/`directionCw`); only a certainly-inverted
///      stroke fails (wrongDirection).
///   3. SHAPE criterion — the DTW `shapeDistance` to the reference
///      (shape_match.dart), scored against a `SoftBand` built from
///      `Tolerances.shapeTcc`/`shapeTcw`; only a certainly-wrong shape fails
///      (tooCurved — the KEPT enum id, Pitfall 2).
///
/// The verdict is SOFT: a criterion landing in the tolerant FUZZY middle
/// PASSES — that is the UAT F2 false-fail fix (a shaky-but-correct child hand
/// no longer fails), while a genuinely wrong shape/direction still falls past
/// the certainly-wrong threshold and fails. Thresholds are DATA
/// ([Tolerances], D-D), never code constants; the chord-curvature proxy this
/// replaces is gone (its `maxCurvature` knob is parse-compat only).
///
/// SECURITY (T-17-03): child points live only in local variables here; nothing
/// is printed, logged, or persisted. Only the derived [StrokeResult] (verdict +
/// per-criterion zone/score scalars) leaves this function.
library;

import '../../models/letter.dart';
import 'scoring_models.dart';
import 'shape_match.dart';
import 'stroke_resampler.dart';
import 'tolerances.dart';

/// Scores a single captured child stroke against [reference] and returns a
/// soft verdict: fail ONLY when a criterion is certainly wrong; the first
/// failing criterion (direction, then shape) names the [MistakeId].
///
/// [childStroke] is a list of [x, y] pixel-coordinate pairs in capture order.
/// [reference] is the authored [StrokeSpec] in normalised 0..1 space.
/// [tolerances] supplies the per-letter scoring knobs (resample count,
/// raw-point floor, soft-band thresholds); it defaults to [Tolerances.normal].
///
/// The returned [StrokeResult.criteria] carries the shape and direction
/// [CriterionResult]s on pass AND fail (the letter scorer aggregates them);
/// only the firm tooShort floor returns without criteria (it short-circuits
/// before geometry).
StrokeResult scoreStroke(
  List<List<double>> childStroke,
  StrokeSpec reference, [
  Tolerances tolerances = Tolerances.normal,
]) {
  // FIRM pre-check — strokeLengthBelowThreshold.
  // Applied to raw input before resampling: too few points = pen lifted early.
  if (strokeLengthBelowThreshold(childStroke, tolerances)) {
    return const StrokeResult(passed: false, mistakeId: MistakeId.tooShort);
  }

  // Resample + normalise ONCE for the direction criterion. NOTE:
  // `shapeDistance` resamples/normalizes its inputs internally — hand it the
  // RAW stroke below, never this normalised copy (no double-normalization).
  final normalised =
      normalizeToUnitBox(resample(childStroke, tolerances.resampleN));

  // ── DIRECTION criterion (D-C: direction STAYS a criterion) ────────────────
  // p ∈ [-1, 1]: +1 = perfectly along the reference direction, -1 = perfectly
  // inverted. 'tap'/dot strokes (and unknown directions) have no direction
  // axis and report a benign certainly-correct entry.
  final p = _directionAlignment(normalised, reference);
  final CriterionResult direction;
  if (p == null) {
    direction = const CriterionResult(
      criterion: 'direction',
      zone: ShapeZone.certainlyCorrect,
      score: 1.0,
    );
  } else {
    final ShapeZone zone;
    if (p >= tolerances.directionCc) {
      zone = ShapeZone.certainlyCorrect;
    } else if (p <= tolerances.directionCw) {
      zone = ShapeZone.certainlyWrong;
    } else {
      zone = ShapeZone.fuzzy; // tolerant middle — PASSES
    }
    final score = ((p - tolerances.directionCw) /
            (tolerances.directionCc - tolerances.directionCw))
        .clamp(0.0, 1.0);
    direction = CriterionResult(
      criterion: 'direction',
      zone: zone,
      score: score,
    );
  }

  // ── SHAPE criterion (DTW `shapeDistance` — replaces the chord proxy) ──────
  // A degenerate reference (< 2 points) yields double.infinity → certainly
  // wrong, never a throw (T-17-04); the child side is already floored above.
  final d = shapeDistance(
    childStroke,
    reference.points,
    n: tolerances.resampleN,
  );
  final band = SoftBand(tcc: tolerances.shapeTcc, tcw: tolerances.shapeTcw);
  final shape = CriterionResult(
    criterion: 'shape',
    zone: band.zoneFor(d),
    score: band.scoreFor(d),
  );

  final criteria = <CriterionResult>[shape, direction];

  // Soft verdict — fail ONLY on certainly-wrong; fuzzy passes (the F2 fix).
  // First-failing readability kept: direction, then shape.
  if (direction.zone == ShapeZone.certainlyWrong) {
    return StrokeResult(
      passed: false,
      mistakeId: MistakeId.wrongDirection,
      criteria: criteria,
    );
  }
  if (shape.zone == ShapeZone.certainlyWrong) {
    return StrokeResult(
      passed: false,
      mistakeId: MistakeId.tooCurved,
      criteria: criteria,
    );
  }
  return StrokeResult(passed: true, criteria: criteria);
}

/// Maps a [MistakeId] to the exact authored feedback string from
/// [letter.commonMistakes], matching by the predicate's check-name convention.
///
/// The enum-value names in [MistakeId] intentionally parallel the
/// [CommonMistake.check] strings in `letters.json`; breaking one requires
/// updating the other. `strokeCurvatureExceedsThreshold` remains tooCurved's
/// check string even though the DTW shape criterion replaced the chord proxy
/// (Pitfall 2 — authored feedback keys off the pairing).
/// [MistakeId.fallback] (or any unmatched id) returns a
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
/// defaults to [Tolerances.normal]'s 10 — A5). This check stays FIRM under the
/// soft scheme (D-C): it short-circuits before any geometric criterion runs.
///
/// Named [strokeLengthBelowThreshold] to match `letters.json` check string.
bool strokeLengthBelowThreshold(
  List<List<double>> pts, [
  Tolerances tolerances = Tolerances.normal,
]) =>
    pts.length < tolerances.minRawPoints;

/// Returns true if the child stroke's direction is CERTAINLY inverted against
/// [reference] — its displacement alignment falls at/below the soft band's
/// certainly-wrong threshold ([Tolerances.directionCw]).
///
/// Operates on the normalised stroke. This is the same alignment `scoreStroke`
/// scores softly; the tolerant fuzzy middle (a wobbly-but-roughly-right start)
/// does NOT count as inverted.
///
/// Named [strokeDirectionInverted] to match `letters.json` check string.
bool strokeDirectionInverted(
  List<List<double>> normalisedPts,
  StrokeSpec reference, [
  Tolerances tolerances = Tolerances.normal,
]) {
  final p = _directionAlignment(normalisedPts, reference);
  return p != null && p <= tolerances.directionCw;
}

/// The child stroke's net-displacement alignment with [reference]'s direction
/// axis, in unit-box space: +1 = perfectly along the reference direction,
/// -1 = perfectly inverted. For `topToBottom` the axis is +y, `rightToLeft`
/// the negative-x axis, etc. Returns null for 'tap' and unknown directions
/// (not direction-checked) and for an empty point list.
double? _directionAlignment(
  List<List<double>> normalisedPts,
  StrokeSpec reference,
) {
  if (normalisedPts.isEmpty) return null;
  final first = normalisedPts.first;
  final last = normalisedPts.last;
  final dy = last[1] - first[1];
  final dx = last[0] - first[0];

  switch (reference.direction) {
    case 'topToBottom':
      return dy;
    case 'bottomToTop':
      return -dy;
    case 'leftToRight':
      return dx;
    case 'rightToLeft':
      return -dx;
    default:
      return null; // 'tap' and unknown directions are not direction-checked
  }
}
