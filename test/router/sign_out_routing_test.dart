// Plan 26-01 — sign-out routing regression (D-01b: sign-out must never strand).
//
// LIVE-PATH test: it drives the REAL `appRouterProvider` (the production redirect
// closure + the merged refreshListenable), the REAL `AuthGate`, and the REAL
// `AuthService.signOut()` — backed only by a firebase_auth_mocks fake. Per the
// project memory "live-path widget tests mandatory" (Phase-15 dead-wire lesson),
// a hand-rolled router that merely MIRRORS the redirect could pass while the real
// wiring is broken; this test exercises the real wiring so it cannot go stale.
//
// Under the ratified account-first entry model (D-01), a real parent account is
// the front door. The bug that triggered Phase 26 (D-01b): signing out restored
// an anonymous identity and the user was left stranded. This test pins the fix:
//
//   1. Sign-out from a signed-in surface (/settings) drives the router to /auth
//      and STAYS there — no redirect loop, no stranded state.
//   2. After sign-out the AuthGate reports signedIn == false even though an
//      anonymous identity is restored for offline reads (D-09c did not re-strand;
//      the anonymous boot identity never counts as signed in — D-01a).
//   3. The redirect settles: exactly one location, /auth, with the ParentAuthScreen
//      sign-in FORM present (a usable form, not a blank/loop).
//   4. Signing back in (non-anonymous) from /auth routes FORWARD (to / when a
//      profile exists) — the account front door works both directions.
//
// firebase_auth_mocks note: MockUserCredential asserts `mockUser.isAnonymous ==
// isAnonymous`. When a PERMANENT mockUser is configured, the anonymous restore in
// signOut() (ensureSignedIn -> signInAnonymously) trips that assert; AuthService's
// ensureSignedIn() try/catch swallows it (fail-safe boot), so currentUser ends
// null rather than anonymous. Either way `signedIn == false` and the redirect
// fires to /auth — the ROUTING behaviour under test is identical to production,
// where the anonymous restore succeeds. The real D-09c restore is unit-tested in
// test/services/auth_service_test.dart.

import 'dart:io';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:qalam/data/curriculum_repository.dart';
import 'package:qalam/data/drift_progress_repository.dart';
import 'package:qalam/data/progress_repository.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/auth_providers.dart';
import 'package:qalam/providers/profile_providers.dart';
import 'package:qalam/providers/progression_providers.dart';
import 'package:qalam/router/app_router.dart';
import 'package:qalam/screens/parent_auth_screen.dart';
import 'package:qalam/services/auth_service.dart';

// ---------------------------------------------------------------------------
// Harness — the REAL app root (mirrors QalamApp) driven by appRouterProvider.
// ---------------------------------------------------------------------------

/// The real shipped curriculum, loaded from disk (dart:io File, NOT rootBundle —
/// so this harness never triggers the rootBundle isolate-decode stall seen in
/// widget tests). Only needed so Home renders cheaply on the sign-back-in leg.
CurriculumRepository _shippedCurriculum() {
  final letters = File('assets/curriculum/letters.json').readAsStringSync();
  final lessons = File('assets/curriculum/lessons.json').readAsStringSync();
  return CurriculumRepository.fromStrings(letters, lessons);
}

/// A no-op ProgressRepository so Home's today-card resolves without a database.
class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<void> recordMastery({
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  }) async {}
  @override
  Future<bool> isMastered(String letterId,
          {required int childProfileId}) async =>
      false;
  @override
  Stream<Set<String>> watchMasteredLetterIds({required int childProfileId}) =>
      Stream<Set<String>>.value(const <String>{});
  @override
  Future<int> letterCleanReps(String letterId,
          {required int childProfileId}) async =>
      0;
  @override
  Stream<int> watchLetterCleanReps(String letterId,
          {required int childProfileId}) =>
      Stream<int>.value(0);
  @override
  Future<void> setLetterCleanReps({
    required int childProfileId,
    required String letterId,
    required int cleanReps,
  }) async {}
}

/// Overrides that keep the destination screens cheap and off the real Drift DB,
/// WITHOUT touching the redirect / AuthGate / AuthService wiring under test.
///
/// `onboardingGate` is pinned deterministically (its async self-seed from the
/// account DB is orthogonal to sign-out routing, which the AuthGate drives);
/// `childProfile` is null so Home renders no 1.5MB avatar image. The list type is
/// inferred from `ProviderContainer.overrides` (Riverpod's `Override` is not
/// re-exported for direct naming).
ProviderContainer _boot(AuthService authService, {required bool hasProfile}) {
  return ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
      onboardingGateProvider.overrideWith((ref) => OnboardingGate(hasProfile)),
      childProfileProvider.overrideWith((ref) async => null),
      curriculumRepositoryProvider.overrideWithValue(_shippedCurriculum()),
      progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
      unitLetterIdsProvider
          .overrideWith((ref) async => const <String>{'alif', 'baa'}),
    ],
  );
}

