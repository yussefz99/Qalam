// DemoCelebrationScreen — the calm mastery moment that closes the loop (DP-06).
//
// This screen honors the anti-gamification rule absolutely. It shows the cheer
// mascot, a quiet teal "MASTERED" badge, the mastered alif glyph (with a soft
// gold glow), EXACTLY ONE gold star, and the warm bilingual line "You learned
// alif." / "أحسنت". That is all. The design mockup's extra three-mark row, its
// running point tally, and its journey link are all OMITTED — a single mark here
// means "you truly mastered this letter": information, not a tally. No bursts,
// no sound blast, no running count (DP-06).
//
// Back Home returns to /demo/home so the walkthrough loops with no dead ends.
// Gold (QalamColors.reward) is the rewards-only token, used here for the single
// star and the glyph glow. The star degrades to a calm fallback if its asset is
// missing (screenshot-stable). Tokens only; copy via gen-l10n.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/arabic_text.dart';
import '../../widgets/qalam_mascot.dart';
import '../demo_alif.dart';

class DemoCelebrationScreen extends StatelessWidget {
  const DemoCelebrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow = l10n?.demoCelebrationEyebrow ?? 'MASTERED';
    final String heading = l10n?.demoCelebrationHeading ?? 'You Learned Alif.';
    final String praiseAr = l10n?.demoCelebrationPraiseAr ?? 'أحسنت';
    final String backHome = l10n?.demoBackHome ?? 'Back Home';

    return Scaffold(
      backgroundColor: QalamColors.bg, // parchment — never white
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(QalamSpace.space10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const QalamMascot(
                      pose: QalamPose.cheer,
                      size: QalamSpace.space24,
                    ),
                    const SizedBox(height: QalamSpace.space6),
                    _MasteredBadge(label: eyebrow),
                    const SizedBox(height: QalamSpace.space8),
                    // The mastered alif glyph with a soft gold glow.
                    Container(
                      width: QalamSpace.space24,
                      height: QalamSpace.space24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: QalamColors.rewardTint,
                        shape: BoxShape.circle,
                      ),
                      child: ArabicText(DemoAlif.glyph, display: true),
                    ),
                    const SizedBox(height: QalamSpace.space6),
                    const _MasteryStar(),
                    const SizedBox(height: QalamSpace.space8),
                    Text(
                      heading,
                      style: QalamTextStyles.display,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: QalamSpace.space3),
                    ArabicText(praiseAr, tashkeel: true),
                    const SizedBox(height: QalamSpace.space10),
                    _BackHomeButton(
                      label: backHome,
                      onPressed: () => context.go('/demo/home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The quiet teal "MASTERED" badge.
class _MasteredBadge extends StatelessWidget {
  const _MasteredBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space5,
        vertical: QalamSpace.space2,
      ),
      child: Text(
        label,
        style: QalamTextStyles.label.copyWith(color: QalamColors.fgOnPrimary),
      ),
    );
  }
}

/// Exactly ONE gold mastery star — the single sanctioned reward mark. Degrades
/// to a calm gold icon if the asset is missing (screenshot-stable), never a red
/// error box.
class _MasteryStar extends StatelessWidget {
  const _MasteryStar();

  @override
  Widget build(BuildContext context) {
    const double size = QalamSpace.space12;
    return SvgPicture.asset(
      'assets/icons/star.svg',
      key: const Key('demoMasteryStar'),
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(QalamColors.reward, BlendMode.srcIn),
      semanticsLabel: 'Mastery star',
      placeholderBuilder: (_) => const _StarFallback(size: size),
      errorBuilder: (context, error, stackTrace) =>
          const _StarFallback(size: size),
    );
  }
}

class _StarFallback extends StatelessWidget {
  const _StarFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded, size: size, color: QalamColors.reward);
  }
}

/// The primary "Back Home" sticker CTA, closing the loop. Keyed and
/// >= targetComfy for the contract test.
class _BackHomeButton extends StatelessWidget {
  const _BackHomeButton({required this.label, required this.onPressed});

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
          key: const Key('demoBackHomeCta'),
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
