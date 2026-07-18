// StrokeCanvas — the Phase-3 interactive trace surface (plan 03-03).
//
// Captures stylus (and, in debug, finger) strokes via a Listener widget —
// NOT a GestureDetector (Pitfall 2 from research). Renders:
//   1. A dotted guide path drawn from the typed referenceStrokes' BODY strokes
//      using a CustomPainter + PathMetrics — NOT Text('ا') (Pitfall 5 / S1-04).
//   2. A calm filled ink circle for each `type == "dot"` stroke (plan 06-10) so
//      the child sees where the dot goes (dots have no length, so they are kept
//      out of the dotted-path metric loop).
//   3. A gold start-dot at the first reference point.
//   4. Live smoothed ink over the guide, reusing the proven quadratic-midpoint
//      painter from practice_screen.dart verbatim.
//
// Input filter (_accept): stylus always accepted; touch accepted only when
// kDebugMode AND acceptTouch are both true (D-13/D-14, Pitfall 5).
//
// SECURITY (T-03-01 / T-01-05): captured points live IN MEMORY ONLY, in
// widget State. They are never printed, logged, or persisted. Points are
// discarded on dispose and on every pointer-cancel. Only the completed
// strokes are forwarded once via onStrokeSubmitted / onLetterComplete; the
// caller scores and then discards them. Plan 04-04 widened this from a
// single-stroke surface to a whole-letter accumulating surface (no
// per-pointer-down clear) so a multi-stroke letter (baa = boat + dot) survives
// to scoreLetter; the accumulated List<List<Offset>> is still in-memory-only.

import 'dart:ui' show PathMetric, PointMode;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../../config/debug_flags.dart';
import '../../../models/letter.dart';
import 'guide_geometry.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';

/// Interactive trace canvas.
///
/// The parent hands in the letter's [referenceStrokes] (from the curriculum
/// data) and stroke callbacks. The canvas ACCUMULATES a whole multi-stroke
/// letter: each time the child lifts the stylus, the finished stroke is appended
/// (and [onStrokeSubmitted] fires for any immediate per-stroke feedback). Once
/// the child has drawn as many strokes as the reference has
/// ([referenceStrokes.length] — the letter-complete signal, Open Q1), the whole
/// accumulated letter is forwarded once via [onLetterComplete] for scoreLetter.
///
/// Prior strokes are NEVER discarded on a new pointer-down (the Plan 04-04 fix to
/// the single-stroke accumulation bug) — so baa's boat survives while the child
/// draws its dot.
/// Imperative handle for a [StrokeCanvas] — lets the exercise engine CLEAR the
/// child's ink and force a SUBMIT (score whatever is drawn so far). For
/// write-mode exercises (no reference strokes) the count-reached auto-complete
/// never fires, so [submit] is the ONLY way to trigger scoring; for trace mode
/// it is an explicit "I'm done" alongside the automatic completion.
class StrokeCanvasController {
  Object? _owner;
  VoidCallback? _onClear;
  VoidCallback? _onSubmit;

  void _attach(Object owner,
      {required VoidCallback onClear, required VoidCallback onSubmit}) {
    _owner = owner;
    _onClear = onClear;
    _onSubmit = onSubmit;
  }

  void _detach(Object owner) {
    // Only the state that currently owns the callbacks may clear them — guards
    // against a stale dispose racing a fresh attach when the canvas key changes.
    if (identical(_owner, owner)) {
      _owner = null;
      _onClear = null;
      _onSubmit = null;
    }
  }

  /// Clear all ink (in-progress + accumulated) so the child can start over.
  void clear() => _onClear?.call();

  /// Submit the strokes drawn so far for scoring (no-op if nothing is drawn).
  void submit() => _onSubmit?.call();
}

class StrokeCanvas extends StatefulWidget {
  const StrokeCanvas({
    super.key,
    required this.referenceStrokes,
    this.onStrokeSubmitted,
    this.onLetterComplete,
    this.controller,
    this.acceptTouch = DebugFlags.allowFingerInput,
  });

  /// Optional imperative handle for clear / submit (the exercise engine wires
  /// the scaffold's Clear and Done buttons through this).
  final StrokeCanvasController? controller;

