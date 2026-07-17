// exercise_presenter — RENDER the selected graph node (Plan 18-07 Task 3).
//
// WHY THIS EXISTS (audit): before 18-07 the unit shell rendered `_section(index)`
// (a fixed 6-section linear switch) and advanced sections linearly. `currentExerciseId`
// — the SELECTED node — had ZERO readers in the render path, so a perfect selection
// (Tasks 1–2) changed NOTHING on screen (the Phase-15 dead wire repeated a layer up).
// This resolver is the missing seam: given any of the graph's nodes it renders the
// matching engine surface (the SAME ExerciseScaffold every section uses — never new
// UI), keyed `graph:<id>` so each presented node gets a FRESH scaffold (a new
// initState clears the tutor line / stops TTS — the previous feedback moment is
// never reused). The shell renders THIS instead of `_section(...)` once selection is
// active, so what the child sees next IS what the selector picked.
//
// All 19 graph nodes are mechanically renderable through ExerciseScaffold:
//   • teachCard (surface==null)   → the Meet / support-card path (MeetSection).
//   • traceLetter / writeLetter   → glyph WriteSurface.
//   • connectWord / completeWord / writeWord → sequence WriteSurface.
//   • buildSentence               → order WriteSurface (writtenWords wired in
//                                    write_surface.dart — the dead end is removed).
//   • fillBlank / transformWord   → the modifier WriteSurface paths.
//   • microDrill                  → the default scaffold branch (the Spotlight
//                                    chrome lands in 18-10; the verdict is already
//                                    D-08-scored by the validator).

import 'package:flutter/widgets.dart';

import '../../models/exercise.dart';
import '../../models/letter.dart';
import 'letter_unit_screen.dart' show LetterUnitData;
import 'sections/meet_section.dart';
import 'widgets/exercise_scaffold.dart';

/// Render the graph node [exerciseId] as its engine surface, resolving the config
/// from [data] (with a calm fallback so a section is always navigable). A
/// `teachCard` (no surface) renders the Meet/support-card path; every other node
/// renders an [ExerciseScaffold] keyed `graph:<id>#<epoch>` (a fresh scaffold per
/// presentation — see [presentEpoch]).
///
/// [onNodeResult] is the T2/T1 scoring chokepoint (increment reps + markNodeCleared);
/// [onNext] is the pass/continue CTA (the shell awaits the controller's `nextReady`
/// and swaps to the next selected node). [onAudioTap] plays a prompt clip.
///
/// [presentEpoch] (18-12) is a monotonic counter the shell increments on EVERY
/// advance. It is folded into the widget key so a re-present of the SAME
/// [exerciseId] still produces a DIFFERENT key — forcing Flutter to remount the
/// scaffold (re-running initState) instead of a silent update that leaves the
/// child stuck on a dead CTA (UAT T3 retry-in-place + T6 active-arc pass).
Widget presentGraphExercise({
  required LetterUnitData data,
  required String exerciseId,
  required void Function(String graphExerciseId) onNodeResult,
  required VoidCallback onNext,
  void Function(String audioId)? onAudioTap,
  ({int total, int active})? ribbon,
  int presentEpoch = 0,
}) {
  final letter = data.letter;
  final exercise = data.exercise(exerciseId) ?? _fallbackExercise(exerciseId, letter);

  // 18-12 (UAT T3 + T6): the key carries a monotonic PRESENTATION EPOCH, not the
  // exercise id alone. A legitimate re-present of the SAME graph-node id — a
  // first-fail retry-in-place, OR an active-arc pass re-present of the floor trace
  // — would otherwise reuse the existing Element (same runtimeType + same Key), so
  // `_ExerciseScaffoldState.initState()` (the ONLY place that resets the controller
  // phase to idle, clears the canvas, and re-arms the instruction hold) never
  // re-ran and the CTA tap was a silent no-op / a permanent dead button. Folding
  // the epoch in makes every advance a DIFFERENT key → a fresh mount → initState
  // re-runs. (See retry-does-nothing-after-fail.md §Resolution + app-stuck-and-
  // teacher-margin-not-understood.md §Resolution cause 1 — one mechanism, both
  // triggers.)
  final key = ValueKey('graph:$exerciseId#$presentEpoch');

  // teachCard (surface == null): the Meet / PromptHeader-only support card — it is
  // not graded through the WriteSurface, so "Got it" just advances (plain onNext).
  if (exercise.surface == null) {
    return MeetSection(
      key: key,
      exercise: exercise,
      letter: letter,
      onAdvance: onNext,
      onGraphNodePassed: onNodeResult,
    );
  }

  return ExerciseScaffold(
    key: key,
    exercise: exercise,
    letter: letter,
    graphExerciseId: exerciseId,
    onGraphNodePassed: onNodeResult,
    onNext: onNext,
    onAudioTap: onAudioTap,
    ribbon: ribbon,
    // In the selection-driven presenter, a fail's continue CTA advances to the
    // SELECTED next node (the remediation / drill after a same-criterion streak).
    advanceOnFix: true,
  );
}

/// A calm fallback [Exercise] for a graph node whose authored config is missing
/// (so a section is always navigable — never a crash). Shape is inferred from the
/// id: a `teachCard` teaches (surface null), a `traceLetter` traces, everything
/// else is a write surface. Mirrors letter_unit_screen.dart's fallbacks.
Exercise _fallbackExercise(String id, Letter letter) {
  final letterId = letter.id;
  if (id.contains('teachCard')) {
    return Exercise(
      id: id,
      type: 'teachCard',
      skill: 'comprehension',
      prompt: [SayPart('Meet the letter.'), AudioPart('snd.$letterId')],
      signedOff: false,
    );
  }
  if (id.contains('traceLetter')) {
    final form = id.split('.').last;
    return Exercise(
      id: id,
      type: 'traceLetter',
      skill: 'formation',
      prompt: [SayPart('Trace the letter.'), AudioPart('snd.$letterId')],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: form),
      expected: Answer(glyph: GlyphAnswer(char: letter.char, form: form)),
      check: const Check(base: 'glyph'),
      feedback: const {'pass': 'Well done.'},
      signedOff: false,
    );
  }
  if (id.contains('writeLetter') || id.contains('microDrill')) {
    return Exercise(
      id: id,
      type: id.contains('microDrill') ? 'microDrill' : 'writeLetter',
      skill: 'recall',
      prompt: [SayPart('Write the letter.'), AudioPart('snd.$letterId')],
      surface: const Surface(mode: 'write', unit: 'glyph', guideForm: 'isolated'),
      expected: Answer(glyph: GlyphAnswer(char: letter.char, form: 'isolated')),
      check: const Check(base: 'glyph'),
      feedback: const {'pass': 'That is it.'},
      signedOff: false,
    );
  }
  // Any word/sentence node → a write-the-word surface (sequence).
  return Exercise(
    id: id,
    type: 'writeWord',
    skill: 'spelling',
    prompt: [const SayPart('Write the word.'), AudioPart('snd.$letterId')],
    surface: const Surface(mode: 'write', unit: 'word'),
    expected: const Answer(word: WordAnswer('باب')),
    check: const Check(base: 'sequence'),
    feedback: const {'pass': 'Well written.'},
    signedOff: false,
  );
}
