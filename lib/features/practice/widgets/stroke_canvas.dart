// StrokeCanvas — the Phase-3 interactive trace surface (plan 03-03).
//
// Captures stylus (and, in debug, finger) strokes via a Listener widget —
// NOT a GestureDetector (Pitfall 2 from research). Renders:
//   1. A dotted guide path drawn from ReferencePath.resolve(referenceStrokes)
//      using a CustomPainter + PathMetrics — NOT Text('ا') (Pitfall 5 / S1-04).
//   2. A gold start-dot at the first reference point.
//   3. Live smoothed ink over the guide, reusing the proven quadratic-midpoint
//      painter from practice_screen.dart verbatim.
//
// Input filter (_accept): stylus always accepted; touch accepted only when
// kDebugMode AND acceptTouch are both true (D-13/D-14, Pitfall 5).
//
// SECURITY (T-03-01 / T-01-05): captured points live IN MEMORY ONLY, in
// widget State. They are never printed, logged, or persisted. Points are
// discarded on dispose and on every pointer-cancel. Only the completed
// List<Offset> is forwarded once via onStrokeSubmitted; the caller scores
// and then discards it.

import 'dart:ui' show PathMetric, PointMode;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../../config/debug_flags.dart';
import '../../../core/scoring/reference_path.dart';
import '../../../models/letter.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';

/// Interactive trace canvas.
///
/// The parent hands in the letter's [referenceStrokes] (from the curriculum
/// data) and an [onStrokeSubmitted] callback. Every time the child lifts the
/// stylus (or accepted pointer), [onStrokeSubmitted] is called with the
/// completed point list for scoring. The canvas then clears itself for the
/// next stroke attempt.
class StrokeCanvas extends StatefulWidget {
  const StrokeCanvas({
    super.key,
    required this.referenceStrokes,
    required this.onStrokeSubmitted,
    this.acceptTouch = DebugFlags.allowFingerInput,
  });

  /// The letter's authored strokes (source: curriculum letters.json).
  /// Resolved via ReferencePath.resolve at paint time — S1-04 one-source-of-truth.
  final List<StrokeSpec> referenceStrokes;

  /// Called on pointer-up with the list of local Offsets the child drew.
  /// The caller is responsible for scoring and then discarding the points.
  final void Function(List<Offset> points) onStrokeSubmitted;

  /// Whether to accept touch events in addition to stylus events.
  /// Defaults to DebugFlags.allowFingerInput (true in debug builds).
  /// Pass false in tests to verify production palm-rejection behaviour.
  final bool acceptTouch;

  @override
  State<StrokeCanvas> createState() => _StrokeCanvasState();
}

class _StrokeCanvasState extends State<StrokeCanvas> {
  /// In-progress stroke points — in-memory only (T-03-01 / T-01-05).
  List<Offset>? _activePoints;

  /// Completed strokes waiting to be repainted (cleared on each new attempt).
  final List<List<Offset>> _completedStrokes = <List<Offset>>[];

  // --- input filter --------------------------------------------------------

  /// Returns true if this pointer kind should be captured.
  /// Production: stylus only. Debug with acceptTouch: also finger/touch.
  bool _accept(PointerDeviceKind kind) {
    if (kind == PointerDeviceKind.stylus) return true;
    if (kDebugMode && widget.acceptTouch && kind == PointerDeviceKind.touch) {
      return true;
    }
    return false;
  }

  // --- stroke lifecycle ----------------------------------------------------

  void _onDown(PointerDownEvent event) {
    if (!_accept(event.kind)) return;
    final Offset local = _localPos(event.position);
    setState(() {
      // Clear previous attempt so the child always starts fresh.
      _completedStrokes.clear();
      _activePoints = <Offset>[local];
    });
  }

  void _onMove(PointerMoveEvent event) {
    if (!_accept(event.kind)) return;
    final List<Offset>? active = _activePoints;
    if (active == null) return;
    setState(() => active.add(_localPos(event.position)));
  }

  void _onUp(PointerUpEvent event) {
    if (!_accept(event.kind)) return;
    _commitStroke();
  }

  void _onCancel(PointerCancelEvent _) {
    // Discard in-progress stroke silently on cancel — never submit.
    setState(() => _activePoints = null);
  }

  void _commitStroke() {
    final List<Offset>? active = _activePoints;
    if (active == null || active.isEmpty) return;
    setState(() {
      _completedStrokes
        ..clear()
        ..add(active);
      _activePoints = null;
    });
    // Forward to the caller for scoring — points are never stored further.
    widget.onStrokeSubmitted(List<Offset>.unmodifiable(active));
  }

  // --- coordinate helper ---------------------------------------------------

