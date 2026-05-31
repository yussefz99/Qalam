// App entrypoint. Thin bootstrap: lock orientation (runtime half of the
// belt-and-suspenders landscape lock — D-10; the manifest pins the platform
// half), then run the Riverpod-rooted app. The real root widget lives in app.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

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
  runApp(const ProviderScope(child: QalamApp()));
}
