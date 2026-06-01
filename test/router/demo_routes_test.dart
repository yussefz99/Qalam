// Wave-1 navigable-walkthrough contract for the /demo route group (DP-03/DP-04).
//
// The demo screens (built in plans 03/04/05) drop into FIXED route slots wired
// here. The DemoStep.next chain MUST encode the FULL forward narrative with no
// dead ends — including feedbackMiss → feedbackPass → celebration — so the
// clean-pass state is reachable by TAPPING (.next), not only by deep link.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/router/demo_routes.dart';

void main() {
  group('demo routes resolve (Test 1)', () {
    testWidgets('every demo path resolves to a non-error builder', (tester) async {
      for (final DemoStep step in DemoStep.values) {
        final GoRouter router = GoRouter(
          initialLocation: step.path,
          routes: demoRoutes(),
          errorBuilder: (context, state) =>
              const _SentinelError(), // must NEVER be hit
        );

        await tester.pumpWidget(
          MaterialAppHarness(router: router),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(_SentinelError),
          findsNothing,
          reason: '${step.path} resolved to the errorBuilder',
        );
      }
    });
  });

  group('DemoStep ordering & helpers (Test 2)', () {
    test('the full forward chain has no dead ends', () {
      expect(DemoStep.home.next, DemoStep.watch);
      expect(DemoStep.watch.next, DemoStep.trace);
      expect(DemoStep.trace.next, DemoStep.feedbackMiss);
      // The clean-pass state is reachable by tapping .next (not only deep-link):
      expect(DemoStep.feedbackMiss.next, DemoStep.feedbackPass);
      expect(DemoStep.feedbackPass.next, DemoStep.celebration);
      // Celebration loops back to demo home — no dead end.
      expect(DemoStep.celebration.next, DemoStep.home);
    });

    test('each step exposes a /demo-prefixed path', () {
      for (final DemoStep step in DemoStep.values) {
        expect(step.path, startsWith('/demo'));
      }
      // The six values exist.
      expect(DemoStep.values.length, 6);
    });
  });

  group('full-chain navigation never errors (Test 3)', () {
    testWidgets('walking home→...→celebration→home never hits errorBuilder',
        (tester) async {
      final GoRouter router = GoRouter(
        initialLocation: DemoStep.home.path,
        routes: demoRoutes(),
        errorBuilder: (context, state) => const _SentinelError(),
      );

      await tester.pumpWidget(MaterialAppHarness(router: router));
      await tester.pumpAndSettle();

      DemoStep current = DemoStep.home;
      // Walk the entire forward chain back to home (6 hops).
      for (int i = 0; i < DemoStep.values.length; i++) {
        current = current.next;
        router.go(current.path);
        await tester.pumpAndSettle();
        expect(
          find.byType(_SentinelError),
          findsNothing,
          reason: 'hop to ${current.path} hit the errorBuilder',
        );
      }
      // After a full loop we are back at home.
      expect(current, DemoStep.home);
    });
  });
}

/// Minimal MaterialApp.router harness so GoRouter has a Navigator/Overlay.
class MaterialAppHarness extends StatelessWidget {
  const MaterialAppHarness({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(
      routerConfig: router,
      color: const Color(0xFFFAF6EE),
    );
  }
}

class _SentinelError extends StatelessWidget {
  const _SentinelError();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
