// ghost_comparison_test.dart — Plan 06-08 (D-21 slow-motion ghost comparison)
//
// The ghost comparison: after a wobbly (failed) letter, the child can watch
// their own stroke (coral, half speed) replayed BESIDE Qalam's reference
// (deep-ink) — a teaching moment, never error-shaming.
//
// Tests:
//   1. Renders two labeled panels: "Yours" + "Qalam's", title "Watch the
//      difference." — never wrong/right wording.
//   2. The child's stroke animation is configured with warnSoft color and
//      durWrite * 2 duration; the reference with inkStroke (default).
//   3. Replayable: a replay affordance restarts the animations.
//   4. No-persistence invariant (T-03-01 / T-06-04): the practice_providers
//      controller carries no live stroke-point structures in CODE — the only
//      List<Offset> mentions are the documentation guard comments.
//   5. The widget never emits "wrong"/"right" framing (T-06-09).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/features/practice/widgets/ghost_comparison.dart';
import 'package:qalam/features/practice/widgets/stroke_order_animation.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/models/letter.dart';
import 'package:qalam/theme/colors.dart';
import 'package:qalam/theme/dimens.dart';

// The child's (wobbly) stroke and Qalam's reference — both pre-normalized 0..1
// StrokeSpecs (the widget takes normalized specs; the screen normalizes the
// child's in-memory strokes via the shared core before handing them over).
const List<StrokeSpec> _childStrokes = <StrokeSpec>[
  StrokeSpec(
    order: 1,
    label: 'wobbly',
    type: 'line',
    direction: 'topToBottom',
    points: <List<double>>[
      <double>[0.45, 0.1],
      <double>[0.55, 0.5],
      <double>[0.48, 0.9],
    ],
  ),
];

const List<StrokeSpec> _referenceStrokes = <StrokeSpec>[
  StrokeSpec(
    order: 1,
    label: 'downstroke',
    type: 'line',
    direction: 'topToBottom',
    points: <List<double>>[
      <double>[0.5, 0.1],
      <double>[0.5, 0.5],
      <double>[0.5, 0.9],
    ],
  ),
];

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 500,
          child: child,
        ),
      ),
    );

void main() {
  group('GhostComparison (D-21)', () {
    testWidgets('1. renders two labeled panels + non-shaming title',
        (tester) async {
      await tester.pumpWidget(
        _host(const GhostComparison(
          childStrokes: _childStrokes,
          referenceStrokes: _referenceStrokes,
        )),
      );
      // Don't pumpAndSettle — the half-speed replay runs; one frame is enough.
      await tester.pump();

      expect(find.text('Yours'), findsOneWidget,
          reason: 'Child panel label');
      expect(find.text("Qalam's"), findsOneWidget,
          reason: 'Reference panel label');
      expect(find.text('Watch the difference.'), findsOneWidget,
          reason: 'Calm panel title');

      // Two replay animations side by side.
      expect(find.byType(StrokeOrderAnimation), findsNWidgets(2));
    });

    testWidgets('2. child stroke = coral + half speed; reference = deep-ink',
        (tester) async {
      await tester.pumpWidget(
        _host(const GhostComparison(
          childStrokes: _childStrokes,
          referenceStrokes: _referenceStrokes,
        )),
      );
      await tester.pump();

      final List<StrokeOrderAnimation> anims = tester
          .widgetList<StrokeOrderAnimation>(find.byType(StrokeOrderAnimation))
          .toList();
      expect(anims.length, 2);

      // The child's animation: coral (warnSoft) at durWrite * 2 (half speed).
      final StrokeOrderAnimation child = anims.firstWhere(
        (a) => a.color == QalamColors.warnSoft,
        orElse: () => fail('No coral (child) animation found'),
      );
      expect(child.duration, QalamMotion.durWrite * 2,
          reason: 'Half speed = durWrite * 2 = 2800ms');
      expect(child.referenceStrokes, _childStrokes);

      // The reference animation: deep-ink (default color → null) at half speed.
      final StrokeOrderAnimation reference = anims.firstWhere(
        (a) => a.referenceStrokes == _referenceStrokes,
        orElse: () => fail('No reference animation found'),
      );
      // Reference uses inkStroke — either explicitly or via the null default.
      expect(
        reference.color == null || reference.color == QalamColors.inkStroke,
        isTrue,
        reason: 'Reference is deep-ink (default or explicit inkStroke)',
      );
      expect(reference.duration, QalamMotion.durWrite * 2,
          reason: 'Both panels animate at the same half speed');
    });

    testWidgets('3. replayable — a replay affordance exists and restarts',
        (tester) async {
      await tester.pumpWidget(
        _host(const GhostComparison(
          childStrokes: _childStrokes,
          referenceStrokes: _referenceStrokes,
        )),
      );
      await tester.pump();

      // A replay affordance is present (icon or labeled button).
      final Finder replay = find.byKey(const ValueKey('ghost-replay'));
      expect(replay, findsOneWidget,
          reason: 'A replay affordance restarts the comparison');

      // Tapping it does not throw and keeps the two animations mounted.
      await tester.tap(replay);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(StrokeOrderAnimation), findsNWidgets(2));
    });

    testWidgets('5. never uses wrong/right shaming framing (T-06-09)',
        (tester) async {
      await tester.pumpWidget(
        _host(const GhostComparison(
          childStrokes: _childStrokes,
          referenceStrokes: _referenceStrokes,
        )),
      );
      await tester.pump();

      expect(find.textContaining('Wrong'), findsNothing);
      expect(find.textContaining('wrong'), findsNothing);
      expect(find.textContaining('Right'), findsNothing);
      expect(find.textContaining('Correct'), findsNothing);
      expect(find.textContaining('Incorrect'), findsNothing);
    });
  });

  group('Stroke-point no-persistence invariant (T-03-01 / T-06-04)', () {
    test('4. practice_providers carries no live stroke-point CODE', () {
      final src = File('lib/providers/practice_providers.dart')
          .readAsLinesSync();
      // Strip comment lines (the SECURITY guard intentionally NAMES the type in
      // prose). Any List<Offset> in executable code is a violation.
      final codeLines = src.where((l) {
        final t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///') &&
            !t.startsWith('*');
      });
      final offenders =
          codeLines.where((l) => l.contains('List<Offset>')).toList();
      expect(offenders, isEmpty,
          reason: 'No List<Offset> in provider CODE — stroke points stay in '
              'widget State (T-03-01). Offenders: $offenders');
    });

    test('ghost_comparison widget imports no repository/database', () {
      final src =
          File('lib/features/practice/widgets/ghost_comparison.dart')
              .readAsStringSync();
      expect(src.contains('repository'), isFalse,
          reason: 'The ghost panel takes data only from widget State');
      expect(src.contains('drift'), isFalse);
      expect(src.contains('Database'), isFalse);
      // SECURITY header documents the no-persistence invariant.
      expect(src.contains('SECURITY'), isTrue,
          reason: 'Widget must carry the no-persistence SECURITY header');
    });
  });
}
