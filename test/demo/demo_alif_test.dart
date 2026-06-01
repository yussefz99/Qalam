// DemoAlif tests — the single static, engine-free mock content source for the
// whole alif demo (DP-01/DP-05).
//
// Every demo screen reads the alif glyph, the authored named-fix strings, and
// the reference stroke from THIS one source — no scorer, no Drift, no network.
// The named-fix strings are copied verbatim from assets/curriculum/letters.json
// (the tutor's voice is the contract); the fallback line is the UI-SPEC calm
// fallback, never "Oops, try again!".

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/demo/demo_alif.dart';

void main() {
  test('Test 1: glyph is "ا" and displayName is "Alif"', () {
    expect(DemoAlif.glyph, 'ا');
    expect(DemoAlif.displayName, 'Alif');
  });

  test('Test 2: heroMissFix is the wrong_direction named fix, verbatim', () {
    expect(DemoAlif.heroMissFix, contains('Start your alif at the top'));
    expect(DemoAlif.heroMissFix, isNot(contains('Oops, try again!')));
    // It is exactly the authored wrong_direction feedback.
    expect(
      DemoAlif.heroMissFix,
      'Start your alif at the top and come down — not from the bottom up.',
    );
  });

  test('Test 3: namedFixes holds all three authored fixes verbatim by id', () {
    expect(DemoAlif.namedFixes.keys.toSet(),
        <String>{'too_short', 'wrong_direction', 'too_curved'});
    expect(
      DemoAlif.namedFixes['too_short'],
      'Your alif needs to be taller — draw it from the top all the way down.',
    );
    expect(
      DemoAlif.namedFixes['wrong_direction'],
      'Start your alif at the top and come down — not from the bottom up.',
    );
    expect(
      DemoAlif.namedFixes['too_curved'],
      'Alif is a straight line — try to keep it as straight as you can.',
    );
  });

  test('Test 4: exposes the single-stroke topToBottom reference points', () {
    // The alif vertical line, normalized 0..1, top (y=0) to bottom (y=1).
    final points = DemoAlif.referencePoints;
    expect(points, isNotEmpty);
    expect(points.first[1], 0.0, reason: 'starts at the top');
    expect(points.last[1], 1.0, reason: 'ends at the bottom');
    // A straight vertical line: every x is the same.
    final xs = points.map((p) => p[0]).toSet();
    expect(xs.length, 1, reason: 'vertical line — constant x');
    expect(DemoAlif.referenceDirection, 'topToBottom');
  });

  test('fallbackFix is the calm UI-SPEC line, never "Oops, try again!"', () {
    expect(DemoAlif.fallbackFix,
        'Something looks off — try again, slower this time.');
    expect(DemoAlif.fallbackFix, isNot(contains('Oops')));
  });
}
