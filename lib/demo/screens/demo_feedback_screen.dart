// DemoFeedbackScreen — the HERO of the walkthrough (DP-04/DP-05/DP-06).
//
// The MISS variant is the shot that sells the product: it proves Qalam
// diagnoses a SPECIFIC stroke problem and offers a SPECIFIC fix in the tutor's
// warm voice. The failing alif is highlighted in CORAL (QalamColors.warnSoft) —
// never red, never a red X — and the tryAgain-pose mascot sits beside a warmly
// framed named-fix card (the verbatim DemoAlif.heroMissFix line). Its gentle
// "Try Again" CTA carries the natural narrative forward: the child retries and
// THIS time it's clean, so the CTA navigates to the clean-pass variant
// (DemoStep.feedbackMiss.next == feedbackPass) — the clean-pass state is
// reachable by tapping, no dead end. There is no retry tally and no pressure
// (DP-06).
//
// The PASS variant is a quiet, specific affirmation (QalamColors.success) with
// warm praise, advancing to Celebration. Tokens only; copy via gen-l10n.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../router/demo_routes.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../demo_alif.dart';
import '../widgets/dotted_guide_painter.dart';
import '../../widgets/qalam_mascot.dart';

/// Which feedback state to show — selected by route (miss is the default the
/// Trace submit lands on; pass is the retry-now-clean state).
enum DemoFeedbackVariant { miss, pass }

class DemoFeedbackScreen extends StatelessWidget {
  const DemoFeedbackScreen({super.key, required this.variant});

  final DemoFeedbackVariant variant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QalamColors.bg, // parchment — never white
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(QalamSpace.space8),
                child: variant == DemoFeedbackVariant.miss
                    ? const _MissView()
                    : const _PassView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The HERO miss state: coral failing stroke + specific named fix + a gentle,
/// pressure-free Try Again → the clean-pass variant.
class _MissView extends StatelessWidget {
  const _MissView();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String fix = l10n?.demoMissFix ?? DemoAlif.heroMissFix;
    final String tryAgain = l10n?.demoTryAgain ?? 'Try Again';

    final List<Offset> points =
        DemoAlif.referencePoints.map((p) => Offset(p[0], p[1])).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const QalamMascot(
              pose: QalamPose.tryAgain,
              size: QalamSpace.space20,
            ),
            const SizedBox(width: QalamSpace.space6),
            // The failing alif, highlighted coral (the full stroke, inked wrong).
            Container(
              decoration: BoxDecoration(
                color: QalamColors.surface,
                borderRadius: BorderRadius.circular(QalamRadii.xl),
                boxShadow: QalamShadows.shadowMd,
              ),
              padding: const EdgeInsets.all(QalamSpace.space4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(QalamRadii.lg),
                child: ColoredBox(
                  color: QalamColors.bg,
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: const Size(
                          QalamSpace.space20, QalamSpace.space20 * 2),
                      painter: DottedGuidePainter(
                        referencePoints: points,
                        inkProgress: 1.0,
                        inkColor: QalamColors.warnSoft, // coral, never red
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: QalamSpace.space8),
        // The specific named fix, in a warm coral-tinted card (the tutor's voice).
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: QalamColors.warnSoftTint,
            borderRadius: BorderRadius.circular(QalamRadii.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: QalamSpace.space6,
            vertical: QalamSpace.space5,
          ),
          child: Text(
            fix,
            style: QalamTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: QalamSpace.space8),
        _StickerButton(
          buttonKey: const Key('demoTryAgainCta'),
          label: tryAgain,
          // Forward to the clean-pass state — the retry-now-clean narrative.
          onPressed: () => context.go(DemoStep.feedbackMiss.next.path),
        ),
      ],
    );
  }
}

/// The clean-pass state: a quiet success affirmation with specific praise,
/// advancing to Celebration.
class _PassView extends StatelessWidget {
  const _PassView();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String praise =
        l10n?.demoPassPraise ?? 'Beautiful — straight and tall. أحسنت.';
    final String continueLabel = l10n?.demoPassContinue ?? 'Continue';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const QalamMascot(pose: QalamPose.idle, size: QalamSpace.space20),
        const SizedBox(height: QalamSpace.space6),
        // Quiet success affirmation — subtle, never a loud score.
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: QalamColors.successTint,
            borderRadius: BorderRadius.circular(QalamRadii.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: QalamSpace.space6,
            vertical: QalamSpace.space5,
          ),
          child: Text(
            praise,
            style: QalamTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: QalamSpace.space8),
        _StickerButton(
          buttonKey: const Key('demoPassContinueCta'),
          label: continueLabel,
          onPressed: () => context.go(DemoStep.feedbackPass.next.path),
        ),
      ],
    );
  }
}

/// Shared sticker-shadow primary CTA. Keyed and >= targetComfy so contract tests
/// can assert size and tap target.
class _StickerButton extends StatelessWidget {
  const _StickerButton({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final QalamTheme qalam =
        Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        boxShadow: qalam.buttonShadow,
      ),
      child: Material(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          child: Container(
            constraints:
                const BoxConstraints(minHeight: QalamTargets.targetComfy),
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space12,
              vertical: QalamSpace.space4,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style:
                  QalamTextStyles.button.copyWith(color: QalamColors.fgOnPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
