// Behavior contract for the Watch (stroke-order) screen — rebuilt faithful to
// the design `DemoScreen` mockup (docs/design/kit/.../screenshots/02-*).
//
// Watch demonstrates HOW baa is written: the walkthrough chrome (nav rail +
// header), the write-pose mascot, a white canvas painting the dotted baa guide
// from the SINGLE reference source (DemoBaa points — never Text('ب'), Pitfall 5)
// with a numbered gold start-dot (the sanctioned reward gold) and the
// distinguishing diacritic dot, an aqua TIP card, and a "Start Tracing" CTA into
// Trace. Per the owner override the audio ("Hear the sound") affordance from the
// mockup is shown (decorative in the mocked demo).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/demo_baa.dart';
import 'package:qalam/demo/screens/demo_watch_screen.dart';
import 'package:qalam/demo/widgets/dotted_guide_painter.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/colors.dart';
import 'package:qalam/theme/dimens.dart';
import 'package:qalam/widgets/qalam_mascot.dart';

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
  testWidgets('Test 1: chrome, write mascot, baa eyebrow/heading, tip',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    // Walkthrough chrome (nav rail + gold star count) — faithful to mockup.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    expect(find.text('39'), findsOneWidget);

    expect(
      find.byWidgetPredicate((w) => w is QalamMascot && w.pose == QalamPose.write),
      findsOneWidget,
    );
    expect(find.text('WATCH · STROKE ORDER'), findsOneWidget);
    expect(find.text('Watch me write baa.'), findsOneWidget);
    expect(find.text('TIP'), findsOneWidget);
    expect(
      find.text('Start at the gold dot. Follow the curve to the left.'),
      findsOneWidget,
    );
  });

  testWidgets('Test 2: dotted guide painted from DemoBaa points, not Text',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    final Finder guide = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DottedGuidePainter);
    expect(guide, findsOneWidget);

    final DottedGuidePainter painter =
        tester.widget<CustomPaint>(guide).painter! as DottedGuidePainter;

    // One source of truth (Pitfall 5): guide consumes the baa reference points.
    final List<Offset> expected =
        DemoBaa.referencePoints.map((p) => Offset(p[0], p[1])).toList();
    expect(painter.referencePoints, expected);

    // Watch is guide-only (no ink yet), with the numbered gold start-dot and the
    // distinguishing diacritic dot.
    expect(painter.inkProgress, 0.0);
    expect(painter.showStartDot, isTrue);
    expect(painter.startDotColor, QalamColors.reward); // gold — start-dot only
    expect(painter.diacriticDots, isNotEmpty);

    // The glyph is NEVER rendered as Text on Watch — only painted.
    expect(find.text('ب'), findsNothing);

    // The canvas is non-interactive (sits under an active IgnorePointer).
    expect(
      find.ancestor(
        of: guide,
        matching:
            find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Test 3: Start Tracing CTA → /demo/trace', (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    final Finder cta = find.byKey(const Key('demoStartTracingCta'));
    expect(cta, findsOneWidget);
    expect(find.text('Start Tracing'), findsOneWidget);
    expect(tester.getSize(cta).height,
        greaterThanOrEqualTo(QalamTargets.targetComfy));

    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/trace',
    );
    expect(find.byType(_TraceSentinel), findsOneWidget);
  });

  testWidgets('Test 4: parchment Scaffold, never white; audio shown per override',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, QalamColors.bg);

    // Faithful to the mockup (owner override): the audio + replay affordances.
    expect(find.text('Hear the sound'), findsOneWidget);
    expect(find.text('Watch again'), findsOneWidget);
  });
}
