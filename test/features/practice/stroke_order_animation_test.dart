// stroke_order_animation_test.dart — Plan 03-03
//
// Tests:
//   1. After pumpAndSettle the animation controller reaches completed
//      (auto-play-once in initState).
//   2. After calling replay() via GlobalKey, the animation runs again
//      and reaches completed after a second pumpAndSettle.
//   3. The widget builds without errors with a real alif StrokeSpec.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/features/practice/widgets/stroke_order_animation.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/theme/colors.dart';

// ---------------------------------------------------------------------------
// Alif fixture — identical to the stroke_canvas_test fixture.
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
// Baa-like dotted fixture — one body line stroke + one single-point dot.
// The dot sits well below the body so its painted circle is unambiguous.
// ---------------------------------------------------------------------------

const List<StrokeSpec> _baaStrokes = <StrokeSpec>[
  StrokeSpec(
    order: 1,
    label: 'body',
    type: 'line',
    direction: 'rightToLeft',
    points: <List<double>>[
      <double>[0.8, 0.4],
      <double>[0.5, 0.5],
      <double>[0.2, 0.4],
    ],
  ),
  StrokeSpec(
    order: 2,
    label: 'dot',
    type: 'dot',
    direction: 'tap',
    points: <List<double>>[
      <double>[0.5, 0.8],
    ],
  ),
];

// ---------------------------------------------------------------------------
// Recording canvas — captures drawCircle calls so a test can prove the dot
// is painted (and with which color) rather than only that the widget builds.
// ---------------------------------------------------------------------------

class _CircleCall {
  _CircleCall(this.center, this.radius, this.color);
  final Offset center;
  final double radius;
  final Color color;
}

