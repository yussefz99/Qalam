// stroke_canvas_test.dart — Plan 03-03
//
// Tests:
//   1. A synthesized STYLUS stroke produces an onStrokeSubmitted callback.
//   2. A synthesized TOUCH stroke is REJECTED when acceptTouch: false (prod).
//   3. A synthesized TOUCH stroke is ACCEPTED when acceptTouch: true (debug).
//
// Pointer synthesis pattern from
// test/features/authoring/authoring_screen_test.dart lines 119-143.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/features/practice/widgets/stroke_canvas.dart';
import 'package:qalam/models/letter.dart';

// ---------------------------------------------------------------------------
// Alif fixture — a minimal single downstroke in normalized 0..1 coordinates.
// ---------------------------------------------------------------------------

const List<StrokeSpec> _alifStrokes = <StrokeSpec>[
  StrokeSpec(
    order: 1,
    label: 'downstroke',
    type: 'line',
    direction: 'topToBottom',
    points: <List<double>>[
      <double>[0.5, 0.1],
      <double>[0.5, 0.5],
      <double>[0.5, 0.9],
    ],
  ),
];

// ---------------------------------------------------------------------------
// Helper — wraps StrokeCanvas in a minimal testable widget tree.
// ---------------------------------------------------------------------------

Widget _buildCanvas({
  required void Function(List<Offset>) onSubmitted,
  required bool acceptTouch,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 400,
        child: StrokeCanvas(
          key: const Key('canvas'),
          referenceStrokes: _alifStrokes,
          onStrokeSubmitted: onSubmitted,
          acceptTouch: acceptTouch,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('StrokeCanvas', () {
    testWidgets(
        '1. stylus stroke → onStrokeSubmitted called with non-empty points',
        (WidgetTester tester) async {
      List<Offset>? captured;

      await tester.pumpWidget(
        _buildCanvas(
          onSubmitted: (pts) => captured = pts,
          acceptTouch: false, // strict prod mode — stylus must still pass
        ),
      );
      await tester.pumpAndSettle();

      final Finder canvasFinder = find.byKey(const Key('canvas'));
      expect(canvasFinder, findsOneWidget);

      final Rect rect = tester.getRect(canvasFinder);
      final Offset topCenter = Offset(rect.center.dx, rect.top + rect.height * 0.15);
      final Offset midCenter = rect.center;
      final Offset bottomCenter =
          Offset(rect.center.dx, rect.bottom - rect.height * 0.15);

      // Synthesize a STYLUS gesture.
      final TestGesture gesture = await tester.startGesture(
        topCenter,
        kind: PointerDeviceKind.stylus,
      );
      await gesture.moveTo(midCenter);
      await gesture.moveTo(bottomCenter);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(captured, isNotNull, reason: 'onStrokeSubmitted must fire');
      expect(captured, isNotEmpty, reason: 'submitted points must be non-empty');
    });

    testWidgets(
        '2. touch stroke REJECTED when acceptTouch: false (prod palm rejection)',
        (WidgetTester tester) async {
      List<Offset>? captured;

      await tester.pumpWidget(
        _buildCanvas(
          onSubmitted: (pts) => captured = pts,
          acceptTouch: false, // production — touch must be silently ignored
        ),
      );
      await tester.pumpAndSettle();

      final Finder canvasFinder = find.byKey(const Key('canvas'));
      final Rect rect = tester.getRect(canvasFinder);
      final Offset topCenter = Offset(rect.center.dx, rect.top + rect.height * 0.15);
      final Offset bottomCenter =
          Offset(rect.center.dx, rect.bottom - rect.height * 0.15);

      // Synthesize a TOUCH gesture — must be rejected.
      final TestGesture gesture = await tester.startGesture(
        topCenter,
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveTo(bottomCenter);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        captured,
        isNull,
        reason: 'touch must be rejected in prod (acceptTouch: false)',
      );
    });

    testWidgets(
        '4. capture does NOT clamp points drawn below the canvas rect (Defect-1)',
        (WidgetTester tester) async {
      // The bottom-edge false-fail root-cause probe: a child who writes slightly
      // LOW drags the stylus past the canvas bottom edge. The capture layer must
      // keep those below-rect points verbatim (no clamp to the rect) so the bowl
      // bottom survives to the position-invariant scorer. A clamp here would
      // flatten the bowl and read "much shallower" (the on-device log symptom).
      List<Offset>? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 300,
                  height: 200, // the canvas rect: local y in [0 .. 200]
                  child: StrokeCanvas(
                    key: const Key('canvas'),
                    referenceStrokes: _alifStrokes,
                    onStrokeSubmitted: (pts) => captured = pts,
                    acceptTouch: false,
                  ),
                ),
                // a sibling BELOW so the drag ends over a different widget.
                const SizedBox(
                    width: 300, height: 200, child: ColoredBox(color: Colors.red)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Rect rect = tester.getRect(find.byKey(const Key('canvas')));
      final TestGesture g = await tester.startGesture(
        Offset(rect.center.dx, rect.bottom - 20),
        kind: PointerDeviceKind.stylus,
      );
      // Drag DOWN past the bottom edge into the red sibling (+60px below).
      await g.moveTo(Offset(rect.center.dx, rect.bottom - 5));
      await g.moveTo(Offset(rect.center.dx, rect.bottom + 20));
      await g.moveTo(Offset(rect.center.dx, rect.bottom + 60));
      await g.up();
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      final double maxLocalY =
          captured!.map((o) => o.dy).reduce((a, b) => a > b ? a : b);
      // The captured local y extends BELOW the canvas height (200) — the
      // below-rect points were kept, not clamped up to the edge.
      expect(maxLocalY, greaterThan(rect.height),
          reason: 'points dragged below the canvas rect must be captured '
              'un-clamped (local y > canvas height), or a low bowl reads shallow.');
    });

    testWidgets(
        '3. touch stroke ACCEPTED when acceptTouch: true (debug-finger flag)',
        (WidgetTester tester) async {
      List<Offset>? captured;

      await tester.pumpWidget(
        _buildCanvas(
          onSubmitted: (pts) => captured = pts,
          acceptTouch: true, // debug finger-input flag enabled
        ),
      );
      await tester.pumpAndSettle();

      final Finder canvasFinder = find.byKey(const Key('canvas'));
      final Rect rect = tester.getRect(canvasFinder);
      final Offset topCenter = Offset(rect.center.dx, rect.top + rect.height * 0.15);
      final Offset midCenter = rect.center;
      final Offset bottomCenter =
          Offset(rect.center.dx, rect.bottom - rect.height * 0.15);

      // Synthesize a TOUCH gesture — must be accepted.
      final TestGesture gesture = await tester.startGesture(
        topCenter,
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveTo(midCenter);
      await gesture.moveTo(bottomCenter);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        captured,
        isNotNull,
        reason: 'touch must be accepted when acceptTouch: true',
      );
      expect(captured, isNotEmpty);
    });
  });
}
