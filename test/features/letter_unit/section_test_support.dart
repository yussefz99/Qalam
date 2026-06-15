// Shared test fixtures + finders for the Letter-Unit section tests (Plan 07-05).
//
// Provides:
//   • baaLetter()   — a baa Letter with an isolated contextual Form carrying
//     reference strokes (so trace surfaces have a guide + scorer geometry), and
//     initial/medial/final left as NULL Forms (the un-authored, pre-07-07 state
//     the Forms section must degrade gracefully on).
//   • meetExercise()      — the baa.teachCard.meet config (no surface/check).
//   • traceIsolatedExercise() — baa.traceLetter.isolated (trace + demo).
//   • traceFormExercise(form) — baa.traceLetter.<form> (trace, guideForm set).
//   • joinExercise()      — the join-into-باب write/word config.
//   • findArabic(text)    — a Text finder that matches the ArabicText output,
//     which wraps Western-digit runs in LRI…PDI; the baa glyphs have no digits
//     so a plain substring match is exact, but we route through the same finder
//     for symmetry with the rest of the suite.

import 'package:flutter/widgets.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';

/// A baa reference body stroke (a shallow bowl) + its dot — enough for the
/// glyph scorer and the dotted guide to have real geometry in trace mode.
const StrokeSpec _baaBody = StrokeSpec(
  order: 1,
  label: 'bowl',
  type: 'curve',
  points: [
    [0.25, 0.40],
    [0.50, 0.62],
    [0.75, 0.40],
  ],
  direction: 'rightToLeft',
);
const StrokeSpec _baaDot = StrokeSpec(
  order: 2,
  label: 'dot',
  type: 'dot',
  points: [
    [0.50, 0.78],
  ],
  direction: 'none',
);

/// A baa [Letter]. The `isolated` contextual Form is authored (has reference
/// strokes); `initial`/`medial`/`final` are present-but-NULL — the exact
/// pre-07-07 "not yet signed off" state the Forms section must handle without
/// crashing or fabricating strokes.
Letter baaLetter() => const Letter(
      id: 'baa',
      char: 'ب',
      name: LetterName(ar: 'باء', display: 'baa'),
      introOrder: 2,
      forms:
          LetterForms(isolated: 'ب', initial: 'بـ', medial: 'ـبـ', final_: 'ـب'),
      referenceStrokes: [_baaBody, _baaDot],
      cleanRepsToAdvance: 1,
      commonMistakes: [],
      mistakesStatus: 'placeholder',
      signedOff: false,
      contextualForms: {
        'isolated': Form(referenceStrokes: [_baaBody, _baaDot]),
        // un-authored forms — Plan 07-07 fills these; until then they are null.
        'initial': null,
        'medial': null,
        'final': null,
      },
    );

/// `baa.teachCard.meet` — PromptHeader-only (no surface/expected/check/feedback).
Exercise meetExercise() => const Exercise(
      id: 'baa.teachCard.meet',
      type: 'teachCard',
      skill: 'comprehension',
      prompt: [
        SayPart(
            'This card just teaches — the sound and the four shapes. Nothing to write here.'),
        AudioPart('snd.baa'),
        ImagePart('img.door', caption: 'باب · baab'),
        FormsPart(char: 'ب', forms: ['isolated', 'initial', 'medial', 'final']),
      ],
      signedOff: false,
    );

/// `baa.traceLetter.isolated` — trace the isolated baa over the dotted guide,
/// with the Watch-me demo enabled and the authored feedback lines.
Exercise traceIsolatedExercise() => const Exercise(
      id: 'baa.traceLetter.isolated',
      type: 'traceLetter',
      skill: 'formation',
      prompt: [
        SayPart(
            'Start at the gold dot and sweep a deep bowl, then the dot below.'),
        AudioPart('snd.baa'),
      ],
      surface:
          Surface(mode: 'trace', unit: 'glyph', guideForm: 'isolated', demo: true),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: 'isolated')),
      check: Check(base: 'glyph'),
      feedback: {
        'pass': 'Beautiful — a deep, smooth bowl. أحسنت!',
        'shallowBowl':
            'A little shallow — give the bowl a deeper curve. Try again, slower.',
        'noDot': 'The bowl is good — now place the dot just below it.',
      },
      policy: Policy(reps: 2),
      signedOff: false,
    );

/// `baa.traceLetter.<form>` — trace a contextual form (initial/medial/final).
Exercise traceFormExercise(String form) => Exercise(
      id: 'baa.traceLetter.$form',
      type: 'traceLetter',
      skill: 'formation',
      prompt: [
        SayPart('Trace the $form baa.'),
        RulePart('$form form'),
      ],
      surface: Surface(mode: 'trace', unit: 'glyph', guideForm: form),
      expected: Answer(glyph: GlyphAnswer(char: 'ب', form: form)),
      check: const Check(base: 'glyph', modifiers: ['positionalForm']),
      feedback: const {
        'pass': "That's the shape — ready to join.",
        'wrongForm': 'Keep it small and flat. Try once more.',
      },
      signedOff: false,
    );

/// The join-into-باب stage — write the whole word from the joined forms.
Exercise joinExercise() => const Exercise(
      id: 'baa.connectWord.baab',
      type: 'connectWord',
      skill: 'spelling',
      prompt: [
        SayPart(
            'Now join them — keep your pen down and write باب, all in one go.'),
        AudioPart('word.baab'),
      ],
      surface: Surface(mode: 'write', unit: 'word'),
      expected: Answer(word: WordAnswer('باب')),
      check: Check(base: 'sequence', modifiers: ['joinContinuity']),
      feedback: {
        'pass': 'Joined in one go — باب, "door." أحسنت!',
        'lifted':
            "Don't lift between the letters — let baa reach across to join. Try again.",
      },
      signedOff: false,
    );

/// A finder for an Arabic string as rendered by ArabicText (which is a Text
/// whose data is the digit-isolated source; baa glyphs carry no digits so the
/// match is exact). Uses a predicate so it tolerates the surrounding widget.
Finder findArabic(String text) => find.byWidgetPredicate(
      (w) => w is Text && w.data == text,
    );
