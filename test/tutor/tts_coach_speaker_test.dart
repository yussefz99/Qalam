// TtsCoachSpeaker — the on-device coach VOICE seam (Phase 16, PRES-02).
//
// This is the Wave-0 RED contract (Nyquist): it imports
// `package:qalam/tutor/tts_coach_speaker.dart`, which does NOT exist yet, so the
// whole suite fails to COMPILE (RED by missing symbol). Plan 16-02 writes the
// file (the pure `segmentByScript` splitter + the `TtsCoachSpeaker` class over an
// injectable TTS engine) and turns these GREEN with ZERO test edits — the symbol
// names below ARE the Wave-2 contract.
//
// What this suite locks (pure Dart, NO device — there is no TTS backend in a
// flutter_test run; the speaker is driven through an injected fake engine):
//
//   segmentByScript (pure, device-free — the analog of audioAssetFor):
//     1. A mixed line splits into ordered (locale, text) runs — the Arabic run
//        ('ar', ...) separated from the Latin run ('en-US', ...), in order.
//     2. A pure-English line returns a single ('en-US', ...) run; a pure-Arabic
//        line returns a single ('ar', ...) run.
//     3. The empty string returns an empty list (nothing to speak).
//
//   TtsCoachSpeaker (graceful degrade — the never-block posture, ADR-014):
//     4. With an engine whose isLanguageAvailable('ar') == false, the Arabic run
//        is SKIPPED and the English run is still spoken — never throws. We assert
//        the English run was attempted and the Arabic run was NOT.
//
// RED-by-missing-symbol is the INTENDED Wave-0 state — do NOT implement
// segmentByScript / TtsCoachSpeaker here. Only the failing tests live in this file.

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/tutor/tts_coach_speaker.dart';

/// A recording fake of the injectable TTS engine seam the [TtsCoachSpeaker]
/// speaks through. It reports Arabic availability via [arAvailable] and records
/// every (locale, text) pair handed to speak — so a test can assert exactly which
/// runs were attempted and which were skipped, with no real audio backend.
///
/// `TtsEngine` is the Wave-2 contract: the speaker takes an engine so a fake can
/// be injected here and a real `FlutterTts`-backed engine ships in 16-02.
class _RecordingTtsEngine implements TtsEngine {
  _RecordingTtsEngine({required this.arAvailable});

  /// Whether the (faked) on-device engine has the Arabic voice installed. A
  /// stock Pixel Tablet often lacks it (RESEARCH D-06) → graceful degrade.
  final bool arAvailable;

  /// Every (locale, text) pair the speaker attempted to speak, in order.
  final List<(String, String)> spoken = <(String, String)>[];

  @override
  Future<bool> isLanguageAvailable(String locale) async =>
      locale == 'ar' ? arAvailable : true;

  @override
  Future<void> setLanguage(String locale) async {
    _pendingLocale = locale;
  }

  String? _pendingLocale;

  @override
  Future<void> speak(String text) async {
    spoken.add((_pendingLocale ?? 'en-US', text));
  }

  @override
  Future<void> awaitSpeakCompletion(bool await_) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  group('segmentByScript (pure, device-free)', () {
    test('a mixed Arabic+Latin line splits into ordered runs', () {
      // أحسنت ("well done") is the Arabic run; the rest is the English run. Order
      // preserved: the Arabic token leads, the Latin guidance follows.
      final runs = segmentByScript('أحسنت — that curve is perfect');
      expect(runs.length, 2);
      expect(runs[0].$1, 'ar');
      expect(runs[0].$2.trim(), 'أحسنت');
      expect(runs[1].$1, 'en-US');
      expect(runs[1].$2.contains('that curve is perfect'), isTrue);
    });

    test('a pure-English line is a single en-US run', () {
      final runs = segmentByScript('Try again, slower this time.');
      expect(runs.length, 1);
      expect(runs.single.$1, 'en-US');
      expect(runs.single.$2, 'Try again, slower this time.');
    });

    test('a pure-Arabic line is a single ar run', () {
      final runs = segmentByScript('أحسنت');
      expect(runs.length, 1);
      expect(runs.single.$1, 'ar');
      expect(runs.single.$2.trim(), 'أحسنت');
    });

    test('the empty string yields an empty list (nothing to speak)', () {
      expect(segmentByScript(''), isEmpty);
    });
  });

  group('TtsCoachSpeaker (graceful degrade — never blocks)', () {
    test('Arabic-unavailable: skips the Arabic run, still speaks English',
        () async {
      final engine = _RecordingTtsEngine(arAvailable: false);
      final speaker = TtsCoachSpeaker(engine);

      // Must NOT throw even though the Arabic voice is missing (ADR-014).
      await expectLater(
        speaker.speak('أحسنت — that curve is perfect'),
        completes,
      );

      // The English run was attempted; the Arabic run was NOT.
      final spokenLocales = engine.spoken.map((r) => r.$1).toList();
      expect(spokenLocales.contains('en-US'), isTrue,
          reason: 'the English guidance must still be voiced');
      expect(spokenLocales.contains('ar'), isFalse,
          reason: 'the missing Arabic voice run must be skipped, not spoken');
    });

    test('Arabic-available: speaks both runs in order', () async {
      final engine = _RecordingTtsEngine(arAvailable: true);
      final speaker = TtsCoachSpeaker(engine);

      await expectLater(
        speaker.speak('أحسنت — that curve is perfect'),
        completes,
      );

      final spokenLocales = engine.spoken.map((r) => r.$1).toList();
      expect(spokenLocales, containsAllInOrder(<String>['ar', 'en-US']));
    });
  });
}
