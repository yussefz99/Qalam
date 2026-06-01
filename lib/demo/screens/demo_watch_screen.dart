// DemoWatchScreen — the stroke-order demonstration (DP-03/DP-07).
//
// Watch shows the child HOW alif is formed before they try it: the write-pose
// Qalam mascot beside a dotted alif guide, with a numbered gold start-dot at the
// top and one calm tip. A single "Start Tracing" CTA leads into Trace.
//
// ONE SOURCE OF TRUTH (Pitfall 5): the dotted guide is PAINTED from
// `DemoAlif.referencePoints` — the same normalized geometry every demo screen
// shares — and is never rendered as a glyph string. A glyph would drift from the
// scored/traced path; painting the reference points guarantees guide ==
// reference.
//
// Gold is REWARDS-ONLY everywhere in the app; the numbered start-dot is the one
// sanctioned gold use on this screen (UI-SPEC), via QalamColors.reward. There is
// no audio-playback affordance (DP-07). Static demo (DP-01): the guide is
// painted once, no engine, no animation required. Tokens only.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../router/demo_routes.dart';
import '../../theme/brand_theme_ext.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/qalam_mascot.dart';
import '../demo_alif.dart';

class DemoWatchScreen extends StatelessWidget {
  const DemoWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow = l10n?.demoWatchEyebrow ?? 'WATCH · STROKE ORDER';
    final String heading = l10n?.demoWatchHeading ?? 'Watch Me Write Alif.';
    final String tip =
        l10n?.demoWatchTip ?? 'Start at the gold dot. Follow the line down.';
    final String startTracing = l10n?.demoStartTracing ?? 'Start Tracing';

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
                    const SizedBox(height: QalamSpace.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const QalamMascot(
                          pose: QalamPose.write,
                          size: QalamSpace.space20,
                        ),
                        const SizedBox(width: QalamSpace.space6),
                        const _DottedGuideCard(),
                      ],
                    ),
                    const SizedBox(height: QalamSpace.space8),
                    _TipCard(tip: tip),
                    const SizedBox(height: QalamSpace.space8),
                    _StartTracingButton(
                      label: startTracing,
                      onPressed: () => context.go(DemoStep.trace.path),
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

/// The dotted-alif canvas — a soft-aqua frame with a parchment inset (mirroring
/// the Practice ink card), holding the painted guide. Wrapped in [IgnorePointer]
/// because the demonstration is non-interactive: it is something to watch, not a
/// touch target.
class _DottedGuideCard extends StatelessWidget {
  const _DottedGuideCard();

  @override
  Widget build(BuildContext context) {
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
              painter: DottedAlifPainter(
                points: DemoAlif.referencePoints,
                guideColor: QalamColors.inkStroke,
                startDotColor: QalamColors.reward, // gold — start-dot only
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the alif guide as a DOTTED line through the shared reference points
/// (normalized 0..1), with a numbered gold start-dot at the first point.
///
/// Public so the Watch contract test can prove the guide is fed from
/// [DemoAlif.referencePoints] (one source of truth) and that the start-dot uses
/// the reward token — without rendering the glyph as Text.
class DottedAlifPainter extends CustomPainter {
  DottedAlifPainter({
    required this.points,
    required this.guideColor,
    required this.startDotColor,
  });

  /// Normalized (0..1) reference points the guide is drawn from.
  final List<List<double>> points;

  /// Color of the dotted guide line (deep-ink).
  final Color guideColor;

  /// Color of the numbered start-dot (gold reward token — the only gold here).
  final Color startDotColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Inset so the guide and start-dot never touch the card edges.
    const double inset = QalamSpace.space5;
    final Rect field = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    Offset toPixel(List<double> p) =>
        Offset(field.left + p[0] * field.width, field.top + p[1] * field.height);

    final List<Offset> pixels = points.map(toPixel).toList();

    // Dotted guide: evenly spaced dots stippled along each segment.
    final Paint dot = Paint()
      ..color = guideColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    const double dotRadius = 3;
    const double spacing = QalamSpace.space4; // gap between guide dots
    for (int i = 0; i < pixels.length - 1; i++) {
      final Offset a = pixels[i];
      final Offset b = pixels[i + 1];
      final double segLen = (b - a).distance;
      if (segLen == 0) continue;
      final int steps = (segLen / spacing).floor();
      for (int s = 0; s <= steps; s++) {
        final double t = steps == 0 ? 0 : s / steps;
        canvas.drawCircle(Offset.lerp(a, b, t)!, dotRadius, dot);
      }
    }

    // Numbered gold start-dot at the first reference point (top of alif).
    final Offset start = pixels.first;
    const double startRadius = QalamSpace.space3; // 12px
    canvas.drawCircle(
      start,
      startRadius,
      Paint()
        ..color = startDotColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    final TextPainter number = TextPainter(
      text: TextSpan(
        text: '1',
        style: QalamTextStyles.label.copyWith(
          color: QalamColors.fgOnPrimary,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(
      canvas,
      start - Offset(number.width / 2, number.height / 2),
    );
  }

  @override
  bool shouldRepaint(DottedAlifPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.startDotColor != startDotColor;
}

/// The calm one-line tip beneath the guide.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: QalamColors.primaryTint, // gentle teal wash
        borderRadius: BorderRadius.circular(QalamRadii.lg),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space6,
        vertical: QalamSpace.space4,
      ),
      child: Text(
        tip,
        style: QalamTextStyles.body,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The primary "Start Tracing" CTA with the signature sticker shadow. Keyed and
/// >= targetComfy so the contract test can assert its size and tap target.
class _StartTracingButton extends StatelessWidget {
  const _StartTracingButton({required this.label, required this.onPressed});

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
          key: const Key('demoStartTracingCta'),
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
