// ListenWriteSection — Section 5 of the baa Letter Unit (Plan 07-06).
//
// "Listen & Write" — the RECALL GATE. No dotted guide this time: the child
// LISTENS, then writes the word (or its first letter) FROM MEMORY, scored
// on-device with the authored feedback. This is the prototype's `listenWrite()`
// surface (unit.js), reproduced 1:1:
//
//   • a left prompt column: a word ↔ first-letter toggle (.lw-sub), a task card
//     (.lw-card) with the task + sub line, and a big Play button (.bigplay) that
//     plays the word clip OFFLINE;
//   • a right write surface with the ".noguide / from memory" badge — NO dotted
//     glyph (the engine WriteSurface in write-mode draws a blank ruled line);
//   • the toggle swaps the active config between `baa.writeWord.dictation` and
//     `baa.writeLetter.fromSound`; a scored pass shows the authored praise, a
//     miss the authored fix.
//
// CONFIG-DRIVEN (COMPONENTS.md): each mode is the engine's ExerciseScaffold fed
// the matching write Exercise — no bespoke grading UI; the authored feedback
// comes straight from the config's `feedback` map. The two configs are write/
// unit:word and write/unit:glyph respectively, so neither shows a guide glyph.
//
// FINISH GATE: the whole section is the recall gate, so finishing REQUIRES the
// WORD task (the first-letter toggle is phonological-awareness practice, but the
// gate is "wrote the word from memory"). [onFinish] is wired to the word pass.
//
// ANTI-GAMIFICATION: the engine's ONE star on a pass, zero counters/tallies.
// OFFLINE AUDIO (S1-06): the big Play plays the active config's word clip via
// [audioPlayerProvider].

import 'package:flutter/material.dart' hide Form;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/exercise.dart';
import '../../../models/letter.dart';
import '../../../providers/audio_providers.dart';
import '../../../theme/qalam_tokens.dart';
import '../../../theme/text_styles.dart';
import '../exercise_controller.dart';
import '../widgets/exercise_scaffold.dart';

/// Static copy for the Listen & Write section (English defaults; call site
/// passes l10n — keeps the widget test independent of `flutter gen-l10n`).
class ListenWriteStrings {
  const ListenWriteStrings({
    this.kick = 'Listen & Write',
    this.writeWordTab = 'Write the word',
    this.firstLetterTab = 'First letter',
    this.wordTask = 'Listen, then write the whole word.',
    this.wordSub = 'Dictation — from memory, no guide.',
    this.letterTask = 'Listen. Write the letter the word starts with.',
    this.letterSub = 'Phonological awareness — hear → first letter.',
    this.playWord = 'Play the word',
    this.noGuide = 'No guide · from memory',
  });

  final String kick;
  final String writeWordTab;
  final String firstLetterTab;
  final String wordTask;
  final String wordSub;
  final String letterTask;
  final String letterSub;
  final String playWord;
  final String noGuide;
}

/// The two recall modes the toggle swaps between.
enum LwMode { word, letter }

/// Section 5 — Listen & Write (the recall gate). Feed it the [writeWord] config
/// (`baa.writeWord.dictation`) and the [writeLetter] config
/// (`baa.writeLetter.fromSound`) plus the [letter]; [onFinish] fires once the
/// child writes the WORD from memory (the gate).
class ListenWriteSection extends ConsumerStatefulWidget {
  const ListenWriteSection({
    super.key,
    required this.writeWord,
    required this.writeLetter,
    required this.letter,
    this.onFinish,
    this.strings = const ListenWriteStrings(),
  });

  /// `baa.writeWord.dictation` — write the whole word from memory (the gate).
  final Exercise writeWord;

  /// `baa.writeLetter.fromSound` — write the first letter from the sound.
  final Exercise writeLetter;

  /// The letter (for the glyph scorer geometry on the first-letter task).
  final Letter letter;

  /// Fires once the WORD task is cleanly written (the recall gate is met).
  final VoidCallback? onFinish;

  /// Section copy (English defaults; call site passes l10n).
  final ListenWriteStrings strings;

  @override
  ConsumerState<ListenWriteSection> createState() => ListenWriteSectionState();
}

/// Public state so the host (and the widget test) can read/drive the mode.
class ListenWriteSectionState extends ConsumerState<ListenWriteSection> {
  LwMode _mode = LwMode.word;

  /// The active config for the current mode — the word↔first-letter swap.
  Exercise get activeExercise =>
      _mode == LwMode.word ? widget.writeWord : widget.writeLetter;

  LwMode get mode => _mode;

