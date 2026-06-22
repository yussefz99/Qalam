// App entrypoint. Thin bootstrap: lock orientation (runtime half of the
// belt-and-suspenders landscape lock — D-10; the manifest pins the platform
// half), then run the Riverpod-rooted app. The real root widget lives in app.dart.

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'firebase_options.dart';
import 'providers/parent_providers.dart';
import 'providers/profile_providers.dart';
import 'services/auth_service.dart';
import 'tutor/tutor_providers.dart';

/// The runtime half of the landscape lock (D-10), extracted so it is awaitable
/// and testable. Pins the app to landscape (both rotations); never portrait.
Future<void> lockOrientation() {
  return SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await lockOrientation();

  // Bring up Firebase, then sign in anonymously BEFORE the first curriculum read
  // (Phase 06.1, D-09b). An anonymous identity must exist so Firestore rules can
  // gate curriculum reads on `request.auth != null`. Zero PII; children never log
  // in (no login UI — D-09b). ensureSignedIn() is idempotent, so a returning user
  // keeps their existing anonymous identity. linkWithCredential (D-09c) upgrades
  // this identity to a permanent account in v2 without losing it.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check gates the Cloud Run tutor (`POST /coach` verifies a limited-use
  // App Check token). Activate BEFORE any backend call. On an emulator/debug
  // build Play Integrity is unavailable, so use the DEBUG provider: on first run
  // it prints a debug secret to logcat — paste it into Firebase Console → App
  // Check → com.technion.qalam → Manage debug tokens. Release builds use Play
  // Integrity on a real device.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
  );

  await AuthService().ensureSignedIn();

  // One-time boot read of the onboarding gate flag (Pattern 3): construct the
  // production DB once, read hasProfile() synchronously-before-first-frame, then
  // seed both the shared DB and the gate via ProviderScope overrides so the
  // router's redirect resolves correctly on the very first frame (no async-in-
  // redirect, no flicker — Pitfall 2/3).
  final db = AppDatabase();
  final hasProfile = await db.hasProfile();

  runApp(
    ProviderScope(
      overrides: [
        // One shared DB instance for the app lifetime; the provider owns disposal
        // (Pitfall 7) — do not let AppDatabase be constructed twice.
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        // Seed the gate from the boot-time read; markProfileCreated() flips it
        // after onboarding (refreshListenable re-runs the router redirect).
        onboardingGateProvider.overrideWith((ref) => OnboardingGate(hasProfile)),
        // Seed the parent gate LOCKED every launch (D-07 per-entry, no session
        // unlock and no boot DB read). The /parent screen flips it after a
        // correct PIN and relocks it on "Done"/dispose.
        parentGateProvider.overrideWith((ref) => ParentGate()),
        // Wire the real App Check token getter at the composition root (the
        // tutor seam's default is null → offline floor). The RemoteAgentBrain
        // sends this limited-use token to the App-Check-gated `/coach`; any
        // failure returns null so the brain cleanly degrades to the floor.
        appCheckTokenGetterProvider.overrideWith(
          (ref) => () async {
            try {
              return await FirebaseAppCheck.instance.getLimitedUseToken();
            } catch (_) {
              return null;
            }
          },
        ),
      ],
      child: const QalamApp(),
    ),
  );
}
