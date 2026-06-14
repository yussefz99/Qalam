// App entrypoint. Thin bootstrap: lock orientation (runtime half of the
// belt-and-suspenders landscape lock — D-10; the manifest pins the platform
// half), then run the Riverpod-rooted app. The real root widget lives in app.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'providers/parent_providers.dart';
import 'providers/profile_providers.dart';

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
      ],
      child: const QalamApp(),
    ),
  );
}
