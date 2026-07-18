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
  final rawJson =
      jsonDecode(File('assets/curriculum/letters.json').readAsStringSync())
          as Map<String, dynamic>;
  final rawLetters = rawJson['letters'] as List;

  final letters = rawLetters
      .map((j) => Letter.fromJson(j as Map<String, dynamic>))
      .toList();

  Letter byId(String id) => letters.firstWhere((l) => l.id == id);

  /// The RAW isolated-form referenceStrokes list (untouched by model parsing) —
  /// used to pin exact, deep JSON equality of the transplanted bowl body.
  List<dynamic> rawIsolatedStrokes(String id) {
    final letter =
        rawLetters.firstWhere((l) => (l as Map)['id'] == id) as Map;
    final cf = letter['contextualForms'] as Map;
    final isolated = cf['isolated'] as Map;
    return isolated['referenceStrokes'] as List;
  }

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

  /// Owner-directed 2026-07-18 (quick fix 260718-nft Task 2 —
  /// tools/curriculum/copy_baa_bowl_to_taa_thaa.py): ب ت ث share the SAME bowl
  /// body; only the dots differ. The owner's authored isolated bodies for
  /// taa/thaa kept failing his on-device traces against the scorer, so both
  /// isolated body strokes were replaced with a DEEP COPY of baa's validated
  /// 12-point bowl. This group pins that transplant from the SHIPPED bundle:
  /// the bodies deep-equal baa's, the dots (and stroke counts) are untouched.
  group('taa/thaa isolated bowl = baa isolated bowl (owner-directed copy)', () {
    test('taa.isolated stroke[0] deep-equals baa.isolated stroke[0]', () {
      final baaBody = rawIsolatedStrokes('baa')[0];
      final taaBody = rawIsolatedStrokes('taa')[0];
      expect(taaBody, equals(baaBody),
          reason: 'taa isolated body must be a deep copy of baa isolated body '
              '(the shared ب ت ث bowl)');
      // The bowl is the validated 12-point baa body, and a curve (not taa's old
      // 9-point curve) — pin the shape so a re-authoring regression is caught.
      expect((baaBody as Map)['points'], hasLength(12),
          reason: 'baa isolated bowl is the 12-point body');
      expect(baaBody['type'], 'curve');
      expect(baaBody['label'], 'body');
    });

    test('thaa.isolated stroke[0] deep-equals baa.isolated stroke[0]', () {
      final baaBody = rawIsolatedStrokes('baa')[0];
      final thaaBody = rawIsolatedStrokes('thaa')[0];
      expect(thaaBody, equals(baaBody),
          reason: 'thaa isolated body must be a deep copy of baa isolated body '
              '(the shared ب ت ث bowl)');
      // thaa's old body was a 7-point "line"; the transplant makes it baa's
      // 12-point "curve" — verify the type crossed too (whole-object copy).
      expect((thaaBody as Map)['type'], 'curve',
          reason: 'thaa isolated body inherits baa body type (curve), not its '
              'old line');
    });

    test('taa keeps its 3 isolated strokes (bowl + 2 dots), dots untouched', () {
      final strokes = rawIsolatedStrokes('taa');
      expect(strokes, hasLength(3),
          reason: 'taa isolated = 1 body + 2 dots');
      expect((strokes[1] as Map)['label'], 'dot_right');
      expect((strokes[2] as Map)['label'], 'dot_left');
      // Dots are single-point taps above the bowl — unchanged by the copy.
      expect((strokes[1] as Map)['points'], const [
        [0.523, 0.408]
      ]);
      expect((strokes[2] as Map)['points'], const [
        [0.459, 0.407]
      ]);
    });

    test('thaa keeps its 4 isolated strokes (bowl + 3 dots), dots untouched',
        () {
      final strokes = rawIsolatedStrokes('thaa');
      expect(strokes, hasLength(4),
          reason: 'thaa isolated = 1 body + 3 dots');
      expect((strokes[1] as Map)['label'], 'dot_right');
      expect((strokes[2] as Map)['label'], 'dot_left');
      expect((strokes[3] as Map)['label'], 'dot_top');
      expect((strokes[1] as Map)['points'], const [
        [0.528, 0.436]
      ]);
      expect((strokes[2] as Map)['points'], const [
        [0.464, 0.435]
      ]);
      expect((strokes[3] as Map)['points'], const [
        [0.492, 0.365]
      ]);
    });

    test('the parsed StrokeSpec bodies also match (model round-trip)', () {
      // Guard the model path too: after Letter.fromJson, the isolated body
      // points must still deep-equal across baa/taa/thaa.
      List<List<double>> isoBodyPoints(String id) =>
          byId(id).contextualForms!['isolated']!.referenceStrokes[0].points;
      expect(isoBodyPoints('taa'), equals(isoBodyPoints('baa')));
      expect(isoBodyPoints('thaa'), equals(isoBodyPoints('baa')));
      expect(isoBodyPoints('baa'), hasLength(12));
    });

    test('signedOff flags on the touched forms are left untouched', () {
      // The data change is to the mother's-domain curriculum; the copy does not
      // sign anything off. taa/thaa isolated stay draft for her review.
      Map isolatedForm(String id) {
        final letter =
            rawLetters.firstWhere((l) => (l as Map)['id'] == id) as Map;
        return (letter['contextualForms'] as Map)['isolated'] as Map;
      }

      expect(isolatedForm('taa')['signedOff'], isFalse,
          reason: 'taa.contextualForms.isolated stays draft (mother review)');
      expect(isolatedForm('thaa')['signedOff'], isFalse,
          reason: 'thaa.contextualForms.isolated stays draft (mother review)');
    });
  });
}
