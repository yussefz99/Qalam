// Widget test for the v2 parent-auth PROTOTYPE (quick task 260622-pas).
//
// Asserts the UI-only contract: the screen renders, the email + password fields
// are present, the Sign in <-> Sign up toggle swaps the primary CTA label and
// reveals the confirm-password field, and the CTAs are inert (a tap surfaces the
// "not wired (v2)" SnackBar rather than doing anything real).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/dev/parent_auth_spike_screen.dart';

void main() {
  Widget harness() => const MaterialApp(home: ParentAuthSpikeScreen());

  group('ParentAuthSpikeScreen (v2 prototype)', () {
    testWidgets(
      'renders the screen with email + password fields and a banner',
      (WidgetTester tester) async {
        await tester.pumpWidget(harness());

        expect(find.byKey(const Key('parentAuthScreen')), findsOneWidget);
        expect(find.byKey(const Key('authEmailField')), findsOneWidget);
        expect(find.byKey(const Key('authPasswordField')), findsOneWidget);
        // The honest "this is a prototype" marker is shown.
        expect(find.text('V2 PROTOTYPE'), findsOneWidget);
      },
    );

    testWidgets('defaults to Sign in: CTA reads "Sign in", no confirm field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(harness());

      // "Sign in" appears in the toggle too, so scope the assertion to the CTA.
      expect(
        find.descendant(
          of: find.byKey(const Key('authPrimaryCta')),
          matching: find.text('Sign in'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('authConfirmField')), findsNothing);
    });

    testWidgets(
      'tapping Sign up swaps the CTA to "Create account" and reveals confirm',
      (WidgetTester tester) async {
        await tester.pumpWidget(harness());

        await tester.tap(find.byKey(const Key('authModeSignUp')));
        await tester.pumpAndSettle();

        expect(find.text('Create account'), findsOneWidget);
        expect(find.byKey(const Key('authConfirmField')), findsOneWidget);
      },
    );

    testWidgets('primary CTA is inert — shows the "not wired (v2)" SnackBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(harness());

      await tester.tap(find.byKey(const Key('authPrimaryCta')));
      await tester.pump(); // let the SnackBar animate in

      expect(
        find.textContaining('Not wired yet'),
        findsOneWidget,
        reason: 'the prototype must do nothing real — only flag the v2 gap',
      );
    });

    testWidgets('Google button is present and inert', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(harness());

      final google = find.byKey(const Key('authGoogleButton'));
      expect(google, findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      // The button sits below the default 600px test viewport — scroll it into
      // view before tapping, otherwise the tap offset misses.
      await tester.ensureVisible(google);
      await tester.pumpAndSettle();
      await tester.tap(google);
      await tester.pump();
      expect(find.textContaining('Not wired yet'), findsOneWidget);
    });
  });
}
