import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

Future<void> lockOrientation() {
  return SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await lockOrientation();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Anonymous auth remains an internal Firebase/offline identity only. The
  // router requires a permanent account, and persisted app data is selected by
  // that account's Firebase UID.
  await AuthService().ensureSignedIn();

  runApp(const ProviderScope(child: QalamApp()));
}
