// TutorPanel — LEFT zone of the _TraceWorkspace (landscape three-zone layout).
//
// Presentation-only StatelessWidget. Shows the Qalam mascot with the tutor's
// name/role, a speech bubble (neutral / coral / leaf), and a Sound section card
// with a speaker button for letter audio (Phase-7 pull-forward, owner's call).
//
// ANTI-GAMIFICATION: no points, no tallies, no counters. The Sound control is
// the sole relaxation of the original "NO 'Play sound'" rule — the owner pulled
// Phase-7 audio forward. All other anti-gamification invariants hold.
//
// SECURITY (T-03-01/T-01-05): this widget receives the Letter only for
// rendering letter.name.ar / letter.name.display in the Sound card. It never
// reads referenceStrokes and never stores or transmits any data.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/letter.dart';
import '../../../theme/brand_theme_ext.dart';
import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';
import '../../../widgets/qalam_mascot.dart';

/// Bubble tone: controls the speech-bubble background and border colour.
enum BubbleTone {
  /// Default — surfaceRaised, no border.
  none,

  /// Coral (warnSoft) — for showFix feedback.
  coral,

  /// Leaf (success) — for showPraise affirmation.
  leaf,
}

// Structural size from the mockup — no token exists for mascot hero sizing.
const double _kMascotSize = 150.0;

/// The left zone of the practice workspace: mascot + bubble + Sound card.
///
/// Pass either [bubbleText] (a plain string) or [bubbleChild] (an arbitrary
/// widget, e.g. the thinking-dots row). [bubbleChild] takes priority if both
/// are provided.
class TutorPanel extends StatelessWidget {
  const TutorPanel({
    super.key,
    required this.pose,
    required this.tone,
    required this.letter,
    this.toneLabel,
    this.bubbleText,
    this.bubbleChild,
    this.onHear,
  });

  /// Mascot pose to render.
  final QalamPose pose;

  /// Speech bubble colour tone.
  final BubbleTone tone;

  /// The current letter — used only for Sound card display.
  final Letter letter;

  /// Optional label shown above the bubble body (e.g. "Qalam says").
  final String? toneLabel;

  /// Plain-text bubble body. Ignored when [bubbleChild] is set.
  final String? bubbleText;

  /// Widget bubble body (e.g. thinking-dots row). Takes priority over [bubbleText].
  final Widget? bubbleChild;

  /// Called when the speaker button is tapped.
  /// null ⇒ button is disabled + visually softened.
  final VoidCallback? onHear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tutorName = l10n?.practiceTutorName ?? 'Qalam';
    final tutorRole = l10n?.practiceTutorRole ?? 'Your Writing Tutor';
    final soundLabel = l10n?.practiceSoundLabel ?? 'Sound';
    final hearLabel = l10n?.practiceHearLetterLabel ?? 'Hear the letter';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: QalamSpace.space4,
        vertical: QalamSpace.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Mascot
          QalamMascot(pose: pose, size: _kMascotSize),
          const SizedBox(height: QalamSpace.space2),

          // Tutor name + role
          Text(
            tutorName,
            style: QalamTextStyles.label.copyWith(color: QalamColors.fg),
            textAlign: TextAlign.center,
          ),
          Text(
            tutorRole,
            style: QalamTextStyles.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: QalamSpace.space4),

          // Speech bubble
          _BubbleCard(
            tone: tone,
            toneLabel: toneLabel,
            bubbleText: bubbleText,
            bubbleChild: bubbleChild,
          ),
          const SizedBox(height: QalamSpace.space4),

