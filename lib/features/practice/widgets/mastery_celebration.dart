// MasteryCelebration — dignified mastery moment (plan 03-04, parameterized 06-07).
//
// A calm full-screen celebration: the mascot, the MASTERED letter's glyph,
// exactly ONE settling gold star, a warm line naming the letter, the decided
// CTA set, and one warm tutor line.
//
// PHASE 6 (06-07) — D-14 / D-16 / D-17, Pitfall 6:
//   - The widget is PARAMETERIZED on the mastered letter ([glyph]/[letterName]):
//     it speaks the actual letter (ب / "You learned baa.") — never a hardcoded
//     'alif'/'ا' after another letter is mastered (Pitfall 6).
//   - D-14: a primary filled-teal "Next Lesson" CTA goes straight into the
//     newly unlocked letter ([onNextLesson]); "Back Home" is demoted to a ghost.
//   - D-16: on the last lesson ([isLastLesson]) the primary slot becomes
//     "See Journey" and Next Lesson is absent (no capstone screen).
//   - D-17: one warm tutor line — "Go show your {letterName} to someone at home."
//   - "See journey" ghost link navigates /journey?highlight={masteredLetterId}
//     (D-15 handoff).
//
// ANTI-GAMIFICATION INVARIANTS (D-03/D-08/PLAT-03 — enforced by tests):
//   - Exactly ONE gold star — QalamColors.reward ONLY for this star.
//   - NO running star counter, NO "+N today", NO "THIS WEEK" stat.
//   - NO three-star rating, NO streak, NO badge hype.
//   - NO confetti, NO sound blast.
//   - The star earning is information ("you mastered baa"), not a score.
//
// Mascot: SvgPicture.asset('assets/mascot/qalam-cheer.svg') with a graceful
// SizedBox fallback if the asset is missing — never crash.
//
// The letter glyph uses ArabicText (Cairo display, 96px) — RTL island.
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

/// Full-screen mastery celebration shown after the required clean reps
/// (D-07/D-08), parameterized on the mastered letter (06-07).
class MasteryCelebration extends StatefulWidget {
  const MasteryCelebration({
    super.key,
    required this.glyph,
    required this.letterName,
    required this.masteredLetterId,
    required this.onBackHome,
    this.onNextLesson,
    this.isLastLesson = false,
  });

  /// The mastered letter's Arabic glyph (e.g. 'ب') — rendered via [ArabicText]
  /// at display scale. Never hardcoded (Pitfall 6).
  final String glyph;

  /// The mastered letter's romanized display name (e.g. 'baa') — woven into the
  /// celebration line and the D-17 tutor line.
  final String letterName;

  /// The mastered letter's canonical id — fed to /journey?highlight= (D-15).
  final String masteredLetterId;

  /// Called when the child taps the demoted "Back Home" ghost CTA.
  final VoidCallback onBackHome;

  /// Called when the child taps the primary "Next Lesson" CTA (D-14) — goes
  /// straight into the newly unlocked letter's practice. Null only on the last
  /// lesson (D-16), where the primary slot becomes "See Journey".
  final VoidCallback? onNextLesson;

  /// D-16: when true there is no next lesson — the primary slot becomes
  /// "See Journey" and "Next Lesson" is absent (no special capstone screen).
  final bool isLastLesson;

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
    final celebLine = l10n?.practiceCelebrationLineFor(widget.letterName) ??
        'You learned ${widget.letterName}.';
    final arabicPraise = l10n?.practiceCelebrationArabic ?? 'أحسنت';
    final masteredLabel = l10n?.practiceMasteredEyebrow ?? 'MASTERED';
    final backHomeLabel = l10n?.practiceBackHomeButton ?? 'Back Home';
    final nextLessonLabel = l10n?.celebrationNextLesson ?? 'Next Lesson';
    final seeJourneyButtonLabel =
        l10n?.celebrationSeeJourneyButton ?? 'See Journey';
    final tutorLine = l10n?.celebrationShowSomeone(widget.letterName) ??
        'Go show your ${widget.letterName} to someone at home.';

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

                  // The mastered letter's glyph — Arabic display (96px Cairo).
                  // QalamColors.reward glow behind the glyph. Parameterized
                  // (Pitfall 6) — never a hardcoded 'ا'.
                  _MasteredGlyph(glyph: widget.glyph),
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
                  const SizedBox(height: QalamSpace.space4),

                  // D-17 tutor line — exactly one warm, specific, family line,
                  // Body scale, under the Arabic praise. The tutor's voice.
                  Text(
                    tutorLine,
                    style: QalamTextStyles.body.copyWith(
                      color: QalamColors.fgMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: QalamSpace.space12),

                  // PRIMARY CTA — exactly ONE filled-teal primary per screen.
                  //   Default variant (D-14): "Next Lesson" → newly unlocked letter.
                  //   Last lesson (D-16): "See Journey" → the journey map.
                  _PrimaryCelebrationButton(
                    label: widget.isLastLesson
                        ? seeJourneyButtonLabel
                        : nextLessonLabel,
                    onPressed: widget.isLastLesson
                        ? () => context.go(
                              '/journey?highlight=${widget.masteredLetterId}',
                            )
                        // onNextLesson is provided in the default variant; fall
                        // back to a no-op rather than crash if absent.
                        : (widget.onNextLesson ?? () {}),
                  ),
                  const SizedBox(height: QalamSpace.space4),

                  // "Back Home" — DEMOTED to a ghost/outlined secondary (D-14:
                  // one primary per screen).
                  _GhostCelebrationButton(
                    label: backHomeLabel,
                    onPressed: widget.onBackHome,
                  ),
                  const SizedBox(height: QalamSpace.space4),

                  // "See journey" tertiary ghost LINK — navigates
                  // /journey?highlight={masteredLetterId} (D-15 handoff).
                  // No star count, no "+N" copy, no score (PLAT-03).
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: QalamTargets.targetMin,
                    ),
                    child: TextButton(
                      onPressed: () => context.go(
                        '/journey?highlight=${widget.masteredLetterId}',
                      ),
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

/// The mastered letter's glyph at display scale with a soft gold glow behind
/// it. Parameterized on [glyph] (Pitfall 6) — never a hardcoded 'ا'.
class _MasteredGlyph extends StatelessWidget {
  const _MasteredGlyph({required this.glyph});

  final String glyph;

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
        // The mastered letter glyph — ArabicText RTL island, Cairo display 96px.
        ArabicText(
          glyph,
          display: true,
          style: const TextStyle(
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

/// The ONE filled-teal primary CTA (D-14/D-16) — full-width comfy touch target
/// with sticker shadow. Exactly one of these is rendered per variant:
/// "Next Lesson" (default) or "See Journey" (last lesson).
class _PrimaryCelebrationButton extends StatelessWidget {
  const _PrimaryCelebrationButton({
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

/// "Back Home" — DEMOTED secondary, ghost/outlined on parchment (D-14: one
/// primary per screen). No fill, no sticker shadow — clearly subordinate to
/// the teal primary above it.
class _GhostCelebrationButton extends StatelessWidget {
  const _GhostCelebrationButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: QalamColors.primary,
          side: const BorderSide(color: QalamColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QalamRadii.lg),
          ),
          minimumSize: const Size.fromHeight(QalamTargets.targetComfy),
          padding: const EdgeInsets.symmetric(
            horizontal: QalamSpace.space12,
            vertical: QalamSpace.space4,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: QalamTextStyles.button.copyWith(
            color: QalamColors.primary,
          ),
        ),
      ),
    );
  }
}
