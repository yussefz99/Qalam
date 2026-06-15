// WordsSection — Section 4 of the baa Letter Unit (Plan 07-06).
//
// "Words with Baa": the child sees three real words that USE baa
// (door / duck / milk), can HEAR each one offline, and TRACES the whole word.
// This is the prototype's `words()` grid + `traceWord()` (unit.js), reproduced
// 1:1 as two stages:
//
//   • Grid stage — a `.wordgrid` of three `.wordcard`s, each with an image stub,
//     the Arabic word (its baa runs highlighted teal), the romanization + gloss,
//     and a round Play button that plays the word clip OFFLINE. Tapping a card
//     opens its trace surface. A "Trace at least one word" hint gates Next.
//   • Trace stage — the engine's ExerciseScaffold fed the word's writeWord /
//     connectWord Exercise (a WriteSurface the child traces, graded on-device),
//     with a Listen side card playing the word clip and a "Back to words" CTA.
//
// CONFIG-DRIVEN (the hard rule, COMPONENTS.md): the trace stage is the engine's
// ExerciseScaffold fed the matching baa word Exercise — no bespoke grading UI.
// The authored feedback comes straight from each config's `feedback` map.
// OFFLINE AUDIO (S1-06): every Play plays the word's bundled clip via
// [audioPlayerProvider]; an unknown id degrades to a silent no-op.

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../models/word.dart';
import '../../../providers/audio_providers.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../widgets/exercise_scaffold.dart';
import 'section_side_cards.dart';

/// Static copy for the Words section (English defaults; call site passes l10n —
/// keeps the widget test independent of `flutter gen-l10n`, the 07-04/05 rule).
class WordsSectionStrings {
  const WordsSectionStrings({
    this.kick = 'Words with Baa',
    this.play = 'Play',
    this.tapToTrace = 'Tap to trace',
    this.traced = 'Traced',
    this.backToWords = 'Back to words',
    this.listenLabel = 'Listen',
    this.listenPlay = 'Play word',
    this.hint = 'Trace at least one word to go on.',
  });

  final String kick;
  final String play;
  final String tapToTrace;
  final String traced;
  final String backToWords;
  final String listenLabel;
  final String listenPlay;
  final String hint;
}

/// Pairs a vocab [Word] with the [Exercise] that traces it (writeWord /
/// connectWord). The shell builds these from words.json + the unit's exercises.
class WordTrace {
  const WordTrace({required this.word, required this.exercise});

  final Word word;
  final Exercise exercise;
}

/// Section 4 — Words with baa. Feed it the three [words] (each a vocab Word +
/// its trace Exercise) and the [letter]; [onAdvance] advances to Section 5
/// (Listen & Write) once at least one word has been traced.
class WordsSection extends ConsumerStatefulWidget {
  const WordsSection({
    super.key,
    required this.words,
    required this.letter,
    this.onAdvance,
    this.strings = const WordsSectionStrings(),
  });

  /// The three baa-family vocab words + their trace configs (door/duck/milk).
  final List<WordTrace> words;

  /// The letter being practised — its base glyph powers the baa highlight.
  final Letter letter;

  /// Advance to Section 5 (after at least one word is traced).
  final VoidCallback? onAdvance;

  /// Section copy (English defaults; call site passes l10n).
  final WordsSectionStrings strings;

  @override
  ConsumerState<WordsSection> createState() => WordsSectionState();
}

/// Public state so the host (and the widget test) can drive completion.
class WordsSectionState extends ConsumerState<WordsSection> {
  final Set<int> _done = <int>{};
  int? _tracing; // null = grid stage; index = tracing that word.

  void _play(String? id) {
    if (id == null || id.isEmpty) return;
    // Fire-and-forget; the offline player degrades to a silent no-op on an
    // unknown id / missing clip, so the child is never blocked (T-07-02-04).
    ref.read(audioPlayerProvider).playLetter(id);
  }

  void _openTrace(int i) => setState(() => _tracing = i);

  void _backToGrid() => setState(() => _tracing = null);

