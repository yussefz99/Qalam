// ExerciseScaffold — the RTL landscape PAGE SHELL of the Letter-Unit exercise
// engine (Plan 07-04). It hosts the 5 components + the mascot, config-driven from
// a single [Exercise] (COMPONENTS.md §1 / components.js ExerciseScaffold /
// components.css `.ex-scaffold` two-column layout):
//
//   left  `.ex-tutor`  — QalamMascot + "Qalam / Your Writing Tutor" + speech bubble
//   right `.ex-main`   — kick eyebrow + ProgressRibbon row · PromptHeader ·
//                        WriteSurface (or a custom surface / none for teachCard) ·
//                        FeedbackPanel + CTA
//
// CONFIG-DRIVEN: every question type and every unit section is THIS shell fed a
// different [Exercise] — never new UI (the hard constraint). A teachCard
// (surface == null) renders PromptHeader-only with a support CTA — NO WriteSurface,
// NO grading (COMPONENTS.md §1/§3/§4 "NOT teachCard").
//
// The mascot pose + speech tone + FeedbackPanel state come from the
// [ExerciseController] (idle→think→pass|fix), exactly like the prototype's
// `tutorAndFeedback`. Riverpod-only (CLAUDE.md Decided).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exercise_engine/check_result.dart';
import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/qalam_mascot.dart';
import '../exercise_controller.dart';
import 'feedback_panel_v2.dart';
import 'progress_ribbon.dart';
import 'prompt_header.dart';
import 'write_surface.dart';

/// Static copy for the scaffold chrome (call site passes the l10n strings;
/// defaults keep widget tests independent of l10n generation).
class ExerciseScaffoldStrings {
  const ExerciseScaffoldStrings({
    this.tutorName = 'Qalam',
    this.tutorRole = 'Your Writing Tutor',
    this.tutorSays = 'Qalam says',
    this.clear = 'Clear',
    this.tryAgain = 'Try again',
    this.next = 'Next exercise',
    this.markCorrect = 'Mark correct',
    this.gotIt = 'Got it',
    this.playLabel = 'Play',
    this.watchMe = 'Watch me',
    this.teachCardHint = 'Nothing to write — this card teaches.',
  });

  final String tutorName;
  final String tutorRole;
  final String tutorSays;
  final String clear;
  final String tryAgain;
  final String next;
  final String markCorrect;
  final String gotIt;
  final String playLabel;
  final String watchMe;
  final String teachCardHint;
}

/// The exercise page. Drive it by passing the [exercise], the [letter] for the
/// glyph scorer/guide, and the [ribbon] position. The host listens for advance
/// via [onNext] (pass) and supplies the audio tap handler.
class ExerciseScaffold extends ConsumerStatefulWidget {
  const ExerciseScaffold({
    super.key,
    required this.exercise,
    required this.letter,
    this.ribbon,
    this.kick = '',
    this.onNext,
    this.onAudioTap,
    this.strings = const ExerciseScaffoldStrings(),
    this.customSurface,
  });

  /// The config that drives the whole page.
  final Exercise exercise;

  /// The letter geometry for the WriteSurface (guide + scorer).
  final Letter letter;

  /// The R→L position dots `{total, active}`; omit to hide the ribbon.
  final ({int total, int active})? ribbon;

  /// The small eyebrow label (e.g. "Q3 · writeWord").
  final String kick;

  /// Advance handler — invoked from the pass-state "Next exercise" CTA.
  final VoidCallback? onNext;

  /// Tapped when an audio prompt part's play button is pressed.
  final void Function(String audioId)? onAudioTap;

  /// Static chrome copy (defaults are English; call site passes l10n).
  final ExerciseScaffoldStrings strings;

  /// An escape-hatch non-writing center panel (teachCard forms). When provided
  /// AND `exercise.surface == null`, it replaces the (absent) WriteSurface.
  final WidgetBuilder? customSurface;

  @override
  ConsumerState<ExerciseScaffold> createState() => _ExerciseScaffoldState();
}

class _ExerciseScaffoldState extends ConsumerState<ExerciseScaffold> {
  bool get _isTeachCard => widget.exercise.surface == null;

