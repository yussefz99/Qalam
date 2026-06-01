// DemoHomeScreen — the presentation Home, built faithful to docs/design home.png.
//
// OWNER OVERRIDE (2026-06-02, Rami): this screen is implemented 1:1 with the
// Claude Design mockup, INCLUDING the gamification chrome — the header star
// count, the three-star lesson rating, and the "This Week · N stars" tally with
// its weekly-progress bar. That intentionally reverses the anti-gamification
// "Decided" rule in CLAUDE.md for this demo screen; reconcile CLAUDE.md if the
// reversal is meant to stand beyond the presentation.
//
// Layout (tablet landscape): a left Home/Journey/Parent nav rail, a header with
// the student avatar + gold star count + settings, the warm "Welcome back,
// Layla." hero beside the reed-pen mascot, the "Today's Lesson" (letter Baa)
// card — the one interactive affordance, tap → Watch — and the Up Next + This
// Week supporting cards. Mocked-data demo (DP-01): no engine. Copy via gen-l10n
// (DP-02); tokens only; parchment ground, never white.

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

/// An Arabic glyph rendered in the Cairo display face at an arbitrary size —
/// used for the lesson tiles (the named ArabicText display role is fixed at
/// 96px, too large for the small Up-Next tiles).
TextStyle _glyphStyle(double size) => TextStyle(
      fontFamily: QalamFonts.arabicDisplay,
      fontWeight: FontWeight.w600,
      fontSize: size,
      height: 1.0,
      letterSpacing: 0,
      color: QalamColors.primaryPressed, // deep-ink
    );

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QalamColors.bg, // parchment — never white
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const <Widget>[
            _NavRail(),
            Expanded(child: _HomeBody()),
          ],
        ),
      ),
    );
  }
}

/// Left navigation rail — Home (active), Journey, Parent. Visual for the demo;
/// only the lesson card drives navigation.
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
          style: QalamTextStyles.label.copyWith(
            color: tint,
            fontSize: QalamFontSizes.fz12,
          ),
        ),
      ],
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _HeaderBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              QalamSpace.space10,
              QalamSpace.space4,
              QalamSpace.space10,
              QalamSpace.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _Hero(),
                const SizedBox(height: QalamSpace.space5),
                const _LessonCard(),
                const SizedBox(height: QalamSpace.space5),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const <Widget>[
                      Expanded(flex: 14, child: _UpNextCard()),
                      SizedBox(width: QalamSpace.space5),
                      Expanded(flex: 10, child: _ThisWeekCard()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Header — student avatar + name/grade on the left; the gold star count and a
/// settings gear on the right.
class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String name = l10n?.demoHomeStudentName ?? 'Layla';
    final String grade = l10n?.demoHomeStudentGrade ?? 'Grade 3';
    final String stars = l10n?.demoHomeStarCount ?? '39';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QalamSpace.space10,
        QalamSpace.space4,
        QalamSpace.space8,
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
              Text(
                name,
                style: QalamTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(grade, style: QalamTextStyles.label),
            ],
          ),
          const Spacer(),
          // Running star count — gamification chrome (owner override).
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
                _StarIcon(size: 18, color: QalamColors.reward),
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
          Icon(Icons.settings_outlined,
              color: QalamColors.fgMuted, size: 26),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow = l10n?.demoHomeEyebrow ?? "SUNDAY · TODAY'S LESSON";
    final String welcome = l10n?.demoHomeWelcome ?? 'Welcome back, Layla.';
    final String subtitle =
        l10n?.demoHomeSubtitle ?? 'Qalam has a new lesson ready for you.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(eyebrow,
                  style: QalamTextStyles.label.copyWith(color: QalamColors.primary)),
              const SizedBox(height: QalamSpace.space1),
              Text(welcome, style: QalamTextStyles.display),
              const SizedBox(height: QalamSpace.space1),
              Text(subtitle, style: QalamTextStyles.body.copyWith(color: QalamColors.fgMuted)),
            ],
          ),
        ),
        const QalamMascot(pose: QalamPose.idle, size: QalamSpace.space20),
      ],
    );
  }
}

