import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/models/exercise.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/letter_unit.dart';
import 'package:qalam/models/word.dart';

/// Schema v2 typed-model tests (Plan 07-01 Task 1).
///
/// The locked shape is `SCHEMA-V2.md §2`; the concrete configs these models must
/// parse 1:1 are the 19 baa exercises in
/// `docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json`. The final
/// group loads that real file via File IO and asserts every entry deserializes
/// losslessly (CUR-01 — no field lost).

void main() {
  group('Exercise.fromJson — baa.traceLetter.isolated', () {
    // The first config verbatim from EXERCISE-CONFIGS.json.
    final isolatedJson = {
      'id': 'baa.traceLetter.isolated',
      'type': 'traceLetter',
      'skill': 'formation',
      'prompt': [
        {
          'kind': 'say',
          'line': 'Start at the gold dot and sweep a deep bowl, then the dot below.'
        },
        {'kind': 'audio', 'audioId': 'snd.baa'}
      ],
      'surface': {
        'mode': 'trace',
        'unit': 'glyph',
        'guideForm': 'isolated',
        'demo': true
      },
      'expected': {
        'glyph': {'char': 'ب', 'form': 'isolated'}
      },
      'check': 'glyph',
      'feedback': {
        'pass': 'Beautiful — a deep, smooth bowl. أحسنت!',
        'shallowBowl':
            'A little shallow — give the bowl a deeper curve. Try again, slower.',
        'noDot': 'The bowl is good — now place the dot just below it.'
      },
      'signedOff': false
    };

    test('parses the LOCKED shape end to end', () {
      final ex = Exercise.fromJson(isolatedJson);
      expect(ex.id, 'baa.traceLetter.isolated');
      expect(ex.type, 'traceLetter');
      expect(ex.skill, 'formation');
      expect(ex.signedOff, isFalse);

      // prompt: a say + an audio part, in order.
      expect(ex.prompt, hasLength(2));
      expect(ex.prompt[0], isA<SayPart>());
      expect((ex.prompt[0] as SayPart).line, contains('deep bowl'));
      expect(ex.prompt[1], isA<AudioPart>());
      expect((ex.prompt[1] as AudioPart).audioId, 'snd.baa');

      // surface
      final s = ex.surface!;
      expect(s.mode, 'trace');
      expect(s.unit, 'glyph');
      expect(s.guideForm, 'isolated');
      expect(s.demo, isTrue);

      // expected.glyph
      expect(ex.expected!.glyph!.char, 'ب');
      expect(ex.expected!.glyph!.form, 'isolated');

      // check
      expect(ex.check!.base, 'glyph');
      expect(ex.check!.modifiers, isEmpty);

      // feedback.pass reserved praise key (#1)
      expect(ex.feedback!['pass'], isNotNull);
      expect(ex.feedback!['shallowBowl'], isNotNull);
    });
  });

  group('PromptPart polymorphism — each kind round-trips its own fields', () {
    test('say', () {
      final p = PromptPart.fromJson({'kind': 'say', 'line': 'hello'});
      expect(p, isA<SayPart>());
      expect((p as SayPart).line, 'hello');
    });

    test('audio', () {
      final p = PromptPart.fromJson({'kind': 'audio', 'audioId': 'snd.baa'});
      expect(p, isA<AudioPart>());
      expect((p as AudioPart).audioId, 'snd.baa');
    });

    test('image with caption', () {
      final p = PromptPart.fromJson(
          {'kind': 'image', 'imageId': 'img.duck', 'caption': 'what?'});
      expect(p, isA<ImagePart>());
      expect((p as ImagePart).imageId, 'img.duck');
      expect(p.caption, 'what?');
    });

    test('text — gaps[], reveal:thenHide, loose', () {
      final withGaps = PromptPart.fromJson({
        'kind': 'text',
        'text': 'با_',
        'gaps': [
          {'kind': 'letter', 'index': 2}
        ]
      }) as TextPart;
      expect(withGaps.text, 'با_');
      expect(withGaps.gaps, hasLength(1));
      expect(withGaps.gaps.first.kind, 'letter');
      expect(withGaps.gaps.first.index, 2);
      expect(withGaps.reveal, isNull);
      expect(withGaps.loose, isFalse);

      final reveal = PromptPart.fromJson(
          {'kind': 'text', 'text': 'باب', 'reveal': 'thenHide'}) as TextPart;
      expect(reveal.reveal, 'thenHide');

      final loose = PromptPart.fromJson(
          {'kind': 'text', 'text': 'ب  ا  ب', 'loose': true}) as TextPart;
      expect(loose.loose, isTrue);
    });

    test('rule — label', () {
      final p = PromptPart.fromJson(
          {'kind': 'rule', 'label': 'Initial form · أوّل'}) as RulePart;
      expect(p.label, 'Initial form · أوّل');
    });

    test('forms — char + forms[]', () {
      final p = PromptPart.fromJson({
        'kind': 'forms',
        'char': 'ب',
        'forms': ['isolated', 'initial', 'medial', 'final']
      }) as FormsPart;
      expect(p.char, 'ب');
      expect(p.forms, ['isolated', 'initial', 'medial', 'final']);
    });
  });

  group('Check — string grammar parses into {base, modifiers[]}', () {
    test('"glyph+positionalForm" → base glyph + 1 modifier', () {
      final c = Check.fromJson('glyph+positionalForm');
      expect(c.base, 'glyph');
      expect(c.modifiers, ['positionalForm']);
    });

    test('"sequence+joinContinuity+positionalForm" → 3 modifiers', () {
      final c = Check.fromJson('sequence+joinContinuity+positionalForm');
      expect(c.base, 'sequence');
      expect(c.modifiers, ['joinContinuity', 'positionalForm']);
    });

    test('"order+sequence" → base order + modifier sequence', () {
      final c = Check.fromJson('order+sequence');
      expect(c.base, 'order');
      expect(c.modifiers, ['sequence']);
    });

    test('accepts a structured {base, modifiers[]} map (forward-compat)', () {
      final c = Check.fromJson({
        'base': 'glyph',
        'modifiers': ['positionalForm']
      });
      expect(c.base, 'glyph');
      expect(c.modifiers, ['positionalForm']);
    });
  });

  group('teachCard — null surface/expected/check/feedback parses', () {
    test('does not throw, leaves the four fields null', () {
      final teachCard = {
        'id': 'baa.teachCard.meet',
        'type': 'teachCard',
        'skill': 'comprehension',
        'prompt': [
          {'kind': 'say', 'line': 'This card just teaches.'},
          {'kind': 'audio', 'audioId': 'snd.baa'},
          {'kind': 'image', 'imageId': 'img.door', 'caption': 'باب · baab'},
          {
            'kind': 'forms',
            'char': 'ب',
            'forms': ['isolated', 'initial', 'medial', 'final']
          }
        ],
        'surface': null,
        'expected': null,
        'check': null,
        'feedback': null,
        'signedOff': false
      };
      final ex = Exercise.fromJson(teachCard);
      expect(ex.surface, isNull);
      expect(ex.expected, isNull);
      expect(ex.check, isNull);
      expect(ex.feedback, isNull);
      expect(ex.prompt, hasLength(4));
      expect(ex.prompt[3], isA<FormsPart>());
    });
  });

  group('Surface.given + Answer one-of', () {
    test('Surface.given parses {word, blankIndex}', () {
      final s = Surface.fromJson({
        'mode': 'write',
        'unit': 'glyph',
        'given': {'word': 'باب', 'blankIndex': 2}
      });
      expect(s.given!.word, 'باب');
      expect(s.given!.blankIndex, 2);
    });

    test('Answer parses each one-of (glyph / word / words[])', () {
      final glyph = Answer.fromJson({
        'glyph': {'char': 'ب', 'form': 'final'}
      });
      expect(glyph.glyph!.char, 'ب');
      expect(glyph.word, isNull);
      expect(glyph.words, isNull);

      final word = Answer.fromJson({
        'word': {'text': 'باب'}
      });
      expect(word.word!.text, 'باب');
      expect(word.glyph, isNull);

      final words = Answer.fromJson({
        'words': ['البابُ', 'كبير']
      });
      expect(words.words, ['البابُ', 'كبير']);
      expect(words.word, isNull);
    });
  });

  group('LetterUnit + Word', () {
    test('LetterUnit.fromJson parses sections in order with exercise ids', () {
      final unit = LetterUnit.fromJson({
        'letterId': 'baa',
        'sections': [
          {
            'id': 'meet',
            'exercises': ['baa.teachCard.meet']
          },
          {
            'id': 'watchTrace',
            'exercises': ['baa.traceLetter.isolated', 'baa.traceLetter.initial']
          }
        ]
      });
      expect(unit.letterId, 'baa');
      expect(unit.sections, hasLength(2));
      expect(unit.sections[0].id, 'meet');
      expect(unit.sections[1].id, 'watchTrace');
      expect(unit.sections[1].exercises, hasLength(2));
      expect(unit.sections[1].exercises.first, 'baa.traceLetter.isolated');
    });

    test('Word.fromJson parses id/text/audio/image/gloss/letters', () {
      final w = Word.fromJson({
        'id': 'baab',
        'text': 'باب',
        'audio': 'word.baab',
        'image': 'img.door',
        'gloss': {'en': 'door'},
        'letters': ['baa', 'alif', 'baa']
      });
      expect(w.id, 'baab');
      expect(w.text, 'باب');
      expect(w.audio, 'word.baab');
      expect(w.image, 'img.door');
      expect(w.gloss['en'], 'door');
      expect(w.letters, ['baa', 'alif', 'baa']);
    });
  });

  group('Form (per-positional-form data on Letter)', () {
    test('Form.fromJson parses referenceStrokes + commonMistakes + tolerances',
        () {
      final f = Form.fromJson({
        'referenceStrokes': [
          {
            'order': 1,
            'label': 'body',
            'points': [
              [0.1, 0.2],
              [0.3, 0.4]
            ],
            'direction': 'leftToRight'
          }
        ],
        'commonMistakes': [
          {'id': 'shallowBowl', 'check': 'depth', 'feedback': 'deeper bowl'}
        ],
        'tolerances': {'preset': 'loose'}
      });
      expect(f.referenceStrokes, hasLength(1));
      expect(f.commonMistakes, hasLength(1));
      expect(f.commonMistakes.first.id, 'shallowBowl');
      expect(f.tolerances, isNotNull);
    });

    test('Letter.contextualForms parses per-form objects, nulls allowed', () {
      final letter = Letter.fromJson({
        'id': 'baa',
        'char': 'ب',
        'name': {'ar': 'بَاء', 'display': 'Baa'},
        'introOrder': 2,
        'forms': {
          'isolated': 'ب',
          'initial': 'بـ',
          'medial': 'ـبـ',
          'final': 'ـب'
        },
        'referenceStrokes': [],
        'cleanRepsToAdvance': 3,
        'commonMistakes': [],
        'mistakesStatus': 'placeholder',
        'signedOff': false,
        'contextualForms': {
          'isolated': {'referenceStrokes': [], 'commonMistakes': []},
          'medial': null
        }
      });
      expect(letter.contextualForms, isNotNull);
      expect(letter.contextualForms!['isolated'], isA<Form>());
      expect(letter.contextualForms!.containsKey('medial'), isTrue);
      expect(letter.contextualForms!['medial'], isNull);
    });

    test('Letter without contextualForms still parses (additive, backward-compat)',
        () {
      final letter = Letter.fromJson({
        'id': 'alif',
        'char': 'ا',
        'name': {'ar': 'اَلِف', 'display': 'Alif'},
        'introOrder': 1,
        'forms': {
          'isolated': 'ا',
          'initial': 'ا',
          'medial': 'ا',
          'final': 'ا'
        },
        'referenceStrokes': [],
        'cleanRepsToAdvance': 3,
        'commonMistakes': [],
        'mistakesStatus': 'placeholder',
        'signedOff': false
      });
      expect(letter.contextualForms, isNull);
    });
  });

  group('the 19 real baa configs deserialize 1:1 (CUR-01)', () {
    test('EXERCISE-CONFIGS.json — all 19 parse without throwing', () {
      final file = File(
          'docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json');
      expect(file.existsSync(), isTrue,
          reason: 'EXERCISE-CONFIGS.json must exist for the round-trip test');
      final decoded = json.decode(file.readAsStringSync())
          as Map<String, dynamic>;
      final rawExercises = decoded['exercises'] as List<dynamic>;
      expect(rawExercises, hasLength(19));

      final parsed = rawExercises
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(parsed, hasLength(19));

      // Spot-check: every parsed exercise carries a non-empty id + skill, and
      // its prompt list length matches the raw config (no part dropped).
      for (var i = 0; i < parsed.length; i++) {
        final ex = parsed[i];
        final raw = rawExercises[i] as Map<String, dynamic>;
        expect(ex.id, isNotEmpty);
        expect(ex.skill, isNotEmpty);
        expect(ex.prompt, hasLength((raw['prompt'] as List).length),
            reason: 'prompt parts lost for ${ex.id}');
      }

      // The teachCard (last config) has null surface/expected/check/feedback.
      final teachCard = parsed.firstWhere((e) => e.type == 'teachCard');
      expect(teachCard.surface, isNull);
      expect(teachCard.check, isNull);
    });
  });
}
