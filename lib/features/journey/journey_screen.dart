// JourneyScreen — full winding-path Journey Map (Phase 03.1; live data 06-06).
//
// Renders 28 Arabic letter nodes on a fixed 1180×816 canvas with:
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
//   - "N of 28 mastered" is quiet information, never gold, never celebrated.
//
// Data sources (plan 06-06 — 03.1's D-08 amended only by this data fix):
//   - journeyLettersProvider: the 28 letters from letters.json, canonical ids
//     BY CONSTRUCTION (the 03.1 hardcoded list drifted in 19/28 cases and
//     silently never lit — RESEARCH Pitfall 1).
//   - progressionProvider: live mastery + unlock snapshot. Mastered letters
//     light complete; today's letter pulses; skipped-but-unlocked letters
//     keep the future visual but are tappable (D-05/D-07); genuinely locked
//     letters stay inert and visibly unavailable (S1-09).
//
// Layout: NO vertical scrolling; all 28 nodes fit on one screen (D-09).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/journey_progress.dart';
import '../../models/lesson_progression.dart';
import '../../models/letter.dart';
import '../../providers/journey_providers.dart';
import '../../providers/progression_providers.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import 'widgets/journey_node_widget.dart';
import 'widgets/journey_path_painter.dart';

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
/// No vertical scrolling (D-09). Live data from [progressionProvider] +
/// [journeyLettersProvider] (plan 06-06).
/// Anti-gamification: no star counters, no streaks, no "+N" copy (D-23/D-24).
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key, this.highlightId});

  /// The just-mastered letter id from the route's `?highlight=` query param
  /// (D-15). When it matches a complete node, that node's gold star badge
  /// plays the settling recipe once on arrival (same recipe as the
  /// celebration star). Unknown/null → silent no-op (T-06-03 allowlist:
  /// the id must match a rendered node to have any effect).
  final String? highlightId;

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen>
    with SingleTickerProviderStateMixin {
  // D-15 settling star — the celebration star's recipe (mastery_celebration):
  // scale 0→1 with easeSoftBack over durCheer (700ms), opacity easing in over
  // the first 40%. One-shot per arrival; no sound; gold stays confined to the
  // star badge itself (reward-exclusive color).
  late final AnimationController _settleController;
  late final Animation<double> _settleScale;
  late final Animation<double> _settleOpacity;
  bool _settleStarted = false;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: QalamMotion.durCheer, // 700ms — dignified, never slapstick
    );
    _settleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _settleController,
        curve: QalamMotion.easeSoftBack, // gentle overshoot
      ),
    );
    _settleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _settleController,
        // Fade in over the first 40% of the settle.
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _settleController.dispose();
    super.dispose();
  }

  /// Starts the one-shot settle the first time the highlighted node renders
  /// as complete. Unknown ids never start it (silent no-op). With
  /// MediaQuery.disableAnimations the star renders settled immediately.
  void _maybeStartSettle(
    BuildContext context,
    List<Letter> letters,
    ProgressionSnapshot snapshot,
  ) {
    if (_settleStarted) return;
    final id = widget.highlightId;
    if (id == null || id.isEmpty) return;
    final matchesCompleteNode = snapshot.masteredLetterIds.contains(id) &&
        letters.any((letter) => letter.id == id);
    if (!matchesCompleteNode) return;
    _settleStarted = true;
    if (MediaQuery.of(context).disableAnimations) {
      _settleController.value = 1.0;
    } else {
      _settleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod 3: `.value` returns the latest data, or null while loading /
    // on error — no throw.
    final letters = ref.watch(journeyLettersProvider).value;
    final snapshot = ref.watch(progressionProvider).value;

    // Quiet loading/degradation: parchment, no spinner, no error surface to
    // the child (V5 degradation — the providers self-heal when data lands).
    if (letters == null || snapshot == null) {
      return const Scaffold(
        backgroundColor: QalamColors.bg,
        body: SizedBox.shrink(),
      );
    }

    // Today's letter = the first letter item of today's lesson; '' when all
    // mastered (D-11) so no node renders as current.
    final currentLetterId = snapshot.today?.items
            .where((item) => item.type == 'letter')
            .map((item) => item.ref)
            .firstOrNull ??
        '';

    final masteredCount = snapshot.masteredLetterIds.length;
    // Defensive: the canvas has exactly 28 positions (D-09).
    final nodes = letters.take(28).toList();

    // D-15: the just-mastered node's star settles in on arrival (one-shot).
    _maybeStartSettle(context, letters, snapshot);

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
                      // Live mastered count — quiet information, never gold,
                      // never celebrated (T-06-09 / PLAT-03).
                      Text(
                        '$masteredCount of 28 mastered',
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
                  completedCount: masteredCount,
                ),
              ),
            ),

            // ── 28 letter nodes ─────────────────────────────────────────────
            for (var i = 0; i < nodes.length; i++) ...[
              _buildNode(context, i, nodes[i], snapshot, currentLetterId),
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

  /// Build a Positioned node widget for [letter] at [index].
  ///
  /// Tap rules (D-07 / S1-09):
  ///   - complete + current nodes → `/practice?lesson=<owning lesson>`
  ///   - skipped-but-unlocked nodes (future VISUAL, lesson in
  ///     unlockedLessonIds) → also tappable, same destination — revisitable
  ///     without any new visual state (D-05/D-07)
  ///   - genuinely locked nodes (prerequisite unpassed) → inert (S1-09
  ///     "locked lessons visibly unavailable")
  Widget _buildNode(
    BuildContext context,
    int index,
    Letter letter,
    ProgressionSnapshot snapshot,
    String currentLetterId,
  ) {
    final pos = _nodePosition(index);
    final state = JourneyNodeState.compute(
      letter.id,
      snapshot.masteredLetterIds,
      currentLetterId,
    );
    final lessonId = snapshot.lessonIdByLetterId[letter.id];
    final unlocked =
        lessonId != null && snapshot.unlockedLessonIds.contains(lessonId);
    final tappable = lessonId != null &&
        (state == JourneyNodeState.complete ||
            state == JourneyNodeState.current ||
            (state == JourneyNodeState.future && unlocked));
    // D-15: only the highlighted node's badge gets the settle animation —
    // and only when it actually started (complete-node allowlist).
    final settling = _settleStarted && letter.id == widget.highlightId;
    return Positioned(
      left: pos.dx - 34, // 34 = half of 68px node diameter
      top: pos.dy - 34,
      child: JourneyNodeWidget(
        glyph: letter.char,
        name: letter.name.display,
        state: state,
        starSettleScale: settling ? _settleScale : null,
        starSettleOpacity: settling ? _settleOpacity : null,
        // Plan 07-06: baa's node opens its full 6-section Letter Unit
        // (`/unit?letter=baa`); every other letter keeps its existing
        // `/practice?lesson=` path until its unit is built. Deep-link reuse
        // (SC#5) — the journey nav is otherwise unchanged.
        onTap: tappable
            ? () => context.go(
                  letter.id == 'baa'
                      ? '/unit?letter=${letter.id}'
                      : '/practice?lesson=$lessonId',
                )
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
