// The go_router skeleton (D-08). Three placeholder routes match the UI-SPEC
// Screen Shells; the active-tab indicator (later) uses the ink-teal accent.
//
// /parent SEAM ONLY: the PIN-gated parent area lands in P9. The redirect hook is
// left commented below — do NOT build the PIN gate now.

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dev/glyph_audit_screen.dart';
import '../screens/home_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/settings_screen.dart';

part 'app_router.g.dart';

/// App router, exposed as a Riverpod-codegen provider (Riverpod-only — D-11).
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
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
