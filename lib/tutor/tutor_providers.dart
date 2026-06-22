/// The Riverpod wiring for the tutor seam (Plan 14-03 / TUTOR-01 / ADR-015
/// §Seam impact). Riverpod-only (CLAUDE.md Decided).
///
/// This file owns the ONE switch point where the backend is chosen
/// ([tutorBrainFactoryProvider]) and the tutor-owned line channel
/// ([tutorLineProvider]) the scaffold reads. Swapping the backend (online →
/// RemoteAgentBrain, failure → AuthoredFallback) changes NOTHING in the canvas,
/// scorer, curriculum, or `ExerciseController` — only the factory here. The
/// coaching line reaches the UI exclusively through [tutorLineProvider]; the
/// scorer still owns the verdict at the untouched `ExerciseController`
/// (GROUND-01).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import 'authored_fallback_brain.dart';
import 'remote_agent_brain.dart';
import 'tutor_brain.dart';

/// The deployed Cloud Run tutor base URL, supplied at build time via
/// `--dart-define=TUTOR_BASE_URL=https://…`. Empty by default so a build with no
/// define (or an unconfigured dev build) cleanly runs offline: the factory still
/// returns a brain whose AuthoredFallback floor holds, so the loop never blocks.
///
/// Overridable in tests / flavors via a ProviderScope override.
final tutorBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment('TUTOR_BASE_URL');
});

/// The injectable HTTP client the RemoteAgentBrain uses. Overridden in tests with
/// a `MockClient`; the live app uses the default client.
final tutorHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// The app's [AuthService] (anonymous identity → Firebase ID token). Overridable
/// in tests with a fake.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Yields the current Firebase ID token, or null when no user is signed in. The
/// RemoteAgentBrain degrades to the floor on a null token.
final idTokenGetterProvider = Provider<TokenGetter>((ref) {
  final auth = ref.watch(authServiceProvider);
  return () async => auth.currentUser?.getIdToken();
});

/// Yields a Firebase App Check limited-use token, or null. Wired to a real
/// `FirebaseAppCheck.instance.getLimitedUseToken()` at the app composition root;
/// the default here returns null so an un-overridden build degrades to the floor
/// rather than calling the App-Check-gated server unauthenticated.
///
/// (The composition root / `main.dart` overrides this with the real getter once
/// App Check is initialized; kept null-by-default so unit/widget tests and dev
/// builds without App Check stay on the offline floor.)
final appCheckTokenGetterProvider = Provider<TokenGetter>((ref) {
  return () async => null;
});

/// THE single backend switch point (TUTOR-01). Given the active exercise's
/// authored `feedback` map (the offline floor's source of grounded lines), it
/// builds a [RemoteAgentBrain] that wraps an [AuthoredFallbackBrain] degrade
/// floor. Online it coaches via the server; on timeout/offline/error it falls to
/// the authored floor. This is the ONLY place the online↔offline routing lives.
///
/// Exposed as a factory (a function of the per-exercise feedback) because the
/// floor's lines are exercise-specific while the rest of the wiring is global.
final tutorBrainFactoryProvider =
    Provider<TutorBrain Function(Map<String, String> feedback)>((ref) {
  final baseUrl = ref.watch(tutorBaseUrlProvider);
  final client = ref.watch(tutorHttpClientProvider);
  final getIdToken = ref.watch(idTokenGetterProvider);
  final getAppCheckToken = ref.watch(appCheckTokenGetterProvider);

  return (Map<String, String> feedback) {
    final floor = AuthoredFallbackBrain(feedback: feedback);
    return RemoteAgentBrain(
      baseUrl: baseUrl,
      client: client,
      fallback: floor,
      getIdToken: getIdToken,
      getAppCheckToken: getAppCheckToken,
    );
  };
});

/// The tutor-owned coaching-line channel. The scaffold WRITES the brain's line
/// here after the verdict is applied, and the tutor column READS it. Null means
/// "no agent line — show the verdict-side authored line" (the floor). This is the
/// ONLY path a coaching line reaches the UI; it can never flip the scorer's
/// verdict (GROUND-01).
///
/// A [Notifier] (Riverpod 3 dropped `StateProvider`); set the line via
/// `ref.read(tutorLineProvider.notifier).set(line)` / `.clear()`.
class TutorLineNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Set the current agent coaching line (or clear it with null).
  void set(String? line) => state = line;

  /// Clear the agent line — the bubble degrades to the verdict-side authored
  /// line (the floor).
  void clear() => state = null;
}

final tutorLineProvider =
    NotifierProvider<TutorLineNotifier, String?>(TutorLineNotifier.new);
