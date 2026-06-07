// The go_router skeleton (D-08). Three placeholder routes match the UI-SPEC
// Screen Shells; the active-tab indicator (later) uses the ink-teal accent.
//
// /parent SEAM ONLY: the PIN-gated parent area lands in P9. The redirect hook is
// left commented below — do NOT build the PIN gate now.

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dev/authoring_screen.dart';
import '../dev/glyph_audit_screen.dart';
import '../screens/home_screen.dart';
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
  return GoRouter(
    initialLocation: kDemoMode ? '/demo/home' : '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => const PracticeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
      // SEAM ONLY — /parent/* PIN-gated parent area lands in P9 (CONTEXT D-08).
      // Do NOT build the PIN gate now. When it lands, add the route here and a
      // redirect guard, e.g.:
      //   redirect: (context, state) {
      //     if (state.matchedLocation.startsWith('/parent') && !parentUnlocked) {
      //       return '/parent/lock';
      //     }
      //     return null;
      //   },
    ],
  );
}
