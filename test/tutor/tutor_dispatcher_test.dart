// TutorDispatcher — the native function-call dispatcher (Plan 14-01 Task 2).
//
// These tests pin the grounding invariant at the dispatch seam (TUTOR-05,
// GROUND-01):
//   • each of the 4 ACTION decision shapes routes to its matching TutorController
//     method (verified via a recording spy controller).
//   • an unrecognized/extended case is a no-op that does NOT throw.
//   • the controller surface exposes NO setVerdict/awardStar method — the
//     dispatcher has, by construction, no path to flip a fail to a pass.
//
// Pure Dart: no Firebase, no canvas rebuild, imperative dispatch only (the
// Phase 11 kill-shot lesson — never rebuild the canvas from agent state).

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_dispatcher.dart';

/// Records every imperative call the dispatcher makes, in order. Notably it
/// offers NO setVerdict/awardStar method — if the dispatcher tried to flip the
/// verdict, this fake could not satisfy it (compile-time grounding guard).
class _SpyController implements TutorController {
  final List<String> calls = [];
  String? lastSay;
  String? lastLetterId;
  String? lastCoachingLine;

  @override
  void say(String text) {
    calls.add('say');
    lastSay = text;
  }

  @override
  void presentActivity(String letterId, String coachingLine) {
    calls.add('presentActivity');
    lastLetterId = letterId;
    lastCoachingLine = coachingLine;
  }

  @override
  void giveHint() => calls.add('giveHint');

  @override
  void advance() => calls.add('advance');
}

void main() {
  test('Say routes to controller.say with its text', () {
    final spy = _SpyController();
    dispatchTutorDecision(const Say('أحسنت'), spy);
    expect(spy.calls, ['say']);
    expect(spy.lastSay, 'أحسنت');
  });

  test('PresentActivity routes to controller.presentActivity with line + letterId',
      () {
    final spy = _SpyController();
    dispatchTutorDecision(
      const PresentActivity(coachingLine: 'Deeper curve.', letterId: 'baa'),
      spy,
    );
    expect(spy.calls, ['presentActivity']);
    expect(spy.lastLetterId, 'baa');
    expect(spy.lastCoachingLine, 'Deeper curve.');
  });

  test('GiveHint routes to controller.giveHint', () {
    final spy = _SpyController();
    dispatchTutorDecision(const GiveHint(), spy);
    expect(spy.calls, ['giveHint']);
  });

  test('Advance routes to controller.advance', () {
    final spy = _SpyController();
    dispatchTutorDecision(const Advance(), spy);
    expect(spy.calls, ['advance']);
  });

  test('dispatching by an unrecognized tool name is a no-op that does not throw',
      () {
    final spy = _SpyController();
    // The name-keyed entry point: an unknown name must be a logged no-op.
    expect(
      () => dispatchTutorToolName('set_verdict', spy),
      returnsNormally,
    );
    expect(spy.calls, isEmpty); // nothing routed — no verdict path exists
  });

  test('every known tool name routes exactly one imperative call', () {
    for (final name in TutorTool.all) {
      final spy = _SpyController();
      dispatchTutorToolName(name, spy);
      expect(spy.calls.length, 1, reason: 'tool "$name" must route one call');
    }
  });
}
