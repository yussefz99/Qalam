import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/dev/authoring_export.dart';
import 'package:qalam/dev/authoring_screen.dart';
import 'package:qalam/models/letter.dart';

/// 02.1-04 — the dev authoring tool.
///
/// Task 1 cases: the pure-Dart export helper normalizes tagged traced strokes
/// (combined bbox) into a validator-passing referenceStrokes fragment.
/// Task 2 case: the screen captures a traced stroke, tags it, and exports a
/// normalized fragment that passes the D-04 validator.
void main() {
  group('authoring_export — normalize + serialize', () {
    test('a traced near-vertical downstroke exports as a valid open line', () {
      // Raw pixel coordinates from a top→bottom finger trace (x wobbles a hair).
      const captured = CapturedStroke(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        direction: 'topToBottom',
        points: [
          [201.0, 40.0],
          [200.0, 160.0],
          [199.0, 280.0],
          [200.0, 400.0],
        ],
      );

      final specs = normalizeToStrokeSpecs([captured]);

      expect(specs, hasLength(1));
      final s = specs.single;
      expect(s.type, 'line');
      expect(s.direction, 'topToBottom');
      // Top→bottom: first y ≈ 0.0, last y ≈ 1.0.
      expect(s.points.first[1], closeTo(0.0, 1e-9));
      expect(s.points.last[1], closeTo(1.0, 1e-9));
      expect(s.points.first[1] < s.points.last[1], isTrue);
      // Every coord normalized into [0, 1].
      for (final p in s.points) {
        expect(p[0], inInclusiveRange(0.0, 1.0));
        expect(p[1], inInclusiveRange(0.0, 1.0));
      }
      // The whole point of the phase: the exported stroke PASSES the D-04 guard.
      expect(validateReferenceStrokes(specs), isEmpty);
    });

    test('a single tap tagged "dot" exports as exactly one point, "tap"', () {
      const body = CapturedStroke(
        order: 1,
        label: 'body',
        type: 'line',
        direction: 'topToBottom',
        points: [
          [100.0, 50.0],
          [100.0, 450.0],
        ],
      );
      const dot = CapturedStroke(
        order: 2,
        label: 'dot',
        type: 'dot',
        direction: 'tap',
        points: [
          [100.0, 500.0],
        ],
      );

      final specs = normalizeToStrokeSpecs([body, dot]);

      final dotSpec = specs.firstWhere((s) => s.type == 'dot');
      expect(dotSpec.points, hasLength(1));
      expect(dotSpec.direction, 'tap');
      // Normalized together: the dot sits BELOW the body (larger y) — relative
      // position is preserved by the combined-bbox normalization.
      expect(dotSpec.points.single[1], greaterThan(0.5));
      expect(validateReferenceStrokes(specs), isEmpty);
    });

    test('exports a JSON array shaped like letters.json referenceStrokes', () {
      const captured = CapturedStroke(
        order: 1,
        label: 'vertical_stroke',
        type: 'line',
        direction: 'topToBottom',
        points: [
          [200.0, 40.0],
          [200.0, 400.0],
        ],
      );

      final json = exportReferenceStrokesJson([captured]);
      final decoded = jsonDecode(json) as List<dynamic>;

      expect(decoded, hasLength(1));
      final entry = decoded.single as Map<String, dynamic>;
      expect(entry.keys,
          containsAll(<String>['order', 'label', 'type', 'points', 'direction']));
      expect(entry['type'], 'line');
      // Round-trips back through the model, and the result validates.
      final specs = (decoded)
          .map((e) => StrokeSpec.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(validateReferenceStrokes(specs), isEmpty);
    });

    test('empty input exports an empty JSON array', () {
      expect(exportReferenceStrokesJson(const []), '[]');
    });
  });

  group('AuthoringScreen — trace → tag → export', () {
    testWidgets('traces a downstroke and exports a validator-passing fragment',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthoringScreen()));
      await tester.pumpAndSettle();

      // Trace a vertical top→bottom downstroke over the capture canvas.
      final canvas = find.byKey(AuthoringScreen.canvasKey);
      expect(canvas, findsOneWidget);
      final rect = tester.getRect(canvas);
      final topCenter = Offset(rect.center.dx, rect.top + rect.height * 0.15);
      final midCenter = rect.center;
      final bottomCenter =
          Offset(rect.center.dx, rect.bottom - rect.height * 0.15);

      final gesture = await tester.startGesture(topCenter);
      await gesture.moveTo(midCenter);
      await gesture.moveTo(bottomCenter);
      await gesture.up();
      await tester.pumpAndSettle();

      // Export the captured stroke (new strokes default to a top→bottom line).
      await tester.tap(find.byKey(AuthoringScreen.exportButtonKey));
      await tester.pumpAndSettle();

      // The export field shows a JSON fragment; parse it and confirm it passes
      // the D-04 validator.
      final exportField = tester.widget<SelectableText>(
        find.byKey(AuthoringScreen.exportFieldKey),
      );
      final exported = exportField.data!;
      expect(exported.trim(), isNot('[]'));

      final decoded = jsonDecode(exported) as List<dynamic>;
      final specs = decoded
          .map((e) => StrokeSpec.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(specs, isNotEmpty);
      expect(specs.first.direction, 'topToBottom');
      expect(validateReferenceStrokes(specs), isEmpty);
    });
  });
}
