// Home screen — the Walking Skeleton's visible end-to-end proof.
//
// Wires together every Phase-1 foundation seam in one running screen:
//   - قلم brand logo via flutter_svg (brand-asset seam) + Cairo wordmark
//   - parchment background + soft-aqua placeholder card (semantic tokens only)
//   - heading + body copy from gen-l10n AppLocalizations (no hardcoded copy)
//   - one real vocalized Arabic string through the ArabicText RTL island
//     (the on-screen proof of connected-script shaping)
//   - the round-tripped Drift value (skeletonProof) shown small/muted —
//     the persistence seam made visible
//   - an Open Practice CTA with the signature sticker shadow → /practice
//
// NO stars, totals, streaks, badges, emoji, or pseudo-icons (D-13).
// Copy reads are null-safe so the D-05 direction test (bare MaterialApp,
// no l10n delegates) still renders.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/app_database.dart';
import '../l10n/app_localizations.dart';
import '../theme/brand_theme_ext.dart';
import '../theme/colors.dart';
import '../theme/dimens.dart';
import '../theme/text_styles.dart';
import '../widgets/arabic_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // A real, fully-vocalized Arabic sample — the visible connected-script proof.
  // "قَلَم" (qalam = pen): three joined letters with tashkeel, the product's name.
  static const String _arabicSample = 'قَلَم';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = l10n?.homePlaceholderHeading ?? 'Your Journey Starts Soon';
    final body = l10n?.homePlaceholderBody ??
        'Your letters and lessons will live here. For now, head to Practice and write.';
    final cta = l10n?.openPractice ?? 'Open Practice';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: QalamSpace.space6,
        title: const _QalamWordmark(),
      ),
      body: SafeArea(
        // Scrollable so the column never overflows on short/landscape viewports.
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(QalamSpace.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _PlaceholderCard(
                      heading: heading,
                      body: body,
                      arabicSample: _arabicSample,
                    ),
                    const SizedBox(height: QalamSpace.space8),
                    _OpenPracticeButton(
                      label: cta,
                      onPressed: () => context.go('/practice'),
                    ),
                    const SizedBox(height: QalamSpace.space6),
                    // The persistence seam, made visible (round-tripped DB value).
                    const _PersistenceProof(),
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

/// The قلم wordmark: the brand SVG (asset seam) plus the Cairo wordmark, which
/// is what actually reads on screen (flutter_svg does not rasterize the SVG's
/// embedded text glyphs, so the Cairo wordmark below is what is visible).
class _QalamWordmark extends StatelessWidget {
  const _QalamWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPicture.asset(
          'assets/logo.svg',
          height: QalamSpace.space8,
          semanticsLabel: 'Qalam',
        ),
        const SizedBox(width: QalamSpace.space3),
        const ArabicText(
          'قلم',
          display: true,
          style: TextStyle(
            fontFamily: QalamFonts.arabicDisplay,
            fontWeight: FontWeight.w600,
            fontSize: 32,
            height: 1.0,
            letterSpacing: 0,
            color: QalamColors.primary,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.heading,
    required this.body,
    required this.arabicSample,
  });

  final String heading;
  final String body;
  final String arabicSample;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: QalamColors.surface, // soft-aqua
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: QalamShadows.shadowMd,
      ),
      padding: const EdgeInsets.all(QalamSpace.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // The connected-script proof: a real vocalized Arabic word, RTL island.
          ArabicText(arabicSample, display: true, tashkeel: true),
          const SizedBox(height: QalamSpace.space6),
          Text(
            heading,
            style: QalamTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: QalamSpace.space4),
          Text(
            body,
            style: QalamTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OpenPracticeButton extends StatelessWidget {
  const _OpenPracticeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    return DecoratedBox(
      // The signature flat-bottom "sticker" shadow (CSS --shadow-button).
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        boxShadow: qalam.buttonShadow,
      ),
      child: Material(
        color: QalamColors.primary, // ink-teal — reserved for the primary CTA
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: QalamTargets.targetComfy),
            padding: const EdgeInsets.symmetric(
              horizontal: QalamSpace.space12,
              vertical: QalamSpace.space4,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: QalamTextStyles.button.copyWith(color: QalamColors.fgOnPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

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
