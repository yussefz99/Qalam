import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/features/letter_unit/widgets/exercise_scaffold.dart'
    show resolveFloorLine;
import 'package:qalam/tutor/authored_fallback_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';

/// The NON-EMPTY warm feedback floor — quick fix 260718-l12 Task 2.
///
/// Before this fix a scorer FAIL that resolved no authored per-mistake line
/// (an empty/pass-only feedback map, or an unmatched mistakeId) rendered AND
/// spoke an empty string — the "silent fail" bug. Now BOTH resolvers return the
/// shared warm [kGenericTryAgain] floor, while an authored per-mistake line
/// (e.g. baa's `shallowBowl`) still WINS over the floor.
///
/// Verified in BOTH:
///   • [resolveFloorLine] (the ExerciseScaffold verdict/voice-side seam), and
///   • [AuthoredFallbackBrain] (`_resolveLine`, via the public `next`).
String _lineOf(TutorDecision d) => switch (d) {
      Say(:final text) => text,
      PresentActivity(:final coachingLine) => coachingLine,
      _ => '',
    };

void main() {
  group('resolveFloorLine (ExerciseScaffold verdict/voice side)', () {
    test('a fail with an UNRESOLVED mistakeId returns the warm floor, not ""',
        () {
      // A pass-only feedback map: nothing authored for any miss.
      const feedback = <String, String>{'pass': 'أحسنت!'};
      final line = resolveFloorLine(feedback, const CheckResult.fail('anything'));
      expect(line, isNotEmpty);
      expect(line, kGenericTryAgain);
    });

    test('a fail with a NULL feedback map returns the warm floor, not ""', () {
      final line = resolveFloorLine(null, const CheckResult.fail('x'));
      expect(line, kGenericTryAgain);
    });

    test('an authored per-mistake line WINS over the floor', () {
      const feedback = <String, String>{
        'pass': 'أحسنت!',
        'shallowBowl': 'A little shallow — give the bowl a deeper curve.',
      };
      final line =
          resolveFloorLine(feedback, const CheckResult.fail('shallowBowl'));
      expect(line, 'A little shallow — give the bowl a deeper curve.');
      expect(line, isNot(kGenericTryAgain));
    });

    test('a miss with an UNMATCHED id falls back to the first authored line', () {
      const feedback = <String, String>{
        'pass': 'أحسنت!',
        'shallowBowl': 'A little shallow — give the bowl a deeper curve.',
      };
      // Not 'shallowBowl' → the first non-pass authored line, not the floor.
      final line =
          resolveFloorLine(feedback, const CheckResult.fail('unmatched'));
      expect(line, 'A little shallow — give the bowl a deeper curve.');
    });

    test('a pass returns the praise line (unchanged)', () {
      const feedback = <String, String>{'pass': 'أحسنت!'};
      expect(resolveFloorLine(feedback, const CheckResult.pass()), 'أحسنت!');
    });
  });

  group('AuthoredFallbackBrain._resolveLine (offline brain)', () {
    TutorFacts fail(String id) =>
        TutorFacts(letterId: 'thaa', section: 'traceLetter', passed: false, mistakeId: id);
    const passFacts =
        TutorFacts(letterId: 'thaa', section: 'traceLetter', passed: true);

    test('a fail with a pass-only feedback map returns the warm floor, not ""',
        () async {
      const brain = AuthoredFallbackBrain(feedback: {'pass': 'أحسنت!'});
      final line = _lineOf(await brain.next(fail('anything')));
      expect(line, isNotEmpty);
      expect(line, kGenericTryAgain);
    });

    test('a fail with an EMPTY feedback map returns the warm floor, not ""',
        () async {
      const brain = AuthoredFallbackBrain(feedback: {});
      final line = _lineOf(await brain.next(fail('x')));
      expect(line, kGenericTryAgain);
    });

    test('an authored per-mistake line WINS over the floor', () async {
      const brain = AuthoredFallbackBrain(feedback: {
        'pass': 'أحسنت!',
        'shallowBowl': 'A little shallow — give the bowl a deeper curve.',
      });
      final line = _lineOf(await brain.next(fail('shallowBowl')));
      expect(line, 'A little shallow — give the bowl a deeper curve.');
      expect(line, isNot(kGenericTryAgain));
    });

    test('a pass returns the praise line (unchanged)', () async {
      const brain = AuthoredFallbackBrain(feedback: {'pass': 'أحسنت!'});
      expect(_lineOf(await brain.next(passFacts)), 'أحسنت!');
    });
  });
}
