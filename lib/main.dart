// App entrypoint. Thin bootstrap: lock orientation (runtime half of the
// belt-and-suspenders landscape lock — D-10; the manifest pins the platform
// half), bring up Firebase + App Check, sign in, then run the Riverpod-rooted
// app. The real root widget lives in app.dart.
//
// Account-scoped DB + the onboarding/parent gates now self-configure REACTIVELY
// from auth state (partner's parent-accounts architecture, origin/main): the
// account-scoped `appDatabaseProvider` rebuilds on the signed-in UID and
// `onboardingGate` self-seeds by listening to `authStateProvider`, so this
// entrypoint no longer does a boot-time `hasProfile()` read or override those
// gates. The ONLY root override kept here is the App Check token getter, which
// the cloud tutor needs and which main did not carry.

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'tutor/tutor_providers.dart';

Future<void> lockOrientation() {
  return SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await lockOrientation();

  // Bring up Firebase before any auth / App Check / Firestore call (Phase 06.1).
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
    // iOS App Check (the live AI tutor). Without an Apple provider the iPad
    // produces no App Check token, so the App-Check-gated Cloud Run `/coach`
    // rejects the call and RemoteAgentBrain silently degrades to the canned
    // AuthoredFallback floor (= the "canned/wrong feedback" seen on-device).
    // The DEBUG provider with a fixed token lets a sideloaded dev/demo build
    // authenticate: register this exact token in Firebase Console → App Check →
    // com.technion.qalam (iOS app) → Manage debug tokens. Swap to
    // AppleAppAttestProvider for a real App Store release.
    providerApple: const AppleDebugProvider(
      debugToken: 'E2925A26-0602-4C5C-A8D9-9BC80C76FBCE',
    ),
  );

  // Anonymous auth remains an internal Firebase/offline identity only. The
  // router requires a permanent account, and persisted app data is selected by
  // that account's Firebase UID (origin/main parent-accounts architecture).
  // ensureSignedIn() is idempotent, so a returning user keeps their identity.
  await AuthService().ensureSignedIn();

  runApp(
    ProviderScope(
      overrides: [
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
