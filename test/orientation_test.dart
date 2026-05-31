// Wave-0 validation scaffold — D-10 (landscape lock, belt-and-suspenders).
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/main.dart and references
// `lockOrientation` (the extracted, testable half of the runtime lock) which
// does not yet exist — the current main.dart is still the default counter
// scaffold. A later plan rewrites main() to call SystemChrome with
// landscapeLeft + landscapeRight and exposes lockOrientation(); that turns the
// runtime half of this test green. Do NOT add a lib/ stub here.
//
// The lock is enforced at TWO layers (Pitfall 5):
//   1. runtime: SystemChrome.setPreferredOrientations(landscapeLeft/Right)
//   2. platform: android:screenOrientation in AndroidManifest.xml
// The manifest assertion below already passes against the committed manifest;
// the runtime assertion stays red until main() is rewritten.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runtime lock sets landscapeLeft + landscapeRight (D-10)', () async {
    final List<DeviceOrientation> applied = <DeviceOrientation>[];

    // Capture the orientations main()'s lock requests, without a real platform.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        applied
          ..clear()
          ..addAll((call.arguments as List)
              .cast<String>()
              .map((s) => DeviceOrientation.values
                  .firstWhere((o) => o.toString() == s)));
      }
      return null;
    });

    // `lockOrientation` is the extracted, awaitable half of main()'s bootstrap.
    await lockOrientation();

    expect(applied, contains(DeviceOrientation.landscapeLeft));
    expect(applied, contains(DeviceOrientation.landscapeRight));
    expect(applied, isNot(contains(DeviceOrientation.portraitUp)));
  });

  test('platform layer pins android:screenOrientation in the manifest (D-10)',
      () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest.contains('android:screenOrientation'), isTrue,
        reason: 'AndroidManifest must pin orientation at the platform layer');
  });
}
