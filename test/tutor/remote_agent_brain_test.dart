// RemoteAgentBrain — the cloud-tutor call + auto-degrade floor (Plan 14-03 Task 2).
//
// These tests pin the server-call contract and the never-block guarantee
// (TUTOR-02 / TUTOR-03 / G5), with the HTTP client fully MOCKED — no Firebase,
// no network, no live endpoint:
//   • a 200 CoachOut → the matching TutorDecision (tool name + line + plan).
//   • a 503 / non-200 → the AuthoredFallback decision (no throw).
//   • a delayed response beyond the timeout budget → the AuthoredFallback decision.
//   • the outbound request carries Authorization: Bearer <idToken> AND
//     X-Firebase-AppCheck, and its body == facts.toJson() (no extra keys, so the
//     server's extra=forbid returns 200).
//   • a missing ID token → the AuthoredFallback decision (degrade, no throw).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:qalam/core/exercise_engine/check_result.dart';
import 'package:qalam/tutor/authored_fallback_brain.dart';
import 'package:qalam/tutor/remote_agent_brain.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';
import 'package:qalam/tutor/tutor_facts_builder.dart';

const _feedback = <String, String>{
  'pass': 'أحسنت — a smooth, deep curve.',
  'shallowBowl': 'Your baa needs a deeper curve — try again, slower.',
};

const _baseUrl = 'https://qalam-tutor.example.run.app';

/// Pull the spoken line out of whichever ACTION shape the brain returned.
String _lineOf(TutorDecision d) => switch (d) {
      Say(:final text) => text,
      PresentActivity(:final coachingLine) => coachingLine,
      _ => '',
    };

TutorFacts _missFacts() => buildTutorFacts(
      letterId: 'baa',
      section: 'traceLetter',
      // Phase 17 (17-06): the CheckResult carries the DERIVED criteria + word
      // facts (scorer → validator → builder), so the sent body exercises the
      // full mirror of server/app/schema.py TutorFactsIn (Pitfall 1).
      result: const CheckResult(
        passed: false,
        mistakeId: 'shallowBowl',
        criteria: [
          {'criterion': 'shape', 'zone': 'certainlyWrong', 'score': 0.0},
          {'criterion': 'direction', 'zone': 'certainlyCorrect', 'score': 1.0},
        ],
        weakestCriterion: 'shape',
        expectedWord: 'باب',
        writtenWord: 'بب',
      ),
      recentMistakes: const ['shallowBowl'],
      trajectory: const [
        AttemptFact(passed: false, mistakeId: 'shallowBowl', section: 'traceLetter'),
      ],
    );

RemoteAgentBrain _brain(
  http.Client client, {
  Duration timeout = const Duration(seconds: 5),
  Future<String?> Function()? idToken,
  Future<String?> Function()? appCheckToken,
}) {
  return RemoteAgentBrain(
    baseUrl: _baseUrl,
    client: client,
    fallback: const AuthoredFallbackBrain(feedback: _feedback),
    getIdToken: idToken ?? () async => 'fake-id-token',
    getAppCheckToken: appCheckToken ?? () async => 'fake-appcheck-token',
    timeout: timeout,
  );
}

