// THROWAWAY SPIKE GUARD (Phase 11 — GenUI/native-canvas kill-shot).
//
// Serves build-sanity for the whole spike: proves the project depends on the
// LIVE first-party `genui` SDK (publisher labs.flutter.dev) and never on the
// DISCONTINUED `flutter_genui` (0.5.0, replacedBy: genui — RESEARCH Pitfall 3).
//
// A wrong-package install would silently make the spike measure a dead, year-old
// API and the whole kill-shot would test the wrong thing. This guard fails the
// build the moment `flutter_genui` reappears or `genui` disappears.
//
// Reads pubspec.yaml as plain text (no resolution needed) and filters comment
// lines beginning with '#' BEFORE matching, so a header comment that merely
// NAMES flutter_genui (like this one, or pubspec prose) cannot self-invalidate
// the gate. Imports/modifies no durable file (SC-4 stays green by construction).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Resolve pubspec.yaml relative to the package root (test cwd == package root).
  final pubspec = File('pubspec.yaml');

  test('pubspec.yaml exists at the package root', () {
    expect(pubspec.existsSync(), isTrue,
        reason: 'pubspec.yaml must be readable from the test cwd');
  });

  // Strip whole-line comments ('#'-leading, optional indentation) so prose that
  // names flutter_genui cannot trip the absence check.
  final nonCommentLines = pubspec
      .readAsLinesSync()
      .where((line) => !RegExp(r'^\s*#').hasMatch(line))
      .toList();

  test('genui is declared as a dependency (the SDK under test)', () {
    final hasGenui = nonCommentLines
        .any((line) => RegExp(r'^\s*genui:').hasMatch(line));
    expect(hasGenui, isTrue,
        reason: 'the spike must depend on the live first-party `genui` package');
  });

  test('flutter_genui is NOT declared (discontinued — replacedBy genui)', () {
    final hasFlutterGenui = nonCommentLines
        .any((line) => RegExp(r'^\s*flutter_genui:').hasMatch(line));
    expect(hasFlutterGenui, isFalse,
        reason: 'flutter_genui is discontinued (0.5.0, replacedBy: genui); '
            'installing it would make the spike measure a dead API (Pitfall 3)');
  });

  test('firebase_core floor is at least ^4.11.0 (firebase_ai 3.13.0 needs it)',
      () {
    final coreLine = nonCommentLines.firstWhere(
      (line) => RegExp(r'^\s*firebase_core:').hasMatch(line),
      orElse: () => '',
    );
    expect(coreLine, isNotEmpty,
        reason: 'firebase_core must be declared');
    final match =
        RegExp(r'firebase_core:\s*\^?(\d+)\.(\d+)\.(\d+)').firstMatch(coreLine);
    expect(match, isNotNull,
        reason: 'firebase_core must carry an explicit semver floor');
    final major = int.parse(match!.group(1)!);
    final minor = int.parse(match.group(2)!);
    // Require >= 4.11.0 so firebase_ai 3.13.0 co-resolves (Pitfall 4).
    final atOrAboveFloor = major > 4 || (major == 4 && minor >= 11);
    expect(atOrAboveFloor, isTrue,
        reason: 'firebase_core floor must be >= 4.11.0 (found "$coreLine")');
  });

  test('firebase_ai is declared (the Gemini Flash model client)', () {
    final hasFirebaseAi = nonCommentLines
        .any((line) => RegExp(r'^\s*firebase_ai:').hasMatch(line));
    expect(hasFirebaseAi, isTrue,
        reason: 'the spike needs firebase_ai for the present_activity model call');
  });
}
