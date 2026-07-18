// TRACE ↔ SCORER AGREEMENT (debug session taa-thaa-shape-always-fails).
//
// THE INVARIANT UNDER TEST: a child who traces the PAINTED guide faithfully
// must PASS the deterministic scorer — on ANY canvas geometry. This was broken
// on 2026-07-18: the guide painters stretched the authored glyph non-uniformly
// onto the wide letter-unit writebox (`x*width, y*height`), while the scorer's
// shape criterion preserves aspect — so a PERFECT taa/thaa trace scored past
// the certainly-wrong threshold (d=0.161 at a 2:1 canvas, 0.247 at 3.6:1) and
// the trace exercise was mathematically unpassable ("A little more curve —
// try again, slower." on every attempt). baa masked the defect (AI judge owns
// its pass/fail; narrower canvas beside the Teacher's Margin).
//
// LIVE PATH (owner directive — never a re-implementation): the child's trace
// is driven as REAL pointer gestures on the REAL StrokeCanvas at a wide
// tablet-writebox size; the captured strokes go through the REAL
// `exerciseSpecFromExercise` → `validateExercise` call — exactly
// write_surface._onLetterComplete's path — against the REAL bundled
// taa/thaa.traceLetter.isolated exercises and letters.json data.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/exercise_engine/exercise_validator.dart';
import 'package:qalam/features/letter_unit/exercise_spec_adapter.dart';
import 'package:qalam/features/practice/widgets/guide_geometry.dart';
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';
import 'package:qalam/models/exercise.dart' as model;
import 'package:qalam/models/letter.dart';

/// The wide letter-unit writebox on a landscape tablet — the geometry that
/// made the stretched guide certainly-wrong (aspect 3:1).
const Size kWideCanvas = Size(900, 300);

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Letter _letter(String id) {
  final letters = (_loadJson('assets/curriculum/letters.json')['letters']
          as List<dynamic>)
      .cast<Map<String, dynamic>>();
  return Letter.fromJson(letters.firstWhere((l) => l['id'] == id));
}

model.Exercise _exercise(String id) {
  final raw = _loadJson('assets/curriculum/exercises.json');
  final list = (raw['exercises'] as List<dynamic>).cast<Map<String, dynamic>>();
  return model.Exercise.fromJson(list.firstWhere((e) => e['id'] == id));
}

