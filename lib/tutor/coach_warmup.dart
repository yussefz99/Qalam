/// Pure Dart (no Firebase, no Riverpod, no widget tree) — an injectable-client
/// best-effort warm-up ping for the Cloud Run tutor (Phase 16, PRES-01 / D-11).
///
/// The deployed `qalam-tutor` runs with `min-instances=0`, so it scales to zero
/// when idle and the FIRST `/coach` call after a quiet spell pays a cold-start
/// penalty — which would stall the first spoken coach line. To MASK that, the
/// client fires this fire-and-forget `GET /health` the moment a child opens a
/// letter unit, so the container is (likely) already warm by the time the first
/// real `/coach` call lands.
///
/// ROUTE IS `/health`, NOT `/healthz`: Google's edge intercepts the exact path
/// `/healthz` before Cloud Run, so the container never receives it (documented at
/// `server/app/main.py` `GET /health`). The warm-up MUST target `/health`.
///
/// ACCESS CONTROL (RESEARCH V4): `/health` is intentionally UNAUTHENTICATED — it
/// carries no data and just warms the instance; the data-bearing `/coach` stays
/// ID-token + App-Check gated. So the warm-up sends no token.
///
/// NEVER-BLOCK / NEVER-THROW: this is a best-effort cold-start mask. Every error
/// (offline, DNS failure, timeout, a non-200) is SWALLOWED — it must never throw
/// and never block the unit-open path (mirrors the RemoteAgentBrain degrade
/// posture). An empty [baseUrl] (a dev/offline build with no
/// `--dart-define=TUTOR_BASE_URL`) is a clean no-op.
library;

import 'package:http/http.dart' as http;

/// A short ceiling on the warm-up request — it is a fire-and-forget hint, never a
/// gate, so it must not hang. On timeout the error is swallowed like any other.
const Duration _warmUpTimeout = Duration(seconds: 4);

/// Fire a best-effort `GET {baseUrl}/health` to warm the Cloud Run tutor (D-11).
///
/// - When [baseUrl] is empty, returns immediately (no ping — offline/dev build).
/// - Otherwise issues ONE unauthenticated GET to `{baseUrl}/health` with a short
///   timeout, swallowing EVERYTHING (offline / DNS / timeout / non-200). It never
///   throws and never blocks the caller — fire it without awaiting at unit open.
///
/// [client] is injected so a `MockClient` can drive it in tests; the live call
/// site passes the app's shared `tutorHttpClientProvider` client.
Future<void> warmUpCoach(http.Client client, String baseUrl) async {
  if (baseUrl.isEmpty) return; // no define → nothing to warm (clean no-op).
  try {
    await client
        .get(Uri.parse('$baseUrl/health'))
        .timeout(_warmUpTimeout);
  } catch (_) {
    // Offline / DNS / timeout / non-200 / any platform hiccup → swallow. The
    // warm-up is a best-effort cold-start mask, never a gate on opening a unit.
  }
}