          // Sound section card
          _SoundCard(
            letter: letter,
            soundLabel: soundLabel,
            hearLabel: hearLabel,
            onHear: onHear,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BubbleCard — speech bubble with tone-aware colours
// ---------------------------------------------------------------------------

class _BubbleCard extends StatelessWidget {
  const _BubbleCard({
    required this.tone,
    this.toneLabel,
    this.bubbleText,
    this.bubbleChild,
  });

  final BubbleTone tone;
  final String? toneLabel;
  final String? bubbleText;
  final Widget? bubbleChild;

  Color get _bgColor {
    switch (tone) {
      case BubbleTone.none:
        return QalamColors.surfaceRaised;
      case BubbleTone.coral:
        return QalamColors.warnSoftTint;
      case BubbleTone.leaf:
        return QalamColors.successTint;
    }
  }

  Border? get _border {
    switch (tone) {
      case BubbleTone.none:
        return null;
      case BubbleTone.coral:
        return Border.all(color: QalamColors.warnSoft, width: 2);
      case BubbleTone.leaf:
        return Border.all(color: QalamColors.success, width: 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = toneLabel;
    final child = bubbleChild;
    final text = bubbleText;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _bgColor,
        border: _border,
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: QalamShadows.shadowSm,
      ),
      padding: const EdgeInsets.all(QalamSpace.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (label != null) ...<Widget>[
            Text(
              label,
              style: QalamTextStyles.label,
            ),
            const SizedBox(height: QalamSpace.space2),
          ],
          if (child != null)
            child
          else if (text != null)
            Text(text, style: QalamTextStyles.body),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SoundCard — letter audio section
// ---------------------------------------------------------------------------

class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.letter,
    required this.soundLabel,
    required this.hearLabel,
    required this.onHear,
  });

  final Letter letter;
  final String soundLabel;
  final String hearLabel;
  final VoidCallback? onHear;

  @override
  Widget build(BuildContext context) {
    final qalam = Theme.of(context).extension<QalamTheme>() ?? QalamTheme.light;
    final isEnabled = onHear != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: QalamColors.surface,
        border: Border.all(color: QalamColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(QalamRadii.xl),
        boxShadow: QalamShadows.shadowSm,
      ),
      padding: const EdgeInsets.all(QalamSpace.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(soundLabel, style: QalamTextStyles.label),
          const SizedBox(height: QalamSpace.space3),
          Row(
            children: <Widget>[
              // Arabic glyph
              ArabicText(
                letter.name.ar,
                style: QalamTextStyles.arBody.copyWith(
                  color: QalamColors.primary,
                ),
              ),
              const SizedBox(width: QalamSpace.space2),
              // Romanization
              Expanded(
                child: Text(
                  letter.name.display,
                  style: QalamTextStyles.label.copyWith(
                    color: QalamColors.fg,
                  ),
                ),
              ),
              // Speaker button
              Semantics(
                label: hearLabel,
                button: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isEnabled ? qalam.buttonShadow : null,
                  ),
                  child: Material(
                    color: isEnabled
                        ? QalamColors.primary
                        : QalamColors.surface,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onHear,
                      child: SizedBox.square(
                        dimension: QalamTargets.targetMin,
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: isEnabled
                              ? QalamColors.fgOnPrimary
                              : QalamColors.fgMuted,
                          size: QalamSpace.space6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ThinkingDots — 3 blinking dots used as bubble child during scoring
// ---------------------------------------------------------------------------

/// Three animated dots shown while the tutor is "thinking" (scoring in progress).
/// Blinks gently via QalamMotion constants.
class ThinkingDots extends StatefulWidget {
  const ThinkingDots({super.key, this.prefix});

  /// Optional text prefix shown before the dots (e.g. "Let me look at your alif").
  final String? prefix;

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: QalamMotion.durCheer, // 700ms blink cycle
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.prefix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (prefix != null) ...<Widget>[
          Text(prefix, style: QalamTextStyles.body),
          const SizedBox(height: QalamSpace.space2),
        ],
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(3, (int i) {
                // Stagger each dot's opacity by a fraction of the animation.
                final double opacity =
                    ((_controller.value + i * 0.25) % 1.0).clamp(0.3, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(right: QalamSpace.space2),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: QalamColors.fgMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
