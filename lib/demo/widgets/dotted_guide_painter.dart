// DottedGuidePainter — the shared "half-traced" treatment for the demo (DP-01).
//
// Two layers, ONE source of truth (Pitfall 5): both the dotted reference guide
// and the ink overlay are derived from the same resolved, normalized reference
// points (DemoAlif / ReferencePath.resolve) scaled to the canvas — the glyph is
// PAINTED, never rendered as a Text('…') string that could diverge from the
// traced path.
//
//   1. Dotted guide  — the full reference path as evenly dashed segments, in a
//      MUTED neutral token (never gold, never coral/red; gold start-dots and
//      coral failing-strokes belong to the screens, not this reusable painter).
//   2. Ink overlay   — the first `inkProgress` fraction of the stroke, drawn as
//      smoothed deep-ink (QalamColors.inkStroke, QalamInk.strokeWidth, round
//      caps/joins) — exactly the Practice ink treatment. inkProgress 0 = guide
//      only (Watch); ~0.5 = the half-traced Trace hero state.
//
// Pure painting: no recognition, no capture engine, no order/count logic, no I/O.

import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';

class DottedGuidePainter extends CustomPainter {
  DottedGuidePainter({
    required this.referencePoints,
    required this.inkProgress,
    this.inkColor = QalamColors.inkStroke,
    this.showStartDot = false,
    this.startDotColor = QalamColors.reward,
    this.diacriticDots = const <Offset>[],
  });

  /// Normalized (0..1) reference points the guide + ink are drawn from — the
  /// single shared geometry source (DemoAlif / ReferencePath).
  final List<Offset> referencePoints;

  /// Fraction (0..1) of the stroke already traced — the ink overlay covers this
  /// leading portion of the path. 0 = no ink (guide only); 1 = fully inked.
  final double inkProgress;

  /// The ink-overlay color. Defaults to deep-ink (the Practice canvas
  /// treatment); the Feedback miss screen passes QalamColors.warnSoft (coral) to
  /// highlight the failing stroke — never red.
  final Color inkColor;

  /// When true, a numbered gold start-dot ("1") is painted at the first
  /// reference point — the sanctioned reward-token gold (Watch/Trace/Feedback).
  final bool showStartDot;

  /// Color of the numbered start-dot (gold reward token — the only gold here).
  final Color startDotColor;

  /// Distinguishing diacritic dots (normalized 0..1), painted solid in the
  /// stroke color — e.g. the single dot under baa. Empty for letters with none.
  final List<Offset> diacriticDots;

  /// The muted dotted-guide color — a neutral token, never gold/coral.
  Color get guideColor => QalamColors.fgMuted;

  static const double _dashLength = 4;
  static const double _dashGap = 6;
  static const double _guideWidth = 2.5;

  /// Maps the normalized reference points onto [size]. A point [0.5, 1.0] maps
  /// to (0.5 * width, 1.0 * height).
  List<Offset> scaledGuidePoints(Size size) => referencePoints
      .map((p) => Offset(p.dx * size.width, p.dy * size.height))
      .toList();

  /// The leading portion of the scaled stroke that is already inked, by arc
  /// length — the "half-traced" geometry. Returns an empty list at
  /// [inkProgress] 0, the full polyline at 1.0, and an interpolated endpoint in
  /// between. This is what the ink overlay draws (and what tests assert on).
  List<Offset> inkPath(Size size) {
    final double progress = inkProgress.clamp(0.0, 1.0);
    if (progress <= 0) return <Offset>[];

    final List<Offset> pts = scaledGuidePoints(size);
    if (pts.length < 2) return pts;

    double total = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      total += (pts[i + 1] - pts[i]).distance;
    }
    final double target = total * progress;

    final List<Offset> inked = <Offset>[pts.first];
    double walked = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      final double seg = (pts[i + 1] - pts[i]).distance;
      if (walked + seg < target) {
        inked.add(pts[i + 1]);
        walked += seg;
      } else {
        // Interpolate the final inked point partway along this segment.
        final double remain = target - walked;
        final double t = seg == 0 ? 0 : remain / seg;
        inked.add(Offset.lerp(pts[i], pts[i + 1], t)!);
        break;
      }
    }
    return inked;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> guide = scaledGuidePoints(size);
    if (guide.isEmpty) return;

    // Layer 1: the dotted reference guide, dashed via PathMetric.extractPath.
    final Path guidePath = Path()..moveTo(guide.first.dx, guide.first.dy);
    for (int i = 1; i < guide.length; i++) {
      guidePath.lineTo(guide[i].dx, guide[i].dy);
    }
    final Paint guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _guideWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (final PathMetric metric in guidePath.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final double end = (dist + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), guidePaint);
        dist += _dashLength + _dashGap;
      }
    }

    // Layer 2: the smoothed ink overlay over the traced fraction.
    final List<Offset> ink = inkPath(size);
    if (ink.isNotEmpty) {
      final Paint pen = Paint()
        ..color = inkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = QalamInk.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      _paintStroke(canvas, ink, pen);
    }

    // Layer 3: the distinguishing diacritic dot(s) — solid, in the stroke color.
    if (diacriticDots.isNotEmpty) {
      final Paint dotPaint = Paint()
        ..color = inkColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      const double diacriticRadius = QalamInk.strokeWidth * 0.85;
      for (final Offset d in diacriticDots) {
        canvas.drawCircle(
          Offset(d.dx * size.width, d.dy * size.height),
          diacriticRadius,
          dotPaint,
        );
      }
    }

    // Layer 4: the numbered gold start-dot at the first reference point.
    if (showStartDot) {
      final Offset start = guide.first;
      const double startRadius = QalamSpace.space3; // 12px
      canvas.drawCircle(
        start,
        startRadius,
        Paint()
          ..color = startDotColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      final TextPainter number = TextPainter(
        text: TextSpan(
          text: '1',
          style: QalamTextStyles.label.copyWith(
            color: QalamColors.fgOnPrimary,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      number.paint(canvas, start - Offset(number.width / 2, number.height / 2));
    }
  }

  /// Quadratic-smoothed stroke through the sampled points (midpoint smoothing —
  /// the same treatment as the Practice ink canvas).
  void _paintStroke(Canvas canvas, List<Offset> points, Paint pen) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawCircle(points.first, pen.strokeWidth / 2,
          Paint()..color = pen.color);
      return;
    }
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];
      final Offset mid =
          Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, pen);
  }

  @override
  bool shouldRepaint(DottedGuidePainter oldDelegate) =>
      oldDelegate.inkProgress != inkProgress ||
      oldDelegate.inkColor != inkColor ||
      oldDelegate.showStartDot != showStartDot ||
      oldDelegate.startDotColor != startDotColor ||
      !listEquals(oldDelegate.diacriticDots, diacriticDots) ||
      !listEquals(oldDelegate.referencePoints, referencePoints);
}