  /// The letter's authored strokes (source: curriculum letters.json).
  /// The painter iterates these directly: body (line/curve) strokes draw the
  /// dotted guide; `type == "dot"` strokes draw a calm ink circle (plan 06-10).
  /// Still S1-04 one-source-of-truth — same authored data the scorer consumes.
  final List<StrokeSpec> referenceStrokes;

  /// Called on each pointer-up with the single completed stroke the child just
  /// drew, for optional immediate per-stroke feedback. Optional — a caller that
  /// only wants whole-letter verdicts can supply [onLetterComplete] alone.
  /// The caller is responsible for scoring and then discarding the points.
  final void Function(List<Offset> points)? onStrokeSubmitted;

  /// Called ONCE the accumulated stroke count reaches [referenceStrokes.length]
  /// (the letter-complete signal), with the whole multi-stroke letter for
  /// scoreLetter. Each element is one completed stroke's local Offsets, in draw
  /// order. The caller scores the whole letter and then discards the points.
  final void Function(List<List<Offset>> strokes)? onLetterComplete;

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

  /// Completed strokes ACCUMULATED for the whole letter (in-memory only,
  /// T-03-01 / T-01-05). NOT cleared on each new pointer-down — a multi-stroke
  /// letter (baa = boat + dot) accumulates here until the letter-complete signal.
  final List<List<Offset>> _completedStrokes = <List<Offset>>[];

  /// True once [onLetterComplete] has fired for this letter, so we never
  /// double-fire if an extra stroke somehow arrives after completion.
  bool _letterComplete = false;

