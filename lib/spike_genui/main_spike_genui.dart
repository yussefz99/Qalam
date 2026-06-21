// THROWAWAY SPIKE ENTRYPOINT — Phase 11 GenUI/native-canvas kill-shot (Plan 11-02, Task 3).
//
// Run with:  flutter run -t lib/spike_genui/main_spike_genui.dart
//
// PURPOSE: a SEPARATE flutter run -t target for the GATE-deciding A/B harness. It is a
// stripped-down copy of production main() — it needs Firebase init (so firebase_ai can
// attach to the existing app qalam-app-bd7d0 and reach Gemini Flash) but DELIBERATELY
// OMITS the AppDatabase boot read, the onboarding/parent gates, and the router. The
// production lib/main.dart is UNTOUCHED.
//
// StrokeCanvas is a plain StatefulWidget (not a ConsumerStatefulWidget), and the spike
// embeds it directly (NOT the Riverpod-dragging WriteSurface), so a bare runApp with NO
// ProviderScope is sufficient.
//
// This file edits no durable file; the SC-4 git-diff guard proves the sacred paths stay
// untouched for the whole spike. It reuses lib/firebase_options.dart read-only.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart' show configureLogging;

import 'package:qalam/firebase_options.dart';

import 'spike_app.dart';

/// The runtime half of the landscape lock — copied VERBATIM from lib/main.dart
/// (lines 19-24). Tablet-first: landscape both rotations, never portrait.
Future<void> lockOrientation() {
  return SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await lockOrientation();

  // GenUI logging -> debugPrint, so A2UI parsing / surface events are visible during
  // the on-device A/B (per the integrate-genui-firebase skill).
  configureLogging(
    logCallback: (level, msg) => debugPrint('GenUI $level: $msg'),
  );

  // Attach Firebase to the existing project (qalam-app-bd7d0) via the project's
  // read-only firebase_options.dart — firebase_ai then attaches to this app. The spike
  // OMITS AuthService/AppDatabase/gates/router (it needs none of them).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SpikeApp());
}
