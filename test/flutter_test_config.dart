// Global test bootstrap (flutter_test auto-discovers this file and wraps every
// test in this directory tree with it).
//
// WHY THIS EXISTS (the D-12 golden footgun): `flutter test` runs headless and
// does NOT load the fonts declared in pubspec.yaml — it falls back to a built-in
// test font that has NO Arabic glyphs. Without this loader, any golden/widget
// test that renders Arabic shows TOFU (□ .notdef boxes), so the glyph-audit
// golden would "pass" against a baseline of missing glyphs — proving nothing and
// silently defeating the D-12 risk gate (this is exactly Pitfall 3:
// system/test-font fallback masking the bundled font).
//
// Fix: register the BUNDLED TTFs with the test engine via FontLoader, keyed by
// the SAME family strings declared in pubspec.yaml / QalamFonts (they must match
// exactly). After this runs, the glyph-audit golden genuinely exercises Noto
// Naskh Arabic's contextual shaping, and the human-PASS in Task 3 is meaningful.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// pubspec family string → bundled TTF asset paths.
const Map<String, List<String>> _bundledFonts = <String, List<String>>{
  'Noto Naskh Arabic': <String>['assets/fonts/NotoNaskhArabic-Regular.ttf'],
  'Cairo': <String>['assets/fonts/Cairo-Regular.ttf'],
  'Fredoka': <String>['assets/fonts/Fredoka-Medium.ttf'],
  'Nunito': <String>['assets/fonts/Nunito-Regular.ttf'],
};

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final MapEntry<String, List<String>> entry in _bundledFonts.entries) {
    final FontLoader loader = FontLoader(entry.key);
    for (final String path in entry.value) {
      loader.addFont(_loadFontBytes(path));
    }
    await loader.load();
  }

  await testMain();
}

/// Reads a bundled TTF straight off disk (relative to the package root) and
/// hands it to the FontLoader as a ByteData future. Reading from disk (rather
/// than rootBundle) keeps the loader independent of the asset bundle, which is
/// not wired up in the bare test harness.
Future<ByteData> _loadFontBytes(String path) async {
  final Uint8List bytes = await File(path).readAsBytes();
  return ByteData.view(bytes.buffer);
}
