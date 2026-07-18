import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/models/letter.dart';

/// Merge invariants for the surgical ``contextualForms`` merge
/// (tools/curriculum/merge_contextual_forms.py) — quick fix 260718-l12 Task 1.
///
/// The device reads letters Firestore-first; neither prod Firestore nor the
/// bundle carried per-form ``contextualForms`` for thaa, so the on-device
/// scorer had no per-form reference and thaa was "always wrong". The merge tool
/// copies ONLY the ``contextualForms`` field for alif/baa/taa/thaa from the
/// owner drop into the bundle. This test pins that the merge:
///   • gave thaa all four forms, each with non-empty, VALID strokes;
///   • validated every merged contextualForms stroke of all four letters
///     (validateReferenceStrokes — the load-time guard covers only TOP-LEVEL
///     strokes, so nested per-form strokes need an explicit safety net here);
///   • left signedOff UNCHANGED (baa=true, taa=true, alif=false, thaa=false —
///     the owner's false for baa/taa was NOT taken);
///   • left alif.commonMistakes UNCHANGED (the owner's alif commonMistakes
///     change was NOT taken — flagged for the mother instead).
void main() {
  final letters = (jsonDecode(
    File('assets/curriculum/letters.json').readAsStringSync(),
  )['letters'] as List)
      .map((j) => Letter.fromJson(j as Map<String, dynamic>))
      .toList();

  Letter byId(String id) => letters.firstWhere((l) => l.id == id);

  const mergeIds = ['alif', 'baa', 'taa', 'thaa'];
  const allForms = ['isolated', 'initial', 'medial', 'final'];

  test('thaa carries contextualForms with all four forms, each non-empty', () {
    final thaa = byId('thaa');
    expect(thaa.contextualForms, isNotNull,
        reason: 'thaa must carry per-form contextualForms after the merge');
    for (final form in allForms) {
      expect(thaa.contextualForms!.containsKey(form), isTrue,
          reason: 'thaa.contextualForms is missing the "$form" form');
      final f = thaa.contextualForms![form];
      expect(f, isNotNull, reason: 'thaa.contextualForms["$form"] is null');
      expect(f!.referenceStrokes, isNotEmpty,
          reason: 'thaa "$form" has no reference strokes');
    }
  });

  group('every merged contextualForms stroke validates (nested safety net)', () {
    for (final id in mergeIds) {
      test('$id — all per-form strokes pass validateReferenceStrokes', () {
        final letter = byId(id);
        expect(letter.contextualForms, isNotNull,
            reason: '$id must carry contextualForms after the merge');
        letter.contextualForms!.forEach((form, spec) {
          if (spec == null) return; // a non-connector's missing slot is allowed
          final violations = validateReferenceStrokes(spec.referenceStrokes);
          expect(violations, isEmpty,
              reason: '$id "$form" contextualForms strokes are invalid: '
                  '$violations');
        });
      });
    }
  });

  test('signedOff is unchanged: baa=true, taa=true, alif=false, thaa=false', () {
    expect(byId('baa').signedOff, isTrue,
        reason: 'baa stays signed off (the mother signed baa) — owner false NOT taken');
    expect(byId('taa').signedOff, isTrue,
        reason: 'taa stays signed off (the mother signed taa) — owner false NOT taken');
    expect(byId('alif').signedOff, isFalse, reason: 'alif is not signed off');
    expect(byId('thaa').signedOff, isFalse,
        reason: 'thaa content stays DRAFT (signedOff:false) for the mother\'s review');
  });

  test('alif.commonMistakes is unchanged (owner change NOT taken)', () {
    final alif = byId('alif');
    // Pinned to the CURRENT bundle value (three authored mistakes), NOT the
    // owner file — the owner's alif commonMistakes change is deliberately
    // skipped and flagged for the mother.
    expect(alif.commonMistakes.length, 3,
        reason: 'alif keeps its three bundle commonMistakes');
    expect(alif.commonMistakes.map((m) => m.check).toList(), const [
      'strokeLengthBelowThreshold',
      'strokeDirectionInverted',
      'strokeCurvatureExceedsThreshold',
    ], reason: 'alif commonMistakes checks are the bundle values, not the owner file\'s');
  });
}
