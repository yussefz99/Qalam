// Behavior contract for the Celebration screen (plan 02.1.1-05, DP-06).
//
// A calm mastery moment: the cheer mascot, the mastered alif glyph + Arabic
// praise "أحسنت", and EXACTLY ONE quiet gold star — the anti-gamification rule
// held absolutely. No running counter, no weekly tally, no "See journey", no
// three-star row, no confetti. Back Home closes the loop to demo Home (no dead
// end).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/demo_alif.dart';
import 'package:qalam/demo/screens/demo_celebration_screen.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/dimens.dart';
import 'package:qalam/widgets/arabic_text.dart';

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
  testWidgets('Test 1: cheer mascot, MASTERED, heading, alif glyph + أحسنت',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(find.text('MASTERED'), findsOneWidget);
    expect(find.text('You Learned Alif.'), findsOneWidget);

    // The mastered alif glyph and the Arabic praise, both via ArabicText.
    expect(
      find.byWidgetPredicate((w) => w is ArabicText && w.text == DemoAlif.glyph),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) => w is ArabicText && w.text == 'أحسنت'),
      findsOneWidget,
    );
  });

  testWidgets('Test 2 (BINDING): exactly ONE star, no counter chrome',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    // Exactly one mastery star.
    expect(find.byKey(const Key('demoMasteryStar')), findsOneWidget);

    // No running counter / tally / journey / confetti text.
    final RegExp gamification = RegExp(
        r'(\d+\s*stars?|\+\s*\d|weekly|see journey|total|streak)',
        caseSensitive: false);
    expect(
      find.byWidgetPredicate(
          (w) => w is Text && w.data != null && gamification.hasMatch(w.data!)),
      findsNothing,
    );
  });

  test('Test 3: the single star uses the gold reward token', () {
    final String src =
        File('lib/demo/screens/demo_celebration_screen.dart').readAsStringSync();
    expect(src.contains('QalamColors.reward'), isTrue);
  });

  testWidgets('Test 4 (no dead end): Back Home → /demo/home', (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    final Finder backHome = find.byKey(const Key('demoBackHomeCta'));
    expect(backHome, findsOneWidget);
    expect(find.text('Back Home'), findsOneWidget);
    expect(tester.getSize(backHome).height,
        greaterThanOrEqualTo(QalamTargets.targetComfy));

    // The celebration is a tall scrollable column; bring the CTA into view
    // before tapping (it sits below the fold on the small test viewport).
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
