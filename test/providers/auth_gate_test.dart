import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/providers/auth_providers.dart';
import 'package:qalam/services/auth_service.dart';

void main() {
  test('anonymous Firebase identity does not unlock the app', () {
    final gate = AuthGate(
      AuthService(
        MockFirebaseAuth(signedIn: true, mockUser: MockUser(isAnonymous: true)),
      ),
    );
    addTearDown(gate.dispose);

    expect(gate.signedIn, isFalse);
  });

  test('a permanent account unlocks the app', () {
    final gate = AuthGate(
      AuthService(
        MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(isAnonymous: false, email: 'parent@example.com'),
        ),
      ),
    );
    addTearDown(gate.dispose);

    expect(gate.signedIn, isTrue);
  });
}
