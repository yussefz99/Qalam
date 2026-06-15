// Home screen — warm demo home (Phase 03-05).
//
// Shows:
//   - Left NavigationRail: Home (active), Journey (unlocked), Parent (unlocked).
//   - Qalam mascot (assets/mascot/qalam-idle.svg) with graceful fallback.
//   - Static greeting "Welcome back, Layla." (no profile system — Phase 5).
//   - "Today's lesson" card for alif → navigates to /practice on tap.
//   - _PersistenceProof (round-tripped Drift value, visible seam).
//
// Anti-gamification invariants (PLAT-03 / D-13):
//   - NO reward-gold token on this screen (gold = mastery rewards only).
//   - NO ⭐ counter, no "THIS WEEK" tally, no streak, no score, no badge.
//   - Parent nav item unlocked in Phase 9: context.go('/parent') wired (the
//     PIN gate is the access boundary; the child cannot bypass it).
//   - Journey nav item unlocked in Phase 03.1: context.go('/journey') wired.
//
// Null-safe l10n reads throughout:  l10n?.getter ?? 'fallback'  (D-05 compat).
// The D-05 direction test wraps this in bare MaterialApp (no router, no scope);
// it never taps, so context.go inside tap handlers is safe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../features/onboarding/onboarding_data.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson.dart';
import '../models/letter.dart';
import '../providers/profile_providers.dart';
import '../providers/progression_providers.dart';
import '../theme/brand_theme_ext.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';
import '../widgets/arabic_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left nav-rail: Home (active), Journey + Parent (both unlocked).
            _HomeNavRail(l10n: l10n),
            // Main content area.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: QalamSpace.space8,
                  vertical: QalamSpace.space8,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Mascot + greeting header.
                      _GreetingHeader(l10n: l10n),
                      const SizedBox(height: QalamSpace.space8),
                      // Today's lesson card — settles in like a prepared
                      // worksheet, once per arrival (D-13).
                      _PreparedDeskEntrance(
                        child: _TodaysLessonCard(l10n: l10n),
                      ),
                      const SizedBox(height: QalamSpace.space6),
                      // Persistence seam (round-tripped Drift value).
                      const _PersistenceProof(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left nav-rail
// ---------------------------------------------------------------------------

class _HomeNavRail extends StatelessWidget {
  const _HomeNavRail({required this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: QalamColors.surface,
        border: Border(
          right: BorderSide(color: QalamColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: QalamSpace.space8),
      child: Column(
        children: <Widget>[
          // Home — active.
          _NavItem(
            iconAsset: 'assets/icons/qalam-nib.svg',
            label: l10n?.navHome ?? 'Home',
            isActive: true,
            isLocked: false,
            onTap: null, // Already on Home.
          ),
          const SizedBox(height: QalamSpace.space4),
          // Journey — unlocked in Phase 03.1, navigates to /journey.
          _NavItem(
            iconAsset: 'assets/icons/map.svg',
            label: l10n?.navJourney ?? 'Journey',
            isActive: false,
            isLocked: false,
            onTap: () => context.go('/journey'),
          ),
          const SizedBox(height: QalamSpace.space4),
          // Parent — unlocked in Phase 9: routes to the PIN-gated /parent area.
          // A non-lock glyph (A-02: lock.svg is never shipped for this item).
          _NavItem(
            iconAsset: 'assets/icons/ink-drop.svg',
            label: l10n?.navParent ?? 'Parent',
            isActive: false,
            isLocked: false,
            onTap: () => context.go('/parent'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.isLocked,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool isActive;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color labelColor =
        isActive ? QalamColors.primary : QalamColors.fgMuted;

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: QalamSpace.space3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: QalamTargets.targetMin,
                height: QalamTargets.targetMin,
                child: Center(
                  child: _SafeSvgIcon(
                    asset: iconAsset,
                    size: QalamSpace.space8,
                    color: labelColor,
                  ),
                ),
              ),
              Text(
                label,
                style: QalamTextStyles.label.copyWith(color: labelColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders an SVG icon with a graceful SizedBox fallback if the asset is missing.
class _SafeSvgIcon extends StatelessWidget {
  const _SafeSvgIcon({
    required this.asset,
    required this.size,
    this.color,
  });

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting header (mascot + warm text)
// ---------------------------------------------------------------------------

/// Greeting header — scope-aware (mirrors `_PersistenceProof`, lines 374-404).
///
/// The real app always supplies a [ProviderScope]; the bare D-05 direction test
/// does not. When no scope is present this degrades to the static greeting (no
/// avatar) instead of throwing "No ProviderScope found". When a scope IS present
/// it defers to [_GreetingHeaderReader], which reads `childProfileProvider`.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final bool hasScope =
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() !=
            null;
    if (!hasScope) {
      // No-scope fallback (bare harness): static greeting, no avatar.
      return _GreetingLayout(
        l10n: l10n,
        avatarId: null,
        nicknameLabel: null,
      );
    }
    return _GreetingHeaderReader(l10n: l10n);
  }
}

/// Reads `childProfileProvider` and drives the greeting line + avatar from the
/// child's chosen fixed-set nickname/avatar (S1-03 "shown on home").
///
/// `.when` mirrors `_PersistenceProofReader`: on loading/error/no-profile it
/// degrades to the static greeting so Home never blocks or crashes (T-05-07).
class _GreetingHeaderReader extends ConsumerWidget {
  const _GreetingHeaderReader({required this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(childProfileProvider).when(
          data: (ChildProfile? profile) {
            if (profile == null) {
              return _GreetingLayout(
                l10n: l10n,
                avatarId: null,
                nicknameLabel: null,
              );
            }
            // Resolve fixed-set ids → presentation (label/visual) in code only.
            return _GreetingLayout(
              l10n: l10n,
              avatarId: profile.avatarId,
              nicknameLabel: resolveNicknameLabel(profile.nicknameId),
            );
          },
          loading: () => _GreetingLayout(
            l10n: l10n,
            avatarId: null,
            nicknameLabel: null,
          ),
          error: (_, _) => _GreetingLayout(
            l10n: l10n,
            avatarId: null,
            nicknameLabel: null,
          ),
        );
  }
}

/// Pure presentation of the greeting header. When [nicknameLabel] is non-null
/// the greeting shows "Welcome back," + the Arabic nickname island (via
/// [ArabicText]); when [avatarId] is non-null the chosen avatar circle replaces
/// the mascot. Both null → the static (mascot + literal) fallback.
class _GreetingLayout extends StatelessWidget {
  const _GreetingLayout({
    required this.l10n,
    required this.avatarId,
    required this.nicknameLabel,
  });

  final AppLocalizations? l10n;
  final String? avatarId;
  final String? nicknameLabel;

  /// Placeholder palette mirrors AvatarGrid so the home avatar matches the one
  /// picked at onboarding (D-3 — ID→tint in code; never the reward gold).
  static const List<Color> _placeholderTints = <Color>[
    QalamColors.primaryTint,
    QalamColors.successTint,
    QalamColors.warnSoftTint,
    QalamColors.bgDeep,
    QalamColors.border,
    QalamColors.surface,
  ];

  Color _tintFor(String id) {
    final int index = kAvatarIds.indexOf(id);
    if (index < 0) return QalamColors.primaryTint;
    return _placeholderTints[index % _placeholderTints.length];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Leading visual: chosen avatar circle if present, else the mascot.
        if (avatarId != null)
          Container(
            key: Key('homeAvatar_$avatarId'),
            width: QalamSpace.space16,
            height: QalamSpace.space16,
            decoration: BoxDecoration(
              color: _tintFor(avatarId!),
              shape: BoxShape.circle,
              border: Border.all(color: QalamColors.border, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarId!.split('_').last,
              style: QalamTextStyles.heading.copyWith(color: QalamColors.fg),
            ),
          )
        else
          // Mascot: qalam-idle.svg — graceful fallback if asset missing.
          SvgPicture.asset(
            'assets/mascot/qalam-idle.svg',
            width: QalamSpace.space16,
            height: QalamSpace.space16,
            semanticsLabel: 'Qalam',
            placeholderBuilder: (_) => const SizedBox(
              width: QalamSpace.space16,
              height: QalamSpace.space16,
            ),
          ),
        const SizedBox(width: QalamSpace.space6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (nicknameLabel != null)
                // Greeting line: English prefix + the Arabic nickname island.
                // The nickname renders through ArabicText (RTL island), NOT raw
                // Text and NOT a global Directionality (Pitfall 3).
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        'Welcome back, ',
                        style: QalamTextStyles.heading,
                      ),
                    ),
                    ArabicText(
                      nicknameLabel!,
                      style: QalamTextStyles.heading,
                    ),
                  ],
                )
              else
                Text(
                  // Literal fallback when no profile/scope is available. The ARB
                  // key is a {nickname} template; with no nickname we keep the
                  // original warm static greeting.
                  l10n?.homeGreeting('') ?? 'Welcome back, Layla.',
                  style: QalamTextStyles.heading,
                ),
              const SizedBox(height: QalamSpace.space2),
              Text(
                l10n?.homeGreetingSubtitle ??
                    'Qalam has a new lesson ready for you.',
                style: QalamTextStyles.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Prepared-desk entrance (D-13)
// ---------------------------------------------------------------------------

/// First beat of the prepared-desk entrance (D-13): the today-card slides up
/// ~24px while fading in — `easeOutQuart` over `durSlow` (420ms) — like a
/// teacher laying out a worksheet.
///
/// Plays ONCE per arrival at Home: the one-shot decision lives in this State,
/// which provider rebuilds below (inside the card's reader) never recreate.
/// Reduced motion (`MediaQuery.disableAnimations`) skips the controller and
/// renders fully settled immediately.
class _PreparedDeskEntrance extends StatefulWidget {
  const _PreparedDeskEntrance({required this.child});

  final Widget child;

  @override
  State<_PreparedDeskEntrance> createState() => _PreparedDeskEntranceState();
}

class _PreparedDeskEntranceState extends State<_PreparedDeskEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _progress;
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return; // once per arrival — data refreshes never replay it
    _played = true;
    if (MediaQuery.of(context).disableAnimations) return; // settled at once
    final controller = AnimationController(
      vsync: this,
      duration: QalamMotion.durSlow,
    );
    _controller = controller;
    _progress = CurvedAnimation(
      parent: controller,
      curve: QalamMotion.easeOutQuart,
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) return widget.child; // reduced motion: settled
    return AnimatedBuilder(
      animation: progress,
      builder: (BuildContext context, Widget? child) {
        final double v = progress.value;
        return Opacity(
          key: const Key('todayCardEntranceFade'),
          opacity: v,
          child: Transform.translate(
            // Slide up ~24px (QalamSpace.space6) as the card settles.
            offset: Offset(0, QalamSpace.space6 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Second beat of the prepared-desk entrance (D-13): the letter glyph fades
/// up over `durBase` (220ms) AFTER the card settles (`durSlow`).
///
/// One-shot per arrival (same State-persistence reasoning as
/// [_PreparedDeskEntrance] — the layout keeps this widget at a stable tree
/// position across loading/data/all-mastered rebuilds). Reduced motion
/// renders fully settled immediately.
class _GlyphEntranceFade extends StatefulWidget {
  const _GlyphEntranceFade({required this.child});

  final Widget child;

  @override
  State<_GlyphEntranceFade> createState() => _GlyphEntranceFadeState();
}

class _GlyphEntranceFadeState extends State<_GlyphEntranceFade>
    with SingleTickerProviderStateMixin {
  /// Card-settle delay + the glyph fade itself (tokens only).
  static final Duration _total = QalamMotion.durSlow + QalamMotion.durBase;

  AnimationController? _controller;
  Animation<double>? _opacity;
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return;
    _played = true;
    if (MediaQuery.of(context).disableAnimations) return;
    final controller = AnimationController(vsync: this, duration: _total);
    _controller = controller;
    _opacity = CurvedAnimation(
      parent: controller,
      // Hold at 0 while the card settles (durSlow), then fade over durBase.
      curve: Interval(
        QalamMotion.durSlow.inMilliseconds / _total.inMilliseconds,
        1.0,
        curve: QalamMotion.easeOutQuart,
      ),
    );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = _opacity;
    if (opacity == null) return widget.child; // reduced motion: settled
    return AnimatedBuilder(
      animation: opacity,
      builder: (BuildContext context, Widget? child) => Opacity(
        key: const Key('todayCardGlyphFade'),
        opacity: opacity.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Today's lesson card (live — Plan 06-05)
// ---------------------------------------------------------------------------

/// The resolved data the today-card renders: today's lesson id plus its
/// letter (glyph char, romanized name, clean-rep target). `null` from the
/// provider below means every available lesson is passed (D-11 all-mastered).
class _TodayCardData {
  const _TodayCardData({required this.lessonId, required this.letter});

  final String lessonId;
  final Letter letter;
}

/// Composes todayLessonProvider (06-03) with the curriculum letter lookup.
///
/// Error degradation (T-06-08 / UI-SPEC error contract): any failure in the
/// progression chain degrades to the profile's `startingLessonId` lesson so
/// the child always has a Start. If even that fails, the reader's
/// `.when(error:)` branch renders the static alif fallback — a raw error is
/// never shown to the child.
final _todayCardDataProvider = FutureProvider<_TodayCardData?>((ref) async {
  Future<_TodayCardData> resolve(Lesson lesson) async {
    final item = lesson.items.firstWhere((i) => i.type == 'letter');
    final letter =
        await ref.watch(curriculumRepositoryProvider).getLetter(item.ref);
    if (letter == null) {
      throw StateError('unknown letter "${item.ref}" in ${lesson.id}');
    }
    return _TodayCardData(lessonId: lesson.id, letter: letter);
  }

  try {
    final today = await ref.watch(todayLessonProvider.future);
    if (today == null) return null; // all mastered (D-11)
    return await resolve(today);
  } catch (_) {
    // Bounded profile await mirrors progressionProvider's own degradation
    // (06-03): the unoverridden profile read can hang in headless envs.
    final profile = await ref
        .watch(childProfileProvider.future)
        .timeout(const Duration(seconds: 3));
    final lessonId = profile?.startingLessonId ?? 'lesson_01';
    final lesson =
        await ref.watch(curriculumRepositoryProvider).getLesson(lessonId);
    if (lesson == null) throw StateError('unknown lesson "$lessonId"');
    return await resolve(lesson);
  }
});

/// Today's lesson card — scope-aware (mirrors `_GreetingHeader`).
///
/// The bare D-05 direction test pumps HomeScreen without a ProviderScope; in
/// that harness the card degrades to the static alif layout instead of
/// throwing "No ProviderScope found". With a scope it defers to
/// [_TodaysLessonCardReader], which drives the live card (D-08).
class _TodaysLessonCard extends StatelessWidget {
  const _TodaysLessonCard({required this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final bool hasScope =
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() !=
            null;
    if (!hasScope) {
      // No-scope fallback (bare harness): static alif card.
      return _TodayCardLayout(
        eyebrowText: l10n?.homeLessonEyebrow ?? 'TODAY\'S LESSON',
        titleText: l10n?.homeLessonTitle ?? 'The Letter Alif',
        subtitleText: l10n?.homeLessonSubtitle ?? 'Stroke order and tracing',
        glyphChar: 'ا',
        glyphAlpha: 1.0,
        glyphSemantics: null,
        route: '/practice?lesson=lesson_01',
      );
    }
    return _TodaysLessonCardReader(l10n: l10n);
  }
}

/// Reads the composed today-card data and renders the matching variant with
/// full `.when` degradation — loading and error never surface to the child.
class _TodaysLessonCardReader extends ConsumerWidget {
  const _TodaysLessonCardReader({required this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(_todayCardDataProvider).when(
          data: (_TodayCardData? data) {
            if (data == null) {
              // All-mastered end state (D-11): calm, factual, no totals.
              // Tap goes to the Journey — replay lives there (D-12).
              return _TodayCardLayout(
                eyebrowText: l10n?.homeAllMasteredEyebrow ?? 'YOUR LETTERS',
                titleText: l10n?.homeAllMasteredTitle ??
                    'You\'ve mastered all your letters.',
                subtitleText: l10n?.homeAllMasteredBody ??
                    'Visit your journey to practice any letter again.',
                glyphChar: null,
                glyphAlpha: 1.0,
                glyphSemantics: null,
                route: '/journey',
              );
            }
            // Ink-fill (D-09): the persisted clean-rep depth IS the progress.
            // Reps loading/error degrade silently to 0 (a faint ink wash).
            final int reps =
                ref.watch(cleanRepsForLetterProvider(data.letter.id)).when(
                      data: (int value) => value,
                      loading: () => 0,
                      error: (_, _) => 0,
                    );
            final int total = data.letter.cleanRepsToAdvance;
            final double fraction =
                total <= 0 ? 1.0 : (reps / total).clamp(0.0, 1.0);
            return _TodayCardLayout(
              eyebrowText: l10n?.homeLessonEyebrow ?? 'TODAY\'S LESSON',
              titleText: l10n?.homeLessonTitleFor(data.letter.name.display) ??
                  'The Letter ${data.letter.name.display}',
              subtitleText:
                  l10n?.homeLessonSubtitle ?? 'Stroke order and tracing',
              glyphChar: data.letter.char,
              // UI-SPEC prescriptive ramp: 0.25 + 0.75 × (reps / total).
              glyphAlpha: 0.25 + 0.75 * fraction,
              glyphSemantics: l10n?.homeInkFillSemantics(reps, total) ??
                  '$reps of $total clean reps',
              // Plan 07-06: baa has a full 6-section Letter Unit, so its
              // today-card opens `/unit?letter=baa` instead of the thin
              // `/practice` loop. Every OTHER letter keeps its existing
              // `/practice?lesson=` path until its unit is built — alif's
              // start is untouched. (Deep-link reuse, SC#5.)
              route: data.letter.id == 'baa'
                  ? '/unit?letter=${data.letter.id}'
                  : '/practice?lesson=${data.lessonId}',
            );
          },
          // Loading: blank glyph + blank title, no spinner chrome (UI-SPEC —
          // mirrors the _GreetingHeader degradation pattern).
          loading: () => _TodayCardLayout(
            eyebrowText: l10n?.homeLessonEyebrow ?? 'TODAY\'S LESSON',
            titleText: null,
            subtitleText: null,
            glyphChar: null,
            glyphAlpha: 1.0,
            glyphSemantics: null,
            route: null,
          ),
          // Final fallback (the degradation chain itself failed): the static
          // alif Start — never a raw error to the child (T-06-08).
          error: (_, _) => _TodayCardLayout(
            eyebrowText: l10n?.homeLessonEyebrow ?? 'TODAY\'S LESSON',
            titleText: l10n?.homeLessonTitle ?? 'The Letter Alif',
            subtitleText:
                l10n?.homeLessonSubtitle ?? 'Stroke order and tracing',
            glyphChar: 'ا',
            glyphAlpha: 1.0,
            glyphSemantics: null,
            route: '/practice?lesson=lesson_01',
          ),
        );
  }
}

/// Pure presentation of the today-card. Keeps the existing structure (D-08):
/// same Row, glyph container, chevron pill, and `Key('todaysLessonCard')`.
///
/// - [glyphChar] null → empty glyph container (loading / all-mastered).
/// - [titleText] null → blank title area (loading).
/// - [glyphAlpha] — the D-09 ink-fill opacity on deep-ink; NEVER gold.
/// - [glyphSemantics] — a11y-only rep progress; no visible numerals.
/// - [route] null → inert tap (loading); otherwise the single Start.
class _TodayCardLayout extends StatelessWidget {
  const _TodayCardLayout({
    required this.eyebrowText,
    required this.titleText,
    required this.subtitleText,
    required this.glyphChar,
    required this.glyphAlpha,
    required this.glyphSemantics,
    required this.route,
  });

  final String eyebrowText;
  final String? titleText;
  final String? subtitleText;
  final String? glyphChar;
  final double glyphAlpha;
  final String? glyphSemantics;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    final String? destination = route;

    // The lesson glyph — deep-ink at the persisted rep depth (D-09). The ink
    // is the progress: a11y label only, never a visible numeral.
    Widget glyph = Container(
      width: QalamSpace.space16,
      height: QalamSpace.space16,
      decoration: BoxDecoration(
        color: QalamColors.primaryTint,
        borderRadius: BorderRadius.circular(QalamRadii.lg),
      ),
      alignment: Alignment.center,
      child: glyphChar == null
          ? null
          : ArabicText(
              glyphChar!,
              display: true,
              style: QalamTextStyles.arDisplay.copyWith(
                color: QalamColors.inkStroke.withValues(alpha: glyphAlpha),
              ),
            ),
    );
    if (glyphSemantics != null) {
      glyph = Semantics(
        label: glyphSemantics,
        // Own node — without this the label would merge into the card's tap
        // node instead of reading as "{n} of {N} clean reps".
        container: true,
        child: ExcludeSemantics(child: glyph),
      );
    }
    // Outermost wrap: keeps the fade's State at a stable tree position across
    // loading/data/all-mastered rebuilds, so the entrance never replays (D-13).
    glyph = _GlyphEntranceFade(child: glyph);

    return GestureDetector(
      key: const Key('todaysLessonCard'),
      onTap: destination == null ? null : () => context.go(destination),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(QalamRadii.xl),
          boxShadow: QalamShadows.shadowMd,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: QalamColors.surface,
            borderRadius: BorderRadius.circular(QalamRadii.xl),
          ),
          padding: const EdgeInsets.all(QalamSpace.space8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              glyph,
              const SizedBox(width: QalamSpace.space6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      eyebrowText,
                      style: QalamTextStyles.label,
                    ),
                    const SizedBox(height: QalamSpace.space2),
                    if (titleText != null)
                      Text(
                        titleText!,
                        style: QalamTextStyles.heading,
                      )
                    else
                      const SizedBox(height: QalamSpace.space8),
                    const SizedBox(height: QalamSpace.space2),
                    if (subtitleText != null)
                      Text(
                        subtitleText!,
                        style: QalamTextStyles.body,
                      ),
                  ],
                ),
              ),
              // Forward-arrow affordance (uses the button shadow as the primary
              // CTA accent — teal, no gold, no reward token).
              DecoratedBox(
                decoration: BoxDecoration(
                  color: QalamColors.primary,
                  borderRadius: BorderRadius.circular(QalamRadii.pill),
                  boxShadow: qalam.buttonShadow,
                ),
                child: const SizedBox(
                  width: QalamTargets.targetComfy,
                  height: QalamTargets.targetComfy,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: QalamColors.fgOnPrimary,
                    size: QalamSpace.space8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Persistence seam (kept from Phase 1 walking skeleton)
// ---------------------------------------------------------------------------

/// Shows the round-tripped Drift value (the visible persistence seam).
///
/// Reads the provider only when a [ProviderScope] is present. The real app
/// always supplies one (main() wraps QalamApp in ProviderScope); a bare test
/// harness (the D-05 direction test) does not, so this degrades to an empty
/// box instead of throwing "No ProviderScope found".
class _PersistenceProof extends StatelessWidget {
  const _PersistenceProof();

  @override
  Widget build(BuildContext context) {
    final hasScope =
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() !=
            null;
    if (!hasScope) return const SizedBox.shrink();
    return const _PersistenceProofReader();
  }
}

class _PersistenceProofReader extends ConsumerWidget {
  const _PersistenceProofReader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proof = ref.watch(skeletonProofProvider);
    final text = proof.when(
      data: (value) => value,
      loading: () => '…',
      error: (_, _) => 'not saved',
    );
    return Text(
      text,
      style: QalamTextStyles.label.copyWith(color: QalamColors.fgMuted),
      textAlign: TextAlign.center,
    );
  }
}
