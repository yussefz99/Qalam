// MasteryCelebration — Phase-3 dignified mastery moment (plan 03-04).
//
// A calm full-screen celebration: the mascot, the mastered alif glyph,
// exactly ONE settling gold star, a warm line, and Back Home.
//
// ANTI-GAMIFICATION INVARIANTS (D-03/D-08/PLAT-03 — enforced by tests):
//   - Exactly ONE gold star — QalamColors.reward ONLY for this star.
//   - NO running star counter, NO "+N today", NO "THIS WEEK" stat.
//   - NO three-star rating, NO streak, NO badge hype.
//   - 'See journey' button — wired in Phase 03.1 to /journey.
//   - NO confetti, NO sound blast.
//   - The star earning is information ("you mastered alif"), not a score.
//
// Mascot: SvgPicture.asset('assets/mascot/qalam-cheer.svg') with a graceful
// SizedBox fallback if the asset is missing — never crash.
//
// The alif glyph uses ArabicText (Cairo display, 96px) — RTL island.
// "أحسنت" uses ArabicText (Noto Naskh body) — RTL island paired with English.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';

/// Full-screen mastery celebration shown after 3 clean reps (D-07/D-08).
///
/// [onBackHome] is invoked when the child taps "Back Home".
class MasteryCelebration extends StatefulWidget {
  const MasteryCelebration({
    super.key,
    required this.onBackHome,
  });

  /// Called when the child taps the "Back Home" primary CTA.
  final VoidCallback onBackHome;

  @override
  State<MasteryCelebration> createState() => _MasteryCelebrationState();
}

