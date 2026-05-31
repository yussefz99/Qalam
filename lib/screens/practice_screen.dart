// PracticeScreen — the Phase-1 stylus spike (plan 01-03).
//
// The ONLY interactive P1 screen. It de-risks the ink-rendering treatment: live
// freehand ink that reads as real ink on parchment. A CustomPainter draws
// smoothed strokes (deep-ink #0E5B5F, width 6, round caps/joins, quadratic
// smoothing, anti-aliased) over a parchment canvas inset on a soft-aqua framed
// card; a single Clear action (guarded by the "Clear your writing?" confirm)
// wipes the page.
//
// OUT OF SCOPE — deliberately NOT built here (all P3+): the dotted guide letter,
// stroke-order animation, per-stroke correctness feedback, failing-stroke
// highlight, the mastery marker, confetti, and palm/finger rejection. This spike
// captures all pointers and renders raw ink — nothing more.
//
// SECURITY (threat T-01-05): captured stroke points live IN MEMORY ONLY. They
// are never persisted, logged, or transmitted, and are discarded on Clear and on
// navigation away (State is disposed). Phase 1 stores no stroke data.
//
// NO red, no red X, no gamification, no emoji/pseudo-icons (D-13). All copy comes
// from gen-l10n AppLocalizations; colors are semantic tokens only.

import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  /// Completed strokes (each a list of sampled local points) + the in-progress
  /// stroke. In-memory only — discarded on Clear and on dispose (T-01-05).
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _activeStroke;

  bool get _hasInk => _strokes.isNotEmpty || _activeStroke != null;

  void _startStroke(Offset localPosition) {
    setState(() {
      _activeStroke = <Offset>[localPosition];
    });
  }

  void _extendStroke(Offset localPosition) {
    final List<Offset>? active = _activeStroke;
    if (active == null) return;
    setState(() {
      active.add(localPosition);
    });
  }

  void _endStroke() {
    final List<Offset>? active = _activeStroke;
    if (active == null) return;
    setState(() {
      _strokes.add(active);
      _activeStroke = null;
    });
  }

  void _clearAll() {
    setState(() {
      _strokes.clear();
      _activeStroke = null;
    });
  }

  Future<void> _confirmClear() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ClearConfirmDialog(l10n: l10n),
    );
    if (shouldClear ?? false) {
      _clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.writeHere),
        actions: <Widget>[
          // Clear is enabled only when there is ink to clear.
          TextButton(
            onPressed: _hasInk ? _confirmClear : null,
            child: Text(
              l10n.clear,
              style: QalamTextStyles.button.copyWith(
                fontSize: QalamFontSizes.fz20,
                color: _hasInk ? QalamColors.primary : QalamColors.fgMuted,
              ),
            ),
          ),
          const SizedBox(width: QalamSpace.space4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(QalamSpace.space8),
        child: _InkCard(
          hasInk: _hasInk,
          emptyHeading: l10n.writeHere,
          emptyBody: l10n.practiceEmptyBody,
          strokes: _strokes,
          activeStroke: _activeStroke,
          onStrokeStart: _startStroke,
          onStrokeUpdate: _extendStroke,
          onStrokeEnd: _endStroke,
        ),
      ),
    );
  }
}

/// The soft-aqua framed card holding the parchment ink canvas.
class _InkCard extends StatelessWidget {
  const _InkCard({
    required this.hasInk,
    required this.emptyHeading,
    required this.emptyBody,
    required this.strokes,
    required this.activeStroke,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
  });

  final bool hasInk;
  final String emptyHeading;
  final String emptyBody;
  final List<List<Offset>> strokes;
  final List<Offset>? activeStroke;
  final ValueChanged<Offset> onStrokeStart;
  final ValueChanged<Offset> onStrokeUpdate;
  final VoidCallback onStrokeEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Soft-aqua frame with the rounded card radius + soft elevation.
      decoration: BoxDecoration(
        color: QalamColors.surface, // soft-aqua
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: QalamShadows.shadowMd,
      ),
      padding: const EdgeInsets.all(QalamSpace.space4),
      child: ClipRRect(
        // The parchment writing ground, inset within the frame.
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        child: ColoredBox(
          color: QalamColors.bg, // parchment — never white
          child: _InkSurface(
            hasInk: hasInk,
            emptyHeading: emptyHeading,
            emptyBody: emptyBody,
            strokes: strokes,
            activeStroke: activeStroke,
            onStrokeStart: onStrokeStart,
            onStrokeUpdate: onStrokeUpdate,
            onStrokeEnd: onStrokeEnd,
          ),
        ),
      ),
    );
  }
}

