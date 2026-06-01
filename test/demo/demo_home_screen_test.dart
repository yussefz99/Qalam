// Contract for the presentation demo Home (plan 02.1.1-03, rebuilt 2026-06-02).
//
// OWNER OVERRIDE: this Home is faithful to docs/design home.png, INCLUDING the
// gamification chrome (header star count, three-star lesson rating, "This Week ·
// N stars" tally). That intentionally reverses the earlier anti-gamification
// assertion this file used to enforce — see CLAUDE.md "Decided" (to reconcile).
// The lesson card remains the one interactive affordance → Watch.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/screens/demo_home_screen.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/colors.dart';
import 'package:qalam/widgets/arabic_text.dart';
import 'package:qalam/widgets/qalam_mascot.dart';

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
  testWidgets('Test 1: idle mascot, welcome, and Baa lesson card', (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
          (w) => w is QalamMascot && w.pose == QalamPose.idle),
      findsOneWidget,
    );
    expect(find.text('Welcome back, Layla.'), findsOneWidget);

    // The Baa lesson tile renders through the ArabicText RTL island.
    expect(
      find.byWidgetPredicate((w) => w is ArabicText && w.text == 'ب'),
      findsOneWidget,
    );
    expect(find.text('The letter Baa'), findsOneWidget);
  });

  testWidgets('Test 2: tapping the lesson card navigates to /demo/watch',
      (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    final Finder card = find.byKey(const Key('demoLessonCard'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/watch',
    );
    expect(find.byType(_WatchSentinel), findsOneWidget);
  });

  testWidgets('Test 3: faithful-to-mockup chrome (nav rail + gamification)',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    // Left nav rail.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);

    // Gamification chrome present per the owner override (was BINDING-absent).
    expect(find.text('39'), findsOneWidget); // header star count
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('3 lessons · 9 stars'), findsOneWidget);
  });

  testWidgets('Test 4: parchment Scaffold, never white', (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, QalamColors.bg);
  });
}
