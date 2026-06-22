// TUTOR-02 — the offline floor, airplane mode (Plan 14-04 Task 2).
//
// With ZERO model loaded, in airplane mode, EVERY baa coaching moment must still
// yield a grounded, authored line and the loop must never block. This guard loads
// the canonical owner-signed baa `feedback` maps (assets/curriculum/exercises.json
// — the same seed CurriculumRepository.getExercises reads) and, for every coaching
// moment, asserts:
//   (a) AuthoredFallbackBrain.next(facts) returns a NON-EMPTY authored line;
//   (b) that line is byte-identical to what ExerciseController.applyResult would
//       resolve for the same verdict (the floor mirrors the verdict-side line);
//   (c) it never throws and never blocks (pure Dart — no Firebase/network/model);
//   (d) an UNKNOWN mistakeId still yields an authored non-'pass' floor line (never
//       a generic "try again").
//
// Correct-Arabic is the owner's-mother sign-off, NOT a code check — here we assert
// the lines are non-empty exactly AS AUTHORED in the signed seed (see SUMMARY note).
//
// The brain + this test import no firebase_ai/genui/flutter_gemma/http — the file
// list at the top is the proof (cross-checked by durable_layers_no_agent_imports
// for the spine; the floor itself is verified import-clean below).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/tutor/authored_fallback_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts_builder.dart';

/// Pull the spoken line out of whichever ACTION shape the brain returned.
String _lineOf(TutorDecision d) => switch (d) {
      Say(:final text) => text,
      PresentActivity(:final coachingLine) => coachingLine,
      _ => '',
    };

/// Mirror of `ExerciseController.applyResult`'s line resolution — the verdict-side
/// authored line the offline floor must match byte-for-byte:
///   • pass            → feedback['pass']
///   • miss (known id) → feedback[mistakeId]
///   • miss (unknown)  → the first non-'pass' authored line (the floor)
String _applyResultLine(Map<String, String> fb, {required bool passed, String? mistakeId}) {
  if (passed) return fb['pass'] ?? '';
  final direct = mistakeId != null ? fb[mistakeId] : null;
  if (direct != null) return direct;
  for (final entry in fb.entries) {
    if (entry.key != 'pass') return entry.value;
  }
  return '';
}

/// Load every baa exercise's authored `feedback` map from the canonical bundled
/// seed. Returns `{ exerciseId: { pass:..., <mistakeId>:... } }` for each baa
/// exercise that authors feedback.
Map<String, Map<String, String>> _loadBaaFeedback() {
  final raw = File('assets/curriculum/exercises.json').readAsStringSync();
  final decoded = json.decode(raw) as Map<String, dynamic>;
  final list = decoded['exercises'] as List<dynamic>;
  final out = <String, Map<String, String>>{};
  for (final e in list) {
    final m = e as Map<String, dynamic>;
    final id = m['id'] as String? ?? '';
    if (!id.startsWith('baa')) continue;
    final fb = m['feedback'] as Map<String, dynamic>?;
    if (fb == null || fb.isEmpty) continue;
    out[id] = fb.map((k, v) => MapEntry(k, v as String));
  }
  return out;
}

