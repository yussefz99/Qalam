// Behavior contract for the HERO Feedback screen — derived from the design
// feedback colors (docs/design/kit/.../preview/colors-feedback.html) and the
// closest mockup. No 1:1 design page exists, so the miss/pass states are built
// from the brand feedback tokens: CORAL (warnSoft) for the miss, LEAF (success)
// for the pass — NEVER red, never a red X.
//
// MISS is the shot that sells the product: the failing baa stroke highlighted in
// coral, a SPECIFIC named fix in the tutor's warm voice, and a gentle,
// counter-free "Try Again" that advances FORWARD to the clean-pass variant
// (feedbackMiss.next == feedbackPass) — no dead end. PASS is a quiet, specific
// affirmation advancing to Celebration.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/screens/demo_feedback_screen.dart';
import 'package:qalam/demo/widgets/dotted_guide_painter.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/colors.dart';
import 'package:qalam/theme/dimens.dart';
import 'package:qalam/widgets/qalam_mascot.dart';

class _Sentinel extends StatelessWidget {
  const _Sentinel();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

GoRouter _router({required String start}) => GoRouter(
      initialLocation: start,
      routes: <RouteBase>[
        GoRoute(
          path: '/demo/feedback',
          builder: (BuildContext context, GoRouterState state) =>
              const DemoFeedbackScreen(variant: DemoFeedbackVariant.miss),
        ),
        GoRoute(
          path: '/demo/feedback/pass',
          builder: (BuildContext context, GoRouterState state) =>
              const DemoFeedbackScreen(variant: DemoFeedbackVariant.pass),
        ),
        GoRoute(
          path: '/demo/celebration',
          builder: (BuildContext context, GoRouterState state) =>
              const _Sentinel(),
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
  testWidgets('Test 1 (HERO miss): coral failing stroke + specific named fix',
      (tester) async {
    await tester.pumpWidget(_harness(_router(start: '/demo/feedback')));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget); // walkthrough chrome
    expect(
      find.byWidgetPredicate(
          (w) => w is QalamMascot && w.pose == QalamPose.tryAgain),
      findsOneWidget,
    );

    // The specific named fix (not a generic "try again").
    expect(find.textContaining('deeper curve'), findsOneWidget);
    expect(find.text("Let's fix this"), findsOneWidget); // warm coral chip

    // The failing stroke is painted CORAL (warnSoft), not deep-ink, not red.
    final Finder guide = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DottedGuidePainter);
    expect(guide, findsOneWidget);
    final DottedGuidePainter painter =
        tester.widget<CustomPaint>(guide).painter! as DottedGuidePainter;
    expect(painter.inkColor, QalamColors.warnSoft);
    expect(painter.inkProgress, 1.0);
  });

  test('Test 2 (no red): the feedback screen uses coral only, never red', () {
    final String src =
        File('lib/demo/screens/demo_feedback_screen.dart').readAsStringSync();
    final RegExp red = RegExp(r'(Colors\.red|redAccent|0xFFFF0000|#FF0000)');
    expect(red.hasMatch(src), isFalse, reason: 'coral is the only error color');
  });

  testWidgets('Test 3 (miss → pass, no dead end, no counter)', (tester) async {
    final GoRouter router = _router(start: '/demo/feedback');
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    // No try-counter / attempt text (DP-06).
    final RegExp counter =
        RegExp(r'(attempt|tries left|try \d|counter)', caseSensitive: false);
    expect(
      find.byWidgetPredicate(
          (w) => w is Text && w.data != null && counter.hasMatch(w.data!)),
      findsNothing,
    );

    final Finder tryAgain = find.byKey(const Key('demoTryAgainCta'));
    expect(tryAgain, findsOneWidget);
    expect(tester.getSize(tryAgain).height,
        greaterThanOrEqualTo(QalamTargets.targetComfy));

    await tester.ensureVisible(tryAgain);
    await tester.pumpAndSettle();
    await tester.tap(tryAgain);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/feedback/pass',
    );
  });

  testWidgets('Test 4 (clean pass): green stroke + specific praise → Celebration',
      (tester) async {
    final GoRouter router = _router(start: '/demo/feedback/pass');
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    // Specific praise, not generic.
    expect(find.textContaining('deep curve'), findsOneWidget);
    expect(find.text('Beautiful work'), findsOneWidget); // quiet success chip

    // The clean stroke is painted LEAF (success), not coral, not red.
    final Finder guide = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DottedGuidePainter);
    final DottedGuidePainter painter =
        tester.widget<CustomPaint>(guide).painter! as DottedGuidePainter;
    expect(painter.inkColor, QalamColors.success);

    final Finder cta = find.byKey(const Key('demoPassContinueCta'));
    expect(cta, findsOneWidget);
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/celebration',
    );
    expect(find.byType(_Sentinel), findsOneWidget);
  });
}
