// WatchTraceSection — Section 2 of the baa Letter Unit (Plan 07-05).
//
// "Watch & Trace": the child first WATCHES baa being written (the stroke-order
// demo), then TRACES the isolated baa over the dotted guide — scored on-device
// with the authored fix/praise. This is the prototype's `isolated()` surface
// (unit.js), reproduced 1:1 as two phases:
//
//   • Watch phase — the StrokeOrderAnimation auto-plays inside a writebox with a
//     Tip side card; CTAs "Watch again" (replays the demo) and "I'll try"
//     (advances to Trace).
//   • Trace phase — the ExerciseScaffold drives the config-through-engine flow:
//     a WriteSurface(mode:trace, guideForm:isolated, demo) the child traces, the
//     ExerciseController grades it, FeedbackPanelV2 shows ONE star + the authored
//     praise on a pass / the authored "shallowBowl" fix on a miss. A Listen side
//     card plays the baa sound offline.
//
// CONFIG-DRIVEN: the Trace phase is the engine's ExerciseScaffold fed the
// `baa.traceLetter.isolated` Exercise — no bespoke grading UI. The authored
// feedback lines come straight from the config's `feedback` map (the tutor's
// voice). OFFLINE AUDIO (S1-06): the Listen Play plays the bundled clip via
// [audioPlayerProvider].

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../providers/audio_providers.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../practice/widgets/stroke_order_animation.dart';
import '../widgets/exercise_scaffold.dart';
import 'section_side_cards.dart';

/// Static copy for the Watch & Trace section (English defaults; call site passes
/// l10n — keeps the widget test independent of `flutter gen-l10n`).
class WatchTraceStrings {
  const WatchTraceStrings({
    this.watchKick = 'Watch · Stroke Order',
    this.traceKick = 'Your Turn · Trace',
    this.watchAgain = 'Watch again',
    this.illTry = "I'll try",
    this.tipLabel = 'Tip',
    this.tipBody =
        'Start at the gold dot. Follow the curve down and to the left, then place the dot below.',
    this.listenLabel = 'Listen',
    this.listenPlay = 'Play sound',
    this.romanization = 'baa',
  });

  final String watchKick;
  final String traceKick;
  final String watchAgain;
  final String illTry;
  final String tipLabel;
  final String tipBody;
  final String listenLabel;
  final String listenPlay;
  final String romanization;
}

/// The two phases of the section.
enum _Phase { watch, trace }

/// Section 2 — Watch & Trace. Feed it the `baa.traceLetter.isolated` [exercise]
/// and the [letter]; [onAdvance] advances to Section 3 (Forms in context).
class WatchTraceSection extends ConsumerStatefulWidget {
  const WatchTraceSection({
    super.key,
    required this.exercise,
    required this.letter,
    this.onAdvance,
    this.strings = const WatchTraceStrings(),
    this.onGraphNodePassed,
  });

  /// The `baa.traceLetter.isolated` config (trace/glyph/isolated + demo).
  final Exercise exercise;

  /// The letter to trace — its isolated contextual Form supplies the guide
  /// strokes + the demo geometry.
  final Letter letter;

  /// Advance to Section 3 (after a clean trace).
  final VoidCallback? onAdvance;

  /// Section copy (English defaults; call site passes l10n).
  final WatchTraceStrings strings;

  /// Called with the canonical graph node id on a clean scored pass (T2/T3).
  /// Wired to the scaffold's [onGraphNodePassed] with `baa.traceLetter.isolated`.
  final void Function(String graphExerciseId)? onGraphNodePassed;

  @override
  ConsumerState<WatchTraceSection> createState() => _WatchTraceSectionState();
}

class _WatchTraceSectionState extends ConsumerState<WatchTraceSection> {
  _Phase _phase = _Phase.watch;
  final GlobalKey<StrokeOrderAnimationState> _demoKey =
      GlobalKey<StrokeOrderAnimationState>();

  /// The isolated form's reference strokes for the Watch demo (falls back to the
  /// letter's base strokes if the contextual form is absent).
  List<StrokeSpec> get _demoStrokes {
    final ctx = widget.letter.contextualForms;
    final f = ctx?['isolated'];
    if (f != null && f.referenceStrokes.isNotEmpty) return f.referenceStrokes;
    return widget.letter.referenceStrokes;
  }

  void _play(String? id) {
    if (id == null || id.isEmpty) return;
    ref.read(audioPlayerProvider).playLetter(id);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.watch => _buildWatch(),
      _Phase.trace => _buildTrace(),
    };
  }

  // ── Watch phase — the demo + Tip card + CTAs ───────────────────────────────
  Widget _buildWatch() {
    final s = widget.strings;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                s.watchKick,
                style: QalamTextStyles.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.13 * 12.5,
                  color: QalamTokens.inkTeal,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // the writebox with the auto-playing demo.
                  Expanded(child: _DemoBox(demoKey: _demoKey, strokes: _demoStrokes)),
                  const SizedBox(width: 18),
                  // the Tip side card.
                  SizedBox(
                    width: 210,
                    child: TipCard(label: s.tipLabel, body: s.tipBody),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                QuietButton(
                  label: s.watchAgain,
                  icon: Icons.replay_rounded,
                  onTap: () => _demoKey.currentState?.replay(),
                ),
                const Spacer(),
                PrimaryButton(
                  label: s.illTry,
                  iconAfter: Icons.arrow_forward_rounded,
                  onTap: () => setState(() => _phase = _Phase.trace),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Trace phase — the engine scaffold drives trace + grading + CTAs ────────
  Widget _buildTrace() {
    final s = widget.strings;
    // The config-driven engine: WriteSurface(trace) + grading + star + the
    // Clear / Next CTAs. The baa sound plays from the PromptHeader's Play button
    // (the single audio affordance — a separate overlaid Listen card used to
    // duplicate it AND cover the Clear/Next CTAs; owner bugs #3a/#3b).
    return ExerciseScaffold(
      exercise: widget.exercise,
      letter: widget.letter,
      kick: s.traceKick,
      onNext: widget.onAdvance,
      onAudioTap: _play,
      // T2: the canonical graph node id for the isolated-trace exercise.
      graphExerciseId: widget.exercise.id,
      onGraphNodePassed: widget.onGraphNodePassed,
    );
  }
}

/// The writebox hosting the auto-playing stroke-order demo (Watch phase).
class _DemoBox extends StatelessWidget {
  const _DemoBox({required this.demoKey, required this.strokes});

  final GlobalKey<StrokeOrderAnimationState> demoKey;
  final List<StrokeSpec> strokes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QalamTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(QalamTokens.radiusXl),
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
      child: IgnorePointer(
        child: StrokeOrderAnimation(key: demoKey, referenceStrokes: strokes),
      ),
    );
  }
}