  Offset _localPos(Offset global) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    return box.globalToLocal(global);
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: CustomPaint(
        painter: _CanvasPainter(
          referenceStrokes: widget.referenceStrokes,
          completedStrokes: _completedStrokes,
          activeStroke: _activePoints,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() {
    // Points are in-memory only — discard on dispose (T-03-01 / T-01-05).
    _activePoints = null;
    _completedStrokes.clear();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// _CanvasPainter — guide + start-dot + live ink
// ---------------------------------------------------------------------------

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({
    required this.referenceStrokes,
    required this.completedStrokes,
    required this.activeStroke,
  });

  final List<StrokeSpec> referenceStrokes;
  final List<List<Offset>> completedStrokes;
  final List<Offset>? activeStroke;

  // Tuned visual constants for the guide layer.
  static const double _guideStrokeWidth = 2.0;
  static const double _dashLength = 6.0;
  static const double _gapLength = 6.0;
  static const double _startDotRadius = 10.0;
  static const double _startDotInnerRadius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1. Resolve the reference geometry (S1-04 — one source of truth).
    final List<List<List<double>>> resolved =
        ReferencePath.resolve(referenceStrokes);

    if (resolved.isNotEmpty) {
      // 2. Build a single dart:ui Path scaled to this canvas size, joining
      //    all strokes in draw order.
      final Path guidePath = _buildScaledPath(resolved, size);

      // 3. Paint the dotted guide under the ink.
      _paintDottedPath(canvas, guidePath);

      // 4. Gold start-dot at the very first reference point.
      _paintStartDot(canvas, resolved.first.first, size);
    }

    // 5. Paint completed and active ink strokes on top of the guide.
    final Paint inkPen = Paint()
      ..color = QalamColors.inkStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = QalamInk.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final List<Offset> stroke in completedStrokes) {
      _paintStroke(canvas, stroke, inkPen);
    }
    final List<Offset>? active = activeStroke;
    if (active != null) {
      _paintStroke(canvas, active, inkPen);
    }
  }

  // Build a Path from normalized 0..1 reference coords scaled to [size].
  Path _buildScaledPath(List<List<List<double>>> resolved, Size size) {
    final Path path = Path();
    bool firstStroke = true;
    for (final List<List<double>> stroke in resolved) {
      if (stroke.isEmpty) continue;
      final Offset start = _scale(stroke.first, size);
      if (firstStroke) {
        path.moveTo(start.dx, start.dy);
        firstStroke = false;
      } else {
        // Lift pen between separate strokes (e.g. baa body + dot).
        path.moveTo(start.dx, start.dy);
      }
      for (int i = 1; i < stroke.length; i++) {
        final Offset pt = _scale(stroke[i], size);
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }

  // Scale a normalized [0..1, 0..1] point to canvas pixel coordinates.
  Offset _scale(List<double> normalizedPoint, Size size) {
    return Offset(normalizedPoint[0] * size.width, normalizedPoint[1] * size.height);
  }

  // Draw the guide as a dashed/dotted line using PathMetrics.
  void _paintDottedPath(Canvas canvas, Path path) {
    final Paint guidePaint = Paint()
      ..color = QalamColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = _guideStrokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool drawing = true;
      while (distance < metric.length) {
        final double segmentLength = drawing ? _dashLength : _gapLength;
        final double end =
            (distance + segmentLength).clamp(0.0, metric.length);
        if (drawing) {
          canvas.drawPath(metric.extractPath(distance, end), guidePaint);
        }
        distance += segmentLength;
        drawing = !drawing;
      }
    }
  }

  // Paint the gold start-dot (reward color — REWARDS ONLY; see UI-SPEC Color).
  void _paintStartDot(
    Canvas canvas,
    List<double> normalizedPoint,
    Size size,
  ) {
    final Offset center = _scale(normalizedPoint, size);

    // Outer filled circle.
    canvas.drawCircle(
      center,
      _startDotRadius,
      Paint()
        ..color = QalamColors.reward
        ..style = PaintingStyle.fill,
    );
    // Inner white circle to create a ring effect.
    canvas.drawCircle(
      center,
      _startDotInnerRadius,
      Paint()
        ..color = QalamColors.bg
        ..style = PaintingStyle.fill,
    );
  }

  /// Draws one stroke as a quadratic-smoothed path (midpoint smoothing).
  /// Verbatim from practice_screen.dart _InkPainter._paintStroke (lines 298-321).
  void _paintStroke(Canvas canvas, List<Offset> points, Paint pen) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawPoints(PointMode.points, points, pen);
      return;
    }

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];
      final Offset mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, pen);
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) =>
      oldDelegate.referenceStrokes != referenceStrokes ||
      oldDelegate.completedStrokes != completedStrokes ||
      oldDelegate.activeStroke != activeStroke;
}
