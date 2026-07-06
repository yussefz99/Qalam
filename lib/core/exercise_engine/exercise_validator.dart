/// Pure Dart, no dart:ui, no Flutter imports.
///
/// THE VALIDATOR SPINE (Plan 07-03).
///
/// One entry point — `validateExercise` — turns a child's raw strokes into a
/// pass-or-specific-fix [CheckResult] for EVERY baa question type, all
/// data-driven from the exercise config. It is "one core scorer + two thin
/// wrappers + a few rule checks" (COMPONENT-SYSTEM.md §6 / SCHEMA-V2.md §3):
///
///   • base `glyph`    → REUSE the Phase-4 geometric scorer (`scoreLetter`)
///                       against the form's reference strokes. NO new geometry.
///   • base `sequence` → per-letter glyph in order (a thin wrapper over the same
///                       glyph check + the written-word comparison).
///   • base `order`    → compare the written words against the expected order.
///   • modifier `positionalForm`  → assert the written contextual form matches.
///   • modifier `joinContinuity`  → assert no pen-lift between letters.
///   • modifier `transformRule`   → assert the dual/plural/opposite answer.
///
/// The returned [CheckResult.mistakeId] is ALWAYS one of the exercise's authored
/// `feedback` keys (T-07-03-02): the scorer's internal [MistakeId] is translated
/// to a candidate set, then narrowed to the keys the owner actually authored for
/// THIS exercise. An unknown scorer id can never inject raw text — it falls back
/// to a generic authored key (or, if none, the first non-`pass` authored key).
///
/// SECURITY (T-07-03-01): pure in-memory Dart. Strokes are read, scored, and
/// discarded; only the [CheckResult] (a bool + an authored key) leaves here.
/// Nothing is logged or persisted; the tutor never runs client-side (Decided).
library;

import '../scoring/letter_scorer.dart';
import '../scoring/scoring_models.dart';
import '../../models/letter.dart';
import 'check_result.dart';
import 'exercise_check.dart';

/// Validates one captured exercise attempt against its config.
///
/// [exercise] is the validator-facing view (check + expected + feedback).
/// [strokes] is the child's per-stroke capture (`[[ [x,y], … ], …]`) in pixel
/// space — the SAME shape the Phase-4 `scoreLetter` consumes (so the glyph base
/// can delegate without a conversion layer).
///
/// [letter] supplies the reference strokes for the glyph scorer; it is required
/// for any check whose verdict depends on stroke geometry (glyph / sequence's
/// per-letter glyph). The text-level inputs ([writtenWord] / [writtenWords] /
/// [writtenForm]) carry the recogniser's transcription for the wrapper checks
/// (sequence / order / the modifiers) — geometry alone cannot tell باب from بب,
/// so the caller (WriteSurface, Plan 07-04) passes what was written.
///
/// [penLiftedBetweenLetters] is the joinContinuity signal: true when the child
/// lifted the pen between letters of a word that must be written joined.
///
/// [guideForm] is the surface's asked positional form (`Surface.guideForm`) —
/// the scorer's reference is resolved for this form when the exercise's expected
/// glyph does not name one (write mode paints no dotted guide but still has an
/// asked form). The VALIDATOR owns form resolution for scoring (RESEARCH
/// Pattern 2).
Future<CheckResult> validateExercise(
  ExerciseSpec exercise,
  List<List<List<double>>> strokes, {
  Letter? letter,
  String? writtenWord,
  List<String>? writtenWords,
  String? writtenForm,
  String? guideForm,
  bool penLiftedBetweenLetters = false,
}) async {
  final check = exercise.check;
  // A teachCard (no check) is never assessed — it always "passes".
  if (check == null) return const CheckResult.pass();

  switch (check.base) {
    case 'glyph':
      return _validateGlyph(
        exercise,
        strokes,
        letter,
        writtenForm: writtenForm,
        guideForm: guideForm,
      );
    case 'sequence':
      return _validateSequence(
        exercise,
        strokes,
        letter,
        writtenWord: writtenWord,
        writtenForm: writtenForm,
        guideForm: guideForm,
        penLiftedBetweenLetters: penLiftedBetweenLetters,
      );
    case 'order':
      return _validateOrder(
        exercise,
        writtenWords: writtenWords,
      );
    default:
      // Unknown base → never invent a verdict; surface a generic authored miss.
      return CheckResult.fail(_genericMiss(exercise));
  }
}

// ── base: glyph ──────────────────────────────────────────────────────────────

