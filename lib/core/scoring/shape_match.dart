/// Pure Dart, no dart:ui, no Flutter imports.
///
/// SHAPE-MATCH CORE (Phase 17 — the research-backed scorer upgrade).
///
/// The deterministic scorer's missing piece: *how close* is the child's traced
/// curve to the authored reference curve for the asked form? Today's scorer only
/// checks net direction + a chord-curvature ceiling (a proxy tuned for alif's
/// straight line) — it never compares the actual shape to the reference, which is
/// why it is form-blind and false-fails a shaky-but-correct bowl.
///
/// This module adds the metric the field actually uses:
///   • resample both strokes to the same arc-length-equidistant point count,
///   • normalize each to a unit box (size/position invariant — a smaller but
///     correctly-shaped child letter still matches),
///   • take the Dynamic-Time-Warping (DTW) distance between them.
///
/// DTW distance-from-a-reference-shape is a validated, objective letter-form
/// metric that separates good from poor child writers independent of writing
/// speed/kinematics (Guest, handwriting DTW; and the five-criteria children's
/// tutor of Hamdi et al., *Multimedia Tools & Applications* 81:43411, 2022).
///
/// The distance feeds a THREE-ZONE soft band (certainly-correct / fuzzy /
/// certainly-wrong) instead of a hard cut — Hamdi et al.'s TCC/TCW scheme — so a
/// shaky-but-correct child lands in the tolerant middle and PASSES, while a
/// genuinely wrong shape falls past TCW and FAILS. This is the mechanism that
/// fixes the false-fail (UAT F2) without going blind to real errors.
library;

import 'dart:math' as math;

import 'stroke_resampler.dart';

/// Where a criterion's distance falls relative to its two soft thresholds.
enum ShapeZone { certainlyCorrect, fuzzy, certainlyWrong }

/// A soft, two-threshold band over a distance metric (Hamdi et al. 2022's
/// TCC/TCW three-zone scheme).
///
/// [tcc] — at or below this distance the shape is *certainly correct*.
/// [tcw] — at or above this distance it is *certainly wrong*.
/// Between them is the tolerant FUZZY middle, where a continuous [0..1] score
/// interpolates linearly (1.0 at TCC → 0.0 at TCW).
///
/// The two thresholds are DATA, not code: they are meant to be calibrated from
/// labelled child samples (the correct-vs-wrong distance distributions), the same
/// way [Tolerances] presets are. The defaults here are a lenient first cut — a
/// deliberate placeholder until the owner's-mother-labelled set sets them (the
/// research names this labelled-sample requirement explicitly).
class SoftBand {
  /// Distance at/below which the criterion is certainly correct.
  final double tcc;

  /// Distance at/above which the criterion is certainly wrong.
  final double tcw;

  const SoftBand({required this.tcc, required this.tcw})
    : assert(tcc >= 0, 'tcc must be non-negative'),
      assert(tcc < tcw, 'tcc must be below tcw');

  /// First-cut shape band for a resampled/unit-box DTW distance (average
  /// per-aligned-point distance in unit-box space).
  ///
  /// PROVISIONAL — the single source the `Tolerances` soft-band defaults mirror.
  /// WIDENED 2026-07-07 (pre-demo) from tcc/tcw 0.10/0.15 → 0.12/0.16 after the
  /// owner's own correct baa false-failed on device: a real, slightly-shallow
  /// bowl read certainly-wrong against the deep authored reference. Correct
  /// bowls sit at/below TCC=0.12 and pass outright; a flat "line" bowl (0.371
  /// under the anchored normalization) still sits far above TCW=0.16 and fails.
  /// 0.16 is the MAX safe widen: the calibration harness's tightest synthetic
  /// shape-bad (a flat bowl in the FINAL form) is d≈0.1626 and the F5
  /// form-confusion trap is d≈0.2838 — both stay certainly-wrong at 0.16.
  /// These two numbers MUST still be recalibrated from the owner's-mother-
  /// labelled correct-vs-wrong distance distributions before production (the
  /// research names labelled child samples as the hard input).
  static const SoftBand shapeDefault = SoftBand(tcc: 0.12, tcw: 0.16);

  /// The zone [distance] falls into.
  ShapeZone zoneFor(double distance) {
    if (distance <= tcc) return ShapeZone.certainlyCorrect;
    if (distance >= tcw) return ShapeZone.certainlyWrong;
    return ShapeZone.fuzzy;
  }

