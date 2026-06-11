// Plan 05-01 (Wave 0) — OnboardingScreen widget contract (TDD, starts RED).
//
// INTENTIONALLY RED at Wave 0: imports
//   package:qalam/features/onboarding/onboarding_screen.dart
// and references the not-yet-built OnboardingScreen + childProfileRepositoryProvider
// + onboardingGateProvider. A later wave builds the screen, turning this green.
// Do NOT add a lib/ stub here.
//
// Encodes the S1-03 invariants that make this screen safe for a young child:
//   * NO free-text widget anywhere (no TextField / TextFormField / EditableText
//     — no keyboard, no real-name leak). This is the strongest child-data posture.
//   * Back navigation is blocked via PopScope(canPop: false) so the child cannot
//     skip onboarding by pressing the Android back button.
//   * Tapping avatar + nickname + grade then "Let's go" persists a fixed-set-only
//     profile (a stubbed repository records the create) and navigates to Home.
//
// Harness mirrors test/screens/home_screen_test.dart: ProviderScope +
// MaterialApp.router with AppLocalizations delegates.

// ignore_for_file: scoped_providers_should_specify_dependencies

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/child_profile_repository.dart';
import 'package:qalam/features/onboarding/onboarding_screen.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/profile_providers.dart';

/// A test double that records the single profile create() without touching Drift.
class _RecordingRepository implements ChildProfileRepository {
  ({String nicknameId, String avatarId, String grade, String startingLessonId})?
      lastCreated;

  @override
  Future<bool> hasProfile() async => lastCreated != null;

  @override
  Future<ChildProfile?> getProfile() async => null;

  @override
  Future<int> create({
    required String nicknameId,
    required String avatarId,
    required String grade,
    required String startingLessonId,
  }) async {
    lastCreated = (
      nicknameId: nicknameId,
      avatarId: avatarId,
      grade: grade,
      startingLessonId: startingLessonId,
    );
    return 1;
  }
}

Widget _buildWithRouter({required ChildProfileRepository repo}) {
  final goRouter = GoRouter(
    initialLocation: '/onboarding',
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('Home Stub')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      childProfileRepositoryProvider.overrideWithValue(repo),
      onboardingGateProvider.overrideWith((ref) => OnboardingGate(false)),
    ],
    child: MaterialApp.router(
      routerConfig: goRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('OnboardingScreen (S1-03)', () {
    // -----------------------------------------------------------------------
    // Test 1: NO free-text widget anywhere — no keyboard, no real-name leak.
    // -----------------------------------------------------------------------
    testWidgets('renders no free-text input widgets (S1-03)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWithRouter(repo: _RecordingRepository()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing,
          reason: 'no TextField allowed on onboarding (S1-03)');
      expect(find.byType(TextFormField), findsNothing,
          reason: 'no TextFormField allowed on onboarding (S1-03)');
      expect(find.byType(EditableText), findsNothing,
          reason: 'no keyboard/EditableText surface allowed (S1-03)');
    });

    // -----------------------------------------------------------------------
    // Test 2: back navigation is blocked (PopScope canPop:false).
    // -----------------------------------------------------------------------
    testWidgets('blocks back navigation with PopScope(canPop: false)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWithRouter(repo: _RecordingRepository()));
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse,
          reason: 'the child must not be able to skip onboarding via back');
    });

    // -----------------------------------------------------------------------
    // Test 3: full happy path persists a fixed-set profile and lands on Home.
    // -----------------------------------------------------------------------
    testWidgets(
        'tapping avatar + nickname + grade then "Let\'s go" persists and navigates Home',
        (WidgetTester tester) async {
      final repo = _RecordingRepository();
      await tester.pumpWidget(_buildWithRouter(repo: repo));
      await tester.pumpAndSettle();

      // Each fixed-set cell carries a stable Key (mirrors todaysLessonCard).
      await tester.tap(find.byKey(const Key('grade_kg')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatar_avatar_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nickname_nick_star')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingSubmit')));
      await tester.pumpAndSettle();

      // The fixed-set selection was persisted (no free text ever involved).
      expect(repo.lastCreated, isNotNull,
          reason: '"Let\'s go" must persist the selected profile');
      expect(repo.lastCreated!.grade, 'kg');
      expect(repo.lastCreated!.avatarId, 'avatar_1');
      expect(repo.lastCreated!.nicknameId, 'nick_star');
      expect(repo.lastCreated!.startingLessonId, 'lesson_01',
          reason: 'grade kg resolves to the default starting LESSON id '
              '(S1-02; lesson-id namespace, Plan 06-02)');

      // Navigation lands on Home.
      expect(find.text('Home Stub'), findsOneWidget,
          reason: 'after submit the child lands on Home');
    });
  });
}