/// The real app root: watches the REAL appRouterProvider (production redirect).
class _App extends ConsumerWidget {
  const _App();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets(
    'sign-out from /settings routes to /auth and stays there (no loop, no strand)',
    (WidgetTester tester) async {
      // A signed-in permanent parent (the account front door is open).
      final auth = AuthService(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(
            isAnonymous: false,
            email: 'parent@example.com',
            uid: 'parent-uid',
          ),
        ),
      );
      final container = _boot(auth, hasProfile: true);
      addTearDown(container.dispose);

      // Navigate to /settings BEFORE the first pump so the heavy Home route is
      // never built — we only render the light /settings + /auth screens.
      final router = container.read(appRouterProvider);
      router.go('/settings');

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const _App()),
      );
      await tester.pumpAndSettle();

      // Signed-in parent stays on /settings.
      expect(_path(router), '/settings');
      expect(container.read(authGateProvider).signedIn, isTrue);

      // Tap the REAL Sign out button in Settings.
      final signOut = find.byKey(const Key('settingsSignOut'));
      await tester.ensureVisible(signOut);
      await tester.tap(signOut);
      await tester.pumpAndSettle();

      // Behaviour 1: the router landed on /auth (not /settings, /, or /onboarding).
      expect(_path(router), '/auth', reason: 'sign-out must route to /auth');

      // Behaviour 2: the AuthGate flipped to signed-out — the restored anonymous
      // identity (D-09c) never counts as signed in (D-01a / T-26-01-01).
      expect(
        container.read(authGateProvider).signedIn,
        isFalse,
        reason: 'anonymous restore must not re-strand the gate as signed in',
      );

      // Behaviour 3: exactly /auth, with a USABLE sign-in form (no blank/loop).
      expect(find.byKey(const Key('parentAuthScreen')), findsOneWidget);
      expect(find.byKey(const Key('authEmailField')), findsOneWidget);
      expect(find.byKey(const Key('authPasswordField')), findsOneWidget);

      // No loop: further settling leaves the location unchanged at /auth.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(_path(router), '/auth');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the front door works both ways: after sign-out a parent can sign back in '
    'and route forward off /auth',
    (WidgetTester tester) async {
      // Boot as the anonymous boot identity → the router pins /auth (front door).
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(isAnonymous: true),
      );
      final auth = AuthService(mockAuth);
      final container = _boot(auth, hasProfile: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const _App()),
      );
      await tester.pumpAndSettle();

      final router = container.read(appRouterProvider);

      // The anonymous identity does NOT unlock the app — it is pinned to /auth.
      expect(_path(router), '/auth');
      expect(container.read(authGateProvider).signedIn, isFalse);
      expect(find.byKey(const Key('authEmailField')), findsOneWidget);

      // The parent signs in with a real (non-anonymous) account. Swap the mock's
      // backing user to permanent, then drive the REAL AuthService.signInWithEmail.
      mockAuth.mockUser = MockUser(
        isAnonymous: false,
        email: 'parent@example.com',
        uid: 'parent-uid',
      );
      await auth.signInWithEmail('parent@example.com', 'secret123');
      await tester.pumpAndSettle();

      // Routed FORWARD off /auth: a profile exists → Home (a returning parent
      // reaches the child experience). The front door is not a one-way trap.
      expect(container.read(authGateProvider).signedIn, isTrue);
      expect(_path(router), '/', reason: 'sign-in with a profile lands on Home');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sign-out from the ParentAuth signed-in card returns to a usable form '
    '(the parent_auth call site never strands)',
    (WidgetTester tester) async {
      // The _SignedInCard sign-out path (parent_auth_screen _signOut). Rendered
      // directly at /auth because the account-first router redirects a signed-in
      // parent OFF /auth, so the card is only ever transient in the live router —
      // its call site is asserted here at the screen level.
      final auth = AuthService(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(
            isAnonymous: false,
            email: 'parent@example.com',
            uid: 'parent-uid',
          ),
        ),
      );
      final router = GoRouter(
        initialLocation: '/auth',
        routes: <RouteBase>[
          GoRoute(
            path: '/auth',
            builder: (context, state) => const ParentAuthScreen(),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Signed in → the signed-in card with its Sign out CTA.
      expect(find.byKey(const Key('authSignOut')), findsOneWidget);
      expect(container.read(authGateProvider).signedIn, isTrue);

      await tester.tap(find.byKey(const Key('authSignOut')));
      await tester.pumpAndSettle();

      // Back to a usable sign-in form (stays on /auth, ready to sign back in);
      // the gate is signed-out and nothing threw.
      expect(_path(router), '/auth');
      expect(find.byKey(const Key('authEmailField')), findsOneWidget);
      expect(find.byKey(const Key('authSignOut')), findsNothing);
      expect(container.read(authGateProvider).signedIn, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
