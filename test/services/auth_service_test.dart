// AuthService — the v1 anonymous identity + the v2-ready account-linking seam
// (Phase 06.1, D-09b / D-09c).
//
// Encodes the three behaviours the plan locks:
//   1. ensureSignedIn() signs in anonymously when there is no current user →
//      currentUser becomes non-null and isAnonymous (the zero-PII identity that
//      reads curriculum and rules gate on, D-09b).
//   2. ensureSignedIn() is a NO-OP when a user is already signed in — it must not
//      mint a second anonymous user (idempotent boot, safe to call every launch).
//   3. linkToPermanent(credential) delegates to currentUser.linkWithCredential —
//      the account-linking seam (D-09c). Defined now, NOT exercised by a real
//      provider in v1 (there is no child login UI — D-09b).
//
// CHILD-SAFETY: this suite never constructs an email/password/name identity for a
// child. The only runtime path is anonymous (test 1); the link path (test 3) is the
// v2 parent-upgrade seam, asserted via delegation only — no real credential flows.
//
// Tests 1 & 2 use firebase_auth_mocks (a faithful in-memory FirebaseAuth). Test 3
// uses mocktail so the linkWithCredential delegation can be verified directly.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qalam/services/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
  });

  group('AuthService.ensureSignedIn', () {
    test('signs in anonymously when there is no current user', () async {
      final auth = MockFirebaseAuth(); // signedIn: false → currentUser == null
      final service = AuthService(auth);

      expect(auth.currentUser, isNull);

      await service.ensureSignedIn();

      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.isAnonymous, isTrue);
    });

    test('is a no-op when a user is already signed in', () async {
      final existing = MockUser(isAnonymous: true, uid: 'existing-anon-uid');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: existing);
      final service = AuthService(auth);

      final uidBefore = auth.currentUser!.uid;

      await service.ensureSignedIn();

      // Same identity — no second anonymous user was minted.
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.uid, equals(uidBefore));
    });

    test('does NOT throw when anonymous sign-in fails (boot resilience)',
        () async {
      // A failed boot sign-in — no network on a fresh install, or the Anonymous
      // provider not enabled — must degrade to offline, never crash main()
      // before runApp(). ensureSignedIn must complete without rethrowing.
      final auth = _MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);
      when(() => auth.signInAnonymously())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final service = AuthService(auth);

      await expectLater(service.ensureSignedIn(), completes);
      verify(() => auth.signInAnonymously()).called(1);
    });
  });

  group('AuthService.linkToPermanent', () {
    test('delegates to currentUser.linkWithCredential (v2 seam)', () async {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      final credential = _FakeAuthCredential();
      final result = _MockUserCredential();

      when(() => auth.currentUser).thenReturn(user);
      when(() => user.linkWithCredential(any()))
          .thenAnswer((_) async => result);

      final service = AuthService(auth);
      final returned = await service.linkToPermanent(credential);

      verify(() => user.linkWithCredential(credential)).called(1);
      expect(returned, same(result));
    });
  });
}
