// Letter-image resolution seam — the IMAGE twin of audio_providers.dart (quick
// task 260615-tqu). Exposes the imageId → bundled-asset-path resolver over a
// Riverpod provider so any future Consumer call site can resolve illustrations
// through DI (and tests can override it with the Noop reference).
//
// The interface stays stable: a caller reads [imageResolverProvider] and calls
// assetFor(imageId) with a Schema-v2 imageId. [NoopLetterImageResolver] is the
// never-render reference posture (always null) and the test default — exactly
// mirroring NoopLetterAudioPlayer.
//
// Note: _ImagePart itself uses the STATIC pure resolver
// (AssetImageResolver.imageAssetFor) directly so the leaf widget needs no
// Riverpod wiring — same as how _AudioPart takes plain inputs. This provider
// exists for any future Consumer site that prefers DI. Riverpod only (D-11);
// no dispose needed (no native resources, unlike the audio player).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/asset_image_resolver.dart';

abstract interface class LetterImageResolver {
  String? assetFor(String imageId);
}

class NoopLetterImageResolver implements LetterImageResolver {
  const NoopLetterImageResolver();
  @override
  String? assetFor(String imageId) => null;
}

/// Delegates the interface to the pure [AssetImageResolver.imageAssetFor]
/// resolver. Stateless and const-constructible — there are no native resources
/// to release (unlike the audio player), so the provider needs no onDispose.
class AssetLetterImageResolver implements LetterImageResolver {
  const AssetLetterImageResolver();
  @override
  String? assetFor(String imageId) => AssetImageResolver.imageAssetFor(imageId);
}

/// The app's letter-image resolver. Returns the real
/// [AssetLetterImageResolver], which resolves a Schema-v2 `imageId` to a bundled
/// `assets/images/` path; unknown ids resolve to null so the call site falls
/// back to the hatched stub (never an error). Tests override this provider with
/// [NoopLetterImageResolver].
final imageResolverProvider = Provider<LetterImageResolver>(
  (ref) => const AssetLetterImageResolver(),
);
