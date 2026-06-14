// AuthService — the Qalam app's identity layer (Phase 06.1, D-09).
//
// v1 runtime auth is ANONYMOUS only (D-09b): the app signs in anonymously at boot
// so an identity exists before the first curriculum read and the Firestore rules
// can gate on `request.auth != null`. Children NEVER log in and NEVER get a real
// account or PII — there is no login UI in v1 (Decided child-safety guardrail).
//
// The full provider infrastructure (Anonymous + Email/Password + Google) is
// provisioned in the qalam-app-bd7d0 console (D-09a), and `linkToPermanent` below
// is the v2-ready account-linking seam (D-09c): a v1 anonymous identity can later
// be upgraded to a real parent/owner account via Firebase's `linkWithCredential`
// WITHOUT losing identity or local progress. The seam is DEFINED here but NOT
// called anywhere in v1 (no child login UI — D-09b).
//
// FirebaseAuth is constructor-injected (defaulting to FirebaseAuth.instance) so the
// boot path uses the real singleton while tests pass an in-memory / mock fake with
// no network or live device.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
  /// provider [credential] (the v2 account-linking seam, D-09c).
  ///
  /// Defined now so v2 anonymous→permanent linking is architected; NOT called
  /// anywhere in v1 (no child login UI — D-09b). Assumes a current user exists
  /// (the boot path guarantees one).
  Future<UserCredential> linkToPermanent(AuthCredential credential) {
    return _auth.currentUser!.linkWithCredential(credential);
  }
}
