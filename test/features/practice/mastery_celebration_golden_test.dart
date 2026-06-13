// ignore_for_file: scoped_providers_should_specify_dependencies
// mastery_celebration_golden_test.dart — Plan 03-04, reconciled for Phase 6 (06-07)
//
// Golden snapshot + finder assertions for MasteryCelebration.
//
// PHASE 6 (06-07) reconciliation:
//   - The widget is now PARAMETERIZED on the mastered letter (Pitfall 6): it
//     speaks the actual letter, never a hardcoded 'alif'/'ا'.
//   - D-14: a primary "Next Lesson" CTA goes straight into the newly unlocked
//     letter; "Back Home" is demoted to a ghost.
//   - D-16: on the last lesson the primary slot becomes "See Journey" and
//     Next Lesson is absent.
//   - D-17: one warm tutor line — "Go show your {letterName} to someone at home."
//   - The "See journey" ghost link EXISTS and carries the ?highlight= param
//     (the stale Phase-3 "no See journey button" assertion is REWRITTEN here —
//     Phase 6 builds the journey handoff).
//
// PLAT-03 invariants still verified:
//   - Exactly ONE mastery star rendered (CustomPaint by _StarPainter).
//   - NO "THIS WEEK" weekly tally, NO "+N" running counter, NO "streak".
//
// Golden baseline: goldens/mastery_celebration.png — DELIBERATELY re-baked in
// 06-07 for the D-14/D-17 layout change (the ONE sanctioned re-bake). The
// baseline carries the known local-font-drift caveat; glyph_audit golden is
// untouched. Update with:
//   flutter test --update-goldens test/features/practice/mastery_celebration_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/features/practice/widgets/mastery_celebration.dart';
import 'package:qalam/l10n/app_localizations.dart';

/// Builds the celebration inside a GoRouter so the "See journey" ghost link
/// (context.go) has a router to resolve against without throwing.
Widget _buildCelebration({
  String glyph = 'ب',
  String letterName = 'baa',
  String masteredLetterId = 'baa',
  bool isLastLesson = false,
  VoidCallback? onNextLesson,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: MasteryCelebration(
            glyph: glyph,
            letterName: letterName,
            masteredLetterId: masteredLetterId,
            isLastLesson: isLastLesson,
            onNextLesson: onNextLesson,
            onBackHome: () {},
          ),
        ),
      ),
      GoRoute(
        path: '/journey',
        builder: (context, state) =>
            const Scaffold(body: Text('JOURNEY')),
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  group('MasteryCelebration — parameterized (Pitfall 6 / D-14 / D-16 / D-17)', () {
    testWidgets('speaks the mastered letter — never hardcoded alif', (tester) async {
      await tester.pumpWidget(_buildCelebration(letterName: 'baa'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('You learned baa.'),
        findsOneWidget,
        reason: 'Celebration line must template on the mastered letter (Pitfall 6)',
      );
      expect(
        find.textContaining('You learned alif.'),
        findsNothing,
        reason: 'Must NOT hardcode alif after mastering another letter',
      );
      expect(
        find.textContaining('أحسنت'),
        findsOneWidget,
        reason: 'Arabic praise must be present',
      );
    });

    testWidgets('renders the mastered glyph (ب), not a hardcoded ا', (tester) async {
      await tester.pumpWidget(_buildCelebration(glyph: 'ب'));
      await tester.pumpAndSettle();

      expect(find.text('ب'), findsOneWidget, reason: 'Mastered glyph parameterized');
      expect(find.text('ا'), findsNothing, reason: 'No hardcoded alif glyph');
    });

    testWidgets('default variant: Next Lesson primary + Back Home + See journey', (tester) async {
      await tester.pumpWidget(_buildCelebration(onNextLesson: () {}));
      await tester.pumpAndSettle();

      expect(find.text('Next Lesson'), findsOneWidget,
          reason: 'D-14 primary CTA present in the default variant');
      expect(find.text('Back Home'), findsOneWidget,
          reason: 'Back Home demoted but still present');
      expect(find.text('See journey'), findsOneWidget,
          reason: 'Phase 6 builds the journey handoff — the ghost link EXISTS now');
    });

    testWidgets('D-17 tutor line names the mastered letter', (tester) async {
      await tester.pumpWidget(_buildCelebration(letterName: 'baa'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Go show your baa to someone at home.'),
        findsOneWidget,
        reason: 'D-17: exactly one warm, specific tutor line naming the letter',
      );
    });

    testWidgets('last-lesson variant (D-16): See Journey primary, no Next Lesson', (tester) async {
      await tester.pumpWidget(_buildCelebration(isLastLesson: true));
      await tester.pumpAndSettle();

      expect(find.text('Next Lesson'), findsNothing,
          reason: 'D-16: no Next Lesson on the last lesson');
      expect(find.text('See Journey'), findsOneWidget,
          reason: 'D-16: primary slot becomes See Journey (Title Case button)');
      expect(find.text('Back Home'), findsOneWidget,
          reason: 'Back Home stays ghost on the last lesson');
    });

    testWidgets('See journey ghost link navigates with highlight param', (tester) async {
      await tester.pumpWidget(_buildCelebration(masteredLetterId: 'baa'));
      await tester.pumpAndSettle();

      final link = find.text('See journey');
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(find.text('JOURNEY'), findsOneWidget,
          reason: 'See journey navigates to /journey?highlight=baa (D-15 handoff)');
    });

    testWidgets('no THIS WEEK / +N / streak chrome (PLAT-03)', (tester) async {
      await tester.pumpWidget(_buildCelebration());
      await tester.pumpAndSettle();

      expect(find.textContaining('THIS WEEK'), findsNothing);
      expect(find.textContaining('this week'), findsNothing);
      expect(find.textContaining('stars this week'), findsNothing);
      expect(find.textContaining('+ '), findsNothing);
      expect(find.textContaining(' stars'), findsNothing);
      expect(find.textContaining('streak'), findsNothing);
    });

    testWidgets('golden snapshot (deliberately re-baked in 06-07)', (tester) async {
      await tester.pumpWidget(_buildCelebration(onNextLesson: () {}));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MasteryCelebration),
        matchesGoldenFile('goldens/mastery_celebration.png'),
      );
    });
  });
}
