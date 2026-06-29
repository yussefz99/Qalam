// TtsCoachSpeaker — the on-device coach VOICE seam (Phase 16, PRES-02).
//
// The tutor's voice is the product's signature. This file synthesizes the
// coaching line ON-DEVICE via the platform TTS engine — no network round-trip,
// works in airplane mode, $0 (D-04). It is a SEPARATE surface from the bundled
// pronunciation clips (audioplayers / S1-06): those play letter/word sounds;
// THIS speaks the coach's spoken guidance, a beat after the visual verdict.
//
// Seam contract:
//   abstract interface class CoachSpeaker { speak(line) / stop() / dispose() }
// The concrete TtsCoachSpeaker speaks through an injectable [TtsEngine] (so a
// fake can be driven in tests, exactly like NoopLetterAudioPlayer overrides the
// audio seam). The real ship wraps a single reusable FlutterTts instance.
//
// MIXED-LANGUAGE PATTERN (RESEARCH Pattern 2): a coach line is often English
// guidance with a small Arabic token ("أحسنت — that curve is perfect"). The
// platform engine voices ONE language per utterance, so we split the line into
// ordered (locale, text) runs via [segmentByScript] — Arabic-block runs → 'ar',
// everything else → 'en-US' — and speak them sequentially, setting the language
// per run. NEVER one setLanguage for the whole mixed line (the anti-pattern).
//
// NEVER-BLOCK / SILENT-DEGRADE POSTURE (mirrors asset_audio_player.dart, ADR-014):
// TTS is DISPLAY-ONLY. speak() swallows every error, never throws, and never
// blocks the trace loop — the instant on-screen verdict already rendered. When
// the device lacks an Arabic voice (a stock Pixel Tablet often does — D-06), the
// Arabic run is SKIPPED and the English guidance still speaks; a missing voice is
// a silent skip, exactly like an unknown audioId is a silent no-op.
//
// segmentByScript is a PURE, device-free function (the analog of audioAssetFor):
// it is unit-tested with no TTS backend. The class is driven through the injected
// engine, so the whole surface is testable in a headless flutter_test run.

import 'package:flutter_tts/flutter_tts.dart';

/// The minimal TTS-engine seam [TtsCoachSpeaker] speaks through. A fake
/// implements this in tests; the real [FlutterTtsEngine] wraps a [FlutterTts]
/// instance. Keeping the engine behind an interface lets the never-block
/// behaviour and the segment-by-script flow be verified with no real audio
/// backend (there is no platform TTS in a flutter_test run).
abstract interface class TtsEngine {
  /// True when the on-device engine has a voice installed for [locale]. A stock
  /// Pixel Tablet often lacks the Arabic voice (D-06) → graceful degrade.
  Future<bool> isLanguageAvailable(String locale);

  /// Select the language/voice for the next [speak] call.
  Future<void> setLanguage(String locale);

  /// Synthesize and play [text] in the currently-set language.
  Future<void> speak(String text);

  /// When passed `true`, makes [speak] resolve only after the utterance
  /// finishes — so sequential runs do not clobber one another.
  Future<void> awaitSpeakCompletion(bool awaitCompletion);

  /// Stop any in-flight utterance (a cleared idle is silent).
  Future<void> stop();
}

/// The real engine: a thin adapter over a single reusable [FlutterTts] handle.
/// One instance for the app lifetime (mirrors the single AudioPlayer in
/// AssetLetterAudioPlayer) keeps native resources bounded.
class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<bool> isLanguageAvailable(String locale) async {
    final dynamic available = await _tts.isLanguageAvailable(locale);
    return available == true;
  }

  @override
  Future<void> setLanguage(String locale) => _tts.setLanguage(locale);

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) =>
      _tts.awaitSpeakCompletion(awaitCompletion);

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

/// True when [c] is in the Arabic Unicode range — the base block
/// (U+0600–U+06FF) plus the Arabic presentation forms (U+FB50–U+FDFF and
/// U+FE70–U+FEFF). Everything else (Latin, digits, punctuation, the em dash) is
/// non-Arabic and voiced as English.
bool _isArabic(int c) =>
    (c >= 0x0600 && c <= 0x06FF) ||
    (c >= 0xFB50 && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF);

