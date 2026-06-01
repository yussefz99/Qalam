// Behavior contract for the Watch (stroke-order) screen (plan 02.1.1-03, DP-03/DP-07).
//
// Watch demonstrates HOW alif is written: the write-pose mascot beside a dotted
// alif guide painted from the SINGLE reference source (DemoAlif points — never
// Text('ا'), Pitfall 5), with a numbered gold start-dot (the only allowed gold
// use, QalamColors.reward) and one clear "Start Tracing" CTA into Trace. There
// is NO audio / "Listen" / "Play sound" affordance (DP-07).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/demo_alif.dart';
import 'package:qalam/demo/screens/demo_watch_screen.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/colors.dart';
import 'package:qalam/theme/dimens.dart';

class _TraceSentinel extends StatelessWidget {
  const _TraceSentinel();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

GoRouter _router() => GoRouter(
      initialLocation: '/demo/watch',
      routes: <RouteBase>[
        GoRoute(
          path: '/demo/watch',
          builder: (BuildContext context, GoRouterState state) =>
              const DemoWatchScreen(),
        ),
        GoRoute(
          path: '/demo/trace',
          builder: (BuildContext context, GoRouterState state) =>
              const _TraceSentinel(),
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
  testWidgets('Test 1: renders write mascot, eyebrow, heading, and tip',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(find.text('WATCH · STROKE ORDER'), findsOneWidget);
    expect(find.text('Watch Me Write Alif.'), findsOneWidget);
    expect(
      find.text('Start at the gold dot. Follow the line down.'),
      findsOneWidget,
    );
  });

  testWidgets('Test 2: dotted guide is painted from DemoAlif points, not Text',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    final Finder guide = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DottedAlifPainter);
    expect(guide, findsOneWidget);

    final DottedAlifPainter painter =
        tester.widget<CustomPaint>(guide).painter! as DottedAlifPainter;
    // One source of truth (Pitfall 5): the guide consumes the reference points.
    expect(painter.points, DemoAlif.referencePoints);

    // The glyph is NEVER rendered as Text on Watch — only painted.
    expect(find.text('ا'), findsNothing);
  });

  testWidgets('Test 3: numbered gold start-dot (reward token), non-interactive',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    final Finder guide = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DottedAlifPainter);
    final DottedAlifPainter painter =
        tester.widget<CustomPaint>(guide).painter! as DottedAlifPainter;

    // Gold is allowed here ONLY for the start-dot, via the reward token.
    expect(painter.startDotColor, QalamColors.reward);

    // The guide is not a touch target — it sits under an IgnorePointer.
    expect(
      find.ancestor(of: guide, matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );
  });

  testWidgets('Test 4: Start Tracing CTA → /demo/trace, no audio affordance',
      (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    // No audio / listen / play-sound chrome (DP-07).
    final RegExp audio = RegExp(r'(listen|play\s*sound)', caseSensitive: false);
    expect(
      find.byWidgetPredicate(
          (w) => w is Text && w.data != null && audio.hasMatch(w.data!)),
      findsNothing,
    );

    // The CTA exists, is a comfortable touch target, and navigates to Trace.
    final Finder cta = find.byKey(const Key('demoStartTracingCta'));
    expect(cta, findsOneWidget);
    expect(find.text('Start Tracing'), findsOneWidget);
    expect(tester.getSize(cta).height,
        greaterThanOrEqualTo(QalamTargets.targetComfy));

    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/trace',
    );
    expect(find.byType(_TraceSentinel), findsOneWidget);
  });
}
