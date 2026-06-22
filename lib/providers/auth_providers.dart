// Auth providers — expose AuthService + the live auth state to the UI.
//
// Riverpod-only (D-11). The parent auth screen reads authServiceProvider to call
// sign-up/in/out and watches authStateProvider to flip between the form and the
// signed-in card. Kept hand-written (a plain Provider/StreamProvider) — no codegen
// needed for these two leaves.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// The app's single [AuthService] (wraps FirebaseAuth.instance).
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// The current Firebase user (or null), updated on every auth change.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Router refresh source for the app-wide account gate.
///
/// Anonymous Firebase users are an internal Firestore/offline identity only;
/// they never count as signed in and never unlock the application UI.
class AuthGate extends ChangeNotifier {
  AuthGate(AuthService service)
    : _signedIn =
          service.currentUser != null && !service.currentUser!.isAnonymous {
    _subscription = service.authStateChanges().listen((user) {
      final next = user != null && !user.isAnonymous;
      if (next == _signedIn) return;
      _signedIn = next;
      notifyListeners();
    });
  }

  bool _signedIn;
  late final StreamSubscription<User?> _subscription;

  bool get signedIn => _signedIn;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authGateProvider = Provider<AuthGate>((ref) {
  final gate = AuthGate(ref.watch(authServiceProvider));
  ref.onDispose(gate.dispose);
  return gate;
});
