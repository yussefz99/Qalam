// MeetSection — Section 1 of the baa Letter Unit (Plan 07-05).
//
// "Meet the letter": the child HEARS baa, sees the door it names, and watches
// how its shape MORPHS across the four contextual forms — with NOTHING to write.
// This is the prototype's `meet()` surface (unit.js), reproduced 1:1:
//   • a morph card showing ONE large contextual form + an explain line, with
//     join-hint arrows and a "Hear" button (top-right);
//   • a scrub strip of the four MFORMS (isolated/initial/medial/final), tapping
//     a stop morphs the big glyph to that form;
//   • a "Start Writing" primary CTA that advances to Section 2.
//
// CONFIG-DRIVEN (the hard rule, COMPONENTS.md): MeetSection does NOT build a
// bespoke page. It feeds the `baa.teachCard.meet` Exercise into ExerciseScaffold
// (surface == null → the teachCard PromptHeader-only path: no WriteSurface, no
// grading) and supplies the morph card as the scaffold's `customSurface`. The
// scaffold's "Got it" support CTA is relabelled "Start Writing" and wired to
// [onAdvance].
//
// OFFLINE AUDIO (S1-06): the "Hear" button and the prompt's audio part both play
// the bundled `snd.baa` clip through [audioPlayerProvider] (the Plan 07-02
// AssetLetterAudioPlayer) — no network round-trip.
//
// ANTI-GAMIFICATION (CLAUDE.md Decided): a teach card grades nothing — there is
// no star and no score chrome of any kind anywhere in this section.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../providers/audio_providers.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';
import '../widgets/exercise_scaffold.dart';
import '../widgets/prompt_header.dart';

/// Static copy for the Meet section (call site passes the l10n strings; English
/// defaults keep the widget test independent of `flutter gen-l10n`, per the
/// 07-04 component-copy precedent).
class MeetSectionStrings {
  const MeetSectionStrings({
    this.kick = 'Meet the Letter',
    this.hear = 'Hear',
    this.startWriting = 'Start Writing',
    this.joinsOn = 'joins on',
    this.isolatedLabel = 'Isolated',
    this.initialLabel = 'Initial',
    this.medialLabel = 'Medial',
    this.finalLabel = 'Final',
    this.isolatedExplain = 'On its own — the full bowl with its tail.',
    this.initialExplain =
        'At the start — the tail goes; it reaches forward to join.',
    this.medialExplain = 'In the middle — just a little tooth between letters.',
    this.finalExplain = 'At the end — the tail comes back.',
  });

  final String kick;
  final String hear;
  final String startWriting;
  final String joinsOn;
  final String isolatedLabel;
  final String initialLabel;
  final String medialLabel;
  final String finalLabel;
  final String isolatedExplain;
  final String initialExplain;
  final String medialExplain;
  final String finalExplain;
}

/// One stop on the morph scrub strip — a contextual form glyph, its label, its
/// explain line, and which side(s) it joins on (for the join-hint arrows).
class _MorphForm {
  const _MorphForm(this.glyph, this.label, this.explain, this.joins);
  final String glyph;
  final String label;
  final String explain;

  /// "left" | "right" | "both" | null — which side the form reaches to join.
  final String? joins;
}

/// Section 1 — Meet the letter. Feed it the `baa.teachCard.meet` [exercise] and
/// the [letter]; [onAdvance] advances to Section 2 (Watch & Trace).
class MeetSection extends ConsumerStatefulWidget {
  const MeetSection({
    super.key,
    required this.exercise,
    required this.letter,
    this.onAdvance,
    this.strings = const MeetSectionStrings(),
  });

  /// The `baa.teachCard.meet` config (PromptHeader-only — surface == null).
  final Exercise exercise;

  /// The letter being met (its `char` powers the contextual-form glyphs).
  final Letter letter;

  /// Advance to Section 2 (the scaffold's primary support CTA).
  final VoidCallback? onAdvance;

  /// Section copy (English defaults; call site passes l10n).
  final MeetSectionStrings strings;

  @override
  ConsumerState<MeetSection> createState() => _MeetSectionState();
}

class _MeetSectionState extends ConsumerState<MeetSection> {
  int _active = 0;

  /// ZWJ — joins the contextual glyphs so they shape correctly in isolation
  /// (the prototype's MFORMS ZWJ joins).
  static const String _zwj = '‍';

  List<_MorphForm> get _forms {
    final s = widget.strings;
    final base = widget.letter.char;
    return [
      _MorphForm(base, s.isolatedLabel, s.isolatedExplain, null),
      _MorphForm('$base$_zwj', s.initialLabel, s.initialExplain, 'left'),
      _MorphForm('$_zwj$base$_zwj', s.medialLabel, s.medialExplain, 'both'),
      _MorphForm('$_zwj$base', s.finalLabel, s.finalExplain, 'right'),
    ];
  }

  /// The single audioId carried by the meet config's audio part (snd.baa).
  String? get _audioId {
    for (final p in widget.exercise.prompt) {
      if (p is AudioPart) return p.audioId;
    }
    return null;
  }

