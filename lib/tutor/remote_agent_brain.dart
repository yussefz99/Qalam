/// RemoteAgentBrain — the cloud tutor call behind the [TutorBrain] seam
/// (Plan 14-03 / TUTOR-03 / ADR-015).
///
/// It POSTs the non-PII [TutorFacts] to the deployed Cloud Run `/coach` endpoint
/// with a Firebase ID token (Authorization: Bearer …) AND an App Check token
/// (X-Firebase-AppCheck), parses the server's grounded `CoachOut` into the
/// matching [TutorDecision], and — on ANY failure (timeout, offline, non-200,
/// parse error, or a missing token) — silently degrades to the wrapped
/// [AuthoredFallbackBrain] floor. It NEVER throws to its caller, so the trace
/// loop can never block (G5 / TUTOR-02).
///
/// No provider/model key ever touches the client: the keys live in Secret Manager
/// server-side. This brain only carries the caller's identity tokens (verified by
/// the server) — the grounding line itself is produced server-side.
///
/// The HTTP client, the token getters, and the timeout are all injected so the
/// whole class is testable with a `MockClient` and no Firebase.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'authored_fallback_brain.dart';
import 'latency_trace.dart';
import 'tutor_brain.dart';
import 'tutor_decision.dart';
import 'tutor_facts.dart';

/// Returns a token, or null when none is available (e.g. no signed-in user). The
/// brain degrades to the floor on a null/empty token rather than calling the
/// server unauthenticated.
typedef TokenGetter = Future<String?> Function();

/// A [TutorBrain] that calls the grounded Cloud Run tutor and degrades to the
/// authored offline floor on any failure.
class RemoteAgentBrain implements TutorBrain {
  RemoteAgentBrain({
    required this.baseUrl,
    required this.client,
    required this.fallback,
    required this.getIdToken,
    required this.getAppCheckToken,
    this.timeout = const Duration(seconds: 8),
  });

  /// The deployed Cloud Run service base URL (no trailing slash), e.g.
  /// `https://qalam-tutor-xxxx.run.app`. `/coach` is appended.
  final String baseUrl;

  /// The injectable HTTP client (a `MockClient` in tests).
  final http.Client client;

  /// The offline floor this brain degrades to on ANY failure. Constructed with
  /// the active exercise's authored feedback (the same lines the verdict shows).
  final AuthoredFallbackBrain fallback;

  /// Yields the current Firebase ID token (`user.getIdToken()`), or null when no
  /// user is signed in. A null/empty token degrades to the floor.
  final TokenGetter getIdToken;

  /// Yields a Firebase App Check limited-use token
  /// (`FirebaseAppCheck.instance.getLimitedUseToken()`), or null. A null token
  /// degrades to the floor (the server requires App Check).
  final TokenGetter getAppCheckToken;

  /// The per-call budget; on expiry the brain degrades to [fallback].
  final Duration timeout;

  @override
  Future<TutorDecision> next(TutorFacts facts) async {
    try {
      final idToken = await getIdToken();
      if (idToken == null || idToken.isEmpty) {
        // No identity → never call the server unauthenticated; use the floor.
        return fallback.next(facts);
      }
      final appCheck = await getAppCheckToken();
      if (appCheck == null || appCheck.isEmpty) {
        return fallback.next(facts);
      }

      // LATENCY MARK 3 (debug/demo-only): the /coach POST is about to leave the
      // device — the network leg of the written-stroke → first-TTS budget.
      markLatency(LatencySegment.coachRequestSent);
      final response = await client
          .post(
            Uri.parse('$baseUrl/coach'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
              'X-Firebase-AppCheck': appCheck,
            },
            body: jsonEncode(facts.toJson()),
          )
          .timeout(timeout);
      // LATENCY MARK 4 (debug/demo-only): the /coach response returned — the
      // gap from mark 3 is the Cloud Run + model round-trip (the cold-start
      // delta shows up HERE on the first call after idle, min-instances=0).
      markLatency(LatencySegment.coachResponseReceived);

      if (response.statusCode != 200) {
        return fallback.next(facts);
      }

      final decision = _parseCoachOut(response.body, facts);
      // A null parse (malformed / unknown tool) degrades to the floor.
      return decision ?? await fallback.next(facts);
    } catch (_) {
      // Timeout, offline, DNS, TLS, parse — anything. Never block the loop.
      return fallback.next(facts);
    }
  }

  /// Parse a `CoachOut` JSON body into the matching [TutorDecision], attaching a
  /// [TutorPlan] when the args carry one. Returns null on a malformed body or an
  /// unknown tool name (the caller then degrades to the floor — never a throw).
  TutorDecision? _parseCoachOut(String body, TutorFacts facts) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final toolName = decoded['toolName'];
    if (toolName is! String) return null;
    final args = (decoded['args'] is Map)
        ? (decoded['args'] as Map).cast<String, Object?>()
        : const <String, Object?>{};

    final plan = _planFrom(args);
    // Phase 17.1: the AI's image-judge verdict ("pass"|"needsWork") rides top-level on CoachOut.
    final verdict = decoded['verdict'] as String?;

    switch (toolName) {
      case TutorTool.say:
        return Say((args['text'] as String?) ?? '', plan: plan, verdict: verdict);
      case TutorTool.presentActivity:
        return PresentActivity(
          coachingLine: (args['coachingLine'] as String?) ?? '',
          letterId: (args['letterId'] as String?) ?? facts.letterId,
          plan: plan,
          verdict: verdict,
        );
      case TutorTool.giveHint:
        return GiveHint(plan: plan, verdict: verdict);
      case TutorTool.advance:
        return Advance(plan: plan, verdict: verdict);
      default:
        // Unknown / hallucinated tool — never a verdict path (GROUND-01).
        return null;
    }
  }

  /// Build an optional [TutorPlan] from a tool's args, or null when none of the
  /// plan fields are present.
  TutorPlan? _planFrom(Map<String, Object?> args) {
    final nextId = args['nextExerciseId'] as String?;
    final intent = args['intent'] as String?;
    final rationale = args['rationale'] as String?;
    if (nextId == null && intent == null && rationale == null) return null;
    return TutorPlan(
      nextExerciseId: nextId,
      intent: intent,
      rationale: rationale,
    );
  }
}
