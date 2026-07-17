// Phase 19-02 (Wave 2) — QP-02 unit contract: the per-type instruction resolver.
//
// The instruction bar's text is a PER-TYPE template resolved from the exercise
// (D-02) — NOT a transcript of the `say` line (Pitfall 6). This pins the exact
// UI-SPEC Copywriting Contract strings + the two writeWord sub-variants (copy vs
// listen) + the microDrill per-criterion override + the unknown fallback, all
// keyed off `exercise.type` (plus AudioPart / reveal / criteria disambiguation).
//
// l10n-independent: the resolver reads its text from ExerciseScaffoldStrings
// (English defaults), so this test needs no gen-l10n and no BuildContext.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart';
import 'package:qalam/models/exercise.dart';

/// Build a minimal graded [Exercise] of [type] with the given [prompt] parts
/// and [criteria] (all other fields are inert for the resolver).
Exercise _ex(
  String? type, {
  List<PromptPart> prompt = const [],
  List<String> criteria = const [],
}) =>
    Exercise(
      id: 'x.$type',
      type: type,
      skill: 'spelling',
      prompt: prompt,
      criteria: criteria,
      signedOff: false,
    );

void main() {
  group('instructionTemplateFor — per-type template (D-02)', () {
    test('completeWord → "Write the missing letter"', () {
      expect(instructionTemplateFor(_ex('completeWord')).text,
          'Write the missing letter');
    });

    test('traceLetter → "Trace the letter" + brand nib glyph (no Material icon)',
        () {
      final spec = instructionTemplateFor(_ex('traceLetter'));
      expect(spec.text, 'Trace the letter');
      expect(spec.svgAsset, isNotNull,
          reason: 'traceLetter uses the brand qalam-nib.svg glyph');
      expect(spec.icon, isNull);
    });

    test('writeLetter base → "Write the letter"', () {
      expect(instructionTemplateFor(_ex('writeLetter')).text, 'Write the letter');
    });

    test('writeWord base → "Write the word"', () {
      expect(instructionTemplateFor(_ex('writeWord')).text, 'Write the word');
    });

    test('writeWord copy variant (reveal:thenHide) → "Copy the word"', () {
      final ex = _ex('writeWord', prompt: const [
        TextPart(text: 'باب', reveal: 'thenHide'),
      ]);
      final spec = instructionTemplateFor(ex);
      expect(spec.text, 'Copy the word');
      expect(spec.icon, Icons.content_copy_rounded);
    });

    test('listen variant (carries an AudioPart) → "Listen and write"', () {
      final ex = _ex('writeWord', prompt: const [AudioPart('snd.baab')]);
      final spec = instructionTemplateFor(ex);
      expect(spec.text, 'Listen and write');
      expect(spec.icon, Icons.hearing_rounded);
    });

    test('writeLetter listen variant (AudioPart) → "Listen and write"', () {
      final ex = _ex('writeLetter', prompt: const [AudioPart('snd.baa')]);
      expect(instructionTemplateFor(ex).text, 'Listen and write');
    });

    test('connectWord → "Join the letters"', () {
      expect(instructionTemplateFor(_ex('connectWord')).text, 'Join the letters');
    });

    test('fillBlank → "Write the missing part"', () {
      expect(instructionTemplateFor(_ex('fillBlank')).text,
          'Write the missing part');
    });

    test('transformWord → "Change the word"', () {
      expect(instructionTemplateFor(_ex('transformWord')).text, 'Change the word');
    });

    test('buildSentence → "Build the sentence"', () {
      expect(instructionTemplateFor(_ex('buildSentence')).text,
          'Build the sentence');
    });

    test('microDrill base → "Practice this part"', () {
      expect(instructionTemplateFor(_ex('microDrill')).text, 'Practice this part');
    });

    test('unknown type → fallback "Look and write"', () {
      expect(instructionTemplateFor(_ex('somethingNew')).text, 'Look and write');
    });

    test('null type → fallback "Look and write"', () {
      expect(instructionTemplateFor(_ex(null)).text, 'Look and write');
    });
  });

  group('instructionTemplateFor — microDrill per-criterion override', () {
    test('dot → "Practice the dot"', () {
      expect(
          instructionTemplateFor(_ex('microDrill', criteria: const ['dot'])).text,
          'Practice the dot');
    });

    test('shape → "Practice the curve"', () {
      expect(
          instructionTemplateFor(_ex('microDrill', criteria: const ['shape']))
              .text,
          'Practice the curve');
    });

    test('strokeOrder → "Practice the start"', () {
      expect(
          instructionTemplateFor(
                  _ex('microDrill', criteria: const ['strokeOrder']))
              .text,
          'Practice the start');
    });
  });
}