/// Linear-interpolate a polyline to [n] points (a smooth faithful trace).
List<List<double>> _interp(List<List<double>> pts, int n) {
  final seg = <double>[0];
  var total = 0.0;
  for (var i = 1; i < pts.length; i++) {
    final dx = pts[i][0] - pts[i - 1][0];
    final dy = pts[i][1] - pts[i - 1][1];
    total += Offset(dx, dy).distance;
    seg.add(total);
  }
  final out = <List<double>>[];
  for (var k = 0; k < n; k++) {
    final target = total * k / (n - 1);
    var i = 1;
    while (i < seg.length - 1 && seg[i] < target) {
      i++;
    }
    final span = seg[i] - seg[i - 1];
    final t = span <= 0 ? 0.0 : (target - seg[i - 1]) / span;
    out.add([
      pts[i - 1][0] + (pts[i][0] - pts[i - 1][0]) * t,
      pts[i - 1][1] + (pts[i][1] - pts[i - 1][1]) * t,
    ]);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> traceOnCanvasAndExpectPass(
    WidgetTester tester, {
    required String letterId,
    required String exerciseId,
  }) async {
    final letter = _letter(letterId);
    final exercise = _exercise(exerciseId);
    final reference = (letter.contextualForms?['isolated'])!.referenceStrokes;

    List<List<Offset>>? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: kWideCanvas.width,
            height: kWideCanvas.height,
            child: StrokeCanvas(
              referenceStrokes: reference,
              acceptTouch: true,
              onLetterComplete: (s) => captured = s,
            ),
          ),
        ),
      ),
    );

    final canvasTopLeft = tester.getTopLeft(find.byType(StrokeCanvas));
    final ordered = [...reference]..sort((a, b) => a.order.compareTo(b.order));

    // Trace each reference stroke EXACTLY along the PAINTED guide: the same
    // scaleNormalizedPoint mapping the painter uses is, by definition, where
    // the dotted guide (and the ink dots) appear on screen.
    for (final stroke in ordered) {
      if (stroke.type == 'dot') {
        final at = canvasTopLeft +
            scaleNormalizedPoint(stroke.points.first, kWideCanvas);
        final g = await tester.startGesture(at);
        await tester.pump(const Duration(milliseconds: 16));
        await g.up();
        await tester.pump(const Duration(milliseconds: 16));
      } else {
        final path = _interp(stroke.points, 30);
        final g = await tester.startGesture(
          canvasTopLeft + scaleNormalizedPoint(path.first, kWideCanvas),
        );
        for (final p in path.skip(1)) {
          await g.moveTo(canvasTopLeft + scaleNormalizedPoint(p, kWideCanvas));
          await tester.pump(const Duration(milliseconds: 4));
        }
        await g.up();
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    expect(captured, isNotNull,
        reason: 'letter-complete must fire after ${ordered.length} strokes');

    // THE LIVE APPLY PATH — write_surface._onLetterComplete verbatim:
    // Offsets → [x,y] pixel pairs → adapter spec → validateExercise.
    final pixelStrokes = captured!
        .map((s) => s.map((o) => <double>[o.dx, o.dy]).toList())
        .toList();
    final spec = exerciseSpecFromExercise(exercise);
    final result = await validateExercise(
      spec,
      pixelStrokes,
      letter: letter,
      guideForm: 'isolated',
    );

    expect(
      result.passed,
      isTrue,
      reason: 'a faithful trace of the painted guide must pass the scorer '
          '(got mistakeId=${result.mistakeId}, criteria=${result.criteria})',
    );
  }

  testWidgets(
      'taa: faithful trace of the painted isolated guide passes the scorer '
      'on a 3:1 writebox', (tester) async {
    await traceOnCanvasAndExpectPass(
      tester,
      letterId: 'taa',
      exerciseId: 'taa.traceLetter.isolated',
    );
  });

  testWidgets(
      'thaa: faithful trace of the painted isolated guide passes the scorer '
      'on a 3:1 writebox', (tester) async {
    await traceOnCanvasAndExpectPass(
      tester,
      letterId: 'thaa',
      exerciseId: 'thaa.traceLetter.isolated',
    );
  });

  test(
      'REGRESSION PIN: a non-uniformly stretched trace (the pre-fix painted '
      'guide) is certainly-wrong — the scorer is aspect-sensitive by design',
      () async {
    final letter = _letter('taa');
    final exercise = _exercise('taa.traceLetter.isolated');
    final reference = (letter.contextualForms?['isolated'])!.referenceStrokes;
    final ordered = [...reference]..sort((a, b) => a.order.compareTo(b.order));

    // The OLD painter mapping: x*width, y*height — a 3:1 stretch.
    final stretched = [
      for (final s in ordered)
        if (s.type == 'dot')
          [
            [
              s.points.first[0] * kWideCanvas.width,
              s.points.first[1] * kWideCanvas.height,
            ]
          ]
        else
          _interp(s.points, 30)
              .map((p) =>
                  [p[0] * kWideCanvas.width, p[1] * kWideCanvas.height])
              .toList(),
    ];

    final result = await validateExercise(
      exerciseSpecFromExercise(exercise),
      stretched,
      letter: letter,
      guideForm: 'isolated',
    );
    expect(
      result.passed,
      isFalse,
      reason: 'the aspect-preserving shape criterion must keep rejecting a '
          '3:1-stretched bowl — if this starts passing, the scorer has gone '
          'aspect-blind (flat-line bowls would pass as round bowls)',
    );
  });
}