/// Splits [line] into ordered `(locale, text)` runs for per-language synthesis.
///
/// Arabic-block runs map to `'ar'`; every other run (Latin, punctuation, digits,
/// the em dash) maps to `'en-US'`. Order is preserved, so an Arabic token that
/// leads the line is spoken first. A pure-English line is a single `('en-US', …)`
/// run; a pure-Arabic line is a single `('ar', …)` run; the empty string yields
/// an empty list (nothing to speak).
///
/// This is the PURE, device-free core (the analog of `audioAssetFor`) — no
/// FlutterTts, no platform call — so it is unit-testable with no TTS backend.
List<(String locale, String text)> segmentByScript(String line) {
  if (line.isEmpty) return const <(String, String)>[];

  final runs = <(String, String)>[];
  final buffer = StringBuffer();
  bool? currentIsArabic;

  void flush() {
    if (buffer.isEmpty) return;
    final locale = (currentIsArabic ?? false) ? 'ar' : 'en-US';
    runs.add((locale, buffer.toString()));
    buffer.clear();
  }

  for (final rune in line.runes) {
    final runeIsArabic = _isArabic(rune);
    if (currentIsArabic != null && runeIsArabic != currentIsArabic) {
      flush();
    }
    currentIsArabic = runeIsArabic;
    buffer.writeCharCode(rune);
  }
  flush();

  return runs;
}

/// The coach-voice seam. A `Noop` is injected in widget/unit tests (mirrors
/// `NoopLetterAudioPlayer`); the real [TtsCoachSpeaker] ships on device.
abstract interface class CoachSpeaker {
  /// Speak [line] a beat after the visual verdict. Never throws, never blocks.
  Future<void> speak(String line);

  /// Stop any in-flight utterance (a cleared idle is silent).
  Future<void> stop();

  /// Release the native engine handle. Called from provider disposal.
  Future<void> dispose();
}

/// Speaks a coach line on-device through an injectable [TtsEngine], voicing the
/// mixed-language line per-script and gracefully degrading when the Arabic voice
/// is absent — never throwing, never blocking the trace loop (ADR-014).
class TtsCoachSpeaker implements CoachSpeaker {
  /// [engine] defaults to the real [FlutterTtsEngine]; tests inject a fake.
  TtsCoachSpeaker([TtsEngine? engine]) : _engine = engine ?? FlutterTtsEngine();

  final TtsEngine _engine;

  @override
  Future<void> speak(String line) async {
    // Whole body wrapped in a swallow-everything guard: a missing voice, a synth
    // error, or a slow first-synthesis must NEVER throw to the caller or stall
    // the visual (ADR-014 display-only — mirrors asset_audio_player.playLetter).
    try {
      final runs = segmentByScript(line);
      if (runs.isEmpty) return;

      // Make each speak() resolve only after its utterance finishes, so the runs
      // are voiced in order rather than the last one clobbering the rest.
      await _engine.awaitSpeakCompletion(true);

      // Check the Arabic voice ONCE per line (not per run) — the answer is stable
      // for the whole utterance and the call can be slow.
      final bool arOk = await _engine.isLanguageAvailable('ar');

      for (final (locale, text) in runs) {
        // Graceful degrade: skip the Arabic run when no Arabic voice is
        // installed; the English guidance still speaks (D-06).
        if (locale == 'ar' && !arOk) continue;
        await _engine.setLanguage(locale);
        await _engine.speak(text);
      }
    } catch (_) {
      // Missing voice / synth error / platform hiccup → swallow. Voice is an
      // enhancement layered a beat after the instant on-screen verdict, never a
      // gate on the trace loop (ADR-014, mirrors the audio never-block posture).
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // A cleared idle is silent; a stop hiccup is non-fatal.
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Disposal errors are non-fatal — nothing depends on a clean teardown.
    }
  }
}

/// A no-op coach speaker for tests and as the never-block reference posture
/// (mirrors `NoopLetterAudioPlayer`). Every method is a silent no-op.
class NoopTtsCoachSpeaker implements CoachSpeaker {
  const NoopTtsCoachSpeaker();

  @override
  Future<void> speak(String line) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
