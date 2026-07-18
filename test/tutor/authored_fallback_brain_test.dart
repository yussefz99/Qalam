// AuthoredFallbackBrain — the offline floor (Plan 14-01 Task 2).
//
// These tests pin the grounded, airplane-mode coaching path (TUTOR-02):
//   • a pass → the decision line == feedback['pass'] (the signed-off praise).
//   • a miss with a known mistakeId → line == feedback[mistakeId] (the specific fix).
//   • a miss with an UNKNOWN id → a non-empty authored FLOOR line (first non-'pass'
//     authored line) — never an empty/generic string when any authored line exists.
//   • pure Dart: constructing + calling next() touches NO Firebase, NO network,
//     NO model — it runs in a plain `flutter test` with no fakes.
//
// This mirrors ExerciseController.applyResult's resolution exactly, so the offline
// brain line == the verdict-side authored line by construction.

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/tutor/authored_fallback_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts_builder.dart';

const _feedback = <String, String>{
  'pass': 'أحسنت — a smooth, deep curve.',
  'shallowBowl': 'Your baa needs a deeper curve — try again, slower.',
  'missingDot': 'baa has one dot below — add it under the bowl.',
};

/// Pull the spoken line out of whichever ACTION shape the brain returned.
String _lineOf(TutorDecision d) => switch (d) {
      Say(:final text) => text,
      PresentActivity(:final coachingLine) => coachingLine,
      _ => '',
    };

void main() {
  final brain = AuthoredFallbackBrain(feedback: _feedback);

  test('a pass → the authored praise line (feedback[pass])', () async {
    final facts = buildTutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      result: const CheckResult.pass(),
    );
    final decision = await brain.next(facts);
    expect(_lineOf(decision), _feedback['pass']);
  });

  test('a miss with a known mistakeId → the specific authored fix line', () async {
    final facts = buildTutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      result: const CheckResult.fail('shallowBowl'),
    );
    final decision = await brain.next(facts);
    expect(_lineOf(decision), _feedback['shallowBowl']);
  });

  test('a miss with an unknown id → a non-empty authored floor line', () async {
    final facts = buildTutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      result: const CheckResult.fail('somethingUnauthored'),
    );
    final decision = await brain.next(facts);
    final line = _lineOf(decision);
    expect(line, isNotEmpty);
    // The floor is an AUTHORED non-'pass' line — never the praise, never generic.
    expect(line, isNot(_feedback['pass']));
    expect(_feedback.values.contains(line), isTrue);
  });

  test('with no authored feedback at all → a FAIL speaks the warm floor (never silent)',
      () async {
    // 260718-l12 silent-fail fix: the old contract ("nothing authored → nothing
    // to say") let a scorer FAIL pass in total silence — the on-device bug the
    // owner hit on thaa. A FAIL now always resolves at least kGenericTryAgain.
    final empty = AuthoredFallbackBrain(feedback: const {});
    final facts = buildTutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      result: const CheckResult.fail('shallowBowl'),
    );
    final decision = await empty.next(facts);
    expect(_lineOf(decision), kGenericTryAgain); // fail → warm floor, never ''
  });
}