void main() {
  test('a 200 CoachOut → the matching TutorDecision (tool name + line + plan)',
      () async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'toolName': 'say',
          'args': {
            'text': 'Deeper curve at the bottom — slower this time.',
            'nextExerciseId': 'baa-q4',
            'intent': 'reinforce',
          },
          'source': 'agent',
          'grounded': true,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final decision = await _brain(client).next(_missFacts());

    expect(decision, isA<Say>());
    expect(decision.toolName, TutorTool.say);
    expect(_lineOf(decision), 'Deeper curve at the bottom — slower this time.');
    expect(decision.plan?.nextExerciseId, 'baa-q4');
    expect(decision.plan?.intent, 'reinforce');
  });

  test('a 200 present_activity CoachOut → a PresentActivity with the server line',
      () async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'toolName': 'present_activity',
          'args': {'coachingLine': 'Let us trace baa again, slowly.', 'letterId': 'baa'},
          'source': 'agent',
          'grounded': true,
        }),
        200,
      );
    });

    final decision = await _brain(client).next(_missFacts());
    expect(decision, isA<PresentActivity>());
    expect(_lineOf(decision), 'Let us trace baa again, slowly.');
  });

  test('a 503 → the AuthoredFallback decision, never a throw', () async {
    final client = MockClient((req) async => http.Response('upstream timeout', 503));
    final decision = await _brain(client).next(_missFacts());
    // The floor resolves feedback[mistakeId] for the miss.
    expect(_lineOf(decision), _feedback['shallowBowl']);
  });

  test('a response delayed past the timeout budget → the AuthoredFallback decision',
      () async {
    final client = MockClient((req) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return http.Response(
        jsonEncode({'toolName': 'say', 'args': {'text': 'too late'}}),
        200,
      );
    });
    final decision = await _brain(
      client,
      timeout: const Duration(milliseconds: 20),
    ).next(_missFacts());
    expect(_lineOf(decision), _feedback['shallowBowl']); // floor, not "too late"
  });

  test('a network error / offline → the AuthoredFallback decision (no throw)',
      () async {
    final client = MockClient((req) async {
      throw const _FakeSocketException();
    });
    final decision = await _brain(client).next(_missFacts());
    expect(_lineOf(decision), _feedback['shallowBowl']);
  });

  test('a missing ID token → degrade to the AuthoredFallback (no throw)', () async {
    var called = false;
    final client = MockClient((req) async {
      called = true;
      return http.Response('{}', 200);
    });
    final decision = await _brain(
      client,
      idToken: () async => null,
    ).next(_missFacts());
    expect(called, isFalse, reason: 'no request should go out without an ID token');
    expect(_lineOf(decision), _feedback['shallowBowl']);
  });

  test('the request carries both auth headers and a body == facts.toJson()',
      () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({'toolName': 'say', 'args': {'text': 'ok'}}),
        200,
      );
    });

    final facts = _missFacts();
    await _brain(client).next(facts);

    expect(captured.method, 'POST');
    expect(captured.url.toString(), '$_baseUrl/coach');
    expect(captured.headers['Authorization'], 'Bearer fake-id-token');
    expect(captured.headers['X-Firebase-AppCheck'], 'fake-appcheck-token');

    final sentBody = jsonDecode(captured.body) as Map<String, Object?>;
    // Byte-for-byte the non-PII whitelist — no extra key that would 422 under
    // the server's extra=forbid. The two Phase-15 graph-position fields
    // (clearedTiers/clearedCompetencies) and the four Phase-17 criteria/word
    // fields (17-06) mirror server/app/schema.py (Pitfall 1).
    expect(sentBody, facts.toJson());
    expect(sentBody.keys.toSet(), {
      'letterId',
      'section',
      'passed',
      'mistakeId',
      'struggleTags',
      'recentMistakes',
      'trajectory',
      'strengthTags',
      'clearedTiers',
      'clearedCompetencies',
      // Phase 17 (17-06): the criteria + word mirror fields, present because the
      // CheckResult above carries them (omit-when-null otherwise).
      'criteria',
      'weakestCriterion',
      'expectedWord',
      'writtenWord',
    });
    // Each criteria entry carries EXACTLY the CriterionIn keys (point-free).
    final criterion = (sentBody['criteria'] as List).first as Map;
    expect(criterion.keys.toSet(), {'criterion', 'zone', 'score'});
  });
}

/// A stand-in for a `SocketException` so the test does not import `dart:io`
/// (which is unavailable on the web test runner). The brain catches any thrown
/// error, so the exact type is irrelevant.
class _FakeSocketException implements Exception {
  const _FakeSocketException();
}