/// Captures pointer input and paints the smoothed ink. Captures ALL pointers
/// (stylus-only rejection is P3); converts global → local before sampling.
class _InkSurface extends StatelessWidget {
  const _InkSurface({
    required this.hasInk,
    required this.emptyHeading,
    required this.emptyBody,
    required this.strokes,
    required this.activeStroke,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
  });

  final bool hasInk;
  final String emptyHeading;
  final String emptyBody;
  final List<List<Offset>> strokes;
  final List<Offset>? activeStroke;
  final ValueChanged<Offset> onStrokeStart;
  final ValueChanged<Offset> onStrokeUpdate;
  final VoidCallback onStrokeEnd;

  Offset _local(BuildContext context, Offset global) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent e) =>
          onStrokeStart(_local(context, e.position)),
      onPointerMove: (PointerMoveEvent e) =>
          onStrokeUpdate(_local(context, e.position)),
      onPointerUp: (PointerUpEvent e) => onStrokeEnd(),
      onPointerCancel: (PointerCancelEvent e) => onStrokeEnd(),
      child: CustomPaint(
        painter: _InkPainter(strokes: strokes, activeStroke: activeStroke),
        // Fill the available card space; show the empty-state prompt until the
        // child starts writing.
        child: SizedBox.expand(
          child: hasInk
              ? null
              : _EmptyPrompt(heading: emptyHeading, body: emptyBody),
        ),
      ),
    );
  }
}

/// The "Write Here" empty-state prompt, centered on the parchment.
class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(QalamSpace.space8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                heading,
                style: QalamTextStyles.heading.copyWith(
                  color: QalamColors.fgMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: QalamSpace.space4),
              Text(
                body,
                style: QalamTextStyles.body.copyWith(
                  color: QalamColors.fgMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints completed + in-progress strokes as smoothed ink paths.
class _InkPainter extends CustomPainter {
  _InkPainter({required this.strokes, required this.activeStroke});

  final List<List<Offset>> strokes;
  final List<Offset>? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = QalamColors.inkStroke // deep-ink #0E5B5F (--primary-pressed)
      ..style = PaintingStyle.stroke
      ..strokeWidth = QalamInk.strokeWidth // 6px, in the 4–8 range
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final List<Offset> stroke in strokes) {
      _paintStroke(canvas, stroke, pen);
    }
    final List<Offset>? active = activeStroke;
    if (active != null) {
      _paintStroke(canvas, active, pen);
    }
  }

  /// Draws one stroke as a quadratic-smoothed path through the sampled points
  /// (midpoint smoothing — not a raw polyline — to remove jitter).
  void _paintStroke(Canvas canvas, List<Offset> points, Paint pen) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      // A single tap: render a dot so the stroke is visible.
      canvas.drawPoints(PointMode.points, points, pen);
      return;
    }

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final Offset current = points[i];
      final Offset next = points[i + 1];
      // Curve to the midpoint between consecutive points, using the current
      // point as the control — Catmull-Rom-style quadratic smoothing.
      final Offset mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    // Finish the line into the final sampled point.
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, pen);
  }

  @override
  bool shouldRepaint(_InkPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.activeStroke != activeStroke;
}

/// The destructive "Clear your writing?" confirmation. Coral-tinted Clear (soft,
/// never red, never a red X) + a default Keep Writing dismiss.
class _ClearConfirmDialog extends StatelessWidget {
  const _ClearConfirmDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: QalamColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QalamRadii.xl),
      ),
      title: Text(l10n.clearConfirmHeading, style: QalamTextStyles.heading),
      content: Text(l10n.clearConfirmBody, style: QalamTextStyles.body),
      actions: <Widget>[
        // Non-destructive default.
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.keepWriting,
            style: QalamTextStyles.button.copyWith(
              fontSize: QalamFontSizes.fz20,
              color: QalamColors.primary,
            ),
          ),
        ),
        // Destructive, but warm: coral-tinted soft, never red.
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: QalamColors.warnSoftTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(QalamRadii.md),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space5,
              vertical: QalamSpace.space3,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.clear,
            style: QalamTextStyles.button.copyWith(
              fontSize: QalamFontSizes.fz20,
              color: QalamColors.warnSoft,
            ),
          ),
        ),
      ],
    );
  }
}