class _MasteryCelebrationState extends State<MasteryCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _starController;
  late final Animation<double> _starScale;
  late final Animation<double> _starOpacity;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: QalamMotion.durCheer, // 700ms — gentle, never slapstick
    );

    // Star settles in with easeSoftBack (gentle overshoot) — dignified, not hype.
    _starScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _starController,
        curve: QalamMotion.easeSoftBack,
      ),
    );

    _starOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _starController,
        // Fade in over the first 40% of the animation.
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Auto-play once on appear.
    _starController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final celebLine = l10n?.practiceCelebrationLine ?? 'You learned alif.';
    final arabicPraise = l10n?.practiceCelebrationArabic ?? 'أحسنت';
    final masteredLabel = l10n?.practiceMasteredEyebrow ?? 'MASTERED';
    final backHomeLabel = l10n?.practiceBackHomeButton ?? 'Back Home';

    return Scaffold(
      backgroundColor: QalamColors.bg, // parchment — never white
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space8,
              vertical: QalamSpace.space10,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Mastered eyebrow badge.
                  _MasteredBadge(label: masteredLabel),
                  const SizedBox(height: QalamSpace.space8),

                  // Mascot — graceful fallback if asset missing.
                  const _MascotCheer(),
                  const SizedBox(height: QalamSpace.space6),

                  // The mastered alif glyph — Arabic display (96px Cairo).
                  // QalamColors.reward glow behind the glyph.
                  const _MasteredGlyph(),
                  const SizedBox(height: QalamSpace.space8),

                  // Exactly ONE settling gold star (D-07/D-08).
                  _SettlingStar(
                    scale: _starScale,
                    opacity: _starOpacity,
                  ),
                  const SizedBox(height: QalamSpace.space8),

                  // Warm English line.
                  Text(
                    celebLine,
                    style: QalamTextStyles.display,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: QalamSpace.space4),

                  // Arabic praise island — Noto Naskh, RTL.
                  ArabicText(
                    arabicPraise,
                    style: QalamTextStyles.arBody.copyWith(
                      fontSize: QalamFontSizes.arLarge,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: QalamSpace.space12),

                  // Back Home — primary CTA, comfy touch target.
                  _BackHomeButton(
                    label: backHomeLabel,
                    onPressed: widget.onBackHome,
                  ),
                  const SizedBox(height: QalamSpace.space4),

                  // "See journey" ghost link — navigation affordance only.
                  // No star count, no "+N" copy, no score (D-23/D-24).
                  // Wired in Phase 03.1 to /journey.
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: QalamTargets.targetMin,
                    ),
                    child: TextButton(
                      onPressed: () => context.go('/journey'),
                      style: TextButton.styleFrom(
                        foregroundColor: QalamColors.fgMuted,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        l10n?.journeySeeJourney ?? 'See journey',
                        style: QalamTextStyles.body.copyWith(
                          color: QalamColors.fgMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Teal "MASTERED" badge with ONE gold star glyph (SVG/painted).
class _MasteredBadge extends StatelessWidget {
  const _MasteredBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space6,
        vertical: QalamSpace.space3,
      ),
      decoration: BoxDecoration(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
      ),
      child: Text(
        label,
        style: QalamTextStyles.label.copyWith(
          color: QalamColors.fgOnPrimary,
          fontFamily: QalamFonts.body,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Mascot SVG — graceful SizedBox fallback if asset is missing (never crash).
class _MascotCheer extends StatelessWidget {
  const _MascotCheer();

  static const String _assetPath = 'assets/mascot/qalam-cheer.svg';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Builder(
        builder: (BuildContext context) {
          try {
            return SvgPicture.asset(
              _assetPath,
              height: 140,
              semanticsLabel: 'Qalam the tutor, celebrating',
            );
          } catch (_) {
            // Asset missing — render an empty SizedBox rather than crash.
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

/// The mastered alif glyph at display scale with a soft gold glow behind it.
class _MasteredGlyph extends StatelessWidget {
  const _MasteredGlyph();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Soft gold glow behind the glyph (reward color, REWARDS ONLY).
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: QalamColors.rewardTint,
          ),
        ),
        // The alif glyph — ArabicText RTL island, Cairo display 96px.
        const ArabicText(
          'ا',
          display: true,
          style: TextStyle(
            fontFamily: QalamFonts.arabicDisplay,
            fontWeight: FontWeight.w500,
            fontSize: QalamFontSizes.arDisplay,
            height: 1.1,
            letterSpacing: 0,
            color: QalamColors.primaryPressed,
          ),
        ),
      ],
    );
  }
}

/// Exactly ONE gold star settling in with [QalamMotion.durCheer] (700ms).
///
/// Uses a CustomPainter to draw a gold 5-pointed star — brand glyph only,
/// no emoji, no unicode ⭐ (UI-SPEC Icon Library rule).
/// QalamColors.reward is used ONLY here in the celebration (REWARDS ONLY).
class _SettlingStar extends StatelessWidget {
  const _SettlingStar({
    required this.scale,
    required this.opacity,
  });

  final Animation<double> scale;
  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        scale: scale,
        child: CustomPaint(
          size: const Size(72, 72),
          painter: _StarPainter(color: QalamColors.reward),
        ),
      ),
    );
  }
}

/// Paints a single 5-pointed star in [color].
///
/// Used only for the ONE mastery star on the celebration screen.
/// QalamColors.reward (gold) must be the only non-neutral color passed here.
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerR = size.width / 2;
    final double innerR = outerR * 0.4;

    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      // Alternate outer and inner vertices.
      final double r = i.isEven ? outerR : innerR;
      final double angle = (math.pi / 5) * i - math.pi / 2;
      final double x = cx + r * math.cos(angle);
      final double y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}

/// "Back Home" primary CTA — full-width comfy touch target.
class _BackHomeButton extends StatelessWidget {
  const _BackHomeButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        boxShadow: QalamShadows.buttonShadow,
      ),
      child: Material(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: QalamTargets.targetComfy,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space12,
              vertical: QalamSpace.space4,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: QalamTextStyles.button.copyWith(
                color: QalamColors.fgOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
