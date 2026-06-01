// 02.1-02 Task 2 — the per-letter reference-overlay golden (D-07).
//
// Renders alif's RESOLVED reference path (via ReferencePath.resolve — the same
// one-source-of-truth geometry the scorer/animation use, S1-04) as a pen path
// overlaid on the faint Noto Naskh alif glyph, in draw order. This is BOTH the
// owner+mother visual sign-off artifact (Task 3) AND the CI regression artifact:
// if the resolved path ever traces AROUND the letter again (the old outline bug)
// instead of straight down it, the golden changes and this test fails.
//
// FONTS: test/flutter_test_config.dart loads the bundled Noto Naskh TTF into the
// test engine first, so the backdrop glyph renders as a real alif (not tofu).
//
// BASELINE STATUS: PROVISIONAL until the owner+mother visual-PASS (Task 3).
// Regenerate with:
//   flutter test --update-goldens test/curriculum/reference_overlay_golden_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/reference_path.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/theme/text_styles.dart';

Letter _loadAlif() {
  final raw = File('assets/curriculum/letters.json').readAsStringSync();
  final letters = (jsonDecode(raw) as Map<String, dynamic>)['letters']
      as List<dynamic>;
  return Letter.fromJson(letters
      .cast<Map<String, dynamic>>()
      .firstWhere((l) => l['id'] == 'alif'));
}

/// Draws the faint glyph backdrop + the resolved reference pen path on top, in
/// draw order, with a start marker on the first point of the first stroke.
class _OverlayPainter extends CustomPainter {
  _OverlayPainter(this.resolved);

  /// Stroke-ordered, per-stroke normalized [x,y] point lists from resolve().
  final List<List<List<double>>> resolved;

  Offset _toCanvas(List<double> p, Size size) =>
      Offset(p[0] * size.width, p[1] * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0xFF0E5B5F) // deep ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final stroke in resolved) {
      if (stroke.isEmpty) continue;
      final path = Path()
        ..moveTo(_toCanvas(stroke.first, size).dx, _toCanvas(stroke.first, size).dy);
      for (var i = 1; i < stroke.length; i++) {
        final o = _toCanvas(stroke[i], size);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, pen);
    }

    // Gold start marker on the very first authored point (the numbered "1").
    if (resolved.isNotEmpty && resolved.first.isNotEmpty) {
      final start = _toCanvas(resolved.first.first, size);
      canvas.drawCircle(start, 14, Paint()..color = const Color(0xFFC8951F));
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.resolved != resolved;
}

void main() {
  testWidgets('alif resolved pen path overlays the glyph in draw order (D-07)',
      (WidgetTester tester) async {
    const double side = 400;
    tester.view.physicalSize = const Size(side * 2, side * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final alif = _loadAlif();
    final resolved = ReferencePath.resolve(alif.referenceStrokes);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF6EFE0), // parchment
          body: Center(
            child: SizedBox(
              key: const Key('overlay-golden'),
              width: side,
              height: side,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Faint glyph backdrop.
                  IgnorePointer(
                    child: Center(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Opacity(
                          opacity: 0.15,
                          child: Text(
                            alif.char,
                            style: const TextStyle(
                              fontFamily: QalamFonts.arabic,
                              fontSize: 360,
                              color: Color(0xFF1A2B2B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The resolved reference pen path on top.
                  CustomPaint(painter: _OverlayPainter(resolved)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('overlay-golden')),
      matchesGoldenFile('../goldens/alif_reference_overlay.png'),
    );
  });
}
