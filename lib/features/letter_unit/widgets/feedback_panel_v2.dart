// FeedbackPanelV2 — the two-state graded-feedback panel for the Letter-Unit
// exercise system (Plan 07-04). COMPONENTS.md §4 / components.js FeedbackPanel /
// components.css `.feedback-panel` + `.fix` + `.pass`.
//
// "V2" distinguishes it from the Phase-3/6 Practice feedback chrome; this is the
// config-driven panel the 5-component engine uses. Three states:
//
//   • idle → the calm "write on the surface" hint (.fb-hint).
//   • pass → ONE quiet gold star + the authored praise line (.feedback-panel.pass).
//   • fix  → a coral panel + an ✕ icon + the SPECIFIC authored fix line
//            (.feedback-panel.fix) — the tutor's voice (CLAUDE.md), never "Oops".
//
// ANTI-GAMIFICATION (CLAUDE.md Decided): the pass state shows EXACTLY ONE star
// and NO counter/tally/total/"+N" — a star is a mastery marker, not a score
// (grep-guarded by the Task-1 test). The fix state is coral, never red.

import 'package:flutter/material.dart';

import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';

/// Which feedback face is shown.
enum FeedbackState {
  /// Before the child writes — the calm hint.
  idle,

  /// The attempt passed — one star + praise.
  pass,

  /// The attempt missed — coral + the specific authored fix.
  fix,
}

/// The graded feedback panel. Render with [FeedbackState] + the resolved line
/// (the host resolves `exercise.feedback['pass']` / `feedback[mistakeId]`).
///
/// [line] may contain a small Arabic island (e.g. "أحسنت"); pass it as the
/// `arabicLine` so it renders through [ArabicText] beside the English. The plain
/// [line] is the English tutor sentence.
class FeedbackPanelV2 extends StatelessWidget {
  const FeedbackPanelV2({
    super.key,
    required this.state,
    this.line = '',
    this.idleHint = 'Write on the surface — Qalam checks your strokes.',
    this.passTag = 'Correct · one quiet star',
    this.fixTag = 'A specific fix',
  });

  /// The current face.
  final FeedbackState state;

  /// The resolved tutor line (praise for [FeedbackState.pass]; the authored fix
  /// for [FeedbackState.fix]). Ignored for [FeedbackState.idle].
  final String line;

  /// The idle hint copy (call site passes the l10n `feedbackIdleHint`).
  final String idleHint;

  /// The pass eyebrow (.fb-tag, l10n `feedbackPassTag`).
  final String passTag;

  /// The fix eyebrow (.fb-tag, l10n `feedbackFixTag`).
  final String fixTag;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      FeedbackState.idle => _idle(),
      FeedbackState.pass => _pass(),
      FeedbackState.fix => _fix(),
    };
  }

  // .feedback-panel (idle) — a calm hint with a small teal pen dot.
  Widget _idle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: QalamTokens.inkTeal, // .fb-hint .pen background:var(--ink-teal)
          ),
        ),
        const SizedBox(width: 9), // .fb-hint gap:9
        Flexible(
          child: Text(
            idleHint,
            style: QalamTextStyles.body.copyWith(
              fontSize: 14, // .fb-hint font-size:14px
              fontWeight: FontWeight.w600,
              color: QalamTokens.fgMuted,
            ),
          ),
        ),
      ],
    );
  }

  // .feedback-panel.pass — ONE gold star + the leaf eyebrow + the praise line.
  Widget _pass() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: QalamTokens.leafTint, // .pass background:var(--leaf-tint)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7E4CF)), // .pass border
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // EXACTLY ONE star — a mastery marker, NOT a score (anti-gamification).
          const Icon(
            Icons.star_rounded,
            color: QalamTokens.goldInk, // reward gold — the one quiet star
            size: 44, // .fb-star STAR(44)
          ),
          const SizedBox(width: 13), // .feedback-panel gap:13
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Tag(text: passTag, color: const Color(0xFF1E8A5B)),
                const SizedBox(height: 2),
                _Line(line: line),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // .feedback-panel.fix — the coral ✕ disc + the coral eyebrow + the fix line.
  Widget _fix() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: QalamTokens.coralTint, // .fix background:var(--coral-tint)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6C3B5)), // .fix border
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40, // .fb-ico width:40px
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF6C3B5), // .fb-ico background
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFC2512F), // .fb-ico color — coral-deep, never red
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Tag(text: fixTag, color: const Color(0xFFC2512F)),
                const SizedBox(height: 2),
                _Line(line: line),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.fb-tag` — the small uppercase eyebrow above the feedback line.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: QalamTextStyles.label.copyWith(
          fontSize: 10, // .fb-tag font-size:10px
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1 * 10, // .fb-tag letter-spacing:0.1em
          color: color,
        ),
      );
}

/// `.fb-line` — the tutor sentence. Renders any trailing Arabic island
/// (detected heuristically) through [ArabicText]; otherwise plain English.
class _Line extends StatelessWidget {
  const _Line({required this.line});

  final String line;

  /// Arabic Unicode block test — if the line contains Arabic letters we render
  /// the WHOLE line through [ArabicText] (its RTL island handles the mix).
  static final RegExp _arabic = RegExp(r'[؀-ۿ]');

  @override
  Widget build(BuildContext context) {
    final style = QalamTextStyles.button.copyWith(
      fontSize: 15.5, // .fb-line font-size:15.5px
      fontWeight: FontWeight.w500,
      color: QalamTokens.fg,
      height: 1.34,
    );
    if (_arabic.hasMatch(line)) {
      // Mixed English+Arabic praise (e.g. "Beautiful — … أحسنت.") — ArabicText
      // is the one RTL island that shapes Arabic and isolates digits correctly.
      return ArabicText(line, style: style, textAlign: TextAlign.start);
    }
    return Text(line, style: style);
  }
}
