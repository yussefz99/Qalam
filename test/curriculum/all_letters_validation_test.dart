import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/models/letter.dart';

/// Load-time validation gate over the REAL bundled curriculum asset.
///
/// Every letter in assets/curriculum/letters.json must pass `validateLetter`
/// (open centerlines, dots-as-taps, contiguous order, in-range coords, sane
/// tolerances). This is the regression guard that catches a bad authored stroke
/// — including the provisional DRAFT baa-family/full-alphabet entries — before
/// it can reach a child. Mirrors the Phase 02.1 crown-jewel validator intent.
void main() {
  final letters = (jsonDecode(
    File('assets/curriculum/letters.json').readAsStringSync(),
  )['letters'] as List)
      .map((j) => Letter.fromJson(j as Map<String, dynamic>))
      .toList();

  test('curriculum has all 28 letters', () {
    expect(letters.length, 28);
  });

  group('every letter passes the load-time validator', () {
    for (final letter in letters) {
      test('${letter.id} (${letter.char}) is valid', () {
        expect(validateLetter(letter), isEmpty,
            reason: 'Validation violations for ${letter.id}');
      });
    }
  });

  test('every letter has authored reference strokes (no empty placeholders)',
      () {
    final empty =
        letters.where((l) => l.referenceStrokes.isEmpty).map((l) => l.id);
    expect(empty, isEmpty, reason: 'Letters with no strokes: $empty');
  });

  test('only signed-off letters claim signedOff: true (alif so far)', () {
    final signed = letters.where((l) => l.signedOff).map((l) => l.id).toList();
    expect(signed, ['alif'],
        reason:
            'Only alif is signed off; baa-family + full alphabet are DRAFT '
            '(signedOff:false) until the owner\'s mother signs off. Got: $signed');
  });
}
