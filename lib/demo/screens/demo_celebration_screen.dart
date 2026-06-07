// DemoCelebrationScreen — the mastery moment that closes the loop, rebuilt 1:1
// with the design `CompleteScreen` mockup (.../screenshots/05-celebration-final.png).
//
// OWNER OVERRIDE (2026-06-02, Rami): faithful to the mockup, INCLUDING the
// gamification chrome — the earned three gold stars, the rotated teal MASTERED
// stamp over a giant gold baa glyph (with a soft halo), the cheer mascot with
// confetti, and the running "42 stars / +3 today" total. That intentionally
// reverses CLAUDE.md's anti-gamification "Decided" rule for the demo (already
// applied to the demo Home). Reconcile CLAUDE.md if the reversal is to stand.
//
// Back Home returns to /demo/home so the walkthrough loops with no dead ends.
// Gold (QalamColors.reward) is the rewards-only token. The giant glyph renders
// through ArabicText (the RTL island), never the painted stroke. Tokens only;
// parchment ground, never white.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/arabic_text.dart';
import '../../widgets/qalam_mascot.dart';
import '../demo_baa.dart';
import '../widgets/demo_chrome.dart';

const double _kMascotSize = 140;
const double _kStageHeight = 340;
const double _kHaloSize = 280;
const double _kGlyphSize = 196;

class DemoCelebrationScreen extends StatelessWidget {
  const DemoCelebrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow = l10n?.demoCelebrationEyebrow ?? 'MASTERED';
    final String heading =
        l10n?.demoCelebrationHeading ?? 'You learned the letter baa.';
    final String seeJourney = l10n?.demoHomeSeeJourney ?? 'See journey';
    final String backHome = l10n?.demoBackHome ?? 'Back Home';

    return DemoChrome(
      stars: l10n?.demoCelebrationStarCount ?? '42',
      showClose: false, // Celebration mirrors Home — no close affordance.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          QalamSpace.space10,
          QalamSpace.space4,
          QalamSpace.space10,
          QalamSpace.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoEyebrow(eyebrow),
            const SizedBox(height: QalamSpace.space2),
            Text(heading, style: QalamTextStyles.display),
            const SizedBox(height: QalamSpace.space5),
            // The earned three-star rating — gamification chrome (owner override).
            Center(
              child: Row(
                key: const Key('demoCelebrationStars'),
                mainAxisSize: MainAxisSize.min,
                children: const <Widget>[
                  DemoStarIcon(size: 44),
                  SizedBox(width: QalamSpace.space3),
                  DemoStarIcon(size: 44),
                  SizedBox(width: QalamSpace.space3),
                  DemoStarIcon(size: 44),
                ],
              ),
            ),
            const SizedBox(height: QalamSpace.space5),
            const _CelebrationStage(),
            const SizedBox(height: QalamSpace.space8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const _TotalBlock(),
                const Spacer(),
                DemoGhostButton(label: seeJourney, filled: true),
                const SizedBox(width: QalamSpace.space4),
                DemoPrimaryCta(
                  ctaKey: const Key('demoBackHomeCta'),
                  label: backHome,
                  onPressed: () => context.go('/demo/home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The centered giant gold baa over a soft halo, with the rotated MASTERED stamp,
/// the cheer mascot, and a scatter of confetti.
class _CelebrationStage extends StatelessWidget {
  const _CelebrationStage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kStageHeight,
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          // Confetti — gold + teal, solid tokens (no opacity), settles still.
          const _Confetti(),
          // The mastered glyph on a soft gold halo.
          Center(
            child: Container(
              width: _kHaloSize,
              height: _kHaloSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: QalamColors.rewardTint,
                shape: BoxShape.circle,
              ),
              child: ArabicText(
                DemoBaa.glyph,
                style: demoGlyphStyle(_kGlyphSize, color: QalamColors.reward),
              ),
            ),
          ),
          // The rotated teal MASTERED stamp, overlapping top-right.
          Positioned(
            top: QalamSpace.space4,
            right: QalamSpace.space6,
            child: Transform.rotate(
              angle: -0.10,
              child: const _MasteredStamp(),
            ),
          ),
          // The cheer mascot, bottom-left.
          const Positioned(
            left: 0,
            bottom: 0,
            child: QalamMascot(pose: QalamPose.cheer, size: _kMascotSize),
          ),
        ],
      ),
    );
  }
}

/// The rotated teal "MASTERED" stamp with a gold star.
class _MasteredStamp extends StatelessWidget {
  const _MasteredStamp();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.md),
        boxShadow: QalamShadows.shadowLg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space6,
        vertical: QalamSpace.space3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const DemoStarIcon(size: 28),
          const SizedBox(width: QalamSpace.space3),
          Text(
            l10n?.demoCelebrationStamp ?? 'MASTERED',
            style: QalamTextStyles.heading.copyWith(
              color: QalamColors.fgOnPrimary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The running star total — gamification chrome (owner override).
class _TotalBlock extends StatelessWidget {
  const _TotalBlock();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String total = l10n?.demoCelebrationTotalLabel ?? 'TOTAL';
    final String count = l10n?.demoCelebrationStarCount ?? '42';
    final String starsWord = l10n?.demoCelebrationStarsWord ?? 'stars';
    final String delta = l10n?.demoCelebrationStarsDelta ?? '+3 today';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DemoEyebrow(total),
        const SizedBox(height: QalamSpace.space1),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(count,
                style: QalamTextStyles.display.copyWith(color: QalamColors.reward)),
            const SizedBox(width: QalamSpace.space2),
            Text(starsWord, style: QalamTextStyles.heading),
            const SizedBox(width: QalamSpace.space3),
            Text(delta,
                style: QalamTextStyles.label.copyWith(color: QalamColors.fgMuted)),
          ],
        ),
      ],
    );
  }
}

/// A still scatter of gold + teal confetti, positioned fractionally so it never
/// overflows. Settles to a clean screenshot state (no motion required).
class _Confetti extends StatelessWidget {
  const _Confetti();

  static const List<({Alignment at, double size, Color color, bool round})>
      _pieces = <({Alignment at, double size, Color color, bool round})>[
    (at: Alignment(-0.55, -0.85), size: 14, color: QalamColors.reward, round: true),
    (at: Alignment(0.15, -0.95), size: 12, color: QalamColors.primary, round: false),
    (at: Alignment(0.6, -0.7), size: 16, color: QalamColors.reward, round: false),
    (at: Alignment(-0.85, -0.2), size: 12, color: QalamColors.reward, round: true),
    (at: Alignment(0.85, 0.05), size: 14, color: QalamColors.primary, round: true),
    (at: Alignment(-0.35, 0.6), size: 12, color: QalamColors.reward, round: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        for (final piece in _pieces)
          Align(
            alignment: piece.at,
            child: Container(
              width: piece.size,
              height: piece.size,
              decoration: BoxDecoration(
                color: piece.color,
                shape: piece.round ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: piece.round
                    ? null
                    : BorderRadius.circular(QalamRadii.sm),
              ),
            ),
          ),
      ],
    );
  }
}
