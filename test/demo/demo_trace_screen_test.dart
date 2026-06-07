// Behavior contract for the Trace screen — rebuilt faithful to the design
// `TraceScreen` + `TracingCanvas` mockup (docs/design/kit/.../screenshots/03-*).
//
// Trace hands the pen to the child: the walkthrough chrome, "Stroke 1 of 1"
// progress, the idle mascot beside a white canvas that PAINTS the dotted baa
// guide with live ink OVER it (the half-traced hero state) from the single
// DemoBaa reference source, an aqua "LISTEN" card (the baa glyph via ArabicText +
// a decorative Play-sound), and a primary "Next" CTA → the Feedback (miss)
// screen. No scoring/capture engine (DP-01).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/demo/demo_baa.dart';
import 'package:qalam/demo/screens/demo_trace_screen.dart';
import 'package:qalam/demo/widgets/dotted_guide_painter.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/theme/app_theme.dart';
import 'package:qalam/theme/dimens.dart';
import 'package:qalam/widgets/arabic_text.dart';
import 'package:qalam/widgets/qalam_mascot.dart';

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
  testWidgets('Test 1: chrome, eyebrow, heading, Stroke 1 of 1, half-traced',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget); // chrome nav rail
    expect(find.text('YOUR TURN · TRACE'), findsOneWidget);
    expect(find.text('Now you trace baa.'), findsOneWidget);
    expect(find.text('Stroke 1 of 1'), findsOneWidget);

    expect(
      find.byWidgetPredicate((w) => w is QalamMascot && w.pose == QalamPose.idle),
      findsOneWidget,
    );

    // The half-traced guide: a DottedGuidePainter at partial ink progress, fed
    // from the single baa reference source.
    final Finder guide = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DottedGuidePainter);
    expect(guide, findsOneWidget);
    final DottedGuidePainter painter =
        tester.widget<CustomPaint>(guide).painter! as DottedGuidePainter;
    expect(painter.inkProgress, greaterThan(0.0));
    expect(painter.inkProgress, lessThan(1.0));
    expect(painter.showStartDot, isTrue);
    expect(painter.diacriticDots, isNotEmpty);
    expect(
      painter.referencePoints,
      DemoBaa.referencePoints.map((p) => Offset(p[0], p[1])).toList(),
    );
  });

  testWidgets('Test 2: LISTEN card shows the baa glyph via ArabicText',
      (tester) async {
    await tester.pumpWidget(_harness(_router()));
    await tester.pumpAndSettle();

    expect(find.text('LISTEN'), findsOneWidget);
    // The decorative LISTEN glyph is a proper RTL ArabicText island (constraint
    // #4) — distinct from the PAINTED canvas guide (one source of truth).
    expect(
      find.byWidgetPredicate((w) => w is ArabicText && w.text == DemoBaa.glyph),
      findsOneWidget,
    );
    expect(find.text('Play sound'), findsOneWidget);
  });

  testWidgets('Test 3: Next CTA → /demo/feedback (miss)', (tester) async {
    final GoRouter router = _router();
    await tester.pumpWidget(_harness(router));
    await tester.pumpAndSettle();

    final Finder cta = find.byKey(const Key('demoTraceSubmitCta'));
    expect(cta, findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.getSize(cta).height,
        greaterThanOrEqualTo(QalamTargets.targetComfy));

    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/demo/feedback',
    );
    expect(find.byType(_FeedbackSentinel), findsOneWidget);
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
