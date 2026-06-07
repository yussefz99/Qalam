// JourneyPathPainter — winding snake path CustomPainter (Phase 03.1, plan 02).
//
// Draws two layers:
//   1. Full grey trail — the entire winding path from Alif to the checkpoint.
//   2. Green completed-trail overlay — covers the path from the first letter
//      through `completedCount` letters (Row 1 only in Phase 03.1 mock state).
//
// Canvas coordinate space: 1180 × 816 logical pixels.
// Path coordinates match the SVG in journey_preview.html exactly.

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';

/// CustomPainter that draws the winding path on the Journey Map canvas.
///
/// [completedCount] — the number of letters marked complete (0–28).
/// For Phase 03.1 mock data this is always 3 (alif, baa, taa mastered).
class JourneyPathPainter extends CustomPainter {
  const JourneyPathPainter({required this.completedCount});

  final int completedCount;

  // Node X positions for 7 columns across 1180px (matches journey_preview.html).
  static const List<double> _kXPositions = [
    85.0,
    254.0,
    422.0,
    590.0,
    758.0,
    926.0,
    1094.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // ── Grey full trail ──────────────────────────────────────────────────────
    final greyPaint = Paint()
      ..color = QalamColors.border // #D6E8E8 aqua-edge
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final greyPath = _buildFullPath();
    canvas.drawPath(greyPath, greyPaint);

    // ── Green completed-trail overlay ────────────────────────────────────────
    if (completedCount <= 0) return;

    // For Phase 03.1: completedCount is always ≤ 7 (all on Row 1).
    // Row 1 runs R→L: letter 0 (Alif) at x=1094, letter 1 (Baa) at x=926, etc.
    // The green trail is a horizontal line from (1094, 160) to the x-position
    // of the last completed letter.
    //
    // In the mock state (completedCount=3): green from (1094,160) to (758,160).
    // Stop at the last *complete* node — Taa at index 2 (x=758). Thaa (index 3)
    // is CURRENT, not complete, so we draw up to index (completedCount - 1).
    final clampedCount = completedCount.clamp(0, 7);
    // Letter index of the last complete node in Row 1 (0-based).
    // Row 1 is R→L: letter at position p has x = _kXPositions[6 - p].
    // Last complete node index = clampedCount - 1.
    final lastCompleteIndex = clampedCount - 1; // 0-based index in Row 1 (p)
    final endX = _kXPositions[6 - lastCompleteIndex];

    final greenPath = Path()
      ..moveTo(1094.0, 160.0)
      ..lineTo(endX, 160.0);

    final greenPaint = Paint()
      ..color = QalamColors.success.withValues(alpha: 0.6) // #3FB984 leaf at 60%
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(greenPath, greenPaint);
  }

  /// Builds the full winding trail from Alif (1094,160) to the checkpoint
  /// (590,660), matching the SVG path in journey_preview.html exactly.
  Path _buildFullPath() {
    return Path()
      // Row 1 (y=160): start at Alif (right), go left to the row-end turn
      ..moveTo(1094.0, 160.0)
      ..lineTo(125.0, 160.0)
      ..quadraticBezierTo(85.0, 160.0, 85.0, 200.0)
      // Transition column: down from Row 1 to Row 2
      ..lineTo(85.0, 250.0)
      ..quadraticBezierTo(85.0, 290.0, 125.0, 290.0)
      // Row 2 (y=290): left to right
      ..lineTo(1054.0, 290.0)
      ..quadraticBezierTo(1094.0, 290.0, 1094.0, 330.0)
      // Transition column: down from Row 2 to Row 3
      ..lineTo(1094.0, 380.0)
      ..quadraticBezierTo(1094.0, 420.0, 1054.0, 420.0)
      // Row 3 (y=420): right to left
      ..lineTo(125.0, 420.0)
      ..quadraticBezierTo(85.0, 420.0, 85.0, 460.0)
      // Transition column: down from Row 3 to Row 4
      ..lineTo(85.0, 510.0)
      ..quadraticBezierTo(85.0, 550.0, 125.0, 550.0)
      // Row 4 (y=550): left to right to checkpoint curve
      ..lineTo(1094.0, 550.0)
      // Cubic bezier to checkpoint at (590, 660)
      ..cubicTo(1094.0, 625.0, 840.0, 660.0, 590.0, 660.0);
  }

  @override
  bool shouldRepaint(JourneyPathPainter oldDelegate) =>
      oldDelegate.completedCount != completedCount;
}