  /// A 1.0 (perfect) → 0.0 (certainly wrong) score, linear across the fuzzy band.
  double scoreFor(double distance) {
    if (distance <= tcc) return 1.0;
    if (distance >= tcw) return 0.0;
    return 1.0 - (distance - tcc) / (tcw - tcc);
  }
}

/// The normalized DTW distance between a child stroke and a reference stroke.
///
/// Both are resampled to [n] arc-length-equidistant points and scaled to a unit
/// box, then aligned by DTW. The return value is the average per-aligned-point
/// Euclidean distance in unit-box space: **0.0 = identical shape**, larger =
/// further from the reference. Because both are unit-box-normalized, the metric
/// is size- and position-invariant (a correctly-shaped smaller letter still
/// scores near 0) but preserves aspect ratio (a flat "line" bowl vs a round bowl
/// differ), so it distinguishes a shallow bowl from a deep one.
///
/// Normalization here is ANCHORED (bbox-min → 0 on both axes, no special
/// case) rather than the shared [normalizeToUnitBox]'s zero-extent-axis → 0.5
/// centering. The centering convention is DISCONTINUOUS at zero extent: a
/// perfectly vertical child line (width exactly 0 → x = 0.5) compared against
/// a hairline-width font-extracted reference (width ≈ 0.001 → x anchored ≈ 0)
/// would read as ~0.5 apart on every point and certainly-wrong — a false fail
/// for a PERFECT stroke (the real authored alif exposed this). Anchoring both
/// sides at bbox-min is continuous as extent → 0, so hairline and exact-zero
/// widths agree.
///
/// Returns [double.infinity] for a degenerate stroke (< 2 points) so a
/// pen-slip cannot masquerade as a perfect match.
double shapeDistance(
  List<List<double>> childStroke,
  List<List<double>> referenceStroke, {
  int n = 32,
}) {
  if (childStroke.length < 2 || referenceStroke.length < 2) {
    return double.infinity;
  }
  final a = _anchoredUnitBox(resample(childStroke, n));
  final b = _anchoredUnitBox(resample(referenceStroke, n));
  return _dtw(a, b) / n;
}

/// Unit-box normalization for cross-stroke comparison: translate bbox-min to
/// the origin and scale the longest side to 1.0, preserving aspect ratio —
/// with NO zero-extent special case (see [shapeDistance] for why the shared
/// [normalizeToUnitBox]'s 0.5-centering convention cannot be used here). A
/// fully degenerate stroke (all points coincident) maps to the origin; the
/// < 2-point guard in [shapeDistance] already returns infinity before that
/// matters.
List<List<double>> _anchoredUnitBox(List<List<double>> pts) {
  if (pts.isEmpty) return [];

  var minX = double.infinity, minY = double.infinity;
  var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
  for (final p in pts) {
    if (p[0] < minX) minX = p[0];
    if (p[0] > maxX) maxX = p[0];
    if (p[1] < minY) minY = p[1];
    if (p[1] > maxY) maxY = p[1];
  }

  final scale = math.max(maxX - minX, maxY - minY);
  if (scale <= 0) {
    // All points coincident — map to the origin (guarded upstream anyway).
    return [for (final _ in pts) [0.0, 0.0]];
  }
  return [
    for (final p in pts) [(p[0] - minX) / scale, (p[1] - minY) / scale],
  ];
}

/// Classic Dynamic-Time-Warping total cost between two point sequences, using a
/// rolling two-row DP matrix (O(n·m) time, O(m) space). Cost per cell is the
/// Euclidean distance between the two aligned points.
double _dtw(List<List<double>> a, List<List<double>> b) {
  final n = a.length, m = b.length;
  const inf = double.infinity;
  var prev = List<double>.filled(m + 1, inf);
  var curr = List<double>.filled(m + 1, inf);
  prev[0] = 0.0;
  for (var i = 1; i <= n; i++) {
    curr[0] = inf;
    for (var j = 1; j <= m; j++) {
      final cost = _euclid(a[i - 1], b[j - 1]);
      final best = math.min(prev[j], math.min(curr[j - 1], prev[j - 1]));
      curr[j] = cost + best;
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[m];
}

double _euclid(List<double> p, List<double> q) {
  final dx = p[0] - q[0], dy = p[1] - q[1];
  return math.sqrt(dx * dx + dy * dy);
}
