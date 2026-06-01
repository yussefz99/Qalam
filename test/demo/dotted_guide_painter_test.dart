// Contract for DottedGuidePainter (plan 02.1.1-04, Pitfall 5).
//
// The painter is the shared "half-traced" treatment: a dotted reference guide
// plus an ink overlay covering the first `inkProgress` fraction of the stroke.
// Both layers derive from ONE source — the resolved normalized reference points
// (DemoAlif) — scaled to the canvas. Watch uses inkProgress 0 (guide only);
// Trace uses ~0.5 (the half-traced hero state).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/demo/demo_alif.dart';
import 'package:qalam/demo/widgets/dotted_guide_painter.dart';
import 'package:qalam/theme/colors.dart';

List<Offset> _alifPoints() =>
    DemoAlif.referencePoints.map((p) => Offset(p[0], p[1])).toList();

void main() {
  const Size size = Size(100, 200);

  test('Test 1: paints the alif single stroke without throwing', () {
    final painter = DottedGuidePainter(
      referencePoints: _alifPoints(),
      inkProgress: 0.5,
    );
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    expect(() => painter.paint(canvas, size), returnsNormally);
    recorder.endRecording().dispose();
  });

  test('Test 2: inkProgress controls how much ink is drawn', () {
    final none = DottedGuidePainter(referencePoints: _alifPoints(), inkProgress: 0.0);
    final half = DottedGuidePainter(referencePoints: _alifPoints(), inkProgress: 0.5);
    final full = DottedGuidePainter(referencePoints: _alifPoints(), inkProgress: 1.0);

    // No ink at 0.0 (nothing traced yet).
    expect(none.inkPath(size), isEmpty);

    // Partial ink at 0.5, full ink at 1.0, and half is strictly shorter.
    final double halfLen = _polylineLength(half.inkPath(size));
    final double fullLen = _polylineLength(full.inkPath(size));
    expect(halfLen, greaterThan(0));
    expect(halfLen, lessThan(fullLen));
    // ~half the total length (alif is a straight vertical line).
    expect(halfLen, closeTo(fullLen / 2, fullLen * 0.15));

    // Ink is the deep-ink stroke color (never gold/coral on the guide+ink).
    expect(half.inkColor, QalamColors.inkStroke);
  });

  test('Test 3: scales normalized 0..1 points to the canvas size', () {
    final painter =
        DottedGuidePainter(referencePoints: _alifPoints(), inkProgress: 0.0);
    final List<Offset> scaled = painter.scaledGuidePoints(size);
    // The alif's last reference point is [0.5, 1.0] → (0.5*w, 1.0*h).
    expect(scaled.last.dx, closeTo(0.5 * size.width, 0.001));
    expect(scaled.last.dy, closeTo(1.0 * size.height, 0.001));
  });

  test('Test 4: shouldRepaint only when inputs change', () {
    final a = DottedGuidePainter(referencePoints: _alifPoints(), inkProgress: 0.5);
    final same =
        DottedGuidePainter(referencePoints: _alifPoints(), inkProgress: 0.5);
    final moreInk =
        DottedGuidePainter(referencePoints: _alifPoints(), inkProgress: 0.6);

    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(moreInk), isTrue);
  });
}

double _polylineLength(List<Offset> pts) {
  double total = 0;
  for (int i = 0; i < pts.length - 1; i++) {
    total += (pts[i + 1] - pts[i]).distance;
  }
  return total;
}
