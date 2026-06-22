// Widget tests for the real ParentAuthScreen (owner-approved parent auth).
//
// Drives the screen with an AuthService backed by a firebase_auth_mocks fake, so
// the auth-state stream is controllable without Firebase. These cover the UI
// contract (form vs signed-in card, validation, mode toggle); the actual sign-in
// network paths are unit-tested in test/services/auth_service_test.dart.

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/providers/auth_providers.dart';
import 'package:qalam/screens/parent_auth_screen.dart';
import 'package:qalam/services/auth_service.dart';

Widget _harness(AuthService service) => ProviderScope(
  overrides: [authServiceProvider.overrideWithValue(service)],
  child: const MaterialApp(home: ParentAuthScreen()),
);

void main() {
  group('ParentAuthScreen', () {
    testWidgets('shows the form for an anonymous (not-signed-in) identity', (
      WidgetTester tester,
    ) async {
      final service = AuthService(
        MockFirebaseAuth(signedIn: true, mockUser: MockUser(isAnonymous: true)),
      );
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('authEmailField')), findsOneWidget);
      expect(find.byKey(const Key('authPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('authPrimaryCta')), findsOneWidget);
      expect(find.byKey(const Key('authSignOut')), findsNothing);
      expect(find.byKey(const Key('authForgotPassword')), findsOneWidget);
    });

    testWidgets('empty submit shows a validation error (no Firebase call)', (
      WidgetTester tester,
    ) async {
      final service = AuthService(MockFirebaseAuth(signedIn: false));
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      final cta = find.byKey(const Key('authPrimaryCta'));
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await tester.pump();

      expect(find.text('Enter your email.'), findsOneWidget);
    });

    testWidgets('toggling Sign up reveals the confirm field + CTA label', (
      WidgetTester tester,
    ) async {
      final service = AuthService(MockFirebaseAuth(signedIn: false));
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('authModeSignUp')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('authConfirmField')), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('shows the signed-in card for a real (non-anonymous) account', (
      WidgetTester tester,
    ) async {
      final service = AuthService(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(isAnonymous: false, email: 'parent@example.com'),
        ),
      );
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      expect(find.text('You\'re signed in'), findsOneWidget);
      expect(find.text('parent@example.com'), findsOneWidget);
      expect(find.byKey(const Key('authSignOut')), findsOneWidget);
      // The form is gone.
      expect(find.byKey(const Key('authEmailField')), findsNothing);
    });

    testWidgets('valid sign-in flips the view to the signed-in card', (
      WidgetTester tester,
    ) async {
      final service = AuthService(MockFirebaseAuth(signedIn: false));
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('authEmailField')),
        'parent@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('authPasswordField')),
        'secret123',
      );
      await tester.tap(find.byKey(const Key('authPrimaryCta')));
      await tester.pumpAndSettle();

      expect(find.text('You\'re signed in'), findsOneWidget);
      expect(find.byKey(const Key('authEmailField')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign-up with mismatched passwords shows a local error', (
      WidgetTester tester,
    ) async {
      final service = AuthService(MockFirebaseAuth(signedIn: false));
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('authModeSignUp')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('authEmailField')),
        'parent@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('authPasswordField')),
        'secret123',
      );
      await tester.enterText(
        find.byKey(const Key('authConfirmField')),
        'different',
      );
      final cta = find.byKey(const Key('authPrimaryCta'));
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await tester.pump();

      expect(find.text('Passwords don\'t match.'), findsOneWidget);
    });

    testWidgets('Google sign-in degrades gracefully when not configured', (
      WidgetTester tester,
    ) async {
      // In tests GOOGLE_SERVER_CLIENT_ID is empty, so signInWithGoogle throws a
      // friendly AuthFailure BEFORE touching any platform channel.
      final service = AuthService(MockFirebaseAuth(signedIn: false));
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      final googleButton = find.byKey(const Key('authGoogleButton'));
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('authError')), findsOneWidget);
      expect(find.textContaining('Google sign-in isn\'t set up yet'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign-out from the signed-in card returns to the form', (
      WidgetTester tester,
    ) async {
      final service = AuthService(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(isAnonymous: false, email: 'parent@example.com'),
        ),
      );
      await tester.pumpWidget(_harness(service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('authSignOut')));
      await tester.pumpAndSettle();

      // signOut() restores an anonymous identity → the form returns.
      expect(find.byKey(const Key('authEmailField')), findsOneWidget);
      expect(find.byKey(const Key('authSignOut')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