void main() {
  final baaFeedback = _loadBaaFeedback();

  test('the canonical seed actually yields baa exercises with feedback', () {
    // Non-vacuous: the 14-02 SUMMARY records 18 baa exercises author feedback.
    expect(baaFeedback, isNotEmpty);
    expect(baaFeedback.length, greaterThanOrEqualTo(18),
        reason: 'expected the signed baa seed to author feedback for >=18 exercises');
    // Every authored map has a 'pass' praise line.
    for (final entry in baaFeedback.entries) {
      expect(entry.value.containsKey('pass'), isTrue,
          reason: '${entry.key} authors no pass line');
    }
  });

  group('TUTOR-02 — every baa coaching moment yields a grounded offline line', () {
    // For EACH baa exercise, cover: the pass moment + EVERY authored mistakeId.
    baaFeedback.forEach((exerciseId, fb) {
      final brain = AuthoredFallbackBrain(feedback: fb);
      // section = the exercise id's trailing token (e.g. traceLetter) — the floor
      // resolution does not depend on section, but we pass a realistic value.
      final section = exerciseId.split('.').length > 1
          ? exerciseId.split('.')[1]
          : exerciseId;

      test('$exerciseId · pass → the authored praise line, byte-identical to '
          'applyResult', () async {
        final facts = buildTutorFacts(
          letterId: 'baa',
          section: section,
          result: const CheckResult.pass(),
        );
        final line = _lineOf(await brain.next(facts));
        expect(line, isNotEmpty, reason: '$exerciseId pass line is empty');
        expect(line, _applyResultLine(fb, passed: true),
            reason: '$exerciseId pass line diverged from applyResult');
        expect(line, fb['pass']);
      });

      // Each authored mistakeId (every non-'pass' key).
      for (final mistakeId in fb.keys.where((k) => k != 'pass')) {
        test('$exerciseId · miss "$mistakeId" → the specific authored fix, '
            'byte-identical to applyResult', () async {
          final facts = buildTutorFacts(
            letterId: 'baa',
            section: section,
            result: CheckResult.fail(mistakeId),
          );
          final line = _lineOf(await brain.next(facts));
          expect(line, isNotEmpty,
              reason: '$exerciseId/$mistakeId line is empty');
          expect(line, _applyResultLine(fb, passed: false, mistakeId: mistakeId),
              reason: '$exerciseId/$mistakeId diverged from applyResult');
          expect(line, fb[mistakeId]);
        });
      }

      test('$exerciseId · miss with an UNKNOWN id → an authored floor line '
          '(never empty, never the praise, never generic)', () async {
        final facts = buildTutorFacts(
          letterId: 'baa',
          section: section,
          result: const CheckResult.fail('__unauthored_mistake_id__'),
        );
        final line = _lineOf(await brain.next(facts));
        expect(line, isNotEmpty, reason: '$exerciseId unknown-id floor is empty');
        // The floor is an AUTHORED non-'pass' line — never the praise.
        expect(line, isNot(fb['pass']));
        expect(fb.values.contains(line), isTrue,
            reason: 'the floor line must be one of the authored lines');
        // And it matches applyResult's unknown-id resolution exactly.
        expect(line, _applyResultLine(fb, passed: false, mistakeId: '__unauthored_mistake_id__'));
      });
    });
  });

  test('the offline floor never throws + never blocks across EVERY baa moment '
      '(pass + each mistakeId + unknown id)', () async {
    var moments = 0;
    for (final entry in baaFeedback.entries) {
      final brain = AuthoredFallbackBrain(feedback: entry.value);
      final ids = <String?>[
        null, // pass
        ...entry.value.keys.where((k) => k != 'pass'),
        '__unauthored__',
      ];
      for (final id in ids) {
        final facts = buildTutorFacts(
          letterId: 'baa',
          section: 'traceLetter',
          result: id == null ? const CheckResult.pass() : CheckResult.fail(id),
        );
        // Must complete (never throw, never hang) and return a decision.
        final decision = await brain.next(facts);
        expect(decision, isA<TutorDecision>());
        moments++;
      }
    }
    // Proves the loop covered a substantial number of moments without blocking.
    expect(moments, greaterThanOrEqualTo(36));
  });

  test('the offline floor + this test are import-clean (no Firebase/network/'
      'model)', () {
    // The brain source must import no agent/network/model package.
    final brainSrc = File('lib/tutor/authored_fallback_brain.dart')
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
        .join('\n');
    for (final bad in const [
      'firebase_ai',
      'genui',
      'flutter_gemma',
      'package:http',
      'cloud_firestore',
    ]) {
      expect(brainSrc.contains(bad), isFalse,
          reason: 'AuthoredFallbackBrain must not import "$bad" — it is the '
              'airplane-mode floor');
    }
  });
}