  @override
  void initState() {
    super.initState();
    // Load the controller for this exercise on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseControllerProvider.notifier).load(widget.exercise);
    });
  }

  void _onValidating() =>
      ref.read(exerciseControllerProvider.notifier).think();

  void _onResult(CheckResult result) =>
      ref.read(exerciseControllerProvider.notifier).applyResult(result);

  void _clear() => ref.read(exerciseControllerProvider.notifier).reset();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseControllerProvider);
    final s = widget.strings;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        // .ex-scaffold{padding:18px 26px 22px;}
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── left: the tutor column (.ex-tutor) ──────────────────────────
            SizedBox(
              width: 258, // .ex-tutor width:258px
              child: _TutorColumn(state: state, strings: s),
            ),
            const SizedBox(width: 24), // .ex-scaffold gap:24
            // ── right: the main column (.ex-main) ───────────────────────────
            Expanded(child: _mainColumn(state, s)),
          ],
        ),
      ),
    );
  }

  Widget _mainColumn(ExerciseState state, ExerciseScaffoldStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .ex-ribbonrow — the kick eyebrow + the ProgressRibbon (pushed to edge).
        Row(
          children: [
            if (widget.kick.isNotEmpty)
              Text(
                widget.kick,
                style: QalamTextStyles.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.13 * 12.5, // .ex-kick letter-spacing:0.13em
                  color: QalamTokens.inkTeal,
                ),
              ),
            const Spacer(),
            if (widget.ribbon != null)
              ProgressRibbon(
                total: widget.ribbon!.total,
                active: widget.ribbon!.active,
              ),
          ],
        ),
        // PromptHeader (top).
        PromptHeader(
          parts: widget.exercise.prompt,
          onAudioTap: widget.onAudioTap,
          playLabel: s.playLabel,
        ),
        // The center surface: WriteSurface (graded) / custom (teachCard) / none.
        const SizedBox(height: 14), // .ex-surface margin-top:14
        Expanded(child: _centerSurface()),
        // FeedbackPanel + CTA (bottom) — .ex-foot.
        const SizedBox(height: 12),
        _foot(state, s),
      ],
    );
  }

  Widget _centerSurface() {
    final surface = widget.exercise.surface;
    if (surface != null) {
      return WriteSurface(
        exercise: widget.exercise,
        surface: surface,
        letter: widget.letter,
        onValidating: _onValidating,
        onResult: _onResult,
        watchMeLabel: widget.strings.watchMe,
      );
    }
    // teachCard: a custom non-writing panel, or just empty space.
    return widget.customSurface?.call(context) ?? const SizedBox.shrink();
  }

  Widget _foot(ExerciseState state, ExerciseScaffoldStrings s) {
    // teachCard: NO graded FeedbackPanel — just the teach hint + a support CTA.
    if (_isTeachCard) {
      return Row(
        children: [
          Expanded(
            child: FeedbackPanelV2(
              state: FeedbackState.idle,
              idleHint: s.teachCardHint,
            ),
          ),
          const SizedBox(width: 14),
          _PrimaryCta(label: s.gotIt, onTap: widget.onNext),
        ],
      );
    }

    final fbState = switch (state.phase) {
      ExercisePhase.pass => FeedbackState.pass,
      ExercisePhase.fix => FeedbackState.fix,
      _ => FeedbackState.idle,
    };

    return Row(
      children: [
        Expanded(
          child: FeedbackPanelV2(state: fbState, line: state.line),
        ),
        const SizedBox(width: 14), // .ex-foot gap:14
        ..._ctaFor(state.phase, s),
      ],
    );
  }

  /// The CTA set per phase, mirroring the prototype's `ctaFor`:
  ///   pass → "Next exercise"  · fix → "Clear" + "Try again"  · idle → "Clear" + "Mark correct".
  List<Widget> _ctaFor(ExercisePhase phase, ExerciseScaffoldStrings s) {
    switch (phase) {
      case ExercisePhase.pass:
        return [_PrimaryCta(label: s.next, onTap: widget.onNext)];
      case ExercisePhase.fix:
        return [
          _QuietCta(label: s.clear, onTap: _clear),
          const SizedBox(width: 12),
          _PrimaryCta(label: s.tryAgain, onTap: _clear),
        ];
      default:
        return [
          _QuietCta(label: s.clear, onTap: _clear),
        ];
    }
  }
}

