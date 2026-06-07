// PraisePanel — Phase-3 per-rep praise panel.
//
// Shows a warm, specific affirmation after a CLEAN trace that hasn't yet
// reached mastery. Framed in QalamColors.success (leaf green) — distinct from
// the coral named-fix panel and from the gold mastery celebration (gold is
// rewards-only). A gentle entrance settle, never confetti.
//
// ANTI-GAMIFICATION (PLAT-03 / Decided):
//   - NO points, NO "+1", NO streak hype, NO score.
//   - The remaining-reps line is pedagogical progress ("2 more in a row"),
//     the same neutral information already shown during trace — not a tally.
//
// The panel does NOT display a button — the parent screen owns the
// "Keep going" CTA so it sits at the correct touch-target position.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';

/// A leaf-green panel affirming a clean rep and how many remain to mastery.
///
/// [repsRemaining] is how many more consecutive clean reps are needed; when it
/// is positive the informational line is shown.
class PraisePanel extends StatefulWidget {
  const PraisePanel({
    super.key,
    required this.repsRemaining,
  });

  /// Consecutive clean reps still needed to earn mastery (>= 1 here, since at
  /// 0 the screen shows the celebration instead).
  final int repsRemaining;

  @override
  State<PraisePanel> createState() => _PraisePanelState();
}

class _PraisePanelState extends State<PraisePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settleController;
  late final Animation<double> _settle;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: QalamMotion.durBase, // 220ms gentle entrance
    );
    // A soft overshoot — a small "nice!" settle, never slapstick.
    _settle = CurvedAnimation(
      parent: _settleController,
      curve: QalamMotion.easeSoftBack,
    );
    _settleController.forward();
  }

  @override
  void dispose() {
    _settleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = l10n?.practicePraiseArabic ?? 'أحسنت';
    final line = l10n?.practicePraiseLine ?? "That's a clean alif. Nicely done.";
    final remaining = l10n?.practicePraiseRemaining(widget.repsRemaining) ??
        '${widget.repsRemaining} more in a row to master it.';

    return ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1.0).animate(_settle),
      child: Container(
        decoration: BoxDecoration(
          // Leaf-green success framing — distinct from coral (error) and gold
          // (rewards-only mastery).
          color: QalamColors.successTint,
          border: Border.all(
            color: QalamColors.success,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(QalamRadii.xl),
          boxShadow: QalamShadows.shadowSm,
        ),
        padding: const EdgeInsets.all(QalamSpace.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Arabic praise word — RTL island in the warm tutor register.
            ArabicText(
              arabic,
              style: QalamTextStyles.arBody.copyWith(
                color: QalamColors.success,
              ),
            ),
            const SizedBox(height: QalamSpace.space2),
            // Warm, specific line — names what was good.
            Text(line, style: QalamTextStyles.body),
            const SizedBox(height: QalamSpace.space3),
            // Pedagogical progress — consecutive reps remaining, not a score.
            Text(
              remaining,
              style: QalamTextStyles.label.copyWith(
                color: QalamColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