  /// Marks a word traced (and returns to the grid). Exposed for host/test
  /// sequencing — the same hook the scaffold's onNext calls on a clean pass.
  void debugMarkWordTraced(int i) {
    setState(() {
      _done.add(i);
      _tracing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tracing != null) return _buildTrace(_tracing!);
    return _buildGrid();
  }

  // ── the three-card grid ────────────────────────────────────────────────────
  Widget _buildGrid() {
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
                s.kick,
                style: QalamTextStyles.label.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.13 * 12.5,
                  color: QalamTokens.inkTeal,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // .wordgrid — three equal cards.
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.words.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(
                      child: WordCard(
                        key: ValueKey<String>(
                            'wordCard:${widget.words[i].word.id}'),
                        word: widget.words[i].word,
                        baseGlyph: widget.letter.char,
                        traced: _done.contains(i),
                        playLabel: s.play,
                        traceLabel:
                            _done.contains(i) ? s.traced : s.tapToTrace,
                        playKey: ValueKey<String>(
                            'wordPlay:${widget.words[i].word.id}'),
                        onPlay: () => _play(widget.words[i].word.audio),
                        onTap: () => _openTrace(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── one word's trace surface (the engine scaffold + a Listen side card) ─────
  Widget _buildTrace(int i) {
    final s = widget.strings;
    final wt = widget.words[i];
    final w = wt.word;
    return KeyedSubtree(
      key: ValueKey<String>('wordTrace:${w.id}'),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExerciseScaffold(
              exercise: wt.exercise,
              letter: widget.letter,
              kick: s.kick,
              // A clean pass marks the word traced + returns to the grid.
              onNext: () => debugMarkWordTraced(i),
              onAudioTap: _play,
            ),
          ),
          // The Listen side card — an offline Play affordance for the word.
          PositionedDirectional(
            bottom: 28,
            end: 40,
            child: ListenCard(
              label: s.listenLabel,
              glyph: w.text,
              romanization: _romGloss(w),
              playLabel: s.listenPlay,
              glyphSize: 48,
              playKey: ValueKey<String>('wordTraceListen:${w.id}'),
              onPlay: () => _play(w.audio),
            ),
          ),
          // The "Back to words" quiet CTA — top-start, returns to the grid.
          PositionedDirectional(
            top: 18,
            start: 26,
            child: QuietButton(
              label: s.backToWords,
              icon: Icons.arrow_back_rounded,
              onTap: _backToGrid,
            ),
          ),
        ],
      ),
    );
  }

  /// "baab · door" — romanization + the English gloss, like the prototype's
  /// `${w.rom} · ${w.en}`.
  String _romGloss(Word w) {
    final en = w.gloss['en'];
    final rom = w.id;
    return en == null || en.isEmpty ? rom : '$rom · $en';
  }
}

/// `.wordcard` — one vocab card: an image stub, the Arabic word (its baa runs
/// highlighted teal), the romanization + gloss, a round Play button, and a
/// "tap to trace / traced" tag. Presentation only; the section owns the audio.
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.baseGlyph,
    required this.traced,
    required this.playLabel,
    required this.traceLabel,
    required this.onPlay,
    required this.onTap,
    this.playKey,
  });

  final Word word;
  final String baseGlyph;
  final bool traced;
  final String playLabel;
  final String traceLabel;
  final VoidCallback onPlay;
  final VoidCallback onTap;
  final Key? playKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${word.id} ${word.gloss['en'] ?? ''}'.trim(),
      child: Material(
        color: QalamTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: QalamTokens.aquaEdge),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A0E5B5F),
                    offset: Offset(0, 8),
                    blurRadius: 18,
                    spreadRadius: -8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // .pic — the hatched illustration stub (art is Plan 07-07).
                Expanded(
                  child: _PicStub(caption: word.image ?? word.id),
                ),
                const SizedBox(height: 12),
                // .wd — the Arabic word with its baa runs highlighted teal.
                Center(
                  child: _HighlightedWord(
                    text: word.text,
                    baseGlyph: baseGlyph,
                  ),
                ),
                const SizedBox(height: 10),
                // .meta — rom + en on the start, the Play button on the end.
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.id,
                            style: QalamTextStyles.button.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: QalamTokens.fg,
                            ),
                          ),
                          if ((word.gloss['en'] ?? '').isNotEmpty)
                            Text(
                              word.gloss['en']!,
                              style: QalamTextStyles.label.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: QalamTokens.fgMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _RoundPlay(key: playKey, label: playLabel, onTap: onPlay),
                  ],
                ),
                const SizedBox(height: 10),
                // .trace-tag — "tap to trace" / "✓ traced".
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      traced
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: traced ? QalamTokens.leaf : QalamTokens.inkTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      traceLabel,
                      style: QalamTextStyles.label.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: traced ? QalamTokens.leaf : QalamTokens.inkTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.wordcard .wd` — the Arabic word with its baa runs painted teal. Splits the
/// word on the base glyph so the baa characters render in ink-teal and the rest
/// in deep-ink (the prototype's `<span class="baa">`).
class _HighlightedWord extends StatelessWidget {
  const _HighlightedWord({required this.text, required this.baseGlyph});

  final String text;
  final String baseGlyph;

  @override
  Widget build(BuildContext context) {
    final base = QalamTextStyles.arDisplay.copyWith(
      fontSize: 46, // .wordcard .wd
      fontWeight: FontWeight.w600,
      color: QalamTokens.deepInk,
      height: 1.5,
    );
    final spans = <InlineSpan>[
      for (final ch in text.characters)
        TextSpan(
          text: ch,
          style: ch == baseGlyph
              ? base.copyWith(color: QalamTokens.inkTeal) // .baa highlight
              : base,
        ),
    ];
    // An RTL island so the connected word shapes correctly.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(TextSpan(children: spans), textAlign: TextAlign.center),
    );
  }
}

/// The hatched illustration stub (real art is Plan 07-07's content job).
class _PicStub extends StatelessWidget {
  const _PicStub({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        color: QalamTokens.softAqua,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QalamTokens.aquaEdge),
      ),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: QalamTokens.surfaceRaised.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          caption,
          style: QalamTextStyles.label.copyWith(
            fontSize: 11,
            color: QalamTokens.fgMuted,
          ),
        ),
      ),
    );
  }
}

/// `.wordcard .play` — the round offline Play button on a word card.
class _RoundPlay extends StatelessWidget {
  const _RoundPlay({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: QalamTokens.softAqua,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44, // .wordcard .play
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: QalamTokens.aquaEdge),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.volume_up_rounded,
                size: 22, color: QalamTokens.deepInk),
          ),
        ),
      ),
    );
  }
}
