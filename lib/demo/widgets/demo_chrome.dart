// Shared chrome + building blocks for the BAA walkthrough screens (Watch, Trace,
// Feedback, Celebration), so each screen matches the Claude Design mockups 1:1
// without re-deriving the nav rail / header / button language every time.
//
// OWNER OVERRIDE (2026-06-02, Rami): the walkthrough is faithful to the mockups,
// INCLUDING the gamification chrome (the header gold-star count, the celebration
// star tally). That intentionally reverses CLAUDE.md's anti-gamification
// "Decided" rule for the demo — already applied to the demo Home. Reconcile
// CLAUDE.md if the reversal is meant to stand beyond the presentation.
//
// Tokens only (QalamColors/Space/Radii/Shadows/TextStyles/Fonts) — no raw hex,
// no Material Colors.*. Parchment ground, never white. The ONLY error color is
// coral (QalamColors.warnSoft); there is no red anywhere.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';

/// An Arabic glyph in the Cairo display face at an arbitrary size — the demo
/// Home's `_glyphStyle`, shared so every Arabic tile/label looks identical.
TextStyle demoGlyphStyle(double size, {Color? color}) => TextStyle(
      fontFamily: QalamFonts.arabicDisplay,
      fontWeight: FontWeight.w600,
      fontSize: size,
      height: 1.0,
      letterSpacing: 0,
      color: color ?? QalamColors.primaryPressed, // deep-ink
    );

/// The walkthrough scaffold: left Home/Journey/Parent nav rail + a header
/// (student avatar, name/grade, gold star count, settings, optional close), with
/// [child] filling the rest. Home is the active rail item on every walkthrough
/// screen, matching the mockups.
class DemoChrome extends StatelessWidget {
  const DemoChrome({
    super.key,
    required this.child,
    this.stars = '39',
    this.showClose = true,
  });

  final Widget child;

  /// The header gold-star count (39 through the loop; 42 after the +3 on the
  /// Celebration screen — gamification chrome, owner override).
  final String stars;

  /// Whether the header shows a close (×) affordance (Watch/Trace/Feedback do;
  /// Celebration mirrors Home and does not).
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QalamColors.bg, // parchment — never white
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _NavRail(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _HeaderBar(stars: stars, showClose: showClose),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Container(
      width: 92,
      color: QalamColors.bgDeep,
      padding: const EdgeInsets.symmetric(vertical: QalamSpace.space6),
      child: Column(
        children: <Widget>[
          _NavItem(
            icon: Icons.home_rounded,
            label: l10n?.demoHomeNavHome ?? 'Home',
            active: true,
          ),
          const SizedBox(height: QalamSpace.space4),
          _NavItem(
            icon: Icons.map_outlined,
            label: l10n?.demoHomeNavJourney ?? 'Journey',
            active: false,
          ),
          const SizedBox(height: QalamSpace.space4),
          _NavItem(
            icon: Icons.person_outline,
            label: l10n?.demoHomeNavParent ?? 'Parent',
            active: false,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color tint = active ? QalamColors.primary : QalamColors.fgMuted;
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QalamSpace.space4,
            vertical: QalamSpace.space2,
          ),
          decoration: BoxDecoration(
            color: active ? QalamColors.primaryTint : null,
            borderRadius: BorderRadius.circular(QalamRadii.md),
          ),
          child: Icon(icon, color: tint, size: 26),
        ),
        const SizedBox(height: QalamSpace.space1),
        Text(
          label,
          style: QalamTextStyles.label
              .copyWith(color: tint, fontSize: QalamFontSizes.fz12),
        ),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.stars, required this.showClose});

  final String stars;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String name = l10n?.demoHomeStudentName ?? 'Layla';
    final String grade = l10n?.demoHomeStudentGrade ?? 'Grade 3';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QalamSpace.space8,
        QalamSpace.space4,
        QalamSpace.space6,
        QalamSpace.space2,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: QalamSpace.space12,
            height: QalamSpace.space12,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QalamColors.primaryTint,
              shape: BoxShape.circle,
              border: Border.all(color: QalamColors.primary, width: 2),
            ),
            child: Text(
              name.isNotEmpty ? name[0] : 'L',
              style: QalamTextStyles.heading.copyWith(color: QalamColors.primary),
            ),
          ),
          const SizedBox(width: QalamSpace.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(name,
                  style: QalamTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
              Text(grade, style: QalamTextStyles.label),
            ],
          ),
          const Spacer(),
          // Running gold star count — gamification chrome (owner override).
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space3,
              vertical: QalamSpace.space1,
            ),
            decoration: BoxDecoration(
              color: QalamColors.rewardTint,
              borderRadius: BorderRadius.circular(QalamRadii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const DemoStarIcon(size: 18, color: QalamColors.reward),
                const SizedBox(width: QalamSpace.space1),
                Text(
                  stars,
                  style: QalamTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: QalamColors.primaryPressed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: QalamSpace.space3),
          const Icon(Icons.settings_outlined, color: QalamColors.fgMuted, size: 26),
          if (showClose) ...<Widget>[
            const SizedBox(width: QalamSpace.space3),
            const Icon(Icons.close_rounded, color: QalamColors.fgMuted, size: 26),
          ],
        ],
      ),
    );
  }
}

