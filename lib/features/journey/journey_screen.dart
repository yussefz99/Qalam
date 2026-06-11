// JourneyScreen — full winding-path Journey Map (Phase 03.1, plan 02/03).
//
// Replaces the plan 01 placeholder. Renders 28 Arabic letter nodes on a
// fixed 1180×816 canvas with:
//   - JourneyPathPainter (grey trail + green completed overlay)
//   - 28 Positioned JourneyNodeWidget nodes with 4 visual states
//     (complete/current/future/locked) and pulse glow animation on current
//   - Level 1 Quiz checkpoint box below Row 4
//   - Level 2 locked banner at the bottom
//
// ANTI-GAMIFICATION INVARIANTS (D-23/D-24 — enforced by design review):
//   - No running star counter, no streak, no "+N" copy anywhere.
//   - No QalamColors.reward use outside of JourneyNodeWidget star badges.
//   - Stars appear ONLY as ★★★ badge on complete nodes — mastery info, not score.
//
// Data source: mockJourneyProgressProvider (mock, Phase 03.1 — real wiring in Phase 6).
// Layout: NO vertical scrolling; all 28 nodes fit on one screen (D-09).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/journey_progress.dart';
import '../../providers/journey_providers.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import 'widgets/journey_node_widget.dart';
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
  const JourneyScreen({super.key, this.highlightId});

  /// The just-mastered letter id from the route's `?highlight=` query param
  /// (D-15). Stored but intentionally UNUSED until plan 06-06 wires the
  /// highlight star into the live journey map — do not consume it before then.
  final String? highlightId;

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
              _buildNode(context, i, _kLetters[i], progress),
            ],

            // ── Level 1 Quiz checkpoint (D-19) ──────────────────────────────
            // Centered at x=590, y=660. Box width ≈ 280px → left = 590 - 140 = 450.
            // Box height ≈ 52px → top = 660 - 26 = 634.
            Positioned(
              left: 450,
              top: 634,
              child: const _CheckpointBox(),
            ),
            // Subtext below the checkpoint box.
            Positioned(
              left: 0,
              right: 0,
              top: 694,
              child: Center(
                child: Text(
                  'Complete all 28 letters to unlock',
                  style: QalamTextStyles.label.copyWith(
                    color: QalamColors.fgMuted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // ── Level 2 locked banner (D-20) ────────────────────────────────
            // Centered at x=590, y=752. Width=400 → left = 590 - 200 = 390.
            // Height ≈ 70px → top = 752 - 35 = 717.
            Positioned(
              left: 390,
              top: 717,
              child: Opacity(
                opacity: 0.72,
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: QalamColors.bgDeep,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: QalamColors.borderSoft,
                      width: 2,
                    ),
                    // TODO(03.1): dashed border for fidelity
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 28,
                        color: QalamColors.fgMuted,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level 2 — Words',
                              style: QalamTextStyles.heading.copyWith(
                                color: QalamColors.fgMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Unlocks after completing the Level 1 Quiz',
                              style: QalamTextStyles.label.copyWith(
                                color: QalamColors.fgMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Back to Home button (last = on top for hit testing) ─────────
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_rounded),
                color: QalamColors.primary,
                iconSize: 28,
                style: IconButton.styleFrom(
                  backgroundColor: QalamColors.primaryTint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(QalamRadii.md),
                  ),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a Positioned node widget for the letter at [index].
  Widget _buildNode(
    BuildContext context,
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
      child: JourneyNodeWidget(
        glyph: letter.glyph,
        name: letter.name,
        state: state,
        onTap: (state == JourneyNodeState.complete ||
                state == JourneyNodeState.current)
            ? () => context.go('/practice')
            : null,
      ),
    );
  }
}

// ── _CheckpointBox ────────────────────────────────────────────────────────────

/// Level 1 Quiz checkpoint box — locked until all 28 letters are mastered.
/// Positioned below Row 4 near y=660 (D-19).
class _CheckpointBox extends StatelessWidget {
  const _CheckpointBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      decoration: BoxDecoration(
        color: QalamColors.bgDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QalamColors.borderSoft, width: 2),
        boxShadow: const [
          BoxShadow(color: QalamColors.borderSoft, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: QalamColors.fgMuted,
          ),
          const SizedBox(width: 10),
          Text(
            'Level 1 Quiz',
            style: QalamTextStyles.heading.copyWith(
              color: QalamColors.fgMuted,
            ),
          ),
        ],
      ),
    );
  }
}

