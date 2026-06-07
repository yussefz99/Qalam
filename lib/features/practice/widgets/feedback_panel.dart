// FeedbackPanel — Phase-3 named-fix panel (plan 03-04).
//
// Shows a specific, authored feedback string for a failed stroke. The failing
// stroke area is framed in QalamColors.warnSoft (coral — the only "error"
// color; never red). A gentle easeSoftBack wiggle draws the child's attention
// without pressure.
//
// ANTI-GAMIFICATION (PLAT-03 / Pitfall 7):
//   - Feedback ALWAYS comes from authored commonMistakes[].feedback via l10n.
//   - NEVER "Oops, try again!" — each string names the exact fix.
//   - No try counter, no fail state, no pressure.
//
// The panel does NOT display any button — the parent screen owns the "Try Again"
// CTA so the button can be placed at the correct touch-target position.

import 'package:flutter/material.dart';

import '../../../core/scoring/scoring_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';

/// A coral-framed panel that shows the named fix for a failed stroke.
///
/// [mistakeId] determines which authored feedback string is shown.
/// Pass a [GlobalKey] to drive the entrance animation from the outside.
class FeedbackPanel extends StatefulWidget {
  const FeedbackPanel({
    super.key,
    required this.mistakeId,
  });

  /// The scorer's identified mistake — used to select the authored string.
  final MistakeId mistakeId;

  @override
  State<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleController;
  late final Animation<double> _wiggle;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: QalamMotion.durBase, // 220ms gentle wiggle
    );

    // easeSoftBack gives a gentle overshoot — "let's try that again" energy,
    // never punishing. One forward pass only — not a loop (not slapstick).
    _wiggle = CurvedAnimation(
      parent: _wiggleController,
      curve: QalamMotion.easeSoftBack,
    );

    // Auto-trigger once on appear.
    _wiggleController.forward();
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feedbackText = _feedbackString(l10n, widget.mistakeId);
    final strokeProgress = l10n?.practiceStrokeProgress ?? 'Stroke 1 of 1';

    return AnimatedBuilder(
      animation: _wiggle,
      builder: (BuildContext context, Widget? child) {
        // Subtle horizontal nudge — gentle, never harsh.
        final double dx = _wiggle.value < 0.5
            ? (_wiggle.value * 2) * 6.0 // slide in from left
            : 6.0; // settle at resting position
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          // Coral (warnSoft) frame — the ONLY "error" treatment; never red.
          color: QalamColors.warnSoftTint,
          border: Border.all(
            color: QalamColors.warnSoft,
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
            // Stroke progress line — pedagogical, not a score.
            Text(
              strokeProgress,
              style: QalamTextStyles.label.copyWith(
                color: QalamColors.warnSoft,
              ),
            ),
            const SizedBox(height: QalamSpace.space3),
            // The authored named-fix in the tutor's specific, warm voice.
            Text(
              feedbackText,
              style: QalamTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps a [MistakeId] to the correct l10n getter.
///
/// Feedback ALWAYS comes from authored strings — never a generic "Oops".
/// Matches the MistakeId enum to the authored commonMistakes[].feedback via
/// the l10n keys defined in app_en.arb.
String _feedbackString(AppLocalizations? l10n, MistakeId id) {
  switch (id) {
    case MistakeId.tooShort:
      return l10n?.practiceFeedbackTooShort ??
          'Your alif needs to be taller — draw it from the top all the way down.';
    case MistakeId.wrongDirection:
      return l10n?.practiceFeedbackWrongDirection ??
          'Start your alif at the top and come down — not from the bottom up.';
    case MistakeId.tooCurved:
      return l10n?.practiceFeedbackTooCurved ??
          'Alif is a straight line — try to keep it as straight as you can.';
    case MistakeId.fallback:
      return l10n?.practiceFeedbackFallback ??
          'Something looks off — try again, slower this time.';
  }
}