/// The teal uppercase eyebrow used above every screen heading.
class DemoEyebrow extends StatelessWidget {
  const DemoEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: QalamTextStyles.label.copyWith(
        color: QalamColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// The primary "sticker" CTA — ink-teal with the signature flat-bottom shadow, a
/// comfortable touch target, an optional leading arrow, and a [Key] so contract
/// tests can tap it and assert the route advanced.
class DemoPrimaryCta extends StatelessWidget {
  const DemoPrimaryCta({
    super.key,
    required this.ctaKey,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final Key ctaKey;
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final QalamTheme qalam =
        Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QalamRadii.pill),
        boxShadow: qalam.buttonShadow,
      ),
      child: Material(
        color: QalamColors.primary,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ctaKey,
          onTap: onPressed,
          child: Container(
            constraints:
                const BoxConstraints(minHeight: QalamTargets.targetComfy),
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space10,
              vertical: QalamSpace.space4,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, color: QalamColors.fgOnPrimary, size: 28),
                  const SizedBox(width: QalamSpace.space3),
                ],
                Text(
                  label,
                  style: QalamTextStyles.button
                      .copyWith(color: QalamColors.fgOnPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An outlined ghost / secondary button. Decorative when [onPressed] is null
/// (e.g. the mockup's "Mark correct" / "Hear the sound" affordances, which carry
/// no behavior in the mocked demo).
class DemoGhostButton extends StatelessWidget {
  const DemoGhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// White "secondary" fill (with a soft aqua-edge sticker shadow) instead of a
  /// transparent outline — the mockup's "Mark correct" treatment.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      constraints: const BoxConstraints(minHeight: QalamTargets.targetMin),
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space6,
        vertical: QalamSpace.space3,
      ),
      decoration: BoxDecoration(
        color: filled ? QalamColors.surfaceRaised : null,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
        border: filled
            ? null
            : Border.all(color: QalamColors.border, width: 2),
        boxShadow: filled
            ? const <BoxShadow>[
                BoxShadow(color: QalamColors.border, offset: Offset(0, 4)),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: QalamColors.primaryPressed, size: 22),
            const SizedBox(width: QalamSpace.space2),
          ],
          Text(
            label,
            style: QalamTextStyles.button.copyWith(
              color: QalamColors.primaryPressed,
              fontSize: QalamFontSizes.fz20,
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(QalamRadii.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onPressed, child: content),
    );
  }
}

/// A soft-aqua side card (the Watch "TIP" and Trace "LISTEN" panels).
class DemoAquaCard extends StatelessWidget {
  const DemoAquaCard({super.key, this.eyebrow, required this.children});

  final String? eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QalamColors.surface, // soft-aqua
        borderRadius: BorderRadius.circular(QalamRadii.lg),
      ),
      padding: const EdgeInsets.all(QalamSpace.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (eyebrow != null) ...<Widget>[
            DemoEyebrow(eyebrow!),
            const SizedBox(height: QalamSpace.space3),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// The white canvas card that frames a painted guide/ink (Watch/Trace/Feedback).
class DemoCanvasCard extends StatelessWidget {
  const DemoCanvasCard({super.key, required this.size, required this.painter});

  final double size;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QalamColors.surfaceRaised, // white canvas
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: QalamShadows.shadowMd,
      ),
      padding: const EdgeInsets.all(QalamSpace.space4),
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(size, size),
          painter: painter,
        ),
      ),
    );
  }
}

/// The brand gold star (assets/icons/star.svg) with a calm icon fallback.
class DemoStarIcon extends StatelessWidget {
  const DemoStarIcon({super.key, required this.size, this.color = QalamColors.reward});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/star.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'star',
      placeholderBuilder: (_) => Icon(Icons.star_rounded, size: size, color: color),
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.star_rounded, size: size, color: color),
    );
  }
}
