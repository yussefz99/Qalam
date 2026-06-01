// DemoTraceScreen — the half-traced alif, the middle of the walkthrough (DP-04).
//
// The child's ink sits OVER the dotted alif guide, mid-stroke — exactly how
// Phase 3 will look once the real capture + grading land behind it. Here it is
// faked (DP-01): DottedGuidePainter paints the dotted guide plus a static ink
// overlay at inkProgress ~0.5 (the "half-traced" hero state). Both layers derive
// from the single DemoAlif reference source (Pitfall 5) — the glyph is painted,
// never a Text('…').
//
// There is NO recognition engine, NO capture, NO order/count logic, NO
// persistence (DP-01) — nothing to break on stage. A quiet "Stroke 1 of 1"
// progress label is information, NOT a score (DP-06). The submit / stylus-up CTA
// is labeled by the named gen-l10n key `demoTraceSubmit` (authored in plan 02 —
// no hardcoded copy, DP-02) and leads to the HERO Feedback miss screen. "Mark
// Correct" and audio affordances are omitted (DP-07). Tokens only; Western
// numerals via the l10n copy.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../demo_alif.dart';
import '../widgets/dotted_guide_painter.dart';

class DemoTraceScreen extends StatelessWidget {
  const DemoTraceScreen({super.key});

  /// The fraction of the alif already inked — the half-traced hero state.
  static const double _halfTraced = 0.5;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow = l10n?.demoTraceEyebrow ?? 'YOUR TURN · TRACE';
    final String heading = l10n?.demoTraceHeading ?? 'Now You Trace Alif.';
    final String progress = l10n?.demoTraceProgress ?? 'Stroke 1 of 1';
    final String submit = l10n?.demoTraceSubmit ?? 'Done — Check My Work';

    return Scaffold(
      backgroundColor: QalamColors.bg, // parchment — never white
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(QalamSpace.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(eyebrow, style: QalamTextStyles.label),
                    const SizedBox(height: QalamSpace.space2),
                    Text(
                      heading,
                      style: QalamTextStyles.display,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: QalamSpace.space3),
                    // Quiet progress — information, never a score (DP-06).
                    Text(progress, style: QalamTextStyles.label),
                    const SizedBox(height: QalamSpace.space6),
                    const _TraceCanvasCard(inkProgress: _halfTraced),
                    const SizedBox(height: QalamSpace.space8),
                    _SubmitButton(
                      label: submit,
                      // Canonical path is DemoStep.feedbackMiss.path
                      // ('/demo/feedback') — the HERO miss screen by default.
                      onPressed: () => context.go('/demo/feedback'),
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

/// The trace canvas — soft-aqua frame with a parchment inset (mirroring the
/// Practice ink card), painting the half-traced alif from the shared reference
/// source via [DottedGuidePainter].
class _TraceCanvasCard extends StatelessWidget {
  const _TraceCanvasCard({required this.inkProgress});

  final double inkProgress;

  @override
  Widget build(BuildContext context) {
    final List<Offset> points =
        DemoAlif.referencePoints.map((p) => Offset(p[0], p[1])).toList();
    return Container(
      decoration: BoxDecoration(
        color: QalamColors.surface, // soft-aqua frame
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: QalamShadows.shadowMd,
      ),
      padding: const EdgeInsets.all(QalamSpace.space4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        child: ColoredBox(
          color: QalamColors.bg, // parchment writing ground — never white
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(QalamSpace.space24, QalamSpace.space24 * 2),
              painter: DottedGuidePainter(
                referencePoints: points,
                inkProgress: inkProgress,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The primary submit / stylus-up CTA with the signature sticker shadow. Keyed
/// and >= targetComfy so the contract test can assert its size and tap target.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.label, required this.onPressed});

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
        color: QalamColors.primary, // ink-teal — the primary CTA
        borderRadius: BorderRadius.circular(QalamRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('demoTraceSubmitCta'),
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
              style:
                  QalamTextStyles.button.copyWith(color: QalamColors.fgOnPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