  void _play(String? id) {
    if (id == null || id.isEmpty) return;
    // Fire-and-forget: the offline player degrades to a silent no-op on an
    // unknown id / missing clip (T-07-02-04), so the child is never blocked.
    ref.read(audioPlayerProvider).playLetter(id);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return ExerciseScaffold(
      exercise: widget.exercise,
      letter: widget.letter,
      kick: s.kick,
      // The teachCard "Got it" CTA, relabelled "Start Writing" → Section 2.
      onNext: widget.onAdvance,
      strings: ExerciseScaffoldStrings(gotIt: s.startWriting, playLabel: s.hear),
      // Any audio prompt part in the header plays the bundled clip offline.
      onAudioTap: _play,
      // The morph card replaces the (absent) WriteSurface on the teachCard path.
      customSurface: (_) => _MorphCard(
        forms: _forms,
        active: _active,
        strings: s,
        onSelect: (i) => setState(() => _active = i),
        onHear: () => _play(_audioId),
      ),
    );
  }
}

/// The prototype `.morphcard` — one big contextual glyph + explain line, the
/// join-hint arrows, a "Hear" button, and the `.scrub` strip of the four stops.
class _MorphCard extends StatelessWidget {
  const _MorphCard({
    required this.forms,
    required this.active,
    required this.strings,
    required this.onSelect,
    required this.onHear,
  });

  final List<_MorphForm> forms;
  final int active;
  final MeetSectionStrings strings;
  final ValueChanged<int> onSelect;
  final VoidCallback onHear;

  @override
  Widget build(BuildContext context) {
    final current = forms[active];
    final bool joinLeft = current.joins == 'left' || current.joins == 'both';
    final bool joinRight = current.joins == 'right' || current.joins == 'both';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .morphcard — the big morph + hints + Hear button.
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: QalamTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(QalamTokens.radiusXl), // 28
              border: Border.all(color: QalamTokens.aquaEdge, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A0E5B5F),
                    offset: Offset(0, 8),
                    blurRadius: 18,
                    spreadRadius: -8),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // .bigmorph + .morph-explain, centered.
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ArabicText(
                        current.glyph,
                        style: QalamTextStyles.arDisplay.copyWith(
                          fontSize: 168, // .bigmorph (scaled for the slot)
                          fontWeight: FontWeight.w600,
                          color: QalamTokens.deepInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Text(
                          current.explain,
                          textAlign: TextAlign.center,
                          style: QalamTextStyles.button.copyWith(
                            fontSize: 18, // .morph-explain
                            fontWeight: FontWeight.w500,
                            color: QalamTokens.fgMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // .joinhint.left / .right — the "joins on →" arrows.
                if (joinLeft)
                  Positioned(
                    left: 28,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _JoinHint(label: strings.joinsOn, pointsLeft: true),
                    ),
                  ),
                if (joinRight)
                  Positioned(
                    right: 28,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child:
                          _JoinHint(label: strings.joinsOn, pointsLeft: false),
                    ),
                  ),
                // .playbtn "Hear" — top-right (LTR-anchored control).
                Positioned(
                  top: 16,
                  right: 16,
                  child: _HearButton(
                    key: const ValueKey('meetHearButton'),
                    label: strings.hear,
                    onTap: onHear,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14), // .scrub margin-top:14
        // .scrub — the four-stop track.
        _ScrubTrack(forms: forms, active: active, onSelect: onSelect),
      ],
    );
  }
}

/// `.joinhint` — a small teal "joins on →" affordance.
class _JoinHint extends StatelessWidget {
  const _JoinHint({required this.label, required this.pointsLeft});

  final String label;
  final bool pointsLeft;

  @override
  Widget build(BuildContext context) {
    final arrow = Icon(
      pointsLeft ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
      size: 20,
      color: QalamTokens.inkTeal,
    );
    final text = Text(
      label.toUpperCase(),
      style: QalamTextStyles.label.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.08 * 12,
        color: QalamTokens.inkTeal,
      ),
    );
    return Opacity(
      opacity: 0.85, // .joinhint.show opacity:.85
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: pointsLeft
            ? [arrow, const SizedBox(width: 6), text]
            : [text, const SizedBox(width: 6), arrow],
      ),
    );
  }
}

/// `.scrub-track` — the four contextual-form stops; tapping one morphs the card.
class _ScrubTrack extends StatelessWidget {
  const _ScrubTrack({
    required this.forms,
    required this.active,
    required this.onSelect,
  });

  final List<_MorphForm> forms;
  final int active;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6), // .scrub-track padding:6
      decoration: BoxDecoration(
        color: QalamTokens.softAqua,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QalamTokens.aquaEdge),
      ),
      child: Row(
        children: [
          for (var i = 0; i < forms.length; i++)
            Expanded(
              child: _ScrubStop(
                form: forms[i],
                on: i == active,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.scrub-stop` — one form glyph + its label; the active one is raised white.
class _ScrubStop extends StatelessWidget {
  const _ScrubStop({required this.form, required this.on, required this.onTap});

  final _MorphForm form;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: form.label,
      child: Material(
        color: on ? QalamTokens.surfaceRaised : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ArabicText(
                  form.glyph,
                  style: QalamTextStyles.arBody.copyWith(
                    fontSize: 32, // .scrub-stop .sg
                    fontWeight: FontWeight.w500,
                    color: QalamTokens.deepInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  form.label.toUpperCase(),
                  style: QalamTextStyles.label.copyWith(
                    fontSize: 11, // .scrub-stop .sl
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05 * 11,
                    color: on ? QalamTokens.inkTeal : QalamTokens.fgMuted,
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

/// `.playbtn` "Hear" — the morph card's offline sound control.
class _HearButton extends StatelessWidget {
  const _HearButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: QalamTokens.inkTeal,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 46, // prototype meetPlay height:46
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded,
                    size: 22, color: QalamTokens.fgOnPrimary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: QalamTextStyles.button.copyWith(
                    fontSize: 16,
                    color: QalamTokens.fgOnPrimary,
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