/// The glyph base: delegate to the Phase-4 `scoreLetter`, then layer the
/// positionalForm modifier. Reuses the single geometric scorer verbatim.
Future<CheckResult> _validateGlyph(
  ExerciseSpec exercise,
  List<List<List<double>>> strokes,
  Letter? letter, {
  String? writtenForm,
  String? guideForm,
}) async {
  // positionalForm: the matched contextual form must equal the expected form.
  // Checked BEFORE geometry so a right-shape-wrong-form attempt reports the
  // form miss (the authored line is about the form, not the bowl).
  final formMiss = _checkPositionalForm(exercise, writtenForm);
  if (formMiss != null) return CheckResult.fail(formMiss);

  if (letter == null) {
    // No reference geometry to score against → cannot pass a glyph check.
    return CheckResult.fail(_genericMiss(exercise));
  }

  // The VALIDATOR owns form resolution for scoring (RESEARCH Pattern 2): the
  // asked positional form is the exercise's expected glyph form, else the
  // surface's guideForm. Threading it fixes UAT F5 at the scorer (D-A) — an
  // isolated bowl offered for a medial slot now fails its own per-form reference.
  final form = exercise.expected?.glyph?.form ?? guideForm;
  final result = await scoreLetter(strokes, letter, form: form);
  if (result.passed) return const CheckResult.pass();

  return CheckResult.fail(_mapMistake(result.mistakeId, exercise));
}

// ── base: sequence ───────────────────────────────────────────────────────────

/// The sequence base: validate a word as per-letter glyphs in order. The
/// joinContinuity modifier checks the letters connect (no pen-lift).
///
/// Geometry per-letter would require per-letter stroke segmentation (Plan 07-04
/// owns the WriteSurface that segments a word into per-letter captures); at the
/// validator boundary the per-letter VERDICT is driven by the recogniser's
/// [writtenWord] transcription compared against `expected.word`, with the glyph
/// scorer reused for the (single-glyph) leg when whole-word strokes are a single
/// letter. The first divergence → the authored miss key.
Future<CheckResult> _validateSequence(
  ExerciseSpec exercise,
  List<List<List<double>>> strokes,
  Letter? letter, {
  String? writtenWord,
  String? writtenForm,
  String? guideForm,
  bool penLiftedBetweenLetters = false,
}) async {
  // joinContinuity first: a lifted pen is the specific, authored "lifted" miss.
  if (exercise.check!.hasJoinContinuity && penLiftedBetweenLetters) {
    return CheckResult.fail(_pickKey(exercise, const ['lifted']));
  }

  // positionalForm modifier on a sequence (e.g. baa.connectWord.kitaab).
  final formMiss = _checkPositionalForm(exercise, writtenForm);
  if (formMiss != null) return CheckResult.fail(formMiss);

  final expectedWord = exercise.expected?.word;
  if (expectedWord != null && writtenWord != null) {
    if (writtenWord != expectedWord) {
      return CheckResult.fail(_sequenceMiss(expectedWord, writtenWord, exercise));
    }
  }

  // transformRule modifier on a sequence (dual/plural/opposite).
  final transformMiss = _checkTransformRule(exercise, writtenWord);
  if (transformMiss != null) return CheckResult.fail(transformMiss);

  // Whole-word strokes that reduce to a single glyph → reuse the glyph scorer
  // as the geometric leg (keeps the "one core scorer" promise honest). Resolve
  // the asked form the same way the glyph base does (Pattern 2).
  if (letter != null && strokes.isNotEmpty && expectedWord == null) {
    final form = exercise.expected?.glyph?.form ?? guideForm;
    final result = await scoreLetter(strokes, letter, form: form);
    if (!result.passed) {
      return CheckResult.fail(_mapMistake(result.mistakeId, exercise));
    }
  }

  return const CheckResult.pass();
}

// ── base: order ──────────────────────────────────────────────────────────────

/// The order base: compare the written word groupings against `expected.words`
/// order. A re-ordering or a missing/extra word → the authored miss
/// ("wrongOrder" / "incomplete").
CheckResult _validateOrder(
  ExerciseSpec exercise, {
  List<String>? writtenWords,
}) {
  final expected = exercise.expected?.words;
  if (expected == null) return const CheckResult.pass();
  if (writtenWords == null) {
    return CheckResult.fail(_pickKey(exercise, const ['incomplete', 'wrongOrder']));
  }

  if (writtenWords.length != expected.length) {
    return CheckResult.fail(_pickKey(exercise, const ['incomplete', 'wrongOrder']));
  }

  // Same multiset of words but a different order → wrongOrder; a genuinely
  // different word set → incomplete (the sentence isn't the target one).
  final sameSet = ({...writtenWords}.difference({...expected})).isEmpty &&
      writtenWords.length == expected.length;
  for (var i = 0; i < expected.length; i++) {
    if (writtenWords[i] != expected[i]) {
      return CheckResult.fail(
        _pickKey(
          exercise,
          sameSet ? const ['wrongOrder'] : const ['incomplete', 'wrongOrder'],
        ),
      );
    }
  }

  return const CheckResult.pass();
}

