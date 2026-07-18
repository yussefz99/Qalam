// AssetLetterAudioPlayer — the real, offline implementation of the
// LetterAudioPlayer seam (Phase 4 shipped a Noop; this plan, 07-02, makes it
// real). S1-06: a tappable Play plays a BUNDLED pronunciation clip per letter
// and per word, fully offline — no TTS, no network round-trip at trace time
// (PLAT-01 / T-07-02-04).
//
// Seam contract (unchanged for practice_screen.dart):
//   Future<void> playLetter(String audioIdOrPath)
// practice_screen calls this with whatever lives in letter.audio.letter — which
// in Schema v2 is an `audioId` (e.g. `snd.baa`), not a path. So this player
// resolves an audioId → a bundled asset path via [audioAssetFor], then plays it
// from the asset bundle. A raw `assets/audio/...` path is also accepted and
// passed through unchanged (defensive: either shape works).
//
// NEVER-BLOCK POSTURE (mirrors NoopLetterAudioPlayer, T-07-02-04): an unknown
// audioId, a missing/empty clip, or any playback error is SWALLOWED — the method
// completes without throwing. The child never sees an audio error and is never
// blocked waiting on audio. Audio is an enhancement to the trace loop, not a
// gate on it.
//
// The clips themselves are an OWNER DELIVERABLE: the recordings of the owner's
// mother saying each sound. Placeholder files ship until she records the real
// ones — see assets/audio/README.md for the audioId → asset → real-vs-placeholder
// manifest. Because unknown ids degrade silently, the build stays green whether a
// given clip is the real recording or a placeholder.

import 'package:audioplayers/audioplayers.dart';

import '../providers/audio_providers.dart' show LetterAudioPlayer;

