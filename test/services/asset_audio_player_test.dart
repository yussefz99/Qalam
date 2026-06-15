// AssetLetterAudioPlayer — the offline bundled-clip player over the
// LetterAudioPlayer seam (plan 07-02, S1-06).
//
// What this suite locks (the behaviour, not real audio output — there is no
// platform audio backend in a flutter_test run):
//   1. A known audioId resolves to its expected bundled asset path. This is the
//      pure `audioAssetFor` resolution every Play button depends on (snd.baa,
//      word.baab, word.batta, the sentence clip).
//   2. A raw `assets/audio/...` path passes through unchanged (defensive: a
//      caller holding a path, not an id, still plays).
//   3. An UNKNOWN id (and an empty / whitespace / foreign-path input) resolves
//      to null — nothing to play.
//   4. playLetter('does.not.exist') COMPLETES WITHOUT THROWING — the silent
//      degrade that guarantees the child is never blocked or shown an audio
//      error (T-07-02-04, mirrors NoopLetterAudioPlayer).
//
// Note: tests exercise the pure resolver + the never-throw contract of
// playLetter for an unresolvable id. They do NOT drive a real AudioPlayer
// (asserting that would need a platform channel / integration test); the
// resolution map is the unit under test here.

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/services/asset_audio_player.dart';

void main() {
  group('AssetLetterAudioPlayer.audioAssetFor (pure resolution)', () {
    test('known audioIds resolve to their bundled asset paths', () {
      expect(
        AssetLetterAudioPlayer.audioAssetFor('snd.baa'),
        'assets/audio/snd.baa.mp3',
      );
      expect(
        AssetLetterAudioPlayer.audioAssetFor('word.baab'),
        'assets/audio/word.baab.mp3',
      );
      expect(
        AssetLetterAudioPlayer.audioAssetFor('word.batta'),
        'assets/audio/word.batta.mp3',
      );
      expect(
        AssetLetterAudioPlayer.audioAssetFor('sentence.albaab-kabiir'),
        'assets/audio/sentence.albaab-kabiir.mp3',
      );
    });

    test('a raw assets/audio path passes through unchanged', () {
      expect(
        AssetLetterAudioPlayer.audioAssetFor('assets/audio/snd.baa.mp3'),
        'assets/audio/snd.baa.mp3',
      );
    });

    test('an unmapped dotted audioId resolves by convention (Phase 8)', () {
      // Unmapped dotted ids resolve to assets/audio/<id>.mp3 so new letters'
      // clips play without map maintenance; a missing file degrades to silence
      // at play time (see playLetter test below), never a thrown error.
      expect(AssetLetterAudioPlayer.audioAssetFor('word.haliib'),
          'assets/audio/word.haliib.mp3');
      expect(AssetLetterAudioPlayer.audioAssetFor('snd.taa'),
          'assets/audio/snd.taa.mp3');
    });

    test('empty / whitespace / foreign-path inputs resolve to null', () {
      expect(AssetLetterAudioPlayer.audioAssetFor(''), isNull);
      expect(AssetLetterAudioPlayer.audioAssetFor('   '), isNull);
      expect(
        AssetLetterAudioPlayer.audioAssetFor('assets/icons/door.svg'),
        isNull,
      );
    });
  });

  group('AssetLetterAudioPlayer.playLetter (silent degrade)', () {
    test('an unknown id completes without throwing (never blocks the child)',
        () async {
      final player = AssetLetterAudioPlayer();
      // No platform audio backend in a flutter_test run, and the id is unknown,
      // so this MUST short-circuit to a no-op and complete — never throw.
      await expectLater(player.playLetter('does.not.exist'), completes);
      await expectLater(player.playLetter(''), completes);
    });
  });
}
