// Lane B (finalization push, 2026-07-18) — asset-reference integrity guard.
//
// WHY THIS EXISTS: `word.thalab` shipped referenced by two live thaa exercises
// with NO clip on disk, and `sentence.thaa-draft` likewise — and nothing failed,
// because AssetLetterAudioPlayer's never-block posture silently no-ops a missing
// clip and AssetImageResolver degrades a missing picture to the hatched stub.
// Graceful degradation is right for the CHILD; it must never be how the TEAM
// finds out a reference is broken. This test makes every broken reference loud.
//
// WHAT IT ASSERTS (letter-generic — iterates whatever letters exercises.json
// contains, plus every words.json entry; a newly promoted letter is covered
// automatically, never by editing this file):
//   1. AUDIO — every `audioId` referenced by any exercise prompt or word entry
//      resolves through the live player map/fallback (AssetLetterAudioPlayer
//      .audioAssetFor) to a file that EXISTS on disk. No exceptions, ever:
//      audio is generatable on demand (tools/tts + tools/audio_pipeline), so a
//      missing clip is always a bug.
//   2. IMAGE — every `imageId` referenced by any exercise prompt or word entry
//      resolves through AssetImageResolver.imageAssetFor to a file that EXISTS
//      on disk — EXCEPT the pinned known-missing register below.
//
// THE KNOWN-MISSING REGISTER (a ratchet, not an allowlist that rots): art can
// only be generated in an environment with image-generation access (see
// assets/images/GENERATION-PROGRESS.md), which Lane B did not have. The ids
// below are the exact debt as of 2026-07-18. The register is asserted with
// setEquals in BOTH directions:
//   • a NEW broken image reference fails the build (can't grow silently);
//   • generating one of these images ALSO fails until its id is removed here
//     (the register can never overstate the debt).
// The owner resolves each entry by generating the art in the partner's
// illustration style (assets/images/ILLUSTRATION-STYLE.md) or deliberately
// re-pointing the content — then deleting the id from this set.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/services/asset_audio_player.dart';
import 'package:qalam/services/asset_image_resolver.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Image ids referenced by live content whose art does not exist yet.
/// See the header comment — this is a two-way ratchet, not a skip list.
///
/// EMPTY as of 2026-07-18 evening: the 7 previously-missing illustrations
/// (thalab/thalj for the thaa unit; crown/berries/house/lion/mother vocab
/// rows) were generated in-style via the Vertex image model per
/// assets/images/ILLUSTRATION-STYLE.md — all DRAFTS pending the mother's
/// review, like every model-authored asset. Adding a new content reference
/// without art still fails this test until the art lands or the id is
/// deliberately registered here.
const Set<String> knownMissingImages = <String>{};

/// A single audio/image reference found in live content, with provenance for
/// failure messages.
class _Ref {
  _Ref(this.id, this.source);
  final String id;
  final String source;

  @override
  String toString() => '$id (at $source)';
}

/// Collect every audioId / imageId referenced by exercises.json prompts and
/// words.json entries. Letter-generic: walks whatever is in the files.
({List<_Ref> audio, List<_Ref> images}) _collectRefs() {
  final audio = <_Ref>[];
  final images = <_Ref>[];

  final exercises =
      (_loadJson('assets/curriculum/exercises.json')['exercises'] as List)
          .cast<Map<String, dynamic>>();
  for (final e in exercises) {
    final id = e['id'] as String;
    final prompt = (e['prompt'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    for (final item in prompt) {
      final audioId = item['audioId'] as String?;
      if (item['kind'] == 'audio' && audioId != null && audioId.isNotEmpty) {
        audio.add(_Ref(audioId, 'exercises.json → $id'));
      }
      final imageId = item['imageId'] as String?;
      if (item['kind'] == 'image' && imageId != null && imageId.isNotEmpty) {
        images.add(_Ref(imageId, 'exercises.json → $id'));
      }
    }
  }

  final words = (_loadJson('assets/curriculum/words.json')['words'] as List)
      .cast<Map<String, dynamic>>();
  for (final w in words) {
    final id = w['id'] as String;
    final audioId = w['audio'] as String?;
    if (audioId != null && audioId.isNotEmpty) {
      audio.add(_Ref(audioId, 'words.json → $id'));
    }
    final imageId = w['image'] as String?;
    if (imageId != null && imageId.isNotEmpty) {
      images.add(_Ref(imageId, 'words.json → $id'));
    }
  }

  return (audio: audio, images: images);
}

void main() {
  test('sanity: content walk is non-vacuous and covers multiple letters', () {
    final refs = _collectRefs();
    expect(refs.audio, isNotEmpty,
        reason: 'no audio references found — the walk is broken, not the data');
    expect(refs.images, isNotEmpty,
        reason: 'no image references found — the walk is broken, not the data');
    final letters = refs.audio
        .map((r) => r.source)
        .where((s) => s.startsWith('exercises.json'))
        .map((s) => s.split('→ ').last.split('.').first)
        .toSet();
    expect(letters.length, greaterThanOrEqualTo(2),
        reason: 'expected exercises for multiple letters — letter-generic walk '
            'must not have collapsed to one unit (found: $letters)');
  });

  test('every referenced audioId resolves through the player map to a clip '
      'that exists on disk — NO exceptions', () {
    final refs = _collectRefs();
    final broken = <String>[];
    for (final ref in refs.audio) {
      final asset = AssetLetterAudioPlayer.audioAssetFor(ref.id);
      if (asset == null) {
        broken.add('$ref — resolves to null');
      } else if (!File(asset).existsSync()) {
        broken.add('$ref — resolves to $asset which does NOT exist. '
            '(The player would silently no-op this at runtime — that is the '
            'exact silent failure this test exists to catch.)');
      }
    }
    expect(broken, isEmpty,
        reason: 'Broken audio references. Fix by generating the clip '
            '(tools/tts/generate_audio.py), adding it to '
            'tools/audio_pipeline/audio_manifest.json (status draft-tts), and '
            'running `python -m audio_pipeline generate` + `check` from tools/:'
            '\n${broken.join('\n')}');
  });

  test('every referenced imageId resolves to existing art — with the pinned '
      'known-missing register enforced in BOTH directions', () {
    final refs = _collectRefs();
    final broken = <String, List<String>>{}; // id -> sources
    for (final ref in refs.images) {
      final asset = AssetImageResolver.imageAssetFor(ref.id);
      final exists = asset != null && File(asset).existsSync();
      if (!exists) {
        broken.putIfAbsent(ref.id, () => <String>[]).add(ref.source);
      }
    }

    // Direction 1: nothing broken beyond the pinned register.
    final unexpected = broken.keys.toSet().difference(knownMissingImages);
    expect(unexpected, isEmpty,
        reason: 'NEW broken image reference(s) — art must exist (or the id '
            'must be deliberately added to knownMissingImages with the owner\'s '
            'sign-off): ${unexpected.map((id) => '$id ← ${broken[id]}').join('; ')}');

    // Direction 2: the register never overstates the debt.
    final resolved = knownMissingImages.difference(broken.keys.toSet());
    expect(resolved, isEmpty,
        reason: 'These register entries now resolve (art generated or content '
            're-pointed) — remove them from knownMissingImages so the debt '
            'list stays honest: $resolved');
  });
}