/// Plays bundled pronunciation clips from `assets/audio/` over the
/// [LetterAudioPlayer] seam. Resolves a Schema-v2 `audioId` (or a raw asset
/// path) to a bundled asset and plays it offline. All failures degrade to a
/// silent no-op — the child is never blocked or shown an audio error.
class AssetLetterAudioPlayer implements LetterAudioPlayer {
  AssetLetterAudioPlayer({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  /// One reusable player instance for the app's lifetime. Reusing a single
  /// player (rather than spawning one per tap) keeps native resources bounded
  /// and lets a new clip interrupt a still-playing one (the child taps Play
  /// again before the last clip ends).
  final AudioPlayer _player;

  /// Directory under the asset bundle where all pronunciation clips live. Must
  /// match the `flutter.assets` entry in pubspec.yaml (`assets/audio/`).
  static const String _audioDir = 'assets/audio';

  /// audioId → asset path under [_audioDir], for the baa Letter Unit.
  ///
  /// These ids come from the baa EXERCISE-CONFIGS (`snd.baa`, `word.batta`,
  /// `word.baab`, `sentence.albaab-kabiir`) plus the words the unit teaches.
  /// Keep this map and `assets/audio/README.md` in lockstep: every entry here
  /// is documented there with its real-vs-placeholder status (all PLACEHOLDER
  /// until the owner records the clips).
  ///
  /// `word.haliib` (حليب, "milk") is the third Words-with-Baa card. Its clip now
  /// ships in `assets/audio/`, so it is mapped here — without this entry the
  /// milk card's Play button resolves to null and is a silent no-op.
  // BEGIN GENERATED (audio_manifest)
  // Generated from tools/audio_pipeline/audio_manifest.json — do not edit by hand.
  // Regenerate: `python -m audio_pipeline generate` (from tools/).
  static const Map<String, String> _audioIdToAsset = <String, String>{
    'snd.alif': '$_audioDir/snd.alif.mp3',
    'snd.baa': '$_audioDir/snd.baa.mp3',
    'snd.taa': '$_audioDir/snd.taa.mp3',
    'snd.thaa': '$_audioDir/snd.thaa.mp3',
    'snd.jeem': '$_audioDir/snd.jeem.mp3',
    'snd.haa_c': '$_audioDir/snd.haa_c.mp3',
    'snd.khaa': '$_audioDir/snd.khaa.mp3',
    'snd.daal': '$_audioDir/snd.daal.mp3',
    'snd.dhaal': '$_audioDir/snd.dhaal.mp3',
    'snd.raa': '$_audioDir/snd.raa.mp3',
    'snd.zaay': '$_audioDir/snd.zaay.mp3',
    'snd.seen': '$_audioDir/snd.seen.mp3',
    'snd.sheen': '$_audioDir/snd.sheen.mp3',
    'snd.saad': '$_audioDir/snd.saad.mp3',
    'snd.daad': '$_audioDir/snd.daad.mp3',
    'snd.taa_h': '$_audioDir/snd.taa_h.mp3',
    'snd.zhaa': '$_audioDir/snd.zhaa.mp3',
    'snd.ayn': '$_audioDir/snd.ayn.mp3',
    'snd.ghayn': '$_audioDir/snd.ghayn.mp3',
    'snd.faa': '$_audioDir/snd.faa.mp3',
    'snd.qaaf': '$_audioDir/snd.qaaf.mp3',
    'snd.kaaf': '$_audioDir/snd.kaaf.mp3',
    'snd.laam': '$_audioDir/snd.laam.mp3',
    'snd.meem': '$_audioDir/snd.meem.mp3',
    'snd.noon': '$_audioDir/snd.noon.mp3',
    'snd.haa_f': '$_audioDir/snd.haa_f.mp3',
    'snd.waaw': '$_audioDir/snd.waaw.mp3',
    'snd.yaa': '$_audioDir/snd.yaa.mp3',
    'word.baab': '$_audioDir/word.baab.mp3',
    'word.batta': '$_audioDir/word.batta.mp3',
    'word.haliib': '$_audioDir/word.haliib.mp3',
    'word.taaj': '$_audioDir/word.taaj.mp3',
    'word.tuut': '$_audioDir/word.tuut.mp3',
    'word.bayt': '$_audioDir/word.bayt.mp3',
    'word.asad': '$_audioDir/word.asad.mp3',
    'word.umm': '$_audioDir/word.umm.mp3',
    'word.thalab': '$_audioDir/word.thalab.mp3',
    'sentence.albaab-kabiir': '$_audioDir/sentence.albaab-kabiir.mp3',
    'sentence.attaaj-jamiil': '$_audioDir/sentence.attaaj-jamiil.mp3',
    'sentence.alasad-kabiir': '$_audioDir/sentence.alasad-kabiir.mp3',
    'sentence.aththalab-kabiir': '$_audioDir/sentence.aththalab-kabiir.mp3',
  };
  // END GENERATED

  /// Pure resolver: maps an [audioIdOrPath] to a bundled asset path, or null
  /// when there is nothing to play.
  ///
  /// Resolution order:
  ///   1. A known `audioId` (e.g. `snd.baa`) → its mapped asset path.
  ///   2. A raw asset path already under `assets/audio/` → passed through.
  ///   3. Anything else (unknown id, empty string, foreign path) → null.
  ///
  /// This is the unit-testable core (no real playback): tests assert known ids
  /// resolve to the expected path and unknown ids resolve to null.
  static String? audioAssetFor(String audioIdOrPath) {
    final String value = audioIdOrPath.trim();
    if (value.isEmpty) return null;
    final String? mapped = _audioIdToAsset[value];
    if (mapped != null) return mapped;
    // Defensive pass-through: a caller that already holds a bundled audio path
    // (rather than an id) still plays. Scoped to our audio dir so we never try
    // to play an arbitrary asset.
    if (value.startsWith('$_audioDir/')) return value;
    // Convention fallback (Phase 8): an unmapped dotted audioId (e.g. `snd.taa`,
    // `word.taaj`) resolves to `assets/audio/<id>.mp3`. If the file is absent the
    // player swallows the error and degrades to silence — never blocks the child.
    if (RegExp(r'^[a-z]+(\.[A-Za-z0-9-]+)+$').hasMatch(value)) {
      return '$_audioDir/$value.mp3';
    }
    return null;
  }

  @override
  Future<void> playLetter(String assetPath) async {
    final String? asset = audioAssetFor(assetPath);
    // Unknown id / nothing to play → silent no-op (never throws, never blocks).
    if (asset == null) return;
    try {
      // AssetSource paths are relative to the asset bundle root MINUS the
      // leading `assets/` that audioplayers prepends itself. So `assets/audio/
      // snd.baa.mp3` is played as AssetSource('audio/snd.baa.mp3').
      final String sourcePath = asset.startsWith('assets/')
          ? asset.substring('assets/'.length)
          : asset;
      // stop() first so a rapid re-tap restarts cleanly instead of overlapping.
      await _player.stop();
      await _player.play(AssetSource(sourcePath));
    } catch (_) {
      // Missing file / decode error / platform hiccup → swallow. Audio is an
      // enhancement, never a gate on the trace loop (T-07-02-04). Mirrors the
      // NoopLetterAudioPlayer's never-block posture.
    }
  }

  /// Release native player resources. Call from provider disposal.
  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {
      // Disposal errors are non-fatal — nothing depends on a clean teardown.
    }
  }
}
