/// Pure Dart, no dart:ui, no Flutter imports.
///
/// Data-driven scoring tolerances (Plan 04-01, SC#4).
///
/// The geometric scorer's thresholds used to live as file-level `const`s inside
/// `geometric_stroke_scorer.dart`. This class relocates them into DATA so the
/// curriculum (letters.json) — not code — decides how lenient each letter is.
/// Per D-03 the curriculum picks a teacher-legible named preset
/// (`loose`/`normal`/`strict`) and may nudge individual numeric knobs via
/// `overrides`.
///
/// The `normal` preset is a LOCKED behavior-preserving anchor (RESEARCH A5): it
/// equals today's hardcoded constants so moving the values to data does not
/// shift alif's scoring.
class Tolerances {
  /// Minimum number of raw input points for a stroke to be considered complete.
  /// A gesture ending below this count likely means the child lifted the pen
  /// before finishing. (Was `_kMinRawPoints = 10` in geometric_stroke_scorer.)
  final int minRawPoints;

  /// Number of equidistant points the child stroke is resampled to before the
  /// direction and curvature predicates run. 32 gives stable geometry well
  /// within the sub-300 ms latency budget. (Was `_kResampleN = 32`.)
  final int resampleN;

  /// Maximum perpendicular distance from the best-fit chord (start→end line) in
  /// the normalised 0..1 unit box. A child with a modest natural bow still
  /// passes at this value; a higher ceiling is MORE permissive (lets a more
  /// bowed stroke pass), a lower ceiling is STRICTER. (Was `_kMaxCurvature =
  /// 0.25`.)
  ///
  /// DEPRECATION NOTE: no longer read by `scoreStroke` after Plan 17-02 (the
  /// chord-curvature proxy was replaced by `shapeDistance` + the soft band
  /// below); kept as a field so authored letters.json tolerance overrides
  /// still parse.
  final double maxCurvature;

  /// Soft-band shape threshold: DTW distance at/below which the stroke's shape
  /// is CERTAINLY CORRECT (`SoftBand.tcc` — Plan 17-02, D-C).
  ///
  /// PROVISIONAL (D-D): == the `SoftBand.shapeDefault` cut. D-04 REVERT
  /// (2026-07-20, owner) back to the ORIGINAL 0.10: the 2026-07-07 widen to 0.12
  /// only worked around the painter-stretch bug (a stretched reference inflated
  /// real-bowl DTW distances) — that bug is FIXED in commit 972427e, so the
  /// tighter certainly-correct cut is safe again. The Dart calibration harness is
  /// the regression guard; production values still come from the mom-labelled
  /// calibration set. FALLBACK (D-04): re-affirm 0.12 only if the originals
  /// false-fail real clean strokes on the 26-06 device pass, with the observed
  /// device reason logged here.
  final double shapeTcc;

  /// Soft-band shape threshold: DTW distance at/above which the stroke's shape
  /// is CERTAINLY WRONG (`SoftBand.tcw`) — the only shape zone that fails.
  ///
  /// PROVISIONAL (D-D): == the `SoftBand.shapeDefault` cut. D-04 REVERT
  /// (2026-07-20, owner) back to the ORIGINAL 0.15: the 2026-07-07 widen to 0.16
  /// only worked around the painter-stretch bug (commit 972427e, now fixed).
  /// Tightening tcw only STRENGTHENS the F5 separation — the tightest synthetic
  /// shape-bad (a flat "line" bowl in the FINAL form, d≈0.1626) and the F5
  /// form-confusion trap (isolated bowl offered for medial/final, d≈0.2838) both
  /// stay certainly-wrong below tcw=0.15. The Dart calibration harness is the
  /// regression guard; production values still come from the mom-labelled
  /// captures (D-D). FALLBACK (D-04): re-affirm 0.16 only if real clean strokes
  /// false-fail on the 26-06 device pass, with the observed device reason logged.
  final double shapeTcw;