class _RecordingCanvas implements Canvas {
  final List<_CircleCall> circles = <_CircleCall>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles.add(_CircleCall(c, radius, paint.color));
  }

  @override
  void noSuchMethod(Invocation invocation) {
    // Ignore every other Canvas call (drawPath, etc.) — we only assert circles.
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('StrokeOrderAnimation', () {
    testWidgets('1. builds without errors with a real alif StrokeSpec',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StrokeOrderAnimation(
                referenceStrokes: _alifStrokes,
              ),
            ),
          ),
        ),
      );

      // No exceptions thrown during build/layout/paint.
      expect(tester.takeException(), isNull);
      expect(find.byType(StrokeOrderAnimation), findsOneWidget);
    });

    testWidgets(
        '2. auto-plays once: controller reaches completed after pumpAndSettle',
        (WidgetTester tester) async {
      final GlobalKey<StrokeOrderAnimationState> key =
          GlobalKey<StrokeOrderAnimationState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StrokeOrderAnimation(
                key: key,
                referenceStrokes: _alifStrokes,
              ),
            ),
          ),
        ),
      );

      // Let the auto-play animation run to completion.
      await tester.pumpAndSettle();

      expect(
        key.currentState,
        isNotNull,
        reason: 'State must be accessible via GlobalKey',
      );

      // Access the controller through the state to verify it completed.
      // We verify indirectly: pumpAndSettle only returns when there are no
      // more pending frames, which means the AnimationController must have
      // reached its end (completed or dismissed). Since we called forward()
      // in initState, it must be completed.
      expect(tester.hasRunningAnimations, isFalse,
          reason: 'No animations should be running after pumpAndSettle');
    });

    testWidgets(
        '3. replay() restarts the animation and it completes again',
        (WidgetTester tester) async {
      final GlobalKey<StrokeOrderAnimationState> key =
          GlobalKey<StrokeOrderAnimationState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StrokeOrderAnimation(
                key: key,
                referenceStrokes: _alifStrokes,
              ),
            ),
          ),
        ),
      );

      // Wait for the first auto-play to finish.
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse,
          reason: 'Auto-play should have completed');

      // Trigger replay via the public API.
      key.currentState!.replay();

      // Animation should now be running again.
      expect(tester.hasRunningAnimations, isTrue,
          reason: 'replay() should restart the animation');

      // Wait for it to complete again.
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse,
          reason: 'Animation should complete after replay');
    });

    testWidgets(
        '4. custom duration is applied to the animation controller',
        (WidgetTester tester) async {
      const Duration custom = Duration(milliseconds: 2800);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StrokeOrderAnimation(
                referenceStrokes: _alifStrokes,
                duration: custom,
              ),
            ),
          ),
        ),
      );

      // The widget builds and accepts the custom duration without error.
      expect(tester.takeException(), isNull);
      final StrokeOrderAnimation widget =
          tester.widget(find.byType(StrokeOrderAnimation));
      expect(widget.duration, custom);

      // Mid-flight (1400ms into a 2800ms run) the animation is still running —
      // proving the controller honors the longer custom duration rather than
      // the 1400ms default (which would already be done).
      await tester.pump(); // start the auto-play
      await tester.pump(const Duration(milliseconds: 1400));
      expect(tester.hasRunningAnimations, isTrue,
          reason: 'A 2800ms run must still be animating at 1400ms');
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
        '6. a dotted letter paints a calm filled ink circle for its dot stroke',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StrokeOrderAnimation(referenceStrokes: _baaStrokes),
            ),
          ),
        ),
      );

      // Let the auto-play run to completion so the dot's beat has elapsed.
      await tester.pumpAndSettle();

      // Reach into the rendered CustomPaint and re-run its painter against a
      // recording canvas to prove the dot is actually drawn (not just built).
      final CustomPaint paintWidget = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(StrokeOrderAnimation),
          matching: find.byType(CustomPaint),
        ),
      );
      final CustomPainter painter = paintWidget.painter!;
      final _RecordingCanvas rec = _RecordingCanvas();
      painter.paint(rec, const Size(400, 400));

      // The dot's scaled position: (0.5 * 400, 0.8 * 400) = (200, 320).
      // NB: compare colors via toARGB32() — Color's `==` is unreliable across
      // colorSpaces in current Flutter (two visually identical sRGB colors can
      // compare unequal), so we match on the packed ARGB value.
      const Offset expectedDot = Offset(200, 320);
      final Iterable<_CircleCall> inkDots = rec.circles.where(
        (_CircleCall c) =>
            c.color.toARGB32() == QalamColors.inkStroke.toARGB32() &&
            (c.center - expectedDot).distance < 1.0,
      );
      expect(
        inkDots,
        isNotEmpty,
        reason: 'A type=="dot" stroke must paint a filled ink circle at its '
            'scaled point after the animation settles.',
      );

      // Anti-gamification: the dot must NOT use the gold reward color — that
      // stays reward-exclusive (start-dot + pen-tip only).
      final Iterable<_CircleCall> goldAtDot = rec.circles.where(
        (_CircleCall c) =>
            c.color.toARGB32() == QalamColors.reward.toARGB32() &&
            (c.center - expectedDot).distance < 1.0,
      );
      expect(
        goldAtDot,
        isEmpty,
        reason: 'The dot must be ink, not gold — gold is reward-exclusive.',
      );
    });

    testWidgets(
        '5. custom color is accepted (default-preserving when omitted)',
        (WidgetTester tester) async {
      // Custom color (coral — the ghost-comparison child stroke).
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StrokeOrderAnimation(
                referenceStrokes: _alifStrokes,
                color: QalamColors.warnSoft,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final StrokeOrderAnimation custom =
          tester.widget(find.byType(StrokeOrderAnimation));
      expect(custom.color, QalamColors.warnSoft);

      // Default construction leaves color/duration null (deep-ink + durWrite
      // resolved internally) — behavior preserved for existing callers.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StrokeOrderAnimation(referenceStrokes: _alifStrokes),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final StrokeOrderAnimation def =
          tester.widget(find.byType(StrokeOrderAnimation));
      expect(def.color, isNull);
      expect(def.duration, isNull);
    });
  });
}
