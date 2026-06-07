import 'dart:math' as math;

/// Synthetic alif stroke fixtures for the geometric scorer tests.
///
/// All fixtures are expressed as pixel-coordinate point lists ([x, y] pairs).
/// The scorer's normalizeToUnitBox step makes absolute positions and sizes
/// irrelevant — only shape and direction matter after normalization.

/// A straight vertical stroke, top→bottom, full height.
/// x is constant (50.0); y runs 0→200 in 21 evenly-spaced points.
final List<List<double>> cleanAlif = List<List<double>>.generate(
  21,
  (i) => [50.0, i * 10.0],
);

/// A straight vertical stroke, top→bottom, only ~40% of full height.
/// Triggers the strokeLengthBelowThreshold predicate.
final List<List<double>> tooShort = List<List<double>>.generate(
  9,
  (i) => [50.0, i * 10.0], // 0→80px — well below the 30% threshold
);

/// A straight vertical stroke drawn bottom→top (inverted direction).
/// Triggers the strokeDirectionInverted predicate.
final List<List<double>> inverted = List<List<double>>.generate(
  21,
  (i) => [50.0, 200.0 - i * 10.0], // starts at y=200, ends at y=0
);

/// A top→bottom stroke with a large lateral bow (oscillating x values).
/// The x deviation is large enough to exceed the curvature threshold.
/// Triggers the strokeCurvatureExceedsThreshold predicate.
final List<List<double>> curved = List.generate(21, (i) {
  final t = i / 20.0; // 0.0 → 1.0
  // Sinusoidal lateral bow: peak deviation ~60px at midpoint, 0 at ends.
  final x = 50.0 + 60.0 * math.sin(t * math.pi);
  final y = i * 10.0;
  return [x, y];
});

/// A straight vertical stroke, small size and offset position.
/// Tests that normalization makes size/position irrelevant — should score as passed.
/// 11 points, x offset at 200px, y from 300→350 (small, offset region).
final List<List<double>> smallCorrect = List<List<double>>.generate(
  11,
  (i) => [200.0, 300.0 + i * 5.0], // 300→350, narrow region
);
