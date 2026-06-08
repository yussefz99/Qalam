// home_screen_test.dart — Plan 03-05
//
// Widget tests for HomeScreen: verifies the warm demo home renders correctly,
// lesson-card navigation fires, PLAT-03 anti-gamification invariants hold, and
// Journey/Parent nav entries are visibly locked with no navigation.
//
// Navigation tests use a real GoRouter with a /practice stub so context.go
// can be observed via the router's current location.

// ignore_for_file: scoped_providers_should_specify_dependencies

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/profile_providers.dart';
import 'package:qalam/screens/home_screen.dart';
import 'package:qalam/widgets/arabic_text.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds HomeScreen inside a GoRouter so context.go works.
/// The /practice stub page is a simple scaffold that can be found by finder.
///
/// [profile] overrides childProfileProvider so the greeting reads the chosen
/// fixed-set nickname (S1-03). When null the provider resolves to no profile.
Widget _buildWithRouter({GoRouter? router, ChildProfile? profile}) {
  final goRouter = router ??
      GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) =>
                const Scaffold(body: Text('Practice Screen')),
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      childProfileProvider.overrideWith((ref) async => profile),
    ],
    child: MaterialApp.router(
      routerConfig: goRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// A fixed-set profile fixture — nickname `nick_star`, avatar `avatar_1`.
/// The greeting must resolve `nick_star` to its display label (no real name).
ChildProfile _starProfile() => ChildProfile(
      id: 1,
      nicknameId: 'nick_star',
      avatarId: 'avatar_1',
      grade: 'kg',
      startingLessonId: 'alif',
      createdAt: 0,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen', () {
    // -----------------------------------------------------------------------
    // Test 1: Renders the demo home content
    // -----------------------------------------------------------------------
    testWidgets(
        'greeting renders the chosen nickname label and avatar, plus the alif glyph (Test 1)',
        (WidgetTester tester) async {
      // Override childProfileProvider with a fixed-set profile (S1-03): the
      // greeting must show the resolved nickname LABEL, never a real name and
      // never the old hardcoded 'Layla'.
      await tester.pumpWidget(_buildWithRouter(profile: _starProfile()));
      await tester.pumpAndSettle();

      // The chosen nickname's display label (nick_star → 'نجمة' / Najma) renders
      // through an ArabicText island. The old hardcoded greeting must be gone.
      expect(
        find.text('Welcome back, Layla.'),
        findsNothing,
        reason: 'the hardcoded "Layla" greeting must be replaced by the profile nickname.',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is ArabicText && w.text == 'نجمة',
        ),
        findsOneWidget,
        reason: 'the resolved nickname label for nick_star ("نجمة") must render.',
      );

      // The chosen avatar is rendered in the greeting header.
      expect(
        find.byKey(const Key('homeAvatar_avatar_1')),
        findsOneWidget,
        reason: 'the chosen avatar (avatar_1) must render in the greeting header.',
      );

      // Lesson card title.
      expect(
        find.text('The Letter Alif'),
        findsOneWidget,
        reason: 'Lesson card title "The Letter Alif" must be visible.',
      );

      // The alif ArabicText RTL island.
      expect(
        find.byWidgetPredicate(
          (w) => w is ArabicText && w.text == 'ا',
        ),
        findsOneWidget,
        reason: 'ArabicText widget containing the alif glyph "ا" must exist.',
      );
    });

    // -----------------------------------------------------------------------
    // Test 2: Lesson card tap navigates to /practice
    // -----------------------------------------------------------------------
    testWidgets(
        'lesson card tap navigates to /practice (Test 2)',
        (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) =>
                const Scaffold(body: Text('Practice Screen')),
          ),
        ],
      );

      await tester.pumpWidget(_buildWithRouter(router: router));
      await tester.pumpAndSettle();

      // Tap the lesson card (keyed 'todaysLessonCard').
      final cardFinder = find.byKey(const Key('todaysLessonCard'));
      expect(cardFinder, findsOneWidget,
          reason: 'Lesson card must carry Key("todaysLessonCard").');

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // After tap, the practice screen stub should be visible.
      expect(
        find.text('Practice Screen'),
        findsOneWidget,
        reason: 'Tapping the lesson card must navigate to /practice.',
      );
    });

    // -----------------------------------------------------------------------
    // Test 3: Anti-gamification invariants
    // -----------------------------------------------------------------------
    testWidgets(
        'no gamification chrome: no THIS WEEK, no stars tally, no progress bar (Test 3)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWithRouter());
      await tester.pumpAndSettle();

      // "THIS WEEK" (case variants) must be absent.
      expect(find.textContaining('THIS WEEK'), findsNothing,
          reason: '"THIS WEEK" must be absent (PLAT-03).');
      expect(find.textContaining('this week'), findsNothing);

      // "stars this week" tally must be absent.
      expect(find.textContaining('stars this week'), findsNothing,
          reason: '"stars this week" tally must be absent.');

      // Running star totals / "+N" hype must be absent.
      expect(find.textContaining('total stars'), findsNothing);
      expect(find.textContaining('stars earned'), findsNothing);

      // Weekly progress bar — no LinearProgressIndicator on this screen.
      expect(find.byType(LinearProgressIndicator), findsNothing,
          reason: 'No weekly progress bar on the home screen.');

      // No star emoji gamification chrome.
      expect(find.textContaining('⭐'), findsNothing,
          reason: 'No star emoji on the home screen.');
    });

    // -----------------------------------------------------------------------
    // Test 4: Journey and Parent are locked — labels present, no navigation
    // -----------------------------------------------------------------------
    testWidgets(
        'Journey and Parent nav entries show Coming soon and do not navigate (Test 4)',
        (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) =>
                const Scaffold(body: Text('Practice Screen')),
          ),
        ],
      );

      await tester.pumpWidget(_buildWithRouter(router: router));
      await tester.pumpAndSettle();

      // Journey and Parent labels must be present.
      expect(find.text('Journey'), findsOneWidget,
          reason: '"Journey" nav label must be visible.');
      expect(find.text('Parent'), findsOneWidget,
          reason: '"Parent" nav label must be visible.');

      // "Coming soon" must appear under each locked item.
      expect(
        find.text('Coming soon'),
        findsWidgets,
        reason: '"Coming soon" sublabel must appear under locked nav items.',
      );

      // Capture initial router location.
      final initialLocation =
          router.routerDelegate.currentConfiguration.uri.toString();

      // Tapping the Journey label must not change the route.
      await tester.tap(find.text('Journey'));
      await tester.pumpAndSettle();

      final afterJourneyTap =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(afterJourneyTap, equals(initialLocation),
          reason: 'Tapping Journey must not navigate (it is locked).');

      // Tapping the Parent label must not change the route either.
      await tester.tap(find.text('Parent'));
      await tester.pumpAndSettle();

      final afterParentTap =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(afterParentTap, equals(initialLocation),
          reason: 'Tapping Parent must not navigate (it is locked).');
    });
  });
}