/// The hero "Today's Lesson" card — the one interactive affordance. Tap → Watch.
class _LessonCard extends StatelessWidget {
  const _LessonCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow =
        l10n?.demoHomeLessonEyebrow ?? 'LETTERS & WRITING · LESSON 4';
    final String title = l10n?.demoHomeLessonTitle ?? 'The letter Baa';
    final String meta =
        l10n?.demoHomeLessonMeta ?? '8 minutes · stroke order, tracing, and sounds';
    final QalamTheme qalam =
        Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: qalam.buttonShadow,
      ),
      child: Material(
        color: QalamColors.surfaceRaised, // white hero card
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('demoLessonCard'),
          // Canonical path is DemoStep.watch.path ('/demo/watch').
          onTap: () => context.go('/demo/watch'),
          child: Padding(
            padding: const EdgeInsets.all(QalamSpace.space5),
            child: Row(
              children: <Widget>[
                // Letter tile.
                Container(
                  width: QalamSpace.space24,
                  height: QalamSpace.space24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: QalamColors.surface, // soft-aqua
                    borderRadius: BorderRadius.circular(QalamRadii.lg),
                  ),
                  child: ArabicText('ب', style: _glyphStyle(80)),
                ),
                const SizedBox(width: QalamSpace.space5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(eyebrow,
                          style: QalamTextStyles.label
                              .copyWith(color: QalamColors.primary)),
                      const SizedBox(height: QalamSpace.space1),
                      Text(title, style: QalamTextStyles.heading),
                      const SizedBox(height: QalamSpace.space1),
                      Text(meta,
                          style: QalamTextStyles.body
                              .copyWith(color: QalamColors.fgMuted)),
                    ],
                  ),
                ),
                // Three-star lesson rating (un-earned) — gamification chrome
                // (owner override). Outline stars in a muted token.
                Padding(
                  padding: const EdgeInsets.only(left: QalamSpace.space4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(
                      3,
                      (_) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.star_rounded,
                            size: 26, color: QalamColors.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: QalamColors.surfaceRaised,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        boxShadow: QalamShadows.shadowMd,
      ),
      padding: const EdgeInsets.all(QalamSpace.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n?.demoHomeUpNext ?? 'UP NEXT',
              style: QalamTextStyles.label.copyWith(color: QalamColors.primary)),
          const SizedBox(height: QalamSpace.space3),
          _UpNextRow(
            glyph: 'ت',
            eyebrow: l10n?.demoHomeUpNext1Eyebrow ?? 'SENTENCE BUILDING · L 5',
            title: l10n?.demoHomeUpNext1Title ?? 'Sentence: I see a house',
            minutes: l10n?.demoHomeUpNext1Min ?? '6 min',
          ),
          const SizedBox(height: QalamSpace.space3),
          _UpNextRow(
            glyph: 'ث',
            eyebrow: l10n?.demoHomeUpNext2Eyebrow ?? 'PRONUNCIATION · L 6',
            title: l10n?.demoHomeUpNext2Title ?? 'Sounds: tha vs taa',
            minutes: l10n?.demoHomeUpNext2Min ?? '4 min',
          ),
        ],
      ),
    );
  }
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({
    required this.glyph,
    required this.eyebrow,
    required this.title,
    required this.minutes,
  });

  final String glyph;
  final String eyebrow;
  final String title;
  final String minutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: QalamSpace.space16,
          height: QalamSpace.space16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: QalamColors.surface,
            borderRadius: BorderRadius.circular(QalamRadii.md),
          ),
          child: ArabicText(glyph, style: _glyphStyle(30)),
        ),
        const SizedBox(width: QalamSpace.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(eyebrow,
                  style: QalamTextStyles.label
                      .copyWith(color: QalamColors.primary, fontSize: QalamFontSizes.fz12)),
              Text(title,
                  style: QalamTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Text(minutes, style: QalamTextStyles.label),
      ],
    );
  }
}

/// This Week card — the weekly star tally + progress bar (gamification chrome,
/// owner override).
class _ThisWeekCard extends StatelessWidget {
  const _ThisWeekCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
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
          Text(l10n?.demoHomeThisWeek ?? 'THIS WEEK',
              style: QalamTextStyles.label.copyWith(color: QalamColors.primary)),
          const SizedBox(height: QalamSpace.space2),
          Text(l10n?.demoHomeWeekStats ?? '3 lessons · 9 stars',
              style: QalamTextStyles.heading),
          const SizedBox(height: QalamSpace.space3),
          // Weekly progress bar (~66%).
          ClipRRect(
            borderRadius: BorderRadius.circular(QalamRadii.pill),
            child: Stack(
              children: <Widget>[
                Container(height: 16, color: QalamColors.surfaceRaised),
                FractionallySizedBox(
                  widthFactor: 4 / 6,
                  child: Container(height: 16, color: QalamColors.reward),
                ),
              ],
            ),
          ),
          const SizedBox(height: QalamSpace.space2),
          Text(l10n?.demoHomeWeekProgress ?? '4 of 6 weekly lessons',
              style: QalamTextStyles.label),
          const SizedBox(height: QalamSpace.space3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n?.demoHomeSeeJourney ?? 'See journey',
                  style: QalamTextStyles.label
                      .copyWith(color: QalamColors.primary)),
              const SizedBox(width: QalamSpace.space1),
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: QalamColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

/// The gold star icon from the brand kit, with a calm fallback.
class _StarIcon extends StatelessWidget {
  const _StarIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/star.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'stars',
      placeholderBuilder: (_) => Icon(Icons.star_rounded, size: size, color: color),
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.star_rounded, size: size, color: color),
    );
  }
}
