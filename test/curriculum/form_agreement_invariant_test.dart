// form_agreement_invariant_test.dart — Defect-2 / WR-01 curriculum guard.
//
// The child must be traced, diffed, AND scored against the SAME asked positional
// form. WriteSurface now resolves ONE `_askedForm = expected.glyph.form ??
// surface.guideForm` and threads it into the guide, `computeStrokeDiff`, and the
// validator (Pitfall 7 / reference_resolution.dart header).
//
// That unification collapses to a single form ONLY while the two authored fields
// never disagree. This invariant makes that a hard, load-time guarantee: for
// EVERY authored exercise, when BOTH `expected.glyph.form` and
// `surface.guideForm` are present, they must be EQUAL — so no future authored
// exercise can silently make the guide/diff describe form A while the verdict is
// computed against form B.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> _loadExercises() {
  final raw = File('assets/curriculum/exercises.json').readAsStringSync();
  return (jsonDecode(raw) as Map<String, dynamic>)['exercises']
      .cast<Map<String, dynamic>>();
}

/// The asked form a WriteSurface would resolve for [exercise]:
/// `expected.glyph.form ?? surface.guideForm` (may be null when neither exists).
String? _expectedGlyphForm(Map<String, dynamic> e) {
  final expected = e['expected'] as Map<String, dynamic>?;
  final glyph = expected?['glyph'] as Map<String, dynamic>?;
  return glyph?['form'] as String?;
}

String? _guideForm(Map<String, dynamic> e) {
  final surface = e['surface'] as Map<String, dynamic>?;
  return surface?['guideForm'] as String?;
}

void main() {
  test(
      'every exercise: expected.glyph.form and surface.guideForm AGREE when both '
      'are present (WR-01 — one asked form drives guide, diff, and verdict)', () {
    final exercises = _loadExercises();
    expect(exercises, isNotEmpty);

    final divergent = <String>[];
    var checkedBoth = 0;
    for (final e in exercises) {
      final glyphForm = _expectedGlyphForm(e);
      final guideForm = _guideForm(e);
      if (glyphForm != null && guideForm != null) {
        checkedBoth++;
        if (glyphForm != guideForm) {
          divergent.add(
              '${e['id']}: expected.glyph.form=$glyphForm != surface.guideForm=$guideForm');
        }
      }
    }

    // Guard the guard: the invariant must actually exercise real data (baa carries
    // several trace exercises that name both fields), not vacuously pass.
    expect(checkedBoth, greaterThan(0),
        reason: 'no exercise names both form fields — the invariant is vacuous.');
    expect(divergent, isEmpty,
        reason: 'These exercises trace/diff one form but would be scored against '
            'another — the asked form must be single-valued (WR-01):\n'
            '${divergent.join('\n')}');
  });
}
