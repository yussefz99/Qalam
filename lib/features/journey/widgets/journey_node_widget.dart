// JourneyNodeWidget — animated letter node for the Journey Map screen.
//
// Extracted from journey_screen.dart so the AnimationController for the
// teal pulse glow can live inside a StatefulWidget with its own vsync.
//
// ANTI-GAMIFICATION INVARIANTS (D-13/D-23/D-24):
//   - QalamColors.reward used ONLY for the gold ★★★ badge on complete nodes.
//   - NO running star counter, NO "+N", NO streak copy anywhere in this widget.
//   - The ★★★ badge is mastery information, not a score.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/journey_progress.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';

// ── JourneyNodeWidget ─────────────────────────────────────────────────────────

/// A single letter node on the Journey Map with animated pulse glow (current
/// state), gold star badge (complete state), and tap handling.
///
/// [onTap] is null for future/locked nodes — GestureDetector is inert when
/// onTap is null, so no explicit disable logic is required.
class JourneyNodeWidget extends StatefulWidget {
  const JourneyNodeWidget({
    super.key,
    required this.glyph,
    required this.name,
    required this.state,
    required this.onTap,
    this.starSettleScale,
    this.starSettleOpacity,
  });

  final String glyph;
  final String name;
  final JourneyNodeState state;

  /// Callback for tap events. Pass null for future/locked nodes to disable.
  final VoidCallback? onTap;

  /// D-15 highlight arrival (plan 06-06): when provided (and the node is
  /// complete), the gold ★★★ badge renders inside Scale/Fade transitions
  /// driven by these animations — the "settling star" moment for the
  /// just-mastered node. The ANIMATION (controller, durCheer, easeSoftBack)
  /// is owned by JourneyScreen; this widget is render-only. Null = static
  /// badge (every node except the highlighted one).
  final Animation<double>? starSettleScale;
  final Animation<double>? starSettleOpacity;

  @override
  State<JourneyNodeWidget> createState() => _JourneyNodeWidgetState();
}

