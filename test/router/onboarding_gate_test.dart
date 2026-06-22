// Plan 05-01 (Wave 0) — onboarding redirect-gate contract (TDD, starts RED).
//
// INTENTIONALLY RED at Wave 0: references the not-yet-built OnboardingGate
// (ChangeNotifier) from package:qalam/providers/profile_providers.dart and the
// gate redirect logic. A later wave builds the gate + wires the redirect into
// app_router.dart, turning this green. Do NOT add a lib/ stub here.
//
// Encodes the gate invariants (Pitfall 1 — NO redirect loop):
//   * no profile  → any non-onboarding location redirects to /onboarding
//   * has profile → / resolves to Home; visiting /onboarding redirects to /
//   * after gate.markProfileCreated() the router moves OFF /onboarding WITHOUT
//     ever hitting the _SentinelError errorBuilder (never exceeds redirectLimit).
//
// Mirrors test/router/demo_routes_test.dart: a real GoRouter + a _SentinelError
// errorBuilder used to prove "no loop". The redirect rule under test is built
// inline here so the test pins the BEHAVIOR (both redirect rules present),
// independent of where the production wiring eventually lives.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/providers/profile_providers.dart';

/// Builds a GoRouter wired with the gate redirect + refreshListenable, mirroring
/// the production gate logic in app_router.dart (RESEARCH Pattern 3).
GoRouter _gatedRouter(OnboardingGate gate, {String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: gate,
    redirect: (context, state) {
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!gate.hasProfile && !onOnboarding) return '/onboarding';
      // BOTH rules present — prevents the redirect loop (Pitfall 1).
      if (gate.hasProfile && onOnboarding) return '/';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (c, s) => const _Page('home')),
      GoRoute(
        path: '/onboarding',
        builder: (c, s) => const _Page('onboarding'),
      ),
      GoRoute(path: '/journey', builder: (c, s) => const _Page('journey')),
      GoRoute(path: '/practice', builder: (c, s) => const _Page('practice')),
    ],
    errorBuilder: (context, state) => const _SentinelError(), // must NEVER hit
  );
}

void main() {
  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  group('onboarding gate redirect (no profile)', () {
    testWidgets('any non-onboarding location redirects to /onboarding', (
      tester,
    ) async {
      final router = _gatedRouter(
        OnboardingGate(false),
        initialLocation: '/journey',
      );
      await tester.pumpWidget(_Harness(router: router));
      await tester.pumpAndSettle();

      expect(
        find.byType(_SentinelError),
        findsNothing,
        reason: 'redirect must not loop into the error screen',
      );
      expect(
        locationOf(router),
        '/onboarding',
        reason: 'no profile must force /onboarding',
      );
    });
  });

  group('onboarding gate redirect (has profile)', () {
    testWidgets('/ resolves to Home and /onboarding redirects back to /', (
      tester,
    ) async {
      final router = _gatedRouter(OnboardingGate(true), initialLocation: '/');
      await tester.pumpWidget(_Harness(router: router));
      await tester.pumpAndSettle();
      expect(
        locationOf(router),
        '/',
        reason: 'with a profile, Home is reachable',
      );

      router.go('/onboarding');
      await tester.pumpAndSettle();
      expect(find.byType(_SentinelError), findsNothing);
      expect(
        locationOf(router),
        '/',
        reason: 'with a profile, /onboarding must bounce to /',
      );
    });
  });

  group(
    'query params cannot affect the gate (A3 — matchedLocation is path-only)',
    () {
      testWidgets(
        'no profile: /practice?lesson=lesson_02 still redirects to /onboarding',
        (tester) async {
          final router = _gatedRouter(
            OnboardingGate(false),
            initialLocation: '/practice?lesson=lesson_02',
          );
          await tester.pumpWidget(_Harness(router: router));
          await tester.pumpAndSettle();

          expect(
            find.byType(_SentinelError),
            findsNothing,
            reason: 'query strings must not break the redirect (T-06-06)',
          );
          expect(
            locationOf(router),
            '/onboarding',
            reason: 'the gate sees only the path — ?lesson= cannot bypass it',
          );
        },
      );

      testWidgets(
        'has profile: /practice?lesson=lesson_02 does NOT redirect and keeps the query',
        (tester) async {
          final router = _gatedRouter(
            OnboardingGate(true),
            initialLocation: '/practice?lesson=lesson_02',
          );
          await tester.pumpWidget(_Harness(router: router));
          await tester.pumpAndSettle();

          expect(find.byType(_SentinelError), findsNothing);
          expect(
            locationOf(router),
            '/practice',
            reason: 'with a profile the deep link resolves normally',
          );
          expect(
            router
                .routerDelegate
                .currentConfiguration
                .uri
                .queryParameters['lesson'],
            'lesson_02',
            reason: 'the query parameter survives the redirect pass untouched',
          );
        },
      );
    },
  );

  group('markProfileCreated() flips the gate without a loop', () {
    testWidgets(
      'after markProfileCreated the router leaves /onboarding and never errors',
      (tester) async {
        final gate = OnboardingGate(false);
        final router = _gatedRouter(gate, initialLocation: '/onboarding');
        await tester.pumpWidget(_Harness(router: router));
        await tester.pumpAndSettle();

        // Starts pinned on onboarding (no profile).
        expect(locationOf(router), '/onboarding');

        // Simulate a completed onboarding: flip the gate + navigate Home.
        gate.markProfileCreated();
        router.go('/');
        await tester.pumpAndSettle();

        expect(
          find.byType(_SentinelError),
          findsNothing,
          reason:
              'flipping the gate must not trigger a redirect loop (Pitfall 1)',
        );
        expect(
          locationOf(router),
          '/',
          reason: 'after markProfileCreated the child lands on Home',
        );
      },
    );
  });

  test('requireProfileSetup forces onboarding for a newly created account', () {
    final gate = OnboardingGate(true);

    gate.requireProfileSetup();

    expect(gate.hasProfile, isFalse);
  });
}

/// Minimal MaterialApp-less harness so GoRouter has a Navigator/Overlay.
class _Harness extends StatelessWidget {
  const _Harness({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(
      routerConfig: router,
      color: const Color(0xFFFAF6EE),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}

class _SentinelError extends StatelessWidget {
  const _SentinelError();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
