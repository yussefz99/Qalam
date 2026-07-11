// ExerciseSpec.fromExercise adapter — the carry-forward from Wave 1 (Plan 07-04).
//
// Plan 07-03's validator (lib/core/exercise_engine/) was DECOUPLED from the real
// Schema-v2 Exercise model: it ran in the same wave as 07-01 (which OWNS
// lib/models/exercise.dart) and could not import it without a merge collision.
// So `validateExercise` takes a narrow `ExerciseSpec` view (check + expected +
// feedback) — and 07-03's SUMMARY hands THIS plan the one task it left open:
//
//   "07-04 must add a one-line ExerciseSpec.fromExercise(Exercise) adapter so the
//    engine UI can drive the validator from the real Schema v2 Exercise model.
//    Field names already match the locked schema, so it is mechanical."
//
// This file is that adapter. It lives in lib/features/letter_unit/ (07-04-owned),
// NOT inside lib/core/exercise_engine/ (07-03-owned), so it cannot collide with
// 07-03 on merge. It is a pure mapping — no behaviour, no I/O.

import '../../core/exercise_engine/exercise_check.dart' as spec;
import '../../models/exercise.dart' as model;

/// Adapts the real Schema-v2 [model.Exercise] onto the validator-facing
/// [spec.ExerciseSpec] view, so [WriteSurface] can call `validateExercise` with
/// the engine's actual config. Mechanical: the field names match the locked
/// SCHEMA-V2 §2 verbatim (07-03 SUMMARY).
spec.ExerciseSpec exerciseSpecFromExercise(model.Exercise e) {
  return spec.ExerciseSpec(
    id: e.id,
    // 18-07: carry the template `type` + spotlight `criteria` so a live
    // `type=='microDrill'` exercise scores by its target criterion only (D-08).
    type: e.type,
    check: e.check == null
        ? null
        : spec.CheckSpec(base: e.check!.base, modifiers: e.check!.modifiers),
    expected: e.expected == null ? null : _answer(e.expected!),
    feedback: e.feedback ?? const {},
    criteria: e.criteria,
  );
}

/// Maps the model's `Answer` one-of (glyph | word | words) onto [spec.AnswerSpec].
spec.AnswerSpec _answer(model.Answer a) {
  return spec.AnswerSpec(
    glyph: a.glyph == null
        ? null
        : spec.GlyphAnswer(char: a.glyph!.char, form: a.glyph!.form),
    word: a.word?.text,
    words: a.words,
  );
}
