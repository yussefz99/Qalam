// Home screen — warm demo home (Phase 03-05).
//
// Shows:
//   - Left NavigationRail: Home (active), Journey (locked), Parent (locked).
//   - Qalam mascot (assets/mascot/qalam-idle.svg) with graceful fallback.
//   - Static greeting "Welcome back, Layla." (no profile system — Phase 5).
//   - "Today's lesson" card for alif → navigates to /practice on tap.
//   - _PersistenceProof (round-tripped Drift value, visible seam).
//
// Anti-gamification invariants (PLAT-03 / D-13):
//   - NO QalamColors.reward (gold) on this screen.
//   - NO ⭐ counter, no "THIS WEEK" tally, no streak, no score, no badge.
//   - Parent is inert — no onTap, visibly labelled "Coming soon" (Phase 9).
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
import '../features/onboarding/onboarding_data.dart';
import '../l10n/app_localizations.dart';
import '../providers/profile_providers.dart';
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
            // Left nav-rail: Home (active), Journey (locked), Parent (locked).
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
                      // Today's lesson card.
                      _TodaysLessonCard(l10n: l10n),
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
          // Parent — locked, Phase 9.
          _NavItem(
            iconAsset: 'assets/icons/lock.svg',
            label: l10n?.navParent ?? 'Parent',
            isActive: false,
            isLocked: true,
            sublabel: l10n?.comingSoon ?? 'Coming soon',
            onTap: null, // Inert — no route.
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
    this.sublabel,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool isActive;
  final bool isLocked;
  final String? sublabel;
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
              if (sublabel != null) ...<Widget>[
                const SizedBox(height: QalamSpace.space1),
                Text(
                  sublabel!,
                  style: QalamTextStyles.label.copyWith(
                    color: QalamColors.fgMuted,
                    fontSize: QalamFontSizes.fz12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
  /// picked at onboarding (D-3 — ID→tint in code; NOT QalamColors.reward).
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
// Today's lesson card
// ---------------------------------------------------------------------------

class _TodaysLessonCard extends StatelessWidget {
  const _TodaysLessonCard({required this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;

    return GestureDetector(
      key: const Key('todaysLessonCard'),
      onTap: () => context.go('/practice'),
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
              // Alif glyph — the RTL island for the lesson letter.
              Container(
                width: QalamSpace.space16,
                height: QalamSpace.space16,
                decoration: BoxDecoration(
                  color: QalamColors.primaryTint,
                  borderRadius: BorderRadius.circular(QalamRadii.lg),
                ),
                alignment: Alignment.center,
                child: const ArabicText('ا', display: true),
              ),
              const SizedBox(width: QalamSpace.space6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n?.homeLessonEyebrow ?? 'TODAY\'S LESSON',
                      style: QalamTextStyles.label,
                    ),
                    const SizedBox(height: QalamSpace.space2),
                    Text(
                      l10n?.homeLessonTitle ?? 'The Letter Alif',
                      style: QalamTextStyles.heading,
                    ),
                    const SizedBox(height: QalamSpace.space2),
                    Text(
                      l10n?.homeLessonSubtitle ?? 'Stroke order and tracing',
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
