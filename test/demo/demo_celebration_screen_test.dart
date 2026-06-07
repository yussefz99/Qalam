// Behavior contract for the Celebration screen — rebuilt faithful to the design
// `CompleteScreen` mockup (docs/design/kit/.../screenshots/05-celebration-final.png).
//
// OWNER OVERRIDE (2026-06-02): the celebration is faithful to the mockup,
// INCLUDING the gamification chrome — the earned three gold stars, the running
// "42 stars / +3 today" total, the rotated MASTERED stamp, and confetti. That
// reverses the earlier anti-gamification assertion this file used to enforce.
// Back Home closes the loop to demo Home (no dead end).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/demo_baa.dart';
import 'package:qalam/demo/screens/demo_celebration_screen.dart';
import 'package:qalam/demo/widgets/demo_chrome.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/dimens.dart';
import 'package:qalam/widgets/arabic_text.dart';
import 'package:qalam/widgets/qalam_mascot.dart';

class _HomeSentinel extends StatelessWidget {
  const _HomeSentinel();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

GoRouter _router() => GoRouter(
      initialLocation: '/demo/celebration',
      routes: <RouteBase>[
        GoRoute(
          path: '/demo/celebration',
          builder: (BuildContext context, GoRouterState state) =>
              const DemoCelebrationScreen(),
        ),
        GoRoute(
          path: '/demo/home',
          builder: (BuildContext context, GoRouterState state) =>
              const _HomeSentinel(),
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
  testWidgets('Test 1: cheer mascot, MASTERED, heading, giant baa glyph',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is QalamMascot && w.pose == QalamPose.cheer),
      findsOneWidget,
    );
    // "MASTERED" appears twice — the eyebrow and the rotated stamp.
    expect(find.text('MASTERED'), findsWidgets);
    expect(find.text('You learned the letter baa.'), findsOneWidget);

    // The mastered baa glyph rendered via the RTL ArabicText island.
    expect(
      find.byWidgetPredicate((w) => w is ArabicText && w.text == DemoBaa.glyph),
      findsOneWidget,
    );
  });

  testWidgets('Test 2: faithful gamification — three gold stars + running total',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    // The earned three-star rating (owner override; was BINDING-absent).
    final Finder starsRow = find.byKey(const Key('demoCelebrationStars'));
    expect(starsRow, findsOneWidget);
    expect(
      find.descendant(of: starsRow, matching: find.byType(DemoStarIcon)),
      findsNWidgets(3),
    );

    // Running star total + the +N earned this lesson.
    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('+3 today'), findsOneWidget);
    // Header star count updated to 42 after the +3.
    expect(find.text('42'), findsWidgets);
  });

  testWidgets('Test 3 (no dead end): Back Home → /demo/home', (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    final Finder backHome = find.byKey(const Key('demoBackHomeCta'));
    expect(backHome, findsOneWidget);
    expect(find.text('Back Home'), findsOneWidget);
    expect(find.text('See journey'), findsOneWidget); // secondary (decorative)
    expect(tester.getSize(backHome).height,
        greaterThanOrEqualTo(QalamTargets.targetComfy));

    await tester.ensureVisible(backHome);
    await tester.pumpAndSettle();
    await tester.tap(backHome);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/home',
    );
    expect(find.byType(_HomeSentinel), findsOneWidget);
  });
}
