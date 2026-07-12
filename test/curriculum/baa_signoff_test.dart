import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/stroke_validation.dart';
import 'package:qalam/models/letter.dart';

/// Plan 07-07 — baa Letter Unit load-time validity gate + sign-off human gate.
///
/// Task 1 (this file, DRAFT stage) proves two things:
///   1. All FOUR baa contextual forms (isolated/initial/medial/final) are
///      authored as VALID open centerlines — every form passes
///      `validateReferenceStrokes` (no closed loops, directions agree with point
///      order, dots are single taps drawn after the body, contiguous orders,
///      in-range coords). The crown-jewel D-04 guard can never let a glyph
///      OUTLINE reach the scorer.
///   2. Each form carries 3–4 named common mistakes in the tutor's warm,
///      specific voice.
///
/// The SIGN-OFF assertion is RED at Task 1 BY DESIGN: baa is still
/// `signedOff:false` because the owner's mother has not yet reviewed and signed
/// off (the blocking-human Task 2 gate). This proves the human gate is REQUIRED,
/// not bypassed by an executor. After she signs off (Task 2 → Task 3), the
/// sign-off group flips GREEN and freezes baa as approved curriculum.
///
/// CLAUDE.md (binding): curriculum is the owner's mother's domain. The model
/// DRAFTS; she REVIEWS + SIGNS OFF. No executor ever sets signedOff:true.

Letter _loadBaa() {
  final raw = File('assets/curriculum/letters.json').readAsStringSync();
  final letters =
      (jsonDecode(raw) as Map<String, dynamic>)['letters'] as List<dynamic>;
  final baaJson =
      letters.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == 'baa');
  return Letter.fromJson(baaJson);
}

List<Map<String, dynamic>> _loadExercisesRaw() {
  final raw = File('assets/curriculum/exercises.json').readAsStringSync();
  return (jsonDecode(raw) as Map<String, dynamic>)['exercises']
      .cast<Map<String, dynamic>>();
}

const _formNames = <String>['isolated', 'initial', 'medial', 'final'];

