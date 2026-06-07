// JourneyScreen — full winding-path Journey Map (Phase 03.1, plan 02).
//
// Replaces the plan 01 placeholder. Renders 28 Arabic letter nodes on a
// fixed 1180×816 canvas with:
//   - JourneyPathPainter (grey trail + green completed overlay)
//   - 28 Positioned letter nodes with 4 visual states (complete/current/future/locked)
//   - TODAY pill chip above the current node
//   - Level 1 header pill (top-center)
//
// Data source: mockJourneyProgressProvider (mock, Phase 03.1 — real wiring in Phase 6).
// Layout: NO vertical scrolling; all 28 nodes fit on one screen (D-09).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/journey_progress.dart';
import '../../providers/journey_providers.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/arabic_text.dart';
import 'widgets/journey_path_painter.dart';

// ── Letter record type ───────────────────────────────────────────────────────

typedef _LetterRecord = ({String id, String glyph, String name});

// ── All 28 Arabic letters in curriculum order ────────────────────────────────

const List<_LetterRecord> _kLetters = [
  (id: 'alif', glyph: 'ا', name: 'Alif'),
  (id: 'baa', glyph: 'ب', name: 'Baa'),
  (id: 'taa', glyph: 'ت', name: 'Taa'),
  (id: 'thaa', glyph: 'ث', name: 'Thaa'),
  (id: 'jeem', glyph: 'ج', name: 'Jeem'),
  (id: 'haa', glyph: 'ح', name: 'Haa'),
  (id: 'khaa', glyph: 'خ', name: 'Khaa'),
  (id: 'dal', glyph: 'د', name: 'Dal'),
  (id: 'dhal', glyph: 'ذ', name: 'Dhal'),
  (id: 'ra', glyph: 'ر', name: 'Ra'),
  (id: 'zay', glyph: 'ز', name: 'Zay'),
  (id: 'seen', glyph: 'س', name: 'Seen'),
  (id: 'sheen', glyph: 'ش', name: 'Sheen'),
  (id: 'saad', glyph: 'ص', name: 'Saad'),
  (id: 'daad', glyph: 'ض', name: 'Daad'),
  (id: 'tah', glyph: 'ط', name: 'Tah'),
  (id: 'dhah', glyph: 'ظ', name: 'Dhah'),
  (id: 'ain', glyph: 'ع', name: 'Ain'),
  (id: 'ghain', glyph: 'غ', name: 'Ghain'),
  (id: 'fa', glyph: 'ف', name: 'Fa'),
  (id: 'qaf', glyph: 'ق', name: 'Qaf'),
  (id: 'kaf', glyph: 'ك', name: 'Kaf'),
  (id: 'lam', glyph: 'ل', name: 'Lam'),
  (id: 'meem', glyph: 'م', name: 'Meem'),
  (id: 'noon', glyph: 'ن', name: 'Noon'),
  (id: 'ha', glyph: 'ه', name: 'Ha'),
  (id: 'waw', glyph: 'و', name: 'Waw'),
  (id: 'ya', glyph: 'ي', name: 'Ya'),
];

// ── Layout constants ─────────────────────────────────────────────────────────

/// X positions for 7 node columns across the 1180px canvas.
const List<double> _kXPositions = [
  85.0,
  254.0,
  422.0,
  590.0,
  758.0,
  926.0,
  1094.0,
];

/// Y positions for the 4 rows.
const List<double> _kRowY = [160.0, 290.0, 420.0, 550.0];

/// Compute pixel position for letter at [index] (0-based, 0=Alif).
///
/// Row 0 (0–6):   y=160, R→L — Alif at rightmost x.
/// Row 1 (7–13):  y=290, L→R.
/// Row 2 (14–20): y=420, R→L.
/// Row 3 (21–27): y=550, L→R.
Offset _nodePosition(int index) {
  final row = index ~/ 7;
  final col = index % 7;
  final y = _kRowY[row];
  // Even rows (0, 2): R→L — column 0 maps to x=1094 (rightmost).
  // Odd rows  (1, 3): L→R — column 0 maps to x=85  (leftmost).
  final x = row.isEven
      ? _kXPositions[6 - col]
      : _kXPositions[col];
  return Offset(x, y);
}

// ── JourneyScreen ─────────────────────────────────────────────────────────────