/// The left tutor column: mascot + id + speech bubble (toned by the result).
class _TutorColumn extends StatelessWidget {
  const _TutorColumn({required this.state, required this.strings});

  final ExerciseState state;
  final ExerciseScaffoldStrings strings;

  @override
  Widget build(BuildContext context) {
    final tone = state.tone;
    final Color bubbleBg = switch (tone) {
      ExerciseTone.coral => QalamTokens.coralTint,
      ExerciseTone.leaf => QalamTokens.leafTint,
      ExerciseTone.neutral => QalamTokens.surfaceRaised,
    };
    final Color bubbleBorder = switch (tone) {
      ExerciseTone.coral => const Color(0xFFF6C3B5),
      ExerciseTone.leaf => const Color(0xFFB7E4CF),
      ExerciseTone.neutral => QalamTokens.aquaEdge,
    };
    final bool toned = tone != ExerciseTone.neutral;
    final String bubbleText = _bubbleText();
    // Hide the speech bubble entirely when there's nothing to say (e.g. a
    // teachCard idle with no line) — an empty bubble read as a stray "white box
    // under the mascot" (owner bug #2b). It returns the moment a verdict lands.
    final bool showBubble = bubbleText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .ex-mascot{height:140px}
        SizedBox(
          height: 140,
          child: Center(child: QalamMascot(pose: state.pose, size: 140)),
        ),
        const SizedBox(height: 12),
        // .ex-tid — name + role.
        Text(
          strings.tutorName,
          textAlign: TextAlign.center,
          style: QalamTextStyles.heading.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: QalamTokens.deepInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          strings.tutorRole.toUpperCase(),
          textAlign: TextAlign.center,
          style: QalamTextStyles.label.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.12 * 10, // .ex-tid .role letter-spacing:0.12em
            color: QalamTokens.fgMuted,
          ),
        ),
        if (showBubble) ...[
          const SizedBox(height: 12),
          // .ex-speech — the bubble (toned coral/leaf on a verdict).
          Container(
          constraints: const BoxConstraints(minHeight: 92), // .ex-speech min-height
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: BorderRadius.circular(18), // .ex-speech radius:18
            border: Border.all(color: bubbleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (toned) ...[
                Text(
                  strings.tutorSays.toUpperCase(),
                  style: QalamTextStyles.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1 * 10,
                    color: tone == ExerciseTone.coral
                        ? const Color(0xFFC2512F)
                        : const Color(0xFF1E8A5B),
                  ),
                ),
                const SizedBox(height: 5),
              ],
              Text(
                _bubbleText(),
                style: QalamTextStyles.button.copyWith(
                  fontSize: 16, // .ex-speech font-size:16px
                  fontWeight: FontWeight.w500,
                  color: QalamTokens.fg,
                  height: 1.42,
                ),
              ),
            ],
          ),
          ),
        ],
      ],
    );
  }

  /// The bubble carries the prompt's `say` line in idle, and the verdict line on
  /// a pass/fix (the prototype's `tutorAndFeedback` html). Empty → nothing.
  String _bubbleText() {
    if (state.phase == ExercisePhase.pass ||
        state.phase == ExercisePhase.fix) {
      return state.line;
    }
    return state.line; // idle line set by the host via the controller, if any.
  }
}

/// `.exbtn.primary` — the sticker teal CTA (the prototype's flat-bottom shadow).
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QalamTokens.inkTeal, // .exbtn.primary background:var(--ink-teal)
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 60, // .exbtn height:60px
          padding: const EdgeInsets.symmetric(horizontal: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              // .exbtn.primary box-shadow:0 5px 0 var(--deep-ink)
              BoxShadow(color: QalamTokens.deepInk, offset: Offset(0, 5)),
            ],
          ),
          child: Text(
            label,
            style: QalamTextStyles.button.copyWith(
              fontSize: 18,
              color: QalamTokens.fgOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// `.exbtn.quiet` — the ghost CTA (transparent, aqua-edge border).
class _QuietCta extends StatelessWidget {
  const _QuietCta({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: QalamTokens.aquaEdge, width: 2),
          ),
          child: Text(
            label,
            style: QalamTextStyles.button.copyWith(
              fontSize: 18,
              color: QalamTokens.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}