void main() {
  // ---------------------------------------------------------------------------
  // GROUP 1 — reference strokes valid  (GREEN at Task 1; the load-time guard)
  // ---------------------------------------------------------------------------
  group('reference strokes valid', () {
    test('baa has a contextualForms map with all four positional forms', () {
      final baa = _loadBaa();
      final cf = baa.contextualForms;
      expect(cf, isNotNull,
          reason: 'baa must carry contextualForms after Plan 07-07 Task 1.');
      for (final name in _formNames) {
        expect(cf!.containsKey(name), isTrue,
            reason: 'baa.contextualForms is missing the "$name" form.');
        expect(cf[name], isNotNull,
            reason: 'baa.contextualForms["$name"] must be an authored Form '
                '(baa is a connector — all four slots are real).');
      }
    });

    for (final name in _formNames) {
      test('baa $name form passes validateReferenceStrokes (no closed loops)',
          () {
        final form = _loadBaa().contextualForms![name]!;
        expect(form.referenceStrokes, isNotEmpty,
            reason: 'The $name form must have authored reference strokes.');
        expect(
          validateReferenceStrokes(form.referenceStrokes),
          isEmpty,
          reason: 'The $name form has stroke-validation violations — an open '
              'teaching centerline must not be a glyph outline.',
        );
      });

      test('baa $name form has a body sweep + exactly one dot below it', () {
        final form = _loadBaa().contextualForms![name]!;
        final bodies =
            form.referenceStrokes.where((s) => s.type != 'dot').toList();
        final dots =
            form.referenceStrokes.where((s) => s.type == 'dot').toList();
        expect(bodies, isNotEmpty, reason: '$name needs a body stroke.');
        expect(dots, hasLength(1),
            reason: 'baa has exactly one dot in every form ($name).');
        // baa's dot identity: it sits BELOW the body (greater y = lower on
        // screen). This is letter-identity-critical (vs taa/thaa above).
        final dotY = dots.single.points.single[1];
        final bodyMaxY = bodies
            .expand((s) => s.points)
            .map((p) => p[1])
            .reduce((a, b) => a > b ? a : b);
        expect(dotY, greaterThan(bodyMaxY),
            reason: "baa's dot must sit below the body in the $name form.");
      });

      test('baa $name form has 3-4 common mistakes in the tutor voice', () {
        final form = _loadBaa().contextualForms![name]!;
        expect(form.commonMistakes.length, inInclusiveRange(3, 4),
            reason: 'Each form needs 3-4 named common mistakes ($name).');
        for (final m in form.commonMistakes) {
          expect(m.feedback.trim(), isNotEmpty,
              reason: 'Every mistake needs a child-friendly fix line ($name).');
          // The tutor's voice is never the chatbot "Oops, try again!".
          expect(m.feedback.toLowerCase(), isNot(contains('oops')),
              reason: 'Feedback stays warm + specific, never "Oops" ($name).');
        }
      });

      test('baa $name form tolerances are in range', () {
        final form = _loadBaa().contextualForms![name]!;
        expect(validateTolerances(form.tolerances), isEmpty,
            reason: 'The $name form tolerances must be in range.');
      });
    }

    test('the whole baa letter still passes the load-time validator', () {
      expect(validateLetter(_loadBaa()), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 2 — sign-off human gate  (RED at Task 1; flips GREEN only after the
  // owner's mother signs off in Task 2. NEVER set by an executor.)
  // ---------------------------------------------------------------------------
  group('sign-off gate (RED until the owner\'s mother signs off)', () {
    test('baa is signed off at the letter level', () {
      expect(_loadBaa().signedOff, isTrue,
          reason: 'baa.signedOff must be true ONLY after the owner\'s mother '
              'reviews and approves all four forms + vocab + audio (Task 2). '
              'This assertion is RED at Task 1 by design — it proves the human '
              'gate is required.');
    });

    test('every baa exercise is signed off (except the 18-11-pending microDrills)',
        () {
      final baaExercises = _loadExercisesRaw()
          .where((e) => (e['id'] as String).startsWith('baa.'))
          .toList();
      expect(baaExercises, isNotEmpty);
      // Plan 18-02 adds baa's micro-drill enrichment exercises (dot/bowl/start)
      // as signedOff:false CONTENT — enrichment that never gates the star (its
      // graph nodes are essential:false). The drill copy's sign-off is the
      // batched HUMAN-UAT gate at 18-11 (the owner's mother signs the copy +
      // gold set). Carve them out so the CORE-curriculum sign-off invariant
      // still holds — no executor ever sets signedOff:true.
      // baa.traceLetter.final is the 2026-07-12 owner amendment (trace ALL FOUR
      // forms before production tasks) — authored signedOff:false, pending the
      // same mother gate as the micro-drill copy.
      final coreBaa = baaExercises
          .where((e) =>
              e['type'] != 'microDrill' && e['id'] != 'baa.traceLetter.final')
          .toList();
      final unsigned = coreBaa
          .where((e) => e['signedOff'] != true)
          .map((e) => e['id'])
          .toList();
      expect(unsigned, isEmpty,
          reason: 'These core baa exercises are not signed off yet: $unsigned. '
              'Non-microDrill baa exercises flip to signedOff:true ONLY at the '
              'owner\'s-mother gate.');
      // The microDrills ARE the tracked pending-18-11 unsigned enrichment set.
      final microDrills =
          baaExercises.where((e) => e['type'] == 'microDrill').toList();
      expect(microDrills, isNotEmpty,
          reason: 'Plan 18-02 authors baa micro-drills (dot/bowl/start).');
      expect(microDrills.every((e) => e['signedOff'] != true), isTrue,
          reason: 'micro-drill content stays signedOff:false until the mother '
              'signs it at the 18-11 HUMAN-UAT gate.');
    });
  });
}
