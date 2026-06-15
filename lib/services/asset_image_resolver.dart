// AssetImageResolver — the pure imageId → bundled-asset-path resolver for the
// baa Letter Unit's three vocab illustrations (quick task 260615-tqu). This is
// the IMAGE twin of AssetLetterAudioPlayer's `audioAssetFor`: a pure, testable
// resolver that maps a Schema-v2 `imageId` (e.g. `img.door`) to a bundled
// `assets/images/` path, returning null when there is nothing to render.
//
// NEVER-RENDER-FAIL POSTURE (mirrors the audio seam's never-block posture):
// an unknown / unmapped imageId resolves to null, and _ImagePart then falls
// back to the existing hatched stub. A missing or unloadable file is likewise
// non-fatal — _ImagePart's Image.asset errorBuilder reuses the same stub. A
// picture is an enhancement to the trace loop, never a gate on it.
//
// PLACEHOLDER-SWAPPABLE-BY-imageId convention (the assets/audio/README.md
// equivalent for art): each imageId maps to a fixed on-disk filename. Replacing
// the file under the same name swaps the illustration with no code change; the
// art is an owner deliverable (see assets/images/ILLUSTRATION-STYLE.md).
//
// NOTE — PARKED MANIFEST id COLLISION (do NOT resolve here): the illustration
// manifest (assets/images/manifest.json) carries a translit-canonical id space
// where `img.door` denotes the translit "houses" gloss, which collides with the
// ENGINE's EXERCISE-CONFIGS `img.door` (the باب "door" scene). The engine
// resolves images by the EXERCISE-CONFIGS imageIds — NOT the manifest canonical
// ids — so the on-disk files keyed below (img.door/img.duck/img.big-door) are
// correct for the baa unit as it ships. Reconciling the manifest collision is
// out of scope for this task; it is surfaced here only as a caveat.

/// Pure resolver: maps a baa-unit `imageId` (or a raw `assets/images/` path) to
/// its bundled asset path, or null when there is nothing to render. Mirrors the
/// shape of [AssetLetterAudioPlayer.audioAssetFor]; no Flutter/image-loading
/// dependency, so it is unit-testable without a rasterizer.
class AssetImageResolver {
  const AssetImageResolver._();

  /// Directory under the asset bundle where the vocab illustrations live. Must
  /// match the `flutter.assets` entry in pubspec.yaml (`assets/images/`).
  static const String _imageDir = 'assets/images';

  /// imageId → asset path under [_imageDir], for the baa Letter Unit.
  ///
  /// The imageIds the baa unit references across its content
  /// (`assets/curriculum/words.json` + `exercises.json`):
  ///   • `img.door`     باب "door"  — words grid + writeWord/teachCard prompts
  ///   • `img.duck`     بطة "duck"  — words grid + writeLetter prompt
  ///   • `img.milk`     حليب "milk" — words grid  (ART PENDING, see below)
  ///   • `img.big-door`            — the البابُ كبير "the door is big" scene
  ///
  /// Each is keyed to its on-disk `.webp`. Add a new entry (and its file) to
  /// wire another illustration. PLACEHOLDER-SWAPPABLE: an entry may be mapped
  /// before its file exists — `img.milk` has no committed art yet, so it
  /// resolves to a path that fails to load and silently degrades to the hatched
  /// stub (mirrors assets/audio/README.md's "NOT YET RECORDED" `word.haliib`).
  /// Dropping `img.milk.webp` into `assets/images/` later renders it with no
  /// code change.
  static const Map<String, String> _imageIdToAsset = <String, String>{
    'img.door': '$_imageDir/img.door.webp',
    'img.duck': '$_imageDir/img.duck.webp',
    'img.big-door': '$_imageDir/img.big-door.webp',
    'img.milk': '$_imageDir/img.milk.webp', // ART PENDING — degrades to stub
  };

  /// Pure resolver: maps an [imageId] to a bundled asset path, or null when
  /// there is nothing to render.
  ///
  /// Resolution order (mirrors [AssetLetterAudioPlayer.audioAssetFor]):
  ///   1. A known `imageId` (e.g. `img.door`) → its mapped asset path.
  ///   2. A raw asset path already under `assets/images/` → passed through.
  ///   3. Anything else (unknown id, empty string, foreign path) → null.
  static String? imageAssetFor(String imageId) {
    final String value = imageId.trim();
    if (value.isEmpty) return null;
    final String? mapped = _imageIdToAsset[value];
    if (mapped != null) return mapped;
    // Defensive pass-through: a caller that already holds a bundled image path
    // (rather than an id) still resolves. Scoped to our image dir so we never
    // try to render an arbitrary asset.
    if (value.startsWith('$_imageDir/')) return value;
    return null;
  }
}