// ── modifiers ────────────────────────────────────────────────────────────────

/// positionalForm: the written contextual form must equal `expected.glyph.form`.
/// Returns the authored miss key on a mismatch, or null when it holds / N/A.
String? _checkPositionalForm(ExerciseSpec exercise, String? writtenForm) {
  if (!exercise.check!.hasPositionalForm) return null;
  final expectedForm = exercise.expected?.glyph?.form;
  if (expectedForm == null || writtenForm == null) return null;
  if (writtenForm == expectedForm) return null;
  return _pickKey(exercise, const ['wrongForm', 'hasTail', 'tooBig', 'wrongLetter']);
}

/// transformRule: the written answer must be the expected dual/plural/opposite.
/// Returns the authored miss key when the transformed answer is absent/wrong.
String? _checkTransformRule(ExerciseSpec exercise, String? writtenWord) {
  if (!exercise.check!.hasTransformRule) return null;
  final expectedWord = exercise.expected?.word;
  if (expectedWord == null || writtenWord == null) return null;
  if (writtenWord == expectedWord) return null;
  return _pickKey(
    exercise,
    const ['missingEnding', 'wrongForm', 'wrongAntonym', 'wrongWord'],
  );
}

// ── mistakeId resolution ─────────────────────────────────────────────────────

/// Translates the per-word divergence into the authored sequence miss. A missing
/// dot (the written word is the right letters minus a dot-bearing baa) maps to
/// "missingDot" when authored; otherwise "incomplete" / a generic miss.
String _sequenceMiss(String expected, String written, ExerciseSpec exercise) {
  // Heuristic: the child wrote fewer characters than expected → "incomplete";
  // an equal-length divergence on a dotted letter → "missingDot".
  final candidates = <String>[
    if (written.length < expected.length) 'incomplete',
    'missingDot',
    'incomplete',
    'wrongWord',
  ];
  return _pickKey(exercise, candidates);
}

/// Maps a Phase-4 scorer [MistakeId] to the BEST authored feedback key for this
/// exercise. The scorer speaks geometry (`dotMisplaced`, `wrongStrokeCount`…);
/// the exercise authors speak child-facing fixes (`shallowBowl`, `noDot`,
/// `missingDot`…). Each scorer id carries an ordered candidate list; the first
/// candidate the exercise actually authored wins. Falls back to a generic
/// authored key so no raw scorer internal ever surfaces (T-07-03-02).
String _mapMistake(MistakeId? id, ExerciseSpec exercise) {
  // Each list is tried in order; the FIRST key the exercise authored wins. The
  // geometry/semantic key name (e.g. 'tooShort') is FIRST so a letter that authors
  // its OWN letter-specific feedback (alif: tooShort/wrongDirection/tooCurved) is
  // preferred; the baa-shaped keys (shallowBowl/noDot) stay as the fallback for
  // exercises that only authored those. This is what makes a non-baa letter (alif)
  // resolve to ITS feedback instead of baa's "shallow bowl" / "now the dots".
  const candidatesByMistake = <MistakeId, List<String>>{
    MistakeId.tooShort: ['tooShort', 'shallowBowl', 'incomplete'],
    MistakeId.wrongDirection: ['wrongDirection', 'shallowBowl', 'wrongLetter', 'wrongForm'],
    MistakeId.tooCurved: ['tooCurved', 'shallowBowl'],
    MistakeId.wrongStrokeCount: ['wrongStrokeCount', 'noDot', 'missingDot', 'incomplete'],
    MistakeId.wrongStrokeOrder: ['wrongStrokeOrder', 'noDot', 'missingDot'],
    MistakeId.dotMisplaced: ['dotMisplaced', 'noDot', 'missingDot', 'shallowBowl'],
    MistakeId.wrongLetterIdentity: ['wrongLetterIdentity', 'wrongLetter', 'wrongForm', 'wrongWord'],
    MistakeId.fallback: [],
  };
  final candidates = candidatesByMistake[id ?? MistakeId.fallback] ?? const [];
  return _pickKey(exercise, candidates);
}

/// Returns the first [candidates] key the exercise authored; if none match,
/// falls back to a generic authored miss key (never `pass`, never raw text).
String _pickKey(ExerciseSpec exercise, List<String> candidates) {
  for (final c in candidates) {
    if (exercise.feedback.containsKey(c)) return c;
  }
  return _genericMiss(exercise);
}

/// The exercise's most-generic authored miss: the first feedback key that is not
/// the reserved `pass` praise key. Guarantees a CheckResult.fail always points
/// at AUTHORED copy.
String _genericMiss(ExerciseSpec exercise) {
  for (final key in exercise.feedback.keys) {
    if (key != 'pass') return key;
  }
  // No authored miss line at all → a stable sentinel (still not raw scorer text).
  return 'tryAgain';
}
