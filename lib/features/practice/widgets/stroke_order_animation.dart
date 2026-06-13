// StrokeOrderAnimation — Phase-3 "Watch me write" pen-tip animation (plan 03-03).
//
// Builds a dart:ui Path from ReferencePath.resolve(referenceStrokes) (S1-04 —
// one source of truth) scaled to the canvas size, then drives an
// AnimationController along that path using PathMetric:
//   - extractPath(0, length * t)  → progressively revealed ink
//   - getTangentForOffset(length * t)?.position → animated pen-tip dot
//
// Tokens: QalamMotion.durSlow (420ms) / QalamMotion.easeOutQuart for pacing;
//         QalamColors.reward for the gold start-dot and moving pen-tip;
//         QalamColors.inkStroke for the revealed ink.
//
// Auto-plays ONCE on first build (initState). The parent calls replay() via a
// GlobalKey<StrokeOrderAnimationState> to restart from the "Watch Again" button.
//
// NO Rive, NO Lottie (S1-04 single-source-of-truth, RESEARCH Alternatives).

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/scoring/reference_path.dart';
import '../../../models/letter.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';

/// Animated stroke-order demo widget.
///
/// Access [replay] via `GlobalKey<StrokeOrderAnimationState>`:
/// ```dart
/// final key = GlobalKey<StrokeOrderAnimationState>();
/// StrokeOrderAnimation(key: key, referenceStrokes: letter.referenceStrokes)
/// // ...
/// key.currentState?.replay();
/// ```
class StrokeOrderAnimation extends StatefulWidget {
  const StrokeOrderAnimation({
    super.key,
    required this.referenceStrokes,
    this.duration,
    this.color,
  });

  /// The letter's authored strokes — consumed via ReferencePath.resolve.
  final List<StrokeSpec> referenceStrokes;

  /// How long the pen-tip takes to traverse the whole path. Defaults to
  /// [QalamMotion.durWrite] (1400ms) — the established Watch-phase pacing.
  /// The ghost comparison (D-21) passes `durWrite * 2` for the half-speed
  /// side-by-side replay. Null preserves the original behavior exactly.
  final Duration? duration;

  /// The revealed-ink color. Defaults to [QalamColors.inkStroke] (deep-ink) —
  /// the reference stroke color. The ghost comparison renders the child's
  /// wobbly stroke in [QalamColors.warnSoft] (coral, never red) via this param.
  /// Null preserves the original behavior exactly. The gold start-dot and
  /// pen-tip stay reward-gold regardless (they are not the ink).
  final Color? color;

  @override
  State<StrokeOrderAnimation> createState() => StrokeOrderAnimationState();
}

class StrokeOrderAnimationState extends State<StrokeOrderAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      // 1400ms default — slow enough for a child to follow; the ghost
      // comparison overrides with durWrite * 2 for half-speed replay.
      duration: widget.duration ?? QalamMotion.durWrite,
    );

    // Linear curve = even pen speed. easeOutQuart sprinted then crawled at the
    // end, which read as "too fast then stuck"; a constant pace tracks like a
    // real hand writing the stroke.
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );

    // Auto-play once on first build (D-10).
    _controller.forward();
  }

  /// Replays the animation from the beginning.
  /// Called by the parent's "Watch Again" / "Replay" button.
  void replay() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? _) {
        return CustomPaint(
          painter: _AnimationPainter(
            referenceStrokes: widget.referenceStrokes,
            progress: _animation.value,
            inkColor: widget.color ?? QalamColors.inkStroke,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimationPainter — draws the progressively revealed path + pen-tip dot
// ---------------------------------------------------------------------------

class _AnimationPainter extends CustomPainter {
  _AnimationPainter({
    required this.referenceStrokes,
    required this.progress,
    required this.inkColor,
  });

  final List<StrokeSpec> referenceStrokes;

  /// Animation progress in [0, 1].
  final double progress;

  /// The revealed-ink color (deep-ink by default; coral for the child's stroke
  /// in the ghost comparison). The gold start-dot/pen-tip are unaffected.
  final Color inkColor;

  static const double _penTipRadius = 8.0;
  static const double _startDotRadius = 10.0;
  static const double _startDotInnerRadius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Resolve reference geometry — S1-04 one source of truth.
    final List<List<List<double>>> resolved =
        ReferencePath.resolve(referenceStrokes);
    if (resolved.isEmpty) return;

    // Build a single dart:ui Path from all strokes, scaled to canvas.
    final Path fullPath = _buildScaledPath(resolved, size);

    // Compute PathMetrics once.
    final List<PathMetric> metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    // For simplicity, animate across the total combined length of all metrics.
    final double totalLength =
        metrics.fold(0.0, (double sum, PathMetric m) => sum + m.length);
    if (totalLength <= 0) return;

    final double targetLength = totalLength * progress;

    // Paint ink: revealed portion of the path up to targetLength.
    final Paint inkPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = QalamInk.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    double drawn = 0.0;
    Offset? penTipPos;

    for (final PathMetric metric in metrics) {
      final double remaining = targetLength - drawn;
      if (remaining <= 0) break;

      final double segEnd = remaining.clamp(0.0, metric.length);
      if (segEnd > 0) {
        canvas.drawPath(metric.extractPath(0, segEnd), inkPaint);
      }

      if (remaining < metric.length) {
        // The pen tip is within this segment.
        final tangent = metric.getTangentForOffset(segEnd);
        if (tangent != null) penTipPos = tangent.position;
      } else {
        // Pen tip is past this segment — tentatively place it at its end.
        final tangent = metric.getTangentForOffset(metric.length);
        if (tangent != null) penTipPos = tangent.position;
      }

      drawn += metric.length;
    }

    // Gold start-dot (reward color — REWARDS ONLY; S1-04 / UI-SPEC Color).
    _paintStartDot(canvas, resolved.first.first, size);

    // Animated gold pen-tip dot.
    if (penTipPos != null) {
      canvas.drawCircle(
        penTipPos,
        _penTipRadius,
        Paint()
          ..color = QalamColors.reward
          ..style = PaintingStyle.fill,
      );
    }
  }

  // Build a dart:ui Path from normalized 0..1 coords scaled to [size].
  Path _buildScaledPath(List<List<List<double>>> resolved, Size size) {
    final Path path = Path();
    for (final List<List<double>> stroke in resolved) {
      if (stroke.isEmpty) continue;
      final Offset start = _scale(stroke.first, size);
      path.moveTo(start.dx, start.dy);
      for (int i = 1; i < stroke.length; i++) {
        final Offset pt = _scale(stroke[i], size);
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }

  Offset _scale(List<double> p, Size size) =>
      Offset(p[0] * size.width, p[1] * size.height);

  // Gold ring start-dot — identical visual treatment to stroke_canvas.dart.
  void _paintStartDot(Canvas canvas, List<double> normalizedPoint, Size size) {
    final Offset center = _scale(normalizedPoint, size);
    canvas.drawCircle(
      center,
      _startDotRadius,
      Paint()
        ..color = QalamColors.reward
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      _startDotInnerRadius,
      Paint()
        ..color = QalamColors.bg
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_AnimationPainter oldDelegate) =>
      oldDelegate.referenceStrokes != referenceStrokes ||
      oldDelegate.progress != progress ||
      oldDelegate.inkColor != inkColor;
}
