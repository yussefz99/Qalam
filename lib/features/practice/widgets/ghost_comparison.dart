// GhostComparison — D-21 slow-motion "Watch the difference." panel (plan 06-08).
//
// After a wobbly (failed) letter, the child taps "Watch the Difference" in the
// ShowFix zone and sees their OWN stroke (coral, warnSoft) replayed BESIDE
// Qalam's reference (deep-ink, inkStroke) at HALF speed (durWrite * 2 = 2800ms,
// linear/even pen speed). A teaching moment — side by side, the named fix stays
// on screen — never "wrong vs right", never red (T-06-09 / UI-SPEC D-21).
//
// Reuses the battle-tested StrokeOrderAnimation replay machinery (parameterized
// in plan 06-08 task 1) — no new path/PathMetric code.
//
// SECURITY (T-03-01 / T-06-04): the child's stroke points are the most
// privacy-sensitive data in the app. They arrive here as already-normalized
// StrokeSpecs lifted from PracticeScreen widget State ONLY — this widget NEVER
// persists, logs, transmits, or writes them to any store. They live only as
// long as the State that holds them; no storage seam is imported here.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/letter.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';
import 'stroke_order_animation.dart';

/// Half-speed replay duration (D-21): durWrite (1400ms) doubled for the calm
/// side-by-side comparison so the child can follow each stroke.
final Duration _kGhostDuration = QalamMotion.durWrite * 2;

/// Side-by-side half-speed replay panel: the child's stroke (coral) next to
/// Qalam's reference (deep-ink). Replayable. Takes only normalized in-memory
/// [StrokeSpec]s — never any persisted/stored data (see SECURITY above).
class GhostComparison extends StatefulWidget {
  const GhostComparison({
    super.key,
    required this.childStrokes,
    required this.referenceStrokes,
  });

  /// The child's just-traced (failing) strokes, normalized to 0..1 via the
  /// shared combined-bbox core. From widget State only — never persisted.
  final List<StrokeSpec> childStrokes;

  /// The letter's authored reference strokes (deep-ink panel).
  final List<StrokeSpec> referenceStrokes;

  @override
  State<GhostComparison> createState() => _GhostComparisonState();
}

class _GhostComparisonState extends State<GhostComparison> {
  final GlobalKey<StrokeOrderAnimationState> _yoursKey =
      GlobalKey<StrokeOrderAnimationState>();
  final GlobalKey<StrokeOrderAnimationState> _qalamsKey =
      GlobalKey<StrokeOrderAnimationState>();

  void _replay() {
    _yoursKey.currentState?.replay();
    _qalamsKey.currentState?.replay();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.ghostCompareTitle ?? 'Watch the difference.';
    final yoursLabel = l10n?.ghostCompareYours ?? 'Yours';
    final qalamsLabel = l10n?.ghostCompareQalams ?? "Qalam's";

    return Container(
      decoration: BoxDecoration(
        color: QalamColors.surfaceRaised,
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        border: Border.all(color: QalamColors.border, width: 1.0),
        boxShadow: QalamShadows.shadowMd,
      ),
      padding: const EdgeInsets.all(QalamSpace.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Title row + replay affordance.
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  // Title role (24px Fredoka) per UI-SPEC.
                  style: QalamTextStyles.button.copyWith(
                    color: QalamColors.fg,
                    height: 1.3,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('ghost-replay'),
                onPressed: _replay,
                color: QalamColors.primary,
                iconSize: QalamSpace.space6,
                constraints: const BoxConstraints(
                  minWidth: QalamTargets.targetMin,
                  minHeight: QalamTargets.targetMin,
                ),
                icon: const Icon(Icons.replay),
              ),
            ],
          ),
          const SizedBox(height: QalamSpace.space4),

          // Two side-by-side panels — Yours (coral) | Qalam's (deep-ink).
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _ReplayPanel(
                    label: yoursLabel,
                    animKey: _yoursKey,
                    strokes: widget.childStrokes,
                    // The child's wobbly stroke — coral (warnSoft), NEVER red.
                    color: QalamColors.warnSoft,
                    duration: _kGhostDuration,
                  ),
                ),
                const SizedBox(width: QalamSpace.space4),
                Expanded(
                  child: _ReplayPanel(
                    label: qalamsLabel,
                    animKey: _qalamsKey,
                    strokes: widget.referenceStrokes,
                    // Qalam's reference — deep-ink (the default ink color).
                    color: QalamColors.inkStroke,
                    duration: _kGhostDuration,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One labeled replay panel: a Label-scale caption above a parchment canvas
/// hosting a half-speed [StrokeOrderAnimation].
class _ReplayPanel extends StatelessWidget {
  const _ReplayPanel({
    required this.label,
    required this.animKey,
    required this.strokes,
    required this.color,
    required this.duration,
  });

  final String label;
  final GlobalKey<StrokeOrderAnimationState> animKey;
  final List<StrokeSpec> strokes;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(label, style: QalamTextStyles.label),
        const SizedBox(height: QalamSpace.space2),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(QalamRadii.lg),
            child: ColoredBox(
              color: QalamColors.bg,
              child: StrokeOrderAnimation(
                key: animKey,
                referenceStrokes: strokes,
                color: color,
                duration: duration,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
