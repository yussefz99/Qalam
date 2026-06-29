// warmUpCoach — the session-start cold-start mask (Phase 16, PRES-01 / D-11).
//
// When a child opens a letter unit, the client fires a best-effort GET /health at
// the Cloud Run tutor so the container is warm by the time the first /coach call
// lands (min-instances=0 → a cold start otherwise stalls the first spoken line).
//
// PROVES the D-11 contract (a pure, injectable-client function — no Firebase, no
// widget tree):
//   • a non-empty baseUrl issues EXACTLY ONE GET to {baseUrl}/health (the route is
//     /health, NOT /healthz — Google's edge reserves /healthz; server/app/main.py).
//   • an empty baseUrl (a dev/offline build with no --dart-define) issues NO
//     request — a clean no-op.
//   • a client that THROWS (offline / DNS / timeout) causes warmUpCoach to complete
//     normally — every error is swallowed, it never throws and never blocks the
//     unit-open path (mirrors the RemoteAgentBrain never-throw posture).

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:qalam/tutor/coach_warmup.dart';

void main() {
  group('warmUpCoach (D-11 cold-start mask)', () {
    test('a non-empty baseUrl issues exactly one GET to {baseUrl}/health',
        () async {
      final requests = <http.BaseRequest>[];
      final client = MockClient((req) async {
        requests.add(req);
        return http.Response('{"status":"ok"}', 200);
      });

      await warmUpCoach(client, 'https://qalam-tutor.example.run.app');

      expect(requests.length, 1, reason: 'exactly one warm-up ping');
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        'https://qalam-tutor.example.run.app/health',
        reason: 'the route is /health, never /healthz (Google edge reserves it)',
      );
    });

    test('an empty baseUrl issues NO request (clean no-op)', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response('', 200);
      });

      await warmUpCoach(client, '');

      expect(calls, 0, reason: 'no define → offline/dev build → no ping');
    });

    test('a throwing client → warmUpCoach completes normally (swallowed)',
        () async {
      final client = MockClient((req) async {
        throw Exception('offline / DNS failure / timeout');
      });

      // Must NOT throw — the warm-up is best-effort and never blocks unit-open.
      await expectLater(
        warmUpCoach(client, 'https://qalam-tutor.example.run.app'),
        completes,
      );
    });

    test('a non-200 response is swallowed (never throws)', () async {
      final client = MockClient((req) async => http.Response('cold', 503));

      await expectLater(
        warmUpCoach(client, 'https://qalam-tutor.example.run.app'),
        completes,
      );
    });
  });
}
