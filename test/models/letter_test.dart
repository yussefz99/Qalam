import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/models/letter.dart';

void main() {
  group('Letter.fromJson', () {
    final fullLetterJson = {
      'id': 'baa',
      'char': 'ب',
      'name': {'ar': 'بَاء', 'display': 'Baa'},
      'introOrder': 2,
      'forms': {
        'isolated': 'ب',
        'initial': 'بـ',
        'medial': 'ـبـ',
        'final': 'ـب',
      },
      'referenceStrokes': [
        {
          'order': 1,
          'label': 'body',
          'points': [
            [0.1, 0.2],
            [0.3, 0.4],
          ],
          'direction': 'leftToRight',
        },
        {
          'order': 2,
          'label': 'dot',
          'points': [
            [0.5, 0.6],
            [0.7, 0.8],
          ],
          'direction': 'topToBottom',
        },
      ],
      'cleanRepsToAdvance': 3,
      'commonMistakes': [
        {
          'id': 'too_flat',
          'check': 'strokeCurvatureBelowThreshold',
          'feedback': 'Make the curve rounder.',
        },
        {
          'id': 'missing_dot',
          'check': 'dotAbsent',
          'feedback': 'Don\'t forget the dot underneath.',
        },
      ],
      'mistakesStatus': 'authored',
      'signedOff': true,
      'audio': {'letter': null, 'examples': []},
    };

    test('full-data letter deserialises all fields', () {
      final letter = Letter.fromJson(fullLetterJson);

      expect(letter.id, 'baa');
      expect(letter.char, 'ب');
      expect(letter.name.ar, 'بَاء');
      expect(letter.name.display, 'Baa');
      expect(letter.introOrder, 2);
      expect(letter.forms.isolated, 'ب');
      expect(letter.forms.initial, 'بـ');
      expect(letter.forms.medial, 'ـبـ');
      expect(letter.forms.final_, 'ـب');
      expect(letter.referenceStrokes.length, 2);
      expect(letter.referenceStrokes[0].points.isNotEmpty, true);
      expect(letter.cleanRepsToAdvance, 3);
      expect(letter.commonMistakes.length, 2);
      expect(letter.mistakesStatus, 'authored');
      expect(letter.signedOff, true);
    });

    test('placeholder letter (empty arrays) deserialises without error', () {
      final json = {
        'id': 'zaay',
        'char': 'ز',
        'name': {'ar': 'زَاي', 'display': 'Zaay'},
        'introOrder': 11,
        'forms': {
          'isolated': 'ز',
          'initial': 'ز',
          'medial': 'ز',
          'final': 'ز',
        },
        'referenceStrokes': [],
        'cleanRepsToAdvance': 3,
        'commonMistakes': [],
        'mistakesStatus': 'placeholder',
        'signedOff': false,
        'audio': {'letter': null, 'examples': []},
      };

      final letter = Letter.fromJson(json);

      expect(letter.referenceStrokes.isEmpty, true);
      expect(letter.commonMistakes.isEmpty, true);
      expect(letter.signedOff, false);
    });

    test('StrokeSpec.fromJson maps order, label, points, and direction', () {
      final strokeJson = {
        'order': 1,
        'label': 'vertical_stroke',
        'points': [
          [0.1, 0.9],
          [0.2, 0.5],
          [0.3, 0.1],
        ],
        'direction': 'topToBottom',
      };

      final stroke = StrokeSpec.fromJson(strokeJson);

      expect(stroke.order, 1);
      expect(stroke.label, 'vertical_stroke');
      expect(stroke.direction, 'topToBottom');
      expect(stroke.points.length, 3);
      expect(stroke.points[0], isA<List<double>>());
      expect(stroke.points[0][0], closeTo(0.1, 0.001));
      expect(stroke.points[0][1], closeTo(0.9, 0.001));
    });

    test('StrokeSpec.fromJson with type "curve" yields type == "curve"', () {
      final strokeJson = {
        'order': 1,
        'label': 'bowl',
        'type': 'curve',
        'points': [
          [0.1, 0.5],
          [0.5, 0.7],
          [0.9, 0.5],
        ],
        'direction': 'leftToRight',
      };

      final stroke = StrokeSpec.fromJson(strokeJson);

      expect(stroke.type, 'curve');
    });

    test('StrokeSpec.fromJson with no type key defaults to "line"', () {
      final strokeJson = {
        'order': 1,
        'label': 'vertical_stroke',
        'points': [
          [0.5, 0.0],
          [0.5, 1.0],
        ],
        'direction': 'topToBottom',
      };

      final stroke = StrokeSpec.fromJson(strokeJson);

      expect(stroke.type, 'line');
    });

    test('StrokeSpec.fromJson with type "dot" and one point parses', () {
      final strokeJson = {
        'order': 2,
        'label': 'dot',
        'type': 'dot',
        'points': [
          [0.5, 1.2],
        ],
        'direction': 'tap',
      };

      final stroke = StrokeSpec.fromJson(strokeJson);

      expect(stroke.type, 'dot');
      expect(stroke.points.length, 1);
    });

    test('CommonMistake.fromJson maps id, check, feedback', () {
      final mistakeJson = {
        'id': 'too_short',
        'check': 'strokeLengthBelowThreshold',
        'feedback': 'Draw it from the top all the way down.',
      };

      final mistake = CommonMistake.fromJson(mistakeJson);

      expect(mistake.id, 'too_short');
      expect(mistake.check, 'strokeLengthBelowThreshold');
      expect(mistake.feedback, 'Draw it from the top all the way down.');
    });

    test('AudioRef.fromJson with null letter and empty examples', () {
      final audioJson = {'letter': null, 'examples': []};

      final audio = AudioRef.fromJson(audioJson);

      expect(audio.letter, isNull);
      expect(audio.examples.isEmpty, true);
    });
  });
}
