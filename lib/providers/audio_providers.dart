// Letter-audio playback seam. Phase-7 swaps NoopLetterAudioPlayer for a real
// implementation; until letter.audio.letter lands the Hear button is disabled,
// so this is never actually invoked today (decorative wiring per the owner's
// Phase-7 pull-forward request).
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class LetterAudioPlayer {
  Future<void> playLetter(String assetPath);
}

class NoopLetterAudioPlayer implements LetterAudioPlayer {
  const NoopLetterAudioPlayer();
  @override
  Future<void> playLetter(String assetPath) async {}
}

final audioPlayerProvider =
    Provider<LetterAudioPlayer>((ref) => const NoopLetterAudioPlayer());
