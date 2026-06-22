// Repro for the Forgot-PIN → reauthenticate → reset crash
// (`InheritedElement.debugDeactivated: _dependents.isEmpty is not true`).
// Drives the exact flow: PIN set (enter mode) → Forgot PIN → password → Verify.

import 'package:drift/native.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/features/parent/parent_pin_gate.dart';
import 'package:qalam/features/parent/pin_service.dart';
import 'package:qalam/l10n/app_localizations.dart';
import 'package:qalam/providers/auth_providers.dart';
import 'package:qalam/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Forgot PIN → password → Verify does not crash', (tester) async {
    final executor = NativeDatabase.memory();
    final db = AppDatabase(executor);
    addTearDown(() => executor.close());

    // Put the gate into ENTER mode (a PIN already exists).
    await PinService().setPin(db, '1234');

    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(isAnonymous: false, email: 'parent@example.com'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          authServiceProvider.overrideWithValue(AuthService(auth)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ParentPinGate(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the recovery dialog.
    await tester.tap(find.byKey(const Key('forgotParentPin')));
    await tester.pumpAndSettle();

    // Enter the account password and confirm.
    await tester.enterText(
      find.byKey(const Key('pinRecoveryPassword')),
      'hunter2',
    );
    await tester.tap(find.byKey(const Key('confirmPinRecovery')));
    await tester.pumpAndSettle();

    // If the bug is present, an exception is thrown during settle above.
    expect(tester.takeException(), isNull);

    // And the reset must complete: the gate now asks the parent to CREATE a new
    // PIN (isPinSet is false again).
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.parentPinCreatePrompt), findsOneWidget);
  });
}