  // --- imperative clear / submit (via StrokeCanvasController) ---------------

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this, onClear: _clearInk, onSubmit: _submitNow);
  }

  @override
  void didUpdateWidget(StrokeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this, onClear: _clearInk, onSubmit: _submitNow);
    }
  }

  /// Wipe all ink so the child can start the letter over (the engine's Clear /
  /// Try-again). Resets the letter-complete latch so scoring can fire again.
  void _clearInk() {
    if (!mounted) return;
    setState(() {
      _activePoints = null;
      _completedStrokes.clear();
      _letterComplete = false;
    });
  }

  /// Force a whole-letter submit of the strokes drawn so far — the only scoring
  /// trigger for write-mode exercises (no reference strokes to count against).
  /// No-op if nothing is drawn or the letter already scored.
  void _submitNow() {
    if (_letterComplete || _completedStrokes.isEmpty) return;
    _letterComplete = true;
    widget.onLetterComplete?.call(
      List<List<Offset>>.unmodifiable(
        _completedStrokes
            .map((List<Offset> s) => List<Offset>.unmodifiable(s))
            .toList(growable: false),
      ),
    );
  }

  // --- input filter --------------------------------------------------------

  /// Returns true if this pointer kind should be captured.
  /// Production: stylus only. Debug with acceptTouch: also finger/touch.
  bool _accept(PointerDeviceKind kind) {
    if (kind == PointerDeviceKind.stylus) return true;
    if (kDebugMode && widget.acceptTouch) {
      // Accept touch AND mouse in debug mode so emulator testing works.
      if (kind == PointerDeviceKind.touch || kind == PointerDeviceKind.mouse) {
        return true;
      }
    }
    return false;
  }

  // --- stroke lifecycle ----------------------------------------------------

  void _onDown(PointerDownEvent event) {
    if (!_accept(event.kind)) return;
    final Offset local = _localPos(event.position);
    setState(() {
      // ACCUMULATE — do NOT clear prior strokes (Plan 04-04 fix). A multi-stroke
      // letter keeps every completed stroke until the letter-complete signal;
      // the parent clears the canvas (via a fresh key) between letters.
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
      // APPEND the finished stroke to the whole-letter accumulation — never
      // clear (Plan 04-04). The painter repaints all accumulated strokes.
      _completedStrokes.add(active);
      _activePoints = null;
    });

    // Optional immediate per-stroke feedback — points are never stored further.
    widget.onStrokeSubmitted?.call(List<Offset>.unmodifiable(active));

    // Letter-complete signal (Open Q1 — count-reached): once the child has drawn
    // as many strokes as the reference has, forward the WHOLE accumulated letter
    // once for scoreLetter. Guarded against double-fire.
    final int expected = widget.referenceStrokes.length;
    if (!_letterComplete &&
        expected > 0 &&
        _completedStrokes.length >= expected) {
      _letterComplete = true;
      widget.onLetterComplete?.call(
        List<List<Offset>>.unmodifiable(
          _completedStrokes
              .map((List<Offset> s) => List<Offset>.unmodifiable(s))
              .toList(growable: false),
        ),
      );
    }
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
    widget.controller?._detach(this);
    // Points are in-memory only — discard on dispose (T-03-01 / T-01-05).
    _activePoints = null;
    _completedStrokes.clear();
    _letterComplete = false;
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

  /// Radius of a rendered `type == "dot"` guide circle — ~the ink stroke width
  /// so the child sees a deliberate, calm ink dot where the tap goes (plan
  /// 06-10). Ink-colored, NOT gold (gold stays reward-exclusive).
  static const double _inkDotRadius = QalamInk.strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1. Split the TYPED reference strokes into body (line/curve) vs dot.
    //    We read StrokeSpec.type DIRECTLY — ReferencePath.resolve deliberately
    //    discards `type`, and a single-point dot would otherwise become a
    //    zero-length subpath the dotted-path PathMetric loop never draws.
    final List<StrokeSpec> ordered = <StrokeSpec>[...referenceStrokes]
      ..sort((StrokeSpec a, StrokeSpec b) => a.order.compareTo(b.order));
    final List<StrokeSpec> bodyStrokes = ordered
        .where((StrokeSpec s) => s.type != 'dot' && s.points.isNotEmpty)
        .toList(growable: false);
    final List<StrokeSpec> dotStrokes = ordered
        .where((StrokeSpec s) => s.type == 'dot' && s.points.isNotEmpty)
        .toList(growable: false);

    if (bodyStrokes.isNotEmpty) {
      // 2. Build a single dart:ui Path (body strokes only) scaled to this
      //    canvas size, joining all body strokes in draw order.
      final Path guidePath = _buildScaledPath(bodyStrokes, size);

      // 3. Paint the dotted guide under the ink.
      _paintDottedPath(canvas, guidePath);
    }

    // 4. Paint each dot as a calm filled ink circle so the child sees where
    //    the dot goes while tracing (e.g. baa below, taa's two dots above).
    if (dotStrokes.isNotEmpty) {
      final Paint inkDotPaint = Paint()
        ..color = QalamColors.inkStroke
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      for (final StrokeSpec dot in dotStrokes) {
        canvas.drawCircle(_scale(dot.points.first, size), _inkDotRadius,
            inkDotPaint);
      }
    }

    // 5. Gold start-dot at the very first reference point (body first, else
    //    the first dot for a dot-only letter).
    final List<double>? startPoint = bodyStrokes.isNotEmpty
        ? bodyStrokes.first.points.first
        : (dotStrokes.isNotEmpty ? dotStrokes.first.points.first : null);
    if (startPoint != null) {
      _paintStartDot(canvas, startPoint, size);
    }

    // 6. Paint completed and active ink strokes on top of the guide.
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

  // Build a Path from typed BODY strokes (dots excluded) scaled to [size].
  // Dot strokes are NEVER added here — a single-point dot would become a
  // zero-length subpath the dotted-path metric loop never draws (plan 06-10).
  Path _buildScaledPath(List<StrokeSpec> bodyStrokes, Size size) {
    final Path path = Path();
    for (final StrokeSpec stroke in bodyStrokes) {
      if (stroke.points.isEmpty) continue;
      // Lift pen between separate strokes (each body stroke starts with moveTo).
      final Offset start = _scale(stroke.points.first, size);
      path.moveTo(start.dx, start.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        final Offset pt = _scale(stroke.points[i], size);
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }

  // Scale a normalized [0..1, 0..1] point to canvas pixel coordinates.
  // UNIFORM centered scale via the shared helper — NEVER a per-axis stretch
  // (the taa/thaa trace-unpassable root cause; see guide_geometry.dart).
  Offset _scale(List<double> normalizedPoint, Size size) =>
      scaleNormalizedPoint(normalizedPoint, size);

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
