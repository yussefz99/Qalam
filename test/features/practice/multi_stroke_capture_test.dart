// multi_stroke_capture_test.dart — Plan 04-04, Task 1
//
// Verifies the whole-letter ACCUMULATION fix in StrokeCanvas: two stylus
// strokes for a 2-part letter (e.g. baa = boat + dot) must BOTH survive — the
// canvas must NOT clear prior strokes on a new pointer-down — and the
// letter-complete signal (count-reached, Open Q1) must fire exactly once with a
// 2-element List<List<Offset>>, not 1 and not cleared.
//
// Pointer synthesis pattern from stroke_canvas_test.dart.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';
import 'package:qalam/models/letter.dart';

// ---------------------------------------------------------------------------
// Baa fixture — a 2-part letter: a body line + a dot below it.
// ---------------------------------------------------------------------------

const List<StrokeSpec> _baaStrokes = <StrokeSpec>[
  StrokeSpec(
    order: 1,
    label: 'body_line',
    type: 'line',
    direction: 'rightToLeft',
    points: <List<double>>[
      <double>[0.8, 0.4],
      <double>[0.5, 0.45],
      <double>[0.2, 0.4],
    ],
  ),
  StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    direction: 'tap',
    points: <List<double>>[
      <double>[0.5, 0.7],
    ],
  ),
];

Widget _buildCanvas({
  void Function(List<Offset>)? onSubmitted,
  void Function(List<List<Offset>>)? onLetterComplete,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 400,
        child: StrokeCanvas(
          key: const Key('canvas'),
          referenceStrokes: _baaStrokes,
          onStrokeSubmitted: onSubmitted,
          onLetterComplete: onLetterComplete,
          // Allow touch synthesis without relying on kDebugMode timing.
          acceptTouch: true,
        ),
      ),
    ),
  );
}

void main() {
  group('StrokeCanvas — whole-letter accumulation (Plan 04-04)', () {
    testWidgets(
        'two strokes accumulate and onLetterComplete fires once with a 2-element list',
        (WidgetTester tester) async {
      List<List<Offset>>? completedLetter;
      int letterCompleteCalls = 0;
      int perStrokeCalls = 0;

      await tester.pumpWidget(
        _buildCanvas(
          onSubmitted: (_) => perStrokeCalls++,
          onLetterComplete: (List<List<Offset>> strokes) {
            completedLetter = strokes;
            letterCompleteCalls++;
          },
        ),
      );
      await tester.pumpAndSettle();

      final Finder canvasFinder = find.byKey(const Key('canvas'));
      final Rect rect = tester.getRect(canvasFinder);

      // Stroke 1 — the body line, drawn right→left across the middle.
      final TestGesture body = await tester.startGesture(
        Offset(rect.right - rect.width * 0.2, rect.center.dy),
        kind: PointerDeviceKind.stylus,
      );
      await body.moveTo(Offset(rect.center.dx, rect.center.dy));
      await body.moveTo(Offset(rect.left + rect.width * 0.2, rect.center.dy));
      await body.up();
      await tester.pumpAndSettle();

      // After ONE stroke the letter is NOT yet complete (2-part letter).
      expect(letterCompleteCalls, 0,
          reason: 'one of two strokes drawn — not complete yet');

      // Stroke 2 — the dot, a short tap below the body.
      final TestGesture dot = await tester.startGesture(
        Offset(rect.center.dx, rect.center.dy + rect.height * 0.25),
        kind: PointerDeviceKind.stylus,
      );
      await dot.moveTo(
          Offset(rect.center.dx + 1, rect.center.dy + rect.height * 0.25));
      await dot.up();
      await tester.pumpAndSettle();

      // Letter-complete fires exactly once, carrying BOTH strokes (not cleared).
      expect(letterCompleteCalls, 1,
          reason: 'onLetterComplete fires once at count-reached');
      expect(completedLetter, isNotNull);
      expect(completedLetter!.length, 2,
          reason: 'both strokes accumulate — prior stroke was NOT cleared');
      expect(completedLetter![0], isNotEmpty);
      expect(completedLetter![1], isNotEmpty);
      // Per-stroke callback fired for each finished stroke.
      expect(perStrokeCalls, 2);
    });
  });
}