/// The Journey Map screen — the winding-path progress view for all 28 letters.
///
/// No vertical scrolling (D-09). Data from [mockJourneyProgressProvider] (D-05/D-06).
/// Anti-gamification: no star counters, no streaks, no "+N" copy (D-23/D-24).
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(mockJourneyProgressProvider);

    return Scaffold(
      backgroundColor: QalamColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Level 1 header pill ─────────────────────────────────────────
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: QalamColors.primaryTint,
                    border: Border.all(color: QalamColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(QalamRadii.pill),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Level 1',
                        style: QalamTextStyles.heading.copyWith(
                          color: QalamColors.primaryPressed,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'LETTERS',
                        style: QalamTextStyles.label.copyWith(
                          color: QalamColors.fgMuted,
                          letterSpacing: 1.2,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        color: QalamColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Text(
                        '${progress.masteredIds.length} of 28 mastered',
                        style: QalamTextStyles.body.copyWith(
                          color: QalamColors.fgMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Winding path (grey trail + green completed overlay) ─────────
            Positioned.fill(
              child: CustomPaint(
                painter: JourneyPathPainter(
                  completedCount: progress.masteredIds.length,
                ),
              ),
            ),

            // ── 28 letter nodes ─────────────────────────────────────────────
            for (var i = 0; i < _kLetters.length; i++) ...[
              _buildNode(i, _kLetters[i], progress),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a Positioned node widget for the letter at [index].
  Widget _buildNode(
    int index,
    _LetterRecord letter,
    JourneyProgress progress,
  ) {
    final pos = _nodePosition(index);
    final state = JourneyNodeState.compute(
      letter.id,
      progress.masteredIds,
      progress.currentId,
    );
    return Positioned(
      left: pos.dx - 34, // 34 = half of 68px node diameter
      top: pos.dy - 34,
      child: _JourneyNode(glyph: letter.glyph, name: letter.name, state: state),
    );
  }
}

// ── _JourneyNode ─────────────────────────────────────────────────────────────

/// A single letter node on the Journey Map.
class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.glyph,
    required this.name,
    required this.state,
  });

  final String glyph;
  final String name;
  final JourneyNodeState state;

  @override
  Widget build(BuildContext context) {
    final isMuted =
        state == JourneyNodeState.future || state == JourneyNodeState.locked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          // Extra height at top to accommodate the TODAY chip (28px above circle).
          height: state == JourneyNodeState.current ? 96 + 7.0 : 68 + 7.0,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // TODAY chip — only for current node, positioned above circle
              if (state == JourneyNodeState.current)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(child: _TodayChip()),
                ),
              // The 68px circle node
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(child: _NodeCircle(glyph: glyph, state: state)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          style: QalamTextStyles.label.copyWith(
            color: isMuted ? QalamColors.fgMuted : QalamColors.fg,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── _NodeCircle ───────────────────────────────────────────────────────────────

/// The 68×68 circular tile for a journey node.
class _NodeCircle extends StatelessWidget {
  const _NodeCircle({required this.glyph, required this.state});

  final String glyph;
  final JourneyNodeState state;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final List<BoxShadow> shadows;
    final Color glyphColor;

    switch (state) {
      case JourneyNodeState.complete:
        fill = QalamColors.success;
        shadows = const [
          BoxShadow(color: Color(0xFF2A8A60), offset: Offset(0, 5)),
        ];
        glyphColor = Colors.white;
      case JourneyNodeState.current:
        fill = QalamColors.primary;
        shadows = const [
          BoxShadow(color: QalamColors.primaryPressed, offset: Offset(0, 5)),
        ];
        glyphColor = Colors.white;
      case JourneyNodeState.future:
        // Future nodes use a dashed circle border via CustomPaint overlay.
        return SizedBox(
          width: 68,
          height: 68,
          child: CustomPaint(
            painter: _DashedCirclePainter(),
            child: Center(
              child: ArabicText(
                glyph,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1,
                  color: QalamColors.fgMuted,
                  fontFamily: QalamFonts.arabicDisplay,
                ),
              ),
            ),
          ),
        );
      case JourneyNodeState.locked:
        fill = const Color(0xFFCDD8DA); // warm grey — no semantic token
        shadows = const [];
        glyphColor = QalamColors.fgMuted;
    }

    // complete / current / locked — solid circle
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        boxShadow: shadows,
      ),
      child: Center(
        child: ArabicText(
          glyph,
          style: TextStyle(
            fontSize: 32,
            height: 1,
            color: glyphColor,
            fontFamily: QalamFonts.arabicDisplay,
          ),
        ),
      ),
    );
  }
}

// ── _DashedCirclePainter ──────────────────────────────────────────────────────

/// CustomPainter that draws a dashed circle border for future nodes.
///
/// Divides the circumference into alternating dash/gap arcs drawn via [Canvas.drawArc].
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

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
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}

// ── _TodayChip ────────────────────────────────────────────────────────────────

/// "TODAY" pill label shown above the current letter node.
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
