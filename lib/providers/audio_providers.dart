// Letter-audio playback seam. Phase 4 shipped NoopLetterAudioPlayer; Phase 7
// (plan 07-02) swaps in the real AssetLetterAudioPlayer that plays BUNDLED
// pronunciation clips offline (S1-06) — no TTS, no network round-trip.
//
// The interface stays stable so practice_screen.dart's consumer is unchanged:
// it reads audioPlayerProvider and calls playLetter(...) with the letter's
// audioId. NoopLetterAudioPlayer is kept for tests and as the never-block
// reference posture (unknown ids / missing clips degrade to a silent no-op).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/asset_audio_player.dart';
import 'tts_providers.dart';

abstract interface class LetterAudioPlayer {
  Future<void> playLetter(String assetPath);
}

class NoopLetterAudioPlayer implements LetterAudioPlayer {
  const NoopLetterAudioPlayer();
  @override
  Future<void> playLetter(String assetPath) async {}
}

/// The app's letter-audio player. Returns the real [AssetLetterAudioPlayer],
/// which resolves a Schema-v2 `audioId` to a bundled `assets/audio/` clip and
/// plays it offline; unknown ids / missing clips degrade to a silent no-op so
/// the child is never blocked (T-07-02-04).
///
/// The single player instance is disposed when the provider is torn down so
/// native audio resources do not leak. Tests override this provider with
/// [NoopLetterAudioPlayer] (no real playback in widget/unit tests).
final audioPlayerProvider = Provider<LetterAudioPlayer>((ref) {
  final player = AssetLetterAudioPlayer();
  ref.onDispose(player.dispose);
  // Stop in-flight TTS before a clip so the two engines cannot steal each
  // other's audio focus (Listen tap while the instruction bar is speaking).
  return _TtsAwareLetterAudioPlayer(
    player,
    () => ref.read(ttsCoachSpeakerProvider).stop(),
  );
});

/// Stops the coach TTS engine, then forwards to the bundled-clip player.
class _TtsAwareLetterAudioPlayer implements LetterAudioPlayer {
  _TtsAwareLetterAudioPlayer(this._inner, this._stopTts);

  final AssetLetterAudioPlayer _inner;
  final Future<void> Function() _stopTts;

  @override
  Future<void> playLetter(String assetPath) async {
    try {
      await _stopTts();
    } catch (_) {}
    await _inner.playLetter(assetPath);
  }
}
