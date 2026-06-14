import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/data/firestore_curriculum_codec.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/models/lesson.dart';

/// Round-trip parity tests for the shared Firestore curriculum codec.
///
/// The codec solves the Firestore nested-array landmine (D-06): a StrokeSpec
/// `[x,y]` point pair must be stored as a `{x,y}` map on the Firestore side and
/// rebuilt losslessly to `[x,y]` on read. These tests prove the transform is
/// lossless against the REAL curriculum (alif + a skeleton letter) and that the
/// codec defers to the model `fromJson` contracts (D-08). No Firebase / device
/// needed — the codec operates on plain `Map<String, dynamic>`.

/// Pull a single letter map (by id) out of the real bundled letters.json.
Map<String, dynamic> _letterById(String id) {
  final raw = File('assets/curriculum/letters.json').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final letters = (decoded['letters'] as List).cast<Map<String, dynamic>>();
  return letters.firstWhere((l) => l['id'] == id);
}

Map<String, dynamic> _lessonsFile() {
  final raw = File('assets/curriculum/lessons.json').readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// Deep value-equality assertion for a decoded Letter vs the bundle parse.
void _expectLetterEquals(Letter actual, Letter expected) {
  expect(actual.id, expected.id);
  expect(actual.char, expected.char);
  expect(actual.name.ar, expected.name.ar);
  expect(actual.name.display, expected.name.display);
  expect(actual.introOrder, expected.introOrder);
  expect(actual.forms.isolated, expected.forms.isolated);
  expect(actual.forms.initial, expected.forms.initial);
  expect(actual.forms.medial, expected.forms.medial);
  expect(actual.forms.final_, expected.forms.final_);
  expect(actual.cleanRepsToAdvance, expected.cleanRepsToAdvance);
  expect(actual.mistakesStatus, expected.mistakesStatus);
  expect(actual.signedOff, expected.signedOff);

  // referenceStrokes — order, label, type, direction, and the points themselves
  expect(actual.referenceStrokes.length, expected.referenceStrokes.length);
  for (var i = 0; i < expected.referenceStrokes.length; i++) {
    final a = actual.referenceStrokes[i];
    final e = expected.referenceStrokes[i];
    expect(a.order, e.order);
    expect(a.label, e.label);
    expect(a.type, e.type);
    expect(a.direction, e.direction);
    expect(a.points, e.points,
        reason: 'points must rebuild [x,y]<-{x,y} losslessly');
  }

  // commonMistakes
  expect(actual.commonMistakes.length, expected.commonMistakes.length);
  for (var i = 0; i < expected.commonMistakes.length; i++) {
    expect(actual.commonMistakes[i].id, expected.commonMistakes[i].id);
    expect(actual.commonMistakes[i].check, expected.commonMistakes[i].check);
    expect(
        actual.commonMistakes[i].feedback, expected.commonMistakes[i].feedback);
  }

  // audio (nullable)
  expect(actual.audio?.letter, expected.audio?.letter);
  expect(actual.audio?.examples, expected.audio?.examples);

  // tolerances (nullable)
  expect(actual.tolerances == null, expected.tolerances == null);
}

void main() {
  group('point codec {x,y} <-> [x,y]', () {
    test('Test 1: a point pair encodes to {x,y} and decodes back losslessly',
        () {
      final letter = _letterById('alif');
      final fs = letterToFirestoreMap(letter);

      // On the Firestore side every point is a {x,y} map (no nested arrays).
      final fsStrokes = (fs['referenceStrokes'] as List)
          .cast<Map<String, dynamic>>();
      final fsPoints = (fsStrokes.first['points'] as List)
          .cast<Map<String, dynamic>>();
      expect(fsPoints.first['x'], 0.5);
      expect(fsPoints.first['y'], 0.191);

      // And it decodes back to [0.5, 0.191].
      final back = letterFromFirestore(fs);
      expect(back.referenceStrokes.first.points.first, [0.5, 0.191]);
    });
  });

  group('Letter round-trip parity (D-08)', () {
    test('Test 2: alif (with strokes) round-trips deep-equal vs the bundle',
        () {
      final alifJson = _letterById('alif');
      final expected = Letter.fromJson(alifJson);

      final fs = letterToFirestoreMap(alifJson);
      final actual = letterFromFirestore(fs);

      _expectLetterEquals(actual, expected);

      // points must be List<List<double>>, each pair length 2.
      for (final stroke in actual.referenceStrokes) {
        for (final p in stroke.points) {
          expect(p, isA<List<double>>());
          expect(p.length, 2);
        }
      }
    });

    test('Test 3: a skeleton letter round-trips with empty strokes + signedOff:false',
        () {
      // baa carries signedOff:false in the bundle; build a true skeleton
      // (empty referenceStrokes, placeholder mistakes) to pin Pitfall 6.
      final skeleton = <String, dynamic>{
        'id': 'skeleton',
        'char': 'ص',
        'name': {'ar': 'x', 'display': 'Skeleton'},
        'introOrder': 99,
        'forms': {
          'isolated': 'ص',
          'initial': 'صـ',
          'medial': 'ـصـ',
          'final': 'ـص'
        },
        'referenceStrokes': <dynamic>[],
        'cleanRepsToAdvance': 3,
        'commonMistakes': <dynamic>[],
        'mistakesStatus': 'placeholder',
        'signedOff': false,
        'audio': {'letter': null, 'examples': <dynamic>[]},
      };
      final expected = Letter.fromJson(skeleton);

      final fs = letterToFirestoreMap(skeleton);
      final actual = letterFromFirestore(fs);

      _expectLetterEquals(actual, expected);
      expect(actual.referenceStrokes, isEmpty);
      expect(actual.signedOff, isFalse);
      expect(actual.mistakesStatus, 'placeholder');
    });
  });

  group('Lesson + tolerance ramp round-trip (Pitfall 5)', () {
    test('Test 4a: a lesson round-trips (items, unlock, optional ramp)', () {
      final lessons =
          (_lessonsFile()['lessons'] as List).cast<Map<String, dynamic>>();
      final lessonJson = lessons.first;
      final expected = Lesson.fromJson(lessonJson);

      final fs = lessonToFirestoreMap(lessonJson);
      final actual = lessonFromFirestore(fs);

      expect(actual.id, expected.id);
      expect(actual.order, expected.order);
      expect(actual.title.display, expected.title.display);
      expect(actual.items.length, expected.items.length);
      expect(actual.items.first.type, expected.items.first.type);
      expect(actual.items.first.ref, expected.items.first.ref);
      expect(actual.unlock.requires, expected.unlock.requires);
      expect(actual.unlock.passRule, expected.unlock.passRule);
      expect(actual.toleranceRamp, expected.toleranceRamp);
    });

    test('Test 4b: a lesson WITH a toleranceRamp override round-trips it', () {
      final lessonJson = <String, dynamic>{
        'id': 'lesson_x',
        'order': 7,
        'title': {'display': 'Ramped lesson'},
        'items': [
          {'type': 'letter', 'ref': 'alif'}
        ],
        'unlock': {'requires': <dynamic>[], 'passRule': 'allItemsPassed'},
        'toleranceRamp': ['loose', 'normal', 'strict'],
      };
      final expected = Lesson.fromJson(lessonJson);

      final fs = lessonToFirestoreMap(lessonJson);
      final actual = lessonFromFirestore(fs);

      expect(actual.toleranceRamp, ['loose', 'normal', 'strict']);
      expect(actual.toleranceRamp, expected.toleranceRamp);
    });

    test('Test 4c: defaultToleranceRamp survives the meta doc round-trip', () {
      final ramp =
          (_lessonsFile()['defaultToleranceRamp'] as List).cast<String>();

      final metaDoc = metaToleranceRampToFirestore(ramp);
      expect(metaDoc['ramp'], ramp);

      final back = metaToleranceRampFromFirestore(metaDoc);
      expect(back, ramp);
    });
  });
}
