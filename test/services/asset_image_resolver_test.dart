// AssetImageResolver — the pure imageId → bundled-asset-path resolver for the
// baa Letter Unit's three vocab illustrations (quick task 260615-tqu).
//
// This suite mirrors asset_audio_player_test.dart: it locks the PURE resolution
// the prompt header depends on, WITHOUT loading a real image (there is no
// rasterizer assertion here — _ImagePart's render/fallback is covered by the
// widget test). What this suite locks:
//   1. Each of the three EXERCISE-CONFIGS imageIds (img.door / img.duck /
//      img.big-door) resolves to its on-disk .webp path under assets/images/.
//   2. A raw `assets/images/...` path passes through unchanged (defensive: a
//      caller holding a path, not an id, still resolves).
//   3. An UNKNOWN id (and empty / whitespace / foreign-path input) resolves to
//      null — nothing to render, so _ImagePart falls back to the hatched stub.

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/services/asset_image_resolver.dart';

void main() {
  group('AssetImageResolver.imageAssetFor (pure resolution)', () {
    test('known imageIds resolve to their bundled .webp asset paths', () {
      expect(
        AssetImageResolver.imageAssetFor('img.door'),
        'assets/images/img.door.webp',
      );
      expect(
        AssetImageResolver.imageAssetFor('img.duck'),
        'assets/images/img.duck.webp',
      );
      expect(
        AssetImageResolver.imageAssetFor('img.big-door'),
        'assets/images/img.big-door.webp',
      );
    });

    test('a raw assets/images path passes through unchanged', () {
      expect(
        AssetImageResolver.imageAssetFor('assets/images/img.door.webp'),
        'assets/images/img.door.webp',
      );
    });

    test('an unknown imageId resolves to null (nothing to render)', () {
      expect(AssetImageResolver.imageAssetFor('does.not.exist'), isNull);
      expect(AssetImageResolver.imageAssetFor('img.nope'), isNull);
    });

    test('empty / whitespace / foreign-path inputs resolve to null', () {
      expect(AssetImageResolver.imageAssetFor(''), isNull);
      expect(AssetImageResolver.imageAssetFor('   '), isNull);
      expect(
        AssetImageResolver.imageAssetFor('assets/icons/door.svg'),
        isNull,
      );
    });
  });
}
