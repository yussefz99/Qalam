// Behavior contract for the de-gamified demo Home (plan 02.1.1-03, DP-04/DP-06).
//
// Home opens the walkthrough narrative: the idle mascot, a warm static greeting,
// and an alif "Today's Lesson" card that taps through to Watch. It must PROVE the
// anti-gamification stance even in the demo (DP-06, BINDING) — the mockup's star
// counter / weekly tally / three-star rating are OMITTED and asserted absent.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/demo_alif.dart';
import 'package:qalam/demo/screens/demo_home_screen.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/colors.dart';
import 'package:qalam/widgets/arabic_text.dart';
import 'package:qalam/widgets/qalam_mascot.dart';

/// A marker the Watch slot resolves to, so Test 2 can prove navigation landed
/// on /demo/watch WITHOUT depending on the real DemoWatchScreen (built later).
class _WatchSentinel extends StatelessWidget {
  const _WatchSentinel();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

GoRouter _router() => GoRouter(
      initialLocation: '/demo/home',
      routes: <RouteBase>[
        GoRoute(
          path: '/demo/home',
          builder: (BuildContext context, GoRouterState state) =>
              const DemoHomeScreen(),
        ),
        GoRoute(
          path: '/demo/watch',
          builder: (BuildContext context, GoRouterState state) =>
              const _WatchSentinel(),
        ),
      ],
    );

Widget _harness(GoRouter router) => MaterialApp.router(
      theme: qalamTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );

void main() {
  testWidgets('Test 1: renders idle mascot, warm greeting, and alif lesson card',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    // Idle-pose mascot present.
    expect(
      find.byWidgetPredicate(
          (w) => w is QalamMascot && w.pose == QalamPose.idle),
      findsOneWidget,
    );

    // The warm static greeting (gen-l10n demoHomeGreeting).
    expect(find.text("Let's learn, Layla."), findsOneWidget);

    // The alif glyph rendered through the ArabicText RTL island (not raw Text).
    expect(
      find.byWidgetPredicate(
          (w) => w is ArabicText && w.text == DemoAlif.glyph),
      findsOneWidget,
    );

    // The lesson title.
    expect(find.text('Alif'), findsOneWidget);
  });

  testWidgets('Test 2: tapping the alif lesson card navigates to /demo/watch',
      (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    // Tap the alif glyph island (it lives inside the tappable lesson card).
    await tester.tap(find.byWidgetPredicate(
        (w) => w is ArabicText && w.text == DemoAlif.glyph));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/watch',
    );
    expect(find.byType(_WatchSentinel), findsOneWidget);
  });

  testWidgets('Test 3 (BINDING): no gamification chrome on Home', (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    final RegExp gamification =
        RegExp(r'(stars?\b|weekly|streak|badge|\+\s*\d)', caseSensitive: false);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.data != null && gamification.hasMatch(w.data!),
      ),
      findsNothing,
      reason: 'Home must omit star counter / weekly tally / streak hype (DP-06)',
    );
  });

  testWidgets('Test 4: plain Scaffold on parchment, never white', (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, QalamColors.bg);
  });
}