  /// Soft-band direction threshold: normalized displacement alignment p (in
  /// [-1, 1], projected on the reference direction axis) at/above which the
  /// direction is CERTAINLY CORRECT.
  ///
  /// PROVISIONAL (D-D): synthetic; production values come from the
  /// mom-labelled calibration.
  final double directionCc;

  /// Soft-band direction threshold: alignment p at/below which the direction
  /// is CERTAINLY WRONG (an inverted stroke) — the only direction zone that
  /// fails.
  ///
  /// PROVISIONAL (D-D): synthetic; production values come from the
  /// mom-labelled calibration.
  final double directionCw;

  const Tolerances({
    required this.minRawPoints,
    required this.resampleN,
    required this.maxCurvature,
    this.shapeTcc = 0.10,
    this.shapeTcw = 0.15,
    this.directionCc = 0.3,
    this.directionCw = -0.3,
  });

  /// Named presets. `normal` MUST equal the constants formerly in
  /// geometric_stroke_scorer.dart:16,21,26 (A5). `loose`/`strict` only move the
  /// curvature ceiling for now — that is the single shape knob Plan 02 reads;
  /// other knobs stay at the behavior-preserving values until calibration
  /// proves a reason to diverge them.
  static const Map<String, Tolerances> _presets = {
    'loose': Tolerances(
      minRawPoints: 10,
      resampleN: 32,
      maxCurvature: 0.35, // more permissive than normal
    ),
    'normal': Tolerances(
      minRawPoints: 10, // == _kMinRawPoints (A5)
      resampleN: 32, // == _kResampleN (A5)
      maxCurvature: 0.25, // == _kMaxCurvature (A5)
    ),
    'strict': Tolerances(
      minRawPoints: 10,
      resampleN: 32,
      maxCurvature: 0.18, // stricter than normal
    ),
  };

  /// Resolves a named ramp preset (D-18/D-19): `loose` / `normal` / `strict`.
  /// An unknown or empty name falls back to [normal] — the same defensive
  /// unknown→normal idiom as [Tolerances.fromJson] (never throws; the ramp is
  /// hand-edited curriculum data).
  static Tolerances preset(String name) => _presets[name] ?? normal;

  /// The behavior-preserving default used whenever a letter omits a tolerances
  /// block or names an unknown preset (pure value parsing — never throws).
  static const Tolerances normal = Tolerances(
    minRawPoints: 10,
    resampleN: 32,
    maxCurvature: 0.25,
  );

  /// Builds a [Tolerances] from a curriculum block of the shape:
  ///   { "preset": "normal", "overrides": { "maxCurvature": 0.30 } }
  ///
  /// An unknown or absent `preset` falls back to `normal`. Numeric `overrides`
  /// replace individual knobs on top of the chosen preset. Mirrors the
  /// defensive `fromJson` idiom of `StrokeSpec.fromJson` (letter.dart:55-70):
  /// it reads loosely-typed JSON and never throws on missing keys.
  factory Tolerances.fromJson(Map<String, dynamic> json) {
    final presetName = json['preset'] as String?;
    final base = _presets[presetName] ?? normal;

    final overrides = json['overrides'] as Map<String, dynamic>?;
    if (overrides == null) return base;

    final minRaw = overrides['minRawPoints'] as num?;
    final resample = overrides['resampleN'] as num?;
    final maxCurv = overrides['maxCurvature'] as num?;
    final shapeTccOv = overrides['shapeTcc'] as num?;
    final shapeTcwOv = overrides['shapeTcw'] as num?;

    return Tolerances(
      minRawPoints: minRaw?.toInt() ?? base.minRawPoints,
      resampleN: resample?.toInt() ?? base.resampleN,
      maxCurvature: maxCurv?.toDouble() ?? base.maxCurvature,
      shapeTcc: shapeTccOv?.toDouble() ?? base.shapeTcc,
      shapeTcw: shapeTcwOv?.toDouble() ?? base.shapeTcw,
      directionCc: base.directionCc,
      directionCw: base.directionCw,
    );
  }
}
