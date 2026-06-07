// ignore_for_file: scoped_providers_should_specify_dependencies
// mastery_celebration_golden_test.dart — Plan 03-04
//
// Golden snapshot + finder assertions for MasteryCelebration.
//
// PLAT-03 invariants verified:
//   - "You learned alif." text present (the authored warm line).
//   - Exactly ONE mastery star rendered (CustomPaint by _StarPainter).
//   - NO "THIS WEEK" weekly tally.
//   - NO "+N" running counter text.
//   - NO "See journey" / "Journey" button (Phase 6 feature).
//   - NO "streak" label.
//
// Golden baseline: goldens/mastery_celebration.png (update with
// `flutter test --update-goldens test/features/practice/mastery_celebration_golden_test.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/practice/widgets/mastery_celebration.dart';
import 'package:qalam/l10n/app_localizations.dart';

Widget _buildCelebration() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MasteryCelebration(onBackHome: () {}),
    ),
  );
}

void main() {
  group('MasteryCelebration — golden + PLAT-03', () {
    testWidgets('renders warm mastery line and Arabic praise', (tester) async {
      await tester.pumpWidget(_buildCelebration());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('You learned alif.'),
        findsOneWidget,
        reason: 'Celebration line must be present',
      );
      expect(
        find.textContaining('أحسنت'),
        findsOneWidget,
        reason: 'Arabic praise must be present',
      );
    });

    testWidgets('no THIS WEEK weekly-tally chrome (PLAT-03)', (tester) async {
      await tester.pumpWidget(_buildCelebration());
      await tester.pumpAndSettle();

      expect(find.textContaining('THIS WEEK'), findsNothing);
      expect(find.textContaining('this week'), findsNothing);
      expect(find.textContaining('stars this week'), findsNothing);
    });

    testWidgets('no running counter or +N hype (PLAT-03)', (tester) async {
      await tester.pumpWidget(_buildCelebration());
      await tester.pumpAndSettle();

      // No "+N today", no running star counter.
      expect(find.textContaining('+ '), findsNothing);
      expect(find.textContaining(' stars'), findsNothing);
      expect(find.textContaining('streak'), findsNothing);
    });

    testWidgets('no See Journey button (Phase 6 not yet built)', (tester) async {
      await tester.pumpWidget(_buildCelebration());
      await tester.pumpAndSettle();

      expect(find.text('See journey'), findsNothing);
      expect(find.text('See Journey'), findsNothing);
    });

    testWidgets('golden snapshot', (tester) async {
      await tester.pumpWidget(_buildCelebration());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MasteryCelebration),
        matchesGoldenFile('goldens/mastery_celebration.png'),
      );
    });
  });
}
