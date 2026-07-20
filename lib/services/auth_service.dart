// AuthService — the Qalam app's identity layer (Phase 06.1, D-09).
//
// The app signs in ANONYMOUSLY at boot (D-09b) so an identity exists before the
// first curriculum read and the Firestore rules can gate on `request.auth != null`.
//
// PARENT ACCOUNTS (owner-approved 2026-06-22): real Email/Password + Google
// parent sign-in/up is now LIVE (the parent flows below), reached only from
// behind the PIN-gated parent area. The child-safety core is unchanged —
// CHILDREN STILL NEVER LOG IN (the D-09b child-login ban holds); the owner lifted
// only the "no real accounts in v1" line. When a parent first signs up, the boot
// anonymous identity is LINKED (D-09c) so no local progress is lost; sign-out
// restores an anonymous identity so curriculum reads keep working offline-first.
//
// The provider infrastructure (Anonymous + Email/Password + Google) is provisioned
// in the qalam-app-bd7d0 console (D-09a). FirebaseAuth is constructor-injected
// (defaulting to FirebaseAuth.instance) so the boot path uses the real singleton
// while tests pass an in-memory / mock fake with no network or live device.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A friendly, already-mapped auth error suitable to show a parent verbatim.
///
/// The screen catches this and renders [message] directly — raw Firebase codes
/// (e.g. `weak-password`) never reach the UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => 'AuthFailure: $message';
}

/// Wraps [FirebaseAuth] to expose the app's two identity operations: an idempotent
/// anonymous boot sign-in (v1) and the v2 account-linking upgrade seam.
class AuthService {
  /// Inject a [FirebaseAuth] (tests pass a fake); defaults to the live singleton.
  AuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The current identity, or `null` if no one is signed in yet.
  User? get currentUser => _auth.currentUser;

  /// Ensures an identity exists by signing in anonymously when there is none.
  ///
  /// Idempotent: a NO-OP if a user is already signed in, so it is safe to call on
  /// every launch without minting a second anonymous user. The anonymous identity
  /// carries zero PII (D-09b) and is the one that reads curriculum and (in v2) will
  /// call the tutor.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      // Boot resilience: a failed anonymous sign-in — no network on a fresh
      // install, or the Anonymous provider not yet enabled in the console — must
      // NOT crash the app at launch (main() awaits this before runApp). Swallow
      // it and continue: with no identity the Firestore read is denied, so
      // CurriculumRepository degrades to the bundled offline assets (the
      // offline-first guarantee). Logged so the cause stays visible.
      debugPrint(
        'AuthService.ensureSignedIn: anonymous sign-in failed, '
        'continuing offline (curriculum falls back to bundle): $e',
      );
    }
  }

  /// Upgrades the current anonymous identity to a permanent one by linking a real
  /// provider [credential] (the account-linking seam, D-09c). Used by the parent
  /// auth flows below so a returning anonymous identity (and its local progress)
  /// is preserved when a parent first creates/links an account.
  Future<UserCredential> linkToPermanent(AuthCredential credential) {
    return _auth.currentUser!.linkWithCredential(credential);
  }

  // ---------------------------------------------------------------------------
  // App account auth (owner-approved, 2026-06-22). A real parent-owned account
  // is required by the router before child setup or app content. Children still
  // do not receive their own credentials; they use the configured child profile.
  // ---------------------------------------------------------------------------

  /// Emits the current [User] (or null) and all relevant identity updates.
  ///
  /// `userChanges()` is intentionally broader than `authStateChanges()`: signup
  /// upgrades the boot anonymous user with `linkWithCredential`, which can keep
  /// the same Firebase UID and therefore may not produce a basic auth-state
  /// transition. The broader stream makes the router react immediately after
  /// linking, signing in, signing out, or refreshing the user token.
  Stream<User?> authStateChanges() => _auth.userChanges();

  /// True when [currentUser] is a real (non-anonymous) parent account.
  bool get isSignedInPermanent =>
      _auth.currentUser != null && !_auth.currentUser!.isAnonymous;

  /// Creates a parent account from [email] + [password].
  ///
  /// If the current identity is anonymous (the boot identity), the email is
  /// LINKED to it (D-09c) so no local progress is lost; otherwise a fresh account
  /// is created. Throws [AuthFailure] with a parent-friendly message on failure.
  Future<User> signUpWithEmail(String email, String password) async {
    try {
      final current = _auth.currentUser;
      if (current != null && current.isAnonymous) {
        final cred = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        final result = await current.linkWithCredential(cred);
        return result.user!;
      }
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  /// Signs in to an existing parent account with [email] + [password].
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthFailure(
        'Password verification is unavailable for this account.',
      );
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  /// Signs in (or links) with Google.
  ///
  /// Needs the Firebase Web client id as [googleServerClientId] (Android mints a
  /// Firebase-usable idToken only with it). Until the console step is done that
  /// is empty and this throws a clear [AuthFailure] rather than failing opaquely.
  Future<User> signInWithGoogle() async {
    if (googleServerClientId.isEmpty) {
      throw const AuthFailure(
        'Google sign-in isn\'t set up yet. Finish the Firebase console step '
        '(enable Google + add the SHA-1), then try again.',
      );
    }
    try {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await google.initialize(serverClientId: googleServerClientId);
        _googleInitialized = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google sign-in did not return a token.');
      }
      final cred = GoogleAuthProvider.credential(idToken: idToken);
      final current = _auth.currentUser;
      final UserCredential result = (current != null && current.isAnonymous)
          ? await current.linkWithCredential(cred)
          : await _auth.signInWithCredential(cred);
      return result.user!;
    } on GoogleSignInException catch (e) {
      // User-cancelled is not an error worth shouting about.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Google sign-in was cancelled.');
      }
      throw AuthFailure('Google sign-in failed: ${e.code.name}.');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_friendly(e));
    }
  }

  /// Signs the parent out, then restores an anonymous identity so curriculum
  /// reads keep working offline-first (the app must always have an identity).
  ///
  /// NEVER-STRAND (D-01b, Plan 26-01): the `ensureSignedIn()` anonymous restore
  /// (D-09c) is deliberate and must stay. It does not re-strand the user because
  /// the restored identity is anonymous, which `AuthGate` reports as signed-OUT
  /// (D-01a) — driving the app_router redirect cleanly to `/auth`. The sign-out
  /// fix is ROUTING, not identity: keep this restore intact. Regression-locked by
  /// test/router/sign_out_routing_test.dart.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // best-effort; Google may never have been used
    }
    await _auth.signOut();
    await ensureSignedIn();
  }

  /// The Firebase Web client id (oauth_client `client_type: 3` in
  /// google-services.json), injected at build via
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`. Empty until the owner finishes
  /// the console step; the Google button degrades gracefully while empty.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  bool _googleInitialized = false;

  /// Maps a [FirebaseAuthException] to a calm, parent-readable sentence.
  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email doesn\'t look right.';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'That email already has an account. Try signing in instead.';
      case 'weak-password':
        return 'Please use a longer password (at least 6 characters).';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-not-found':
        return 'No account found for that email. Try signing up.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
