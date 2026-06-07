// DemoTraceScreen — the child's turn, rebuilt 1:1 with the design `TraceScreen` +
// `TracingCanvas` mockup (docs/design/kit/.../screenshots/03-*).
//
// Trace hands over the pen: the walkthrough chrome, a quiet "Stroke 1 of 1"
// progress tracker, the idle Qalam mascot beside a white canvas that PAINTS the
// dotted baa guide with live ink OVER it (the half-traced hero state), an aqua
// "LISTEN" card (the baa glyph + a decorative Play-sound), and a primary "Next"
// CTA into the HERO Feedback (miss) screen.
//
// Both canvas layers derive from the single DemoBaa reference source (Pitfall 5):
// the guide is PAINTED, never a Text('ب'). There is NO recognition engine, NO
// capture, NO scoring, NO persistence (DP-01) — nothing to break on stage. The
// progress tracker is information, not a score (DP-06). "Try again" / "Mark
// correct" and the audio affordance are faithful to the mockup but decorative.
// Tokens only; Western numerals via the l10n copy.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../theme/dimens.dart';
import '../../theme/text_styles.dart';
import '../../widgets/arabic_text.dart';
import '../../widgets/qalam_mascot.dart';
import '../demo_baa.dart';
import '../widgets/demo_chrome.dart';
import '../widgets/dotted_guide_painter.dart';

const double _kMascotSize = 160;
const double _kCanvasSize = 300;
const double _kSideCardWidth = 240;

/// The fraction of the baa already inked — the half-traced hero state.
const double _kInkProgress = 0.7;

class DemoTraceScreen extends StatelessWidget {
  const DemoTraceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String eyebrow = l10n?.demoTraceEyebrow ?? 'YOUR TURN · TRACE';
    final String heading = l10n?.demoTraceHeading ?? 'Now you trace baa.';
    final String progress = l10n?.demoTraceProgress ?? 'Stroke 1 of 1';
    final String tryAgain = l10n?.demoTryAgain ?? 'Try Again';
    final String markCorrect = l10n?.demoTraceMarkCorrect ?? 'Mark correct';
    final String next = l10n?.demoTraceNext ?? 'Next';

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
            // Heading + the "Stroke X of Y" progress tracker on the right.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DemoEyebrow(eyebrow),
                      const SizedBox(height: QalamSpace.space2),
                      Text(heading, style: QalamTextStyles.display),
                    ],
                  ),
                ),
                const SizedBox(width: QalamSpace.space5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(progress, style: QalamTextStyles.label),
                    const SizedBox(height: QalamSpace.space2),
                    const DemoProgressBar(value: _kInkProgress),
                  ],
                ),
              ],
            ),
            const SizedBox(height: QalamSpace.space6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: QalamSpace.space6,
              runSpacing: QalamSpace.space6,
              children: const <Widget>[
                QalamMascot(pose: QalamPose.idle, size: _kMascotSize),
                _TraceCanvas(),
                _ListenCard(),
              ],
            ),
            const SizedBox(height: QalamSpace.space8),
            Row(
              children: <Widget>[
                DemoGhostButton(label: tryAgain, icon: Icons.refresh_rounded),
                const SizedBox(width: QalamSpace.space3),
                DemoGhostButton(label: markCorrect, filled: true),
                const Spacer(),
                DemoPrimaryCta(
                  ctaKey: const Key('demoTraceSubmitCta'),
                  label: next,
                  icon: Icons.arrow_forward_rounded,
                  // Canonical path is DemoStep.feedbackMiss.path ('/demo/feedback')
                  // — the HERO miss screen by default.
                  onPressed: () => context.go('/demo/feedback'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The white canvas painting the dotted baa guide + the half-traced deep-ink
/// overlay + gold start-dot + diacritic dot, with a decorative Replay chip.
class _TraceCanvas extends StatelessWidget {
  const _TraceCanvas();

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
            inkProgress: _kInkProgress, // half-traced hero state
            showStartDot: true,
            startDotColor: QalamColors.reward, // gold — start-dot only
            diacriticDots:
                DemoBaa.diacriticDots.map((p) => Offset(p[0], p[1])).toList(),
          ),
        ),
        Positioned(
          right: QalamSpace.space4,
          bottom: QalamSpace.space4,
          child: DemoCanvasChip(
            label: l10n?.demoReplay ?? 'Replay',
            icon: Icons.refresh_rounded,
          ),
        ),
      ],
    );
  }
}

/// The aqua "LISTEN" side card — the baa glyph (via ArabicText, the RTL island),
/// its romanized name, and a decorative Play-sound affordance.
class _ListenCard extends StatelessWidget {
  const _ListenCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String listen = l10n?.demoTraceListen ?? 'LISTEN';
    final String playSound = l10n?.demoTracePlaySound ?? 'Play sound';

    return SizedBox(
      width: _kSideCardWidth,
      child: DemoAquaCard(
        eyebrow: listen,
        children: <Widget>[
          Center(
            child: ArabicText(
              DemoBaa.glyph,
              style: demoGlyphStyle(72),
            ),
          ),
          const SizedBox(height: QalamSpace.space1),
          Center(
            child: Text(
              DemoBaa.romanized,
              style: QalamTextStyles.heading,
            ),
          ),
          const SizedBox(height: QalamSpace.space4),
          DemoGhostButton(label: playSound, icon: Icons.volume_up_rounded),
        ],
      ),
    );
  }
}
