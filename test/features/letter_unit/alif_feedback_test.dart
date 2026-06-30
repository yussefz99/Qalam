// Verifies the alif fix against the REAL curriculum data (assets/curriculum/*.json):
//  1) a straight vertical line PASSES alif.writeLetter.writeForm ("the correct answer
//     is a straight line"), and
//  2) a wrong (curved) attempt FAILS with a real alif SHAPE line — not the copied
//     sound line "Listen again — which letter makes that sound?".
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/exercise_engine/exercise_check.dart';
import 'package:qalam/core/exercise_engine/exercise_validator.dart';
import 'package:qalam/models/letter.dart';

void main() {
  late Letter alif;
  late ExerciseSpec writeForm;
  late Map<String, String> feedback;

  setUpAll(() {
    final letters = jsonDecode(File('assets/curriculum/letters.json').readAsStringSync())['letters'] as List;
    alif = Letter.fromJson(Map<String, dynamic>.from(
        letters.firstWhere((l) => l['id'] == 'alif') as Map));
    final exs = jsonDecode(File('assets/curriculum/exercises.json').readAsStringSync())['exercises'] as List;
    final raw = Map<String, dynamic>.from(
        exs.firstWhere((e) => e['id'] == 'alif.writeLetter.writeForm') as Map);
    writeForm = ExerciseSpec.fromJson(raw);
    feedback = Map<String, String>.from(raw['feedback'] as Map);
  });

  // A clean straight vertical line, top→bottom, plenty of points.
  List<List<double>> straight() =>
      [for (var i = 0; i < 16; i++) [0.5, 0.18 + i * (0.62 / 15)]];

  // A strongly bowed line (high curvature) — the wrong answer for alif.
  List<List<double>> curved() => [
        for (var i = 0; i < 16; i++)
          [0.5 + 0.32 * math.sin(math.pi * i / 15), 0.18 + i * (0.62 / 15)]
      ];

  test('a straight vertical line PASSES alif (the correct answer is a straight line)', () async {
    final r = await validateExercise(writeForm, [straight()], letter: alif);
    expect(r.passed, isTrue, reason: 'a clean straight alif must pass');
  });

  test('a wrong (curved) alif FAILS with a real shape line, NOT the copied sound line', () async {
    final r = await validateExercise(writeForm, [curved()], letter: alif);
    expect(r.passed, isFalse, reason: 'a bowed alif is wrong');
    final line = feedback[r.mistakeId] ?? '';
    expect(line, isNotEmpty, reason: 'a wrong attempt must give a feedback line');
    expect(line.toLowerCase(), contains('straight'),
        reason: 'alif miss should coach straightness; got: $line');
    expect(line, isNot(contains('Listen again')),
        reason: 'must NOT show the copied sound-question line');
  });
}
