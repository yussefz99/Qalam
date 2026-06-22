// tutor_providers — the single switch point + the offline-floor guarantee
// (Plan 14-03 Task 3).
//
// These tests prove, through the REAL provider seam, that:
//   • tutorBrainFactoryProvider returns a RemoteAgentBrain wrapping the authored
//     floor, and with an UNREACHABLE server it still yields a grounded
//     AuthoredFallback line — the swap changed no scaffold/controller code.
//   • the line path is tutorLineProvider; ExerciseController exposes NO
//     line-setter (a source guard — GROUND-01: the line never flows through the
//     verdict controller).

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts_builder.dart';
import 'package:qalam/tutor/tutor_providers.dart';

const _feedback = <String, String>{
  'pass': 'أحسنت — a smooth, deep curve.',
  'shallowBowl': 'Your baa needs a deeper curve — try again, slower.',
};

String _lineOf(TutorDecision d) => switch (d) {
      Say(:final text) => text,
      PresentActivity(:final coachingLine) => coachingLine,
      _ => '',
    };

void main() {
  test('an unreachable server still yields a grounded AuthoredFallback line '
      'through the real factory seam', () async {
    // A client that always fails — the "server unreachable" condition.
    final failingClient = MockClient((req) async {
      throw const SocketException('unreachable');
    });

    final container = ProviderContainer(
      overrides: [
        tutorHttpClientProvider.overrideWithValue(failingClient),
        // A non-empty base URL so the brain actually tries the (failing) call.
        tutorBaseUrlProvider.overrideWithValue('https://unreachable.example'),
        // Present tokens so the brain attempts the request (then fails over).
        idTokenGetterProvider.overrideWithValue(() async => 'fake-id'),
        appCheckTokenGetterProvider.overrideWithValue(() async => 'fake-appcheck'),
      ],
    );
    addTearDown(container.dispose);

    final makeBrain = container.read(tutorBrainFactoryProvider);
    final brain = makeBrain(_feedback);

    final facts = buildTutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      result: const CheckResult.fail('shallowBowl'),
      recentMistakes: const ['shallowBowl'],
    );
    final decision = await brain.next(facts);

    // The grounded authored floor line for the miss — proving the offline floor
    // holds through the real provider wiring, no scaffold/controller change.
    expect(_lineOf(decision), _feedback['shallowBowl']);
  });

  test('the factory degrades to the floor when no base URL is configured '
      '(dev/offline build)', () async {
    final container = ProviderContainer(
      overrides: [
        // No base URL → never call the server; floor directly.
        tutorBaseUrlProvider.overrideWithValue(''),
        idTokenGetterProvider.overrideWithValue(() async => null),
      ],
    );
    addTearDown(container.dispose);

    final brain = container.read(tutorBrainFactoryProvider)(_feedback);
    final facts = buildTutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      result: const CheckResult.pass(),
    );
    final decision = await brain.next(facts);
    expect(_lineOf(decision), _feedback['pass']);
  });

  test('tutorLineProvider starts null (no agent line until one is written)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(tutorLineProvider), isNull);
  });

  test('ExerciseController exposes NO line-setter — the line path is '
      'tutorLineProvider only (GROUND-01)', () {
    // A source-level guard: the verdict controller must not gain a public method
    // that injects a coaching line (e.g. setLine/say/coach/applyTutorLine). The
    // only way a line reaches the UI is the tutor-owned provider.
    final src = File('lib/features/letter_unit/exercise_controller.dart')
        .readAsStringSync();
    expect(src.contains('tutorLineProvider'), isFalse,
        reason: 'the controller must not touch the tutor line channel');
    for (final forbidden in const [
      'void setLine',
      'void say(',
      'void coach(',
      'void applyTutorLine',
      'void presentActivity',
    ]) {
      expect(src.contains(forbidden), isFalse,
          reason: 'ExerciseController must not expose "$forbidden" (GROUND-01)');
    }
  });
}