class _JourneyNodeWidgetState extends State<JourneyNodeWidget>
    with SingleTickerProviderStateMixin {
  // Pulse glow — only active when state == JourneyNodeState.current.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseSpread; // spread radius lerps 0 → 14

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseSpread = Tween<double>(begin: 0.0, end: 14.0).animate(
      CurvedAnimation(parent: _pulseController, curve: QalamMotion.easeInOut),
    );
    if (widget.state == JourneyNodeState.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(JourneyNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == JourneyNodeState.current) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _circleColor() {
    switch (widget.state) {
      case JourneyNodeState.complete:
        return QalamColors.success;
      case JourneyNodeState.current:
        return QalamColors.primary;
      case JourneyNodeState.future:
        return QalamColors.surfaceRaised; // white
      case JourneyNodeState.locked:
        return const Color(0xFFCDD8DA); // warm grey — no semantic token
    }
  }

  List<BoxShadow> _buildShadow() {
    switch (widget.state) {
      case JourneyNodeState.complete:
        return const [
          BoxShadow(color: Color(0xFF2A8A60), offset: Offset(0, 5)),
        ];
      case JourneyNodeState.current:
        return [
          const BoxShadow(
            color: QalamColors.primaryPressed,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: QalamColors.primary.withValues(alpha: 0.45),
            blurRadius: _pulseSpread.value,
            spreadRadius: _pulseSpread.value,
          ),
        ];
      case JourneyNodeState.future:
      case JourneyNodeState.locked:
        return const [];
    }
  }

  Color _glyphColor() {
    switch (widget.state) {
      case JourneyNodeState.complete:
      case JourneyNodeState.current:
        return Colors.white;
      case JourneyNodeState.future:
      case JourneyNodeState.locked:
        return QalamColors.fgMuted;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  Widget _buildCircle(Widget glyphChild) {
    final circle = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _circleColor(),
        boxShadow: _buildShadow(),
      ),
      alignment: Alignment.center,
      child: glyphChild,
    );

    if (widget.state == JourneyNodeState.future) {
      // Overlay the dashed border via CustomPaint on top of the solid circle.
      return SizedBox(
        width: 68,
        height: 68,
        child: CustomPaint(
          painter: DashedCirclePainter(),
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QalamColors.surfaceRaised,
            ),
            alignment: Alignment.center,
            child: glyphChild,
          ),
        ),
      );
    }

    return circle;
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = widget.state == JourneyNodeState.future ||
        widget.state == JourneyNodeState.locked;

    final glyphChild = ArabicText(
      widget.glyph,
      style: TextStyle(
        fontSize: 32,
        height: 1,
        color: _glyphColor(),
        fontFamily: QalamFonts.arabicDisplay,
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // TODAY pill — current node only, positioned above the circle.
              if (widget.state == JourneyNodeState.current)
                const Positioned(
                  top: -28,
                  child: _TodayChip(),
                ),
              // Animated node circle (pulse glow driven by _pulseSpread).
              AnimatedBuilder(
                animation: _pulseSpread,
                builder: (context, child) => _buildCircle(child!),
                child: glyphChild,
              ),
              // Gold ★★★ badge — complete nodes ONLY (D-13, REWARDS ONLY).
              // With a settle animation (D-15 highlight arrival) the badge
              // scales/fades in once; otherwise it renders statically.
              if (widget.state == JourneyNodeState.complete)
                Positioned(
                  top: -4,
                  right: -5,
                  child: widget.starSettleScale != null
                      ? FadeTransition(
                          key: const Key('journeyHighlightSettle'),
                          opacity: widget.starSettleOpacity ??
                              kAlwaysCompleteAnimation,
                          child: ScaleTransition(
                            scale: widget.starSettleScale!,
                            child: const _StarBadge(),
                          ),
                        )
                      : const _StarBadge(),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            widget.name,
            style: QalamTextStyles.label.copyWith(
              color: isMuted ? QalamColors.fgMuted : QalamColors.fg,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── DashedCirclePainter ───────────────────────────────────────────────────────

/// CustomPainter that draws a dashed circle border for future nodes.
///
/// Moved here from journey_screen.dart so both the screen and the widget can
/// share this painter without duplicating the implementation.
///
/// Divides the circumference into alternating dash/gap arcs via [Canvas.drawArc].
class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter();

  static const double _dashLength = 6.0;
  static const double _gapLength = 4.0;
  static const double _strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide / 2) - (_strokeWidth / 2);
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;

    final dashAngle = (_dashLength / circumference) * 2 * math.pi;
    final gapAngle = (_gapLength / circumference) * 2 * math.pi;
    final stepAngle = dashAngle + gapAngle;

    final paint = Paint()
      ..color = QalamColors.border // aqua-edge #D6E8E8
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Start from the top (−π/2) and draw dashes around the full circle.
    var startAngle = -math.pi / 2;
    while (startAngle < -math.pi / 2 + 2 * math.pi) {
      canvas.drawArc(rect, startAngle, dashAngle, false, paint);
      startAngle += stepAngle;
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter oldDelegate) => false;
}

// ── _TodayChip ────────────────────────────────────────────────────────────────

/// "TODAY" pill label shown above the current letter node.
///
/// Moved here from journey_screen.dart so the node widget owns it.
class _TodayChip extends StatelessWidget {
  const _TodayChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
      ),
      child: const Text(
        'TODAY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          fontFamily: QalamFonts.body,
        ),
      ),
    );
  }
}

// ── _StarBadge ────────────────────────────────────────────────────────────────

/// Gold ★★★ mastery badge for complete nodes.
///
/// QalamColors.reward (gold) is used ONLY here — mastery information, not score.
/// No use of QalamColors.reward is permitted elsewhere on the Journey screen (D-13).
class _StarBadge extends StatelessWidget {
  const _StarBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _Star(),
        _Star(),
        _Star(),
      ],
    );
  }
}

/// A single 11×11 gold star in the mastery badge.
class _Star extends StatelessWidget {
  const _Star();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(11, 11),
      painter: _StarPainter(color: QalamColors.reward),
    );
  }
}

// ── _StarPainter ──────────────────────────────────────────────────────────────

/// Paints a single 5-pointed star in [color].
///
/// Path math copied from mastery_celebration.dart (_StarPainter) — the single
/// source of truth for the 5-pointed star geometry in the Qalam design system.
/// QalamColors.reward (gold) must be the only non-neutral color passed to this
/// painter from the Journey screen (D-13, REWARDS ONLY).
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerR = size.width / 2;
    final double innerR = outerR * 0.4;

    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      // Alternate outer and inner vertices.
      final double r = i.isEven ? outerR : innerR;
      final double angle = (math.pi / 5) * i - math.pi / 2;
      final double x = cx + r * math.cos(angle);
      final double y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}
