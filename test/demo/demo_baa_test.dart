// DemoBaa tests — the single static, engine-free mock content source for the
// BAA walkthrough (Watch → Trace → Feedback → Celebration), coherent with the
// rebuilt demo Home (which shows "The letter Baa") and the design mockups.

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/demo/demo_baa.dart';

void main() {
  test('Test 1: glyph is "ب" and displayName is "Baa"', () {
    expect(DemoBaa.glyph, 'ب');
    expect(DemoBaa.displayName, 'Baa');
    expect(DemoBaa.romanized, 'baa');
  });

  test('Test 2: heroMissFix names the exact baa fix, never "Oops"', () {
    expect(DemoBaa.heroMissFix.toLowerCase(), contains('baa'));
    expect(DemoBaa.heroMissFix.toLowerCase(), contains('curve'));
    expect(DemoBaa.heroMissFix.toLowerCase(), isNot(contains('oops')));
  });

  test('Test 3: passPraise is specific warm praise, never "Oops"', () {
    expect(DemoBaa.passPraise.toLowerCase(), contains('deep curve'));
    expect(DemoBaa.passPraise.toLowerCase(), isNot(contains('oops')));
  });

  test('Test 4: the boat reference stroke is a shallow centered bowl', () {
    final points = DemoBaa.referencePoints;
    expect(points.length, greaterThanOrEqualTo(5));
    // Ordered left → right (start-dot sits upper-left, matching the mockup).
    expect(points.first[0], lessThan(points.last[0]));
    // The bowl dips: the midpoint y is below (greater than) both endpoints.
    final double midY = points[points.length ~/ 2][1];
    expect(midY, greaterThan(points.first[1]));
    expect(midY, greaterThan(points.last[1]));
    // Exactly one distinguishing dot, centered below the bowl.
    expect(DemoBaa.diacriticDots.length, 1);
    expect(DemoBaa.diacriticDots.first[0], closeTo(0.5, 0.01));
    expect(DemoBaa.diacriticDots.first[1], greaterThan(midY));
  });
}
