// DemoWatchScreen — the stroke-order demonstration, rebuilt 1:1 with the design
// `DemoScreen` mockup (docs/design/kit/.../screenshots/02-*).
//
// Watch shows the child HOW baa is formed before they try it: the walkthrough
// chrome (nav rail + header), the write-pose Qalam mascot beside a white canvas
// that PAINTS the dotted baa guide — with a numbered gold start-dot and the
// distinguishing diacritic dot — plus an aqua "TIP" card, and a "Start Tracing"
// CTA into Trace.
//
// ONE SOURCE OF TRUTH (Pitfall 5): the guide is PAINTED from
// `DemoBaa.referencePoints` (the geometry every demo screen shares) — never a
// Text('ب') that could drift from the traced path. Mocked demo (DP-01): no
// engine, no animation required; the audio/replay affordances are faithful to
// the mockup but decorative. Tokens only; parchment ground, never white.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/qalam_mascot.dart';
import '../demo_baa.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/dotted_guide_painter.dart';

const double _kMascotSize = 160;
const double _kCanvasSize = 300;
const double _kSideCardWidth = 240;

class DemoWatchScreen extends StatelessWidget {
  const DemoWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow = l10n?.demoWatchEyebrow ?? 'WATCH · STROKE ORDER';
    final String heading = l10n?.demoWatchHeading ?? 'Watch me write baa.';
    final String startTracing = l10n?.demoStartTracing ?? 'Start Tracing';
    final String watchAgain = l10n?.demoWatchAgain ?? 'Watch again';

    return DemoChrome(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          QalamSpace.space10,
          QalamSpace.space4,
          QalamSpace.space10,
          QalamSpace.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoEyebrow(eyebrow),
            const SizedBox(height: QalamSpace.space2),
            Text(heading, style: QalamTextStyles.display),
            const SizedBox(height: QalamSpace.space6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: QalamSpace.space6,
              runSpacing: QalamSpace.space6,
              children: const <Widget>[
                QalamMascot(pose: QalamPose.write, size: _kMascotSize),
                _WatchCanvas(),
                _TipCard(),
              ],
            ),
            const SizedBox(height: QalamSpace.space8),
            Row(
              children: <Widget>[
                DemoGhostButton(
                  label: watchAgain,
                  icon: Icons.refresh_rounded,
                ),
                const Spacer(),
                DemoPrimaryCta(
                  ctaKey: const Key('demoStartTracingCta'),
                  label: startTracing,
                  icon: Icons.arrow_forward_rounded,
                  // Canonical path is DemoStep.trace.path ('/demo/trace').
                  onPressed: () => context.go('/demo/trace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The white canvas painting the dotted baa guide + gold start-dot + diacritic
/// dot, with a decorative "Replay" chip in the corner (mockup-faithful).
class _WatchCanvas extends StatelessWidget {
  const _WatchCanvas();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Stack(
      children: <Widget>[
        DemoCanvasCard(
          size: _kCanvasSize,
          painter: DottedGuidePainter(
            referencePoints:
                DemoBaa.referencePoints.map((p) => Offset(p[0], p[1])).toList(),
            inkProgress: 0, // Watch = guide only (nothing traced yet)
            showStartDot: true,
            startDotColor: QalamColors.reward, // gold — start-dot only
            diacriticDots:
                DemoBaa.diacriticDots.map((p) => Offset(p[0], p[1])).toList(),
          ),
        ),
        Positioned(
          right: QalamSpace.space4,
          bottom: QalamSpace.space4,
          child: _CanvasChip(
            label: l10n?.demoReplay ?? 'Replay',
            icon: Icons.refresh_rounded,
          ),
        ),
      ],
    );
  }
}

/// The aqua "TIP" side card — calm one-line guidance + a (decorative) audio
/// affordance, faithful to the mockup.
class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String tipLabel = l10n?.demoWatchTipLabel ?? 'TIP';
    final String tip =
        l10n?.demoWatchTip ?? 'Start at the gold dot. Follow the curve to the left.';
    final String hearSound = l10n?.demoWatchHearSound ?? 'Hear the sound';

    return SizedBox(
      width: _kSideCardWidth,
      child: DemoAquaCard(
        eyebrow: tipLabel,
        children: <Widget>[
          Text(tip, style: QalamTextStyles.body),
          const SizedBox(height: QalamSpace.space4),
          DemoGhostButton(label: hearSound, icon: Icons.volume_up_rounded),
        ],
      ),
    );
  }
}

/// A compact pill chip overlaid on the canvas (decorative Replay affordance).
class _CanvasChip extends StatelessWidget {
  const _CanvasChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space3,
        vertical: QalamSpace.space2,
      ),
      decoration: BoxDecoration(
        color: QalamColors.surfaceRaised,
        borderRadius: BorderRadius.circular(QalamRadii.pill),
        border: Border.all(color: QalamColors.border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: QalamColors.primaryPressed),
          const SizedBox(width: QalamSpace.space1),
          Text(
            label,
            style: QalamTextStyles.label.copyWith(color: QalamColors.primaryPressed),
          ),
        ],
      ),
    );
  }
}
