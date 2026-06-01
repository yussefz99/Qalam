// Behavior contract for the Trace screen (plan 02.1.1-04, DP-03/DP-04/DP-07).
//
// Trace is the middle of the narrative: the child's ink sits OVER the dotted
// alif guide, mid-stroke (the half-traced hero state), painted from the single
// DemoAlif reference source via DottedGuidePainter. A submit / stylus-up CTA —
// labeled by the named demoTraceSubmit gen-l10n key — leads to the Feedback miss
// screen. No scoring/capture engine (DP-01); "Mark Correct"/"Play sound" omitted.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/screens/demo_trace_screen.dart';
import 'package:qalam/demo/widgets/dotted_guide_painter.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/dimens.dart';

class _FeedbackSentinel extends StatelessWidget {
  const _FeedbackSentinel();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

GoRouter _router() => GoRouter(
      initialLocation: '/demo/trace',
      routes: <RouteBase>[
        GoRoute(
          path: '/demo/trace',
          builder: (BuildContext context, GoRouterState state) =>
              const DemoTraceScreen(),
        ),
        GoRoute(
          path: '/demo/feedback',
          builder: (BuildContext context, GoRouterState state) =>
              const _FeedbackSentinel(),
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
  testWidgets('Test 1: eyebrow, heading, Stroke 1 of 1, half-traced guide',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(find.text('YOUR TURN · TRACE'), findsOneWidget);
    expect(find.text('Now You Trace Alif.'), findsOneWidget);
    expect(find.text('Stroke 1 of 1'), findsOneWidget);

    // The half-traced guide: a DottedGuidePainter at partial ink progress.
    final Finder guide = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DottedGuidePainter);
    expect(guide, findsOneWidget);
    final DottedGuidePainter painter =
        tester.widget<CustomPaint>(guide).painter! as DottedGuidePainter;
    expect(painter.inkProgress, greaterThan(0.0));
    expect(painter.inkProgress, lessThan(1.0));
  });

  testWidgets('Test 2: demoTraceSubmit CTA → /demo/feedback (miss)',
      (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    // The named submit label (authored in plan 02), not a hardcoded string.
    expect(find.text('Done — Check My Work'), findsOneWidget);

    final Finder cta = find.byKey(const Key('demoTraceSubmitCta'));
    expect(cta, findsOneWidget);
    expect(tester.getSize(cta).height,
        greaterThanOrEqualTo(QalamTargets.targetComfy));

    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/feedback',
    );
    expect(find.byType(_FeedbackSentinel), findsOneWidget);
  });

  testWidgets('Test 3: no glyph Text, no Mark Correct / Play sound',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(find.text('ا'), findsNothing);
    final RegExp omitted =
        RegExp(r'(mark correct|play\s*sound|listen)', caseSensitive: false);
    expect(
      find.byWidgetPredicate(
          (w) => w is Text && w.data != null && omitted.hasMatch(w.data!)),
      findsNothing,
    );
  });

  test('Test 4: the screen wires no scoring / capture engine', () {
    final String src =
        File('lib/demo/screens/demo_trace_screen.dart').readAsStringSync();
    final RegExp engine =
        RegExp(r'(mlkit|ml_kit|drift|scorer|score\()', caseSensitive: false);
    expect(engine.hasMatch(src), isFalse,
        reason: 'Trace is a mocked demo — no recognition/capture engine');
  });
}
