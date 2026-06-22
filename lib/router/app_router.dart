// The go_router skeleton (D-08). Three placeholder routes match the UI-SPEC
// Screen Shells; the active-tab indicator (later) uses the ink-teal accent.
//
// /parent SEAM ONLY: the PIN-gated parent area lands in P9. The redirect hook is
// left commented below — do NOT build the PIN gate now.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dev/authoring_screen.dart';
import '../dev/glyph_audit_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/letter_unit/letter_unit_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../providers/auth_providers.dart';
import '../providers/parent_providers.dart';
import '../providers/profile_providers.dart';
import '../screens/parent_auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/parent_dashboard_screen.dart';
import '../features/practice/practice_screen.dart';
import '../screens/settings_screen.dart';
import 'demo_routes.dart';

part 'app_router.g.dart';

/// Compile-time flag that boots the app straight into the presentation demo
/// walkthrough (phase 02.1.1). Off by default — `flutter run` starts at '/' as
/// usual. Pass `--dart-define=DEMO=true` to launch at `/demo/home` so the full
/// Home → Watch → Trace → Feedback → Celebration loop is tappable for a demo.
const bool kDemoMode = bool.fromEnvironment('DEMO');

/// App router, exposed as a Riverpod-codegen provider (Riverpod-only — D-11).
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // The onboarding gate (S1-03 / Plan 05-03). Seeded at boot in main.dart with a
  // one-time hasProfile() read; flips via markProfileCreated() after onboarding.
  // Used both as the redirect source AND as refreshListenable so the redirect
  // re-runs the instant the gate flips (RESEARCH Pattern 3).
  final gate = ref.watch(onboardingGateProvider);
  final authGate = ref.watch(authGateProvider);
  // The parent-area gate (D-07 per-entry). Merged into refreshListenable so the
  // router re-runs the instant the gate flips lock↔unlock; the '/parent' widget
  // itself is the access boundary (RESEARCH Pattern 3 — no redirect for it).
  final parentGate = ref.watch(parentGateProvider);

  return GoRouter(
    initialLocation: kDemoMode ? '/demo/home' : '/',
    // Re-run redirects when either gate flips (onboarding write / parent
    // lock-unlock). Merged listenable — no second redirect rule for /parent.
    refreshListenable: Listenable.merge(<Listenable>[
      authGate,
      gate,
      parentGate,
    ]),
    // SYNCHRONOUS redirect — NEVER await Drift here (Pitfall 2). The gate flag is
    // read once at boot; both rules below are present to prevent a redirect loop
    // (Pitfall 1): no-profile pins /onboarding; has-profile bounces off it.
    redirect: (context, state) {
      if (kDemoMode) return null; // the demo walkthrough bypasses the gate
      final onAuth = state.matchedLocation == '/auth';
      final onOnboarding = state.matchedLocation == '/onboarding';

      // A real account is the front door to the whole application. Firebase's
      // anonymous boot identity is deliberately NOT sufficient.
      if (!authGate.signedIn) return onAuth ? null : '/auth';

      // Once authenticated, child setup is the second mandatory gate.
      if (onAuth) return gate.hasProfile ? '/' : '/onboarding';
      if (!gate.hasProfile && !onOnboarding) return '/onboarding';
      if (gate.hasProfile && onOnboarding) return '/';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/auth',
        builder: (context, state) => const ParentAuthScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      // First-launch onboarding (S1-02 / S1-03). Reachable only via the gate; the
      // child cannot back out (PopScope) and cannot skip (redirect).
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // `?lesson=` deep-links a specific lesson (S1-09: celebration "Next
      // Lesson", journey taps). The ValueKey forces a FRESH PracticeScreen
      // State per lesson id (Pitfall 5) — without it, navigating from one
      // lesson to another would reuse the old State. Query params are
      // validated downstream against the curriculum catalog (T-06-03); the
      // onboarding gate cannot see them (matchedLocation is path-only).
      GoRoute(
        path: '/practice',
        builder: (context, state) {
          final lessonId = state.uri.queryParameters['lesson'];
          return PracticeScreen(
            key: ValueKey<String?>(lessonId),
            lessonId: lessonId,
          );
        },
      ),
      // The Letter Unit (Plan 07-06). `?letter=` deep-links a specific letter's
      // 6-section unit; home's today-card and the journey node open it. The
      // ValueKey forces a FRESH LetterUnitScreen State per letter id (Pitfall 5,
      // mirroring `/practice`). The letter param is validated DOWNSTREAM against
      // the curriculum catalog (T-07-06-01): an unknown/missing id degrades to
      // the built unit (`baa`) so the child never sees an error or an arbitrary
      // load. The onboarding/parent gates above are untouched (matchedLocation
      // is path-only — the query param is invisible to the redirect).
      GoRoute(
        path: '/unit',
        builder: (context, state) {
          final raw = state.uri.queryParameters['letter'];
          // Degrade an empty/missing id to the built unit; a syntactically-bad
          // id (the screen's loader returns null) shows the calm "preparing"
          // panel rather than crashing.
          final letterId = (raw == null || raw.trim().isEmpty) ? 'baa' : raw;
          return LetterUnitScreen(
            key: ValueKey<String>('unit:$letterId'),
            letterId: letterId,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // `?highlight=` marks the just-mastered letter's node (D-15; consumed by
      // the journey screen in 06-06 — inert until then).
      GoRoute(
        path: '/journey',
        builder: (context, state) =>
            JourneyScreen(highlightId: state.uri.queryParameters['highlight']),
      ),
      // DEBUG SEAM — the D-12 glyph-audit harness. Reachable only by typing this
      // route on an emulator/tablet; it is NOT surfaced in the user-facing nav.
      // It renders only public Arabic letters + Western digits (no sensitive
      // data — threat T-01-06 accepted).
      GoRoute(
        path: '/dev/glyph-audit',
        builder: (context, state) => const GlyphAuditScreen(),
      ),
      // DEBUG SEAM — the D-02 stroke authoring tool (trace-over-glyph → tagged
      // referenceStrokes export). Reachable only by typing this route on a
      // tablet/emulator; it is NOT surfaced in the user-facing nav (T-02.1-07).
      GoRoute(
        path: '/dev/authoring',
        builder: (context, state) => const AuthoringScreen(),
      ),
      // DEMO WALKTHROUGH — the phase-02.1.1 presentation route group (DP-03).
      // Six ordered, tappable demo screens (Home → Watch → Trace →
      // Feedback·miss → Feedback·pass → Celebration → Home) with no dead ends.
      // Screen plans (03/04/05) replace the placeholder builders with real
      // widgets; the path map + ordering stay fixed here. See demo_routes.dart.
      ...demoRoutes(),
      // The PIN-gated parent area (S1-11 / Plan 09-03, CONTEXT D-08). A SINGLE
      // route whose widget is the access boundary: while parentGate is LOCKED it
      // renders the PIN flow (create-first / enter-after); once UNLOCKED it
      // renders the read-only dashboard. No redirect guard here — the merged
      // refreshListenable above re-runs the router on every gate flip, and the
      // widget chooses its own state (RESEARCH Pattern 3 — avoids the Pitfall 2
      // "await Drift in redirect" trap and the Pitfall 1 redirect loop).
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentDashboardScreen(),
      ),
    ],
  );
}
