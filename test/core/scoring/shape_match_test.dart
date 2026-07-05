// Proves the Phase-17 shape-match core behaves the way the research requires:
//   • an identical / size-scaled correct shape → distance ~0 (size-invariant),
//   • a shaky-but-correct child bowl → small distance, lands in the tolerant
//     zone and PASSES (does NOT false-fail — UAT F2),
//   • a genuinely wrong shape (a flat "line" bowl) → large distance, certainly
//     wrong → FAILS,
//   • and the three-zone soft band orders these correctly.
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/shape_match.dart';

void main() {
  // The validated baa isolated "boat/bowl" reference (from assets/curriculum/
  // letters.json contextualForms.isolated) — a real authored per-form reference.
  final bowl = <List<double>>[
    [0.608, 0.447], [0.619, 0.486], [0.620, 0.524], [0.594, 0.552],
    [0.551, 0.565], [0.511, 0.569], [0.474, 0.570], [0.436, 0.566],
    [0.407, 0.559], [0.386, 0.530], [0.381, 0.498], [0.382, 0.460],
  ];

  // A shaky child bowl: the same boat with a small deterministic wobble (±~0.012)
  // — a correct attempt by an unsteady 6-year-old hand.
  final shakyBowl = <List<double>>[
    for (var i = 0; i < bowl.length; i++)
      [
        bowl[i][0] + (i.isEven ? 0.012 : -0.010),
        bowl[i][1] + (i % 3 == 0 ? -0.011 : 0.009),
      ],
  ];

  // The SAME bowl at half size, shifted — a correctly-shaped but smaller letter.
  final smallerBowl = <List<double>>[
    for (final p in bowl) [0.25 + p[0] * 0.5, 0.30 + p[1] * 0.5],
  ];

  // A flat line across the bowl's x-range — the "shallow bowl / it's a line, not
  // a boat" wrong attempt (UAT: the exact case the old scorer mis-handled).
  final flatLine = <List<double>>[
    for (var i = 0; i < 12; i++) [0.620 - i * (0.239 / 11), 0.510],
  ];

  test('identical shape → distance ~0, certainly correct', () {
    final d = shapeDistance(bowl, bowl);
    expect(d, lessThan(1e-9));
    expect(SoftBand.shapeDefault.zoneFor(d), ShapeZone.certainlyCorrect);
    expect(SoftBand.shapeDefault.scoreFor(d), 1.0);
  });

  test('size-invariant: a correctly-shaped SMALLER bowl still scores ~0', () {
    // Both strokes are unit-box normalized, so a uniform scale collapses to the
    // same shape — a smaller correct letter must not be penalized.
    expect(shapeDistance(smallerBowl, bowl), lessThan(1e-6));
  });

  test('shaky-but-correct child bowl PASSES (not certainly wrong) — no false-fail', () {
    final d = shapeDistance(shakyBowl, bowl);
    expect(d, greaterThan(0.0)); // it IS different (wobble)
    expect(d, lessThan(SoftBand.shapeDefault.tcw),
        reason: 'a shaky-but-correct bowl must stay out of the certainly-wrong zone');
    expect(SoftBand.shapeDefault.zoneFor(d), isNot(ShapeZone.certainlyWrong));
  });

  test('a flat "line" bowl is FURTHER from the reference than a shaky good bowl', () {
    final dGood = shapeDistance(shakyBowl, bowl);
    final dFlat = shapeDistance(flatLine, bowl);
    expect(dFlat, greaterThan(dGood),
        reason: 'a genuinely wrong shape must read as further from correct');
  });

  test('a flat "line" bowl lands in the certainly-wrong zone → FAILS', () {
    final d = shapeDistance(flatLine, bowl);
    expect(SoftBand.shapeDefault.zoneFor(d), ShapeZone.certainlyWrong,
        reason: 'a flat line is not an acceptable baa bowl');
  });

  test('SoftBand: score is monotonic and clamped [0,1]', () {
    const band = SoftBand.shapeDefault;
    expect(band.scoreFor(0.0), 1.0);
    expect(band.scoreFor(band.tcc), 1.0);
    expect(band.scoreFor(band.tcw), 0.0);
    expect(band.scoreFor(1.0), 0.0);
    final mid = band.scoreFor((band.tcc + band.tcw) / 2);
    expect(mid, greaterThan(0.0));
    expect(mid, lessThan(1.0));
  });
}
