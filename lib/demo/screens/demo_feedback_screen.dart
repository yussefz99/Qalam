// DemoFeedbackScreen — the HERO of the walkthrough (DP-04/DP-05/DP-06).
//
// No 1:1 design page exists for feedback, so the two states are built from the
// brand feedback tokens (docs/design/kit/.../preview/colors-feedback.html):
//
//   MISS  — the shot that sells the product. The failing baa stroke is painted
//           CORAL (QalamColors.warnSoft) — never red, never a red X — beside the
//           tryAgain-pose mascot and a warm coral card carrying a SPECIFIC named
//           fix in the tutor's voice (the verbatim DemoBaa.heroMissFix). Its
//           gentle, counter-free "Try Again" carries the narrative forward: the
//           child retries and THIS time it's clean, so it navigates to the
//           clean-pass variant — reachable by tapping, no dead end (DP-06).
//
//   PASS  — a quiet, specific affirmation. The clean stroke is painted LEAF
//           (QalamColors.success) with warm praise, advancing to Celebration.
//
// Both canvases PAINT the baa from the single DemoBaa source (Pitfall 5).
// Tokens only; copy via gen-l10n; parchment ground, never white; never red.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../router/demo_routes.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/qalam_mascot.dart';
import '../demo_baa.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/dotted_guide_painter.dart';

const double _kMascotSize = 160;
const double _kCanvasSize = 300;

/// Which feedback state to show — selected by route (miss is the default the
/// Trace submit lands on; pass is the retry-now-clean state).
enum DemoFeedbackVariant { miss, pass }

class DemoFeedbackScreen extends StatelessWidget {
  const DemoFeedbackScreen({super.key, required this.variant});

  final DemoFeedbackVariant variant;

  @override
  Widget build(BuildContext context) {
    return DemoChrome(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          QalamSpace.space10,
          QalamSpace.space4,
          QalamSpace.space10,
          QalamSpace.space8,
        ),
        child: variant == DemoFeedbackVariant.miss
            ? const _MissView()
            : const _PassView(),
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
    final String fix = l10n?.demoMissFix ?? DemoBaa.heroMissFix;
    final String chip = l10n?.demoMissChip ?? "Let's fix this";
    final String tryAgain = l10n?.demoTryAgain ?? 'Try Again';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: QalamSpace.space6,
          runSpacing: QalamSpace.space6,
          children: <Widget>[
            const QalamMascot(pose: QalamPose.tryAgain, size: _kMascotSize),
            _FeedbackCanvas(
              inkColor: QalamColors.warnSoft, // coral, never red
              chipLabel: chip,
              chipTint: QalamColors.warnSoftTint,
              chipColor: QalamColors.warnSoft,
            ),
          ],
        ),
        const SizedBox(height: QalamSpace.space8),
        _MessageCard(message: fix, tint: QalamColors.warnSoftTint),
        const SizedBox(height: QalamSpace.space8),
        DemoPrimaryCta(
          ctaKey: const Key('demoTryAgainCta'),
          label: tryAgain,
          icon: Icons.refresh_rounded,
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
    final String praise = l10n?.demoPassPraise ?? DemoBaa.passPraise;
    final String chip = l10n?.demoPassChip ?? 'Beautiful work';
    final String continueLabel = l10n?.demoPassContinue ?? 'Continue';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: QalamSpace.space6,
          runSpacing: QalamSpace.space6,
          children: <Widget>[
            const QalamMascot(pose: QalamPose.cheer, size: _kMascotSize),
            _FeedbackCanvas(
              inkColor: QalamColors.success, // leaf — the clean stroke
              chipLabel: chip,
              chipTint: QalamColors.successTint,
              chipColor: QalamColors.success,
            ),
          ],
        ),
        const SizedBox(height: QalamSpace.space8),
        _MessageCard(message: praise, tint: QalamColors.successTint),
        const SizedBox(height: QalamSpace.space8),
        DemoPrimaryCta(
          ctaKey: const Key('demoPassContinueCta'),
          label: continueLabel,
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.go(DemoStep.feedbackPass.next.path),
        ),
      ],
    );
  }
}

/// The white canvas painting the full baa stroke in the feedback color, with a
/// floating chip over it.
class _FeedbackCanvas extends StatelessWidget {
  const _FeedbackCanvas({
    required this.inkColor,
    required this.chipLabel,
    required this.chipTint,
    required this.chipColor,
  });

  final Color inkColor;
  final String chipLabel;
  final Color chipTint;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        DemoCanvasCard(
          size: _kCanvasSize,
          painter: DottedGuidePainter(
            referencePoints:
                DemoBaa.referencePoints.map((p) => Offset(p[0], p[1])).toList(),
            inkProgress: 1.0, // the full stroke, inked in the feedback color
            inkColor: inkColor,
            showStartDot: true,
            startDotColor: QalamColors.reward, // gold — start-dot only
            diacriticDots:
                DemoBaa.diacriticDots.map((p) => Offset(p[0], p[1])).toList(),
          ),
        ),
        Positioned(
          top: QalamSpace.space5,
          child: _FeedbackChip(label: chipLabel, tint: chipTint, color: chipColor),
        ),
      ],
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({
    required this.label,
    required this.tint,
    required this.color,
  });

  final String label;
  final Color tint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space4,
        vertical: QalamSpace.space2,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
      ),
      child: Text(
        label,
        style: QalamTextStyles.label.copyWith(color: color),
      ),
    );
  }
}

/// The warm tinted card carrying the named fix / praise, in the tutor's voice.
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.tint});

  final String message;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space6,
        vertical: QalamSpace.space5,
      ),
      child: Text(
        message,
        style: QalamTextStyles.body,
        textAlign: TextAlign.center,
      ),
    );
  }
}
