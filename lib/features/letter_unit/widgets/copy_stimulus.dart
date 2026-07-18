// CopyStimulus — the child-controlled reveal → hide → peek widget for the
// writeWord COPY (نسخ) task (Phase 19-03, D-05 / QP-03).
//
// REPLACES the old static `opacity 0.18` dim in PromptHeader._TextPart
// (prompt_header.dart, the `reveal:"thenHide"` path). The Claude-Design copy
// exercise used to FLASH the word then time it out — a timed auto-hide the child
// could not control. D-05 makes every reveal/hide CHILD-CONTROLLED so recall
// stays honest: the word shows large, the child taps "I'm Ready" to hide it,
// and a "Peek" affordance re-reveals it on demand. NOTHING vanishes on a timer.
//
// HIDE IS BUTTON-ONLY (19 review WR-02): the D-05 sketch also named a
// hide-on-first-stroke trigger, but no stroke-START seam exists anywhere on
// WriteSurface / StrokeCanvas (only letter-complete callbacks), so the earlier
// `hideSignal` Listenable was dead at its only call site — removed rather than
// left as unreachable plumbing. Wiring the stroke trigger needs a capture seam
// (a stroke-begin notification out of StrokeCanvas) — a future phase's work;
// until then "I'm Ready" is the one hide path.
//
// Three states (UI-SPEC §4):
//   • revealed — the word (40px Arabic) + an "I'm Ready" button.
//   • hidden   — the word gone (a calm placeholder) + a "Peek" button.
//   • peeking  — the word back (a deliberate, child-initiated assist) + "Hide".
//
// Tokens only — no gold anywhere (anti-gamification, CLAUDE.md Decided). Reuses
// the _TextPart card shell (surfaceRaised, radius 16, aqua-edge border, the soft
// shadow) so the copy card is pixel-continuous with the other PromptHeader cards.

import 'package:flutter/material.dart';

import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/arabic_text.dart';

/// The three child-controlled reveal states of a copy word (D-05).
enum CopyReveal { revealed, hidden, peeking }

/// A copy-word stimulus the child reveals, hides, and peeks at — never on a
/// timer. [word] is the Arabic word to copy. Hiding is BUTTON-ONLY (the
/// "I'm Ready" tap): a hide-on-first-stroke trigger needs a stroke-START
/// capture seam WriteSurface/StrokeCanvas do not expose today (WR-02 —
/// deferred to a future phase; do not re-add a `hideSignal` without one).
class CopyStimulus extends StatefulWidget {
  const CopyStimulus({
    super.key,
    required this.word,
    this.readyLabel = "I'm Ready",
    this.peekLabel = 'Peek',
    this.hideLabel = 'Hide',
  });

  /// The Arabic word the child copies (shown large in revealed/peeking).
  final String word;

  /// "I'm Ready" button label (Title Case) — the child taps to hide the word.
  final String readyLabel;

  /// "Peek" button label (Title Case) — re-reveals the word from hidden.
  final String peekLabel;

  /// "Hide" button label (Title Case) — returns a peeked word to hidden.
  final String hideLabel;

  @override
  State<CopyStimulus> createState() => _CopyStimulusState();
}

class _CopyStimulusState extends State<CopyStimulus> {
  CopyReveal _state = CopyReveal.revealed;

  void _ready() => setState(() => _state = CopyReveal.hidden);
  void _peek() => setState(() => _state = CopyReveal.peeking);
  void _hide() => setState(() => _state = CopyReveal.hidden);

  /// The word shows in revealed + peeking; hidden shows a calm placeholder.
  bool get _wordVisible => _state != CopyReveal.hidden;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _card(),
        const SizedBox(height: 16), // ≥16px between touch targets (space-4)
        _control(),
      ],
    );
  }

  /// The _TextPart card shell (surfaceRaised, radius 16, aqua-edge border, soft
  /// shadow) holding either the 40px word or a calm hidden placeholder.
  Widget _card() {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: QalamTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QalamTokens.aquaEdge),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A0E5B5F),
              offset: Offset(0, 2),
              blurRadius: 6,
              spreadRadius: -2),
        ],
      ),
      child: _wordVisible ? _word() : _placeholder(),
    );
  }

  /// The copy word at the full 40px stimulus size (UI-SPEC §4 / Display role).
  Widget _word() => Directionality(
        textDirection: TextDirection.rtl,
        child: ArabicText(
          widget.word,
          style: QalamTextStyles.arBody.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: QalamTokens.deepInk,
          ),
        ),
      );

  /// The hidden state — a calm neutral bar, NOT the word (so recall stays honest
  /// and no letter model leaks). Deliberately not an [ArabicText] of the word.
  Widget _placeholder() => SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 96,
            height: 4,
            decoration: BoxDecoration(
              color: QalamTokens.aquaEdge,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  /// The per-state control button. Single-word visible labels; the full verb +
  /// noun intent lives in the Semantics label (UI-SPEC Copywriting rationale).
  Widget _control() {
    return switch (_state) {
      CopyReveal.revealed => _button(
          label: widget.readyLabel,
          semanticsLabel: "I'm ready — hide the word",
          onTap: _ready,
        ),
      CopyReveal.hidden => _button(
          label: widget.peekLabel,
          semanticsLabel: 'Peek at the word',
          onTap: _peek,
        ),
      CopyReveal.peeking => _button(
          label: widget.hideLabel,
          semanticsLabel: 'Hide the word again',
          onTap: _hide,
        ),
    };
  }

  /// A calm ghost control (min-height 64, aqua-edge ring) — no gold, no fill.
  Widget _button({
    required String label,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64), // --target-min
            padding: const EdgeInsets.symmetric(horizontal: 26),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QalamTokens.aquaEdge, width: 2),
            ),
            child: Text(
              label,
              style: QalamTextStyles.button.copyWith(
                fontSize: 20,
                color: QalamTokens.inkTeal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