  void _select(LwMode m) {
    if (m == _mode) return;
    setState(() => _mode = m);
    // Reload the controller for the newly active config so the swap is clean.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(exerciseControllerProvider.notifier).load(activeExercise);
      }
    });
  }

  /// The active config's word/audio id (for the big Play button).
  String? get _activeAudioId {
    for (final p in activeExercise.prompt) {
      if (p is AudioPart) return p.audioId;
    }
    return null;
  }

  void _play(String? id) {
    if (id == null || id.isEmpty) return;
    ref.read(audioPlayerProvider).playLetter(id);
  }

  /// The scaffold's onNext: a clean pass. Only the WORD task opens the gate.
  void _onPass() {
    if (_mode == LwMode.word) widget.onFinish?.call();
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // .lw-prompt — the toggle + task card + big Play.
                  SizedBox(
                    width: 300, // .lw-prompt width:300px
                    child: _PromptColumn(
                      mode: _mode,
                      strings: s,
                      onSelect: _select,
                      onPlay: () => _play(_activeAudioId),
                    ),
                  ),
                  const SizedBox(width: 18), // .lw gap:18
                  // the write surface — NO dotted guide (the recall gate).
                  Expanded(child: _recallSurface(s)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recallSurface(ListenWriteStrings s) {
    return Stack(
      children: [
        Positioned.fill(
          child: ExerciseScaffold(
            // A key per mode so the scaffold/controller reset cleanly on swap.
            key: ValueKey<String>('lwScaffold:${_mode.name}'),
            exercise: activeExercise,
            letter: widget.letter,
            kick: s.kick,
            onNext: _onPass,
            onAudioTap: _play,
          ),
        ),
        // .noguide — the "from memory" badge over the surface (top-start).
        PositionedDirectional(
          top: 18,
          start: 18,
          child: _NoGuideBadge(label: s.noGuide),
        ),
      ],
    );
  }
}

/// The left prompt column: the word↔first-letter toggle, the task card, and the
/// big offline Play button.
class _PromptColumn extends StatelessWidget {
  const _PromptColumn({
    required this.mode,
    required this.strings,
    required this.onSelect,
    required this.onPlay,
  });

  final LwMode mode;
  final ListenWriteStrings strings;
  final ValueChanged<LwMode> onSelect;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final isWord = mode == LwMode.word;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .lw-sub — the two-tab toggle.
        Row(
          children: [
            Expanded(
              child: _Tab(
                key: const ValueKey('lwTabWord'),
                label: strings.writeWordTab,
                active: isWord,
                onTap: () => onSelect(LwMode.word),
              ),
            ),
            const SizedBox(width: 8), // .lw-sub gap:8
            Expanded(
              child: _Tab(
                key: const ValueKey('lwTabLetter'),
                label: strings.firstLetterTab,
                active: !isWord,
                onTap: () => onSelect(LwMode.letter),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14), // .lw-prompt gap:14
        // .lw-card — task + sub + big Play.
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: QalamTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: QalamTokens.aquaEdge, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1A0E5B5F),
                  offset: Offset(0, 8),
                  blurRadius: 18,
                  spreadRadius: -8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWord ? strings.wordTask : strings.letterTask,
                style: QalamTextStyles.heading.copyWith(
                  fontSize: 20, // .lw-card .task
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: QalamTokens.fg,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isWord ? strings.wordSub : strings.letterSub,
                style: QalamTextStyles.label.copyWith(
                  fontSize: 14, // .lw-card .sub
                  fontWeight: FontWeight.w600,
                  color: QalamTokens.fgMuted,
                ),
              ),
              const SizedBox(height: 14),
              _BigPlay(label: strings.playWord, onTap: onPlay),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.lw-sub .b` — one toggle tab (active = teal-ringed, teal-tint).
class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: active ? QalamTokens.tealTint : QalamTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            height: 46, // .lw-sub .b height:46px
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: active ? QalamTokens.inkTeal : QalamTokens.aquaEdge,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: QalamTextStyles.button.copyWith(
                fontSize: 14,
                color: active ? QalamTokens.deepInk : QalamTokens.fgMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.bigplay` — the big teal offline Play button (sticker shadow).
class _BigPlay extends StatelessWidget {
  const _BigPlay({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: QalamTokens.inkTeal,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: 88, // .bigplay height:88px
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: QalamTokens.deepInk, offset: Offset(0, 5)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded,
                    size: 28, color: QalamTokens.fgOnPrimary),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: QalamTextStyles.button.copyWith(
                    fontSize: 20,
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

/// `.noguide` — the "No guide · from memory" pill over the recall surface.
class _NoGuideBadge extends StatelessWidget {
  const _NoGuideBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('lwNoGuideBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: QalamTokens.parchmentDeep, // .noguide background:parchment-deep
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: QalamTextStyles.label.copyWith(
          fontSize: 11, // .noguide font-size:11px
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06 * 11,
          color: QalamTokens.fgMuted,
        ),
      ),
    );
  }
}
