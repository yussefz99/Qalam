---
phase: quick-260615-tqu
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - pubspec.yaml
  - lib/services/asset_image_resolver.dart
  - lib/providers/image_providers.dart
  - lib/features/letter_unit/widgets/prompt_header.dart
  - test/services/asset_image_resolver_test.dart
  - test/features/letter_unit/prompt_header_test.dart
autonomous: true
requirements: [S1-quick-baa-images]

must_haves:
  truths:
    - "The baa unit's three vocab images (door باب, duck بطة, the big-door sentence scene) display in the prompt header instead of the hatched imageId stub."
    - "An unknown / unmapped imageId still renders the existing hatched stub — a missing image never breaks the build or the trace loop (silent degrade, mirroring audio)."
    - "assets/images/ is bundled by the build (declared in pubspec.yaml flutter.assets)."
  artifacts:
    - path: "lib/services/asset_image_resolver.dart"
      provides: "imageId -> bundled asset path resolver (img.door/img.duck/img.big-door), null for unknown ids"
      contains: "imageAssetFor"
    - path: "lib/providers/image_providers.dart"
      provides: "Riverpod provider exposing the image resolver, mirroring audio_providers.dart"
    - path: "test/services/asset_image_resolver_test.dart"
      provides: "resolver returns correct paths for the 3 ids + null for unknown/empty"
  key_links:
    - from: "lib/features/letter_unit/widgets/prompt_header.dart"
      to: "lib/services/asset_image_resolver.dart"
      via: "_ImagePart resolves imageId -> path, renders Image.asset with errorBuilder fallback to the stub"
      pattern: "imageAssetFor"
    - from: "pubspec.yaml"
      to: "assets/images/"
      via: "flutter.assets declaration"
      pattern: "assets/images/"
---

<objective>
Wire the baa Letter Unit's three vocab illustrations into the app so they actually
render. The `.webp` assets already exist on disk (`assets/images/img.door.webp`,
`assets/images/img.duck.webp`, `assets/images/img.big-door.webp`) but nothing
displays them — `_ImagePart` in `prompt_header.dart` still draws a 128×84 hatched
aqua box with the `imageId` as Text, there is no imageId→asset resolver in `lib/`,
and `assets/images/` is not even bundled (absent from `pubspec.yaml`).

This plan mirrors the EXISTING audio pattern exactly (`AssetLetterAudioPlayer` +
`audioPlayerProvider`): a pure `imageId → bundled asset path` resolver that returns
null for unknown ids, exposed via a Riverpod provider, consumed by `_ImagePart`
which renders `Image.asset` and **falls back to the existing hatched stub** on an
unknown id or a load error — the same never-block / silent-degrade posture as audio.

Purpose: make the baa unit's pictures real (door / duck / "the door is big" scene)
while keeping a missing image strictly non-fatal to the trace loop.
Output: a new image resolver service + provider, a bundled `assets/images/`,
`_ImagePart` rendering real images, and tests mirroring the audio/widget suites.

Scope guardrails (do NOT exceed): only the three baa-unit images are wired. Do NOT
touch the schema, the exercise/engine model, content drafts, `manifest.json`, or
`tools/illustrations/build_manifest.py`. The resolver keys on the EXERCISE-CONFIGS
imageIds (`img.door`/`img.duck`/`img.big-door`), NOT on the manifest's translit
canonical ids.
</objective>

<execution_context>
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/workflows/execute-plan.md
@/Users/mareekhalila/Documents/Qalam/qalam/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@.planning/STATE.md

# THE PATTERN TO MIRROR (audio) — reproduce its shape for images:
@lib/services/asset_audio_player.dart
@lib/providers/audio_providers.dart
@test/services/asset_audio_player_test.dart
@assets/audio/README.md

# The stub to replace + the widget test to extend:
@lib/features/letter_unit/widgets/prompt_header.dart
@test/features/letter_unit/prompt_header_test.dart

# The image set + its placeholder-swappable convention + the id-collision caveat:
@assets/images/manifest.json
@assets/images/ILLUSTRATION-STYLE.md
@docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Image resolver + Riverpod provider (mirror the audio seam) + bundle assets/images/</name>
  <files>lib/services/asset_image_resolver.dart, lib/providers/image_providers.dart, test/services/asset_image_resolver_test.dart, pubspec.yaml</files>
  <behavior>
    - imageAssetFor('img.door') == 'assets/images/img.door.webp'
    - imageAssetFor('img.duck') == 'assets/images/img.duck.webp'
    - imageAssetFor('img.big-door') == 'assets/images/img.big-door.webp'
    - imageAssetFor('does.not.exist') == null  (unknown id → nothing to render)
    - imageAssetFor('') == null  and  imageAssetFor('   ') == null  (empty/whitespace)
    - A raw 'assets/images/...' path passes through unchanged (defensive, like audio's path pass-through); a foreign path (e.g. 'assets/icons/x.svg') → null.
  </behavior>
  <action>
    Create `lib/services/asset_image_resolver.dart` mirroring `asset_audio_player.dart`'s pure-resolver shape. Define a static const `_imageDir = 'assets/images'` and a static const `Map<String,String> _imageIdToAsset` with EXACTLY the three EXERCISE-CONFIGS imageIds keyed to their on-disk files: `img.door` → `$_imageDir/img.door.webp`, `img.duck` → `$_imageDir/img.duck.webp`, `img.big-door` → `$_imageDir/img.big-door.webp`. Expose a static `String? imageAssetFor(String imageId)` with the same resolution order as `audioAssetFor`: trim; empty → null; known id → mapped path; a raw path already under `$_imageDir/` → pass through; anything else → null. Add a class-level doc comment matching the audio file's tone — note the never-render-fail posture and the placeholder-swappable-by-imageId convention (assets/audio/README.md equivalent), and add a short NOTE documenting the parked manifest id collision (`img.door` engine-gloss vs `img.door` translit "houses"): the engine resolves by EXERCISE-CONFIGS ids so the on-disk files are correct here; do NOT resolve the manifest collision in this task — just surface it in the comment.

    Create `lib/providers/image_providers.dart` mirroring `audio_providers.dart`: declare an `abstract interface class LetterImageResolver { String? assetFor(String imageId); }`, a `NoopLetterImageResolver` (always returns null, the never-render reference + test default), and a `final imageResolverProvider = Provider<LetterImageResolver>((ref) => const AssetLetterImageResolver());`. Have `AssetLetterImageResolver` implement the interface by delegating `assetFor` to `AssetImageResolver.imageAssetFor` (the static pure resolver). Riverpod only — no new state libs (D-11). No `dispose` needed (no native resources, unlike the audio player).

    Edit `pubspec.yaml`: under `flutter.assets`, add `    - assets/images/` (keep alphabetical-ish placement near the other asset dirs; matches the indentation of the existing `- assets/audio/` line). This is what makes the three `.webp` files actually bundle.

    Create `test/services/asset_image_resolver_test.dart` mirroring `asset_audio_player_test.dart`: a `group('AssetImageResolver.imageAssetFor (pure resolution)')` asserting the three known ids resolve to their `.webp` paths, the raw-path pass-through, and that unknown / empty / whitespace / foreign-path inputs resolve to null (the <behavior> cases above).
  </action>
  <verify>
    <automated>cd "c:/Users/yusse/OneDrive/Desktop/Qalam" && flutter test test/services/asset_image_resolver_test.dart</automated>
  </verify>
  <done>asset_image_resolver.dart + image_providers.dart exist mirroring the audio seam; the three EXERCISE-CONFIGS imageIds resolve to their on-disk .webp paths and unknown/empty inputs resolve to null; `assets/images/` is declared under flutter.assets in pubspec.yaml; the resolver test passes.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Render real images in _ImagePart with silent-degrade fallback to the stub</name>
  <files>lib/features/letter_unit/widgets/prompt_header.dart, test/features/letter_unit/prompt_header_test.dart</files>
  <behavior>
    - _ImagePart given imageId 'img.door' (which resolves to a bundled path) renders an Image.asset (not the hatched-stub Text), still inside the 128×84 / radius-14 box, with the caption beneath if present.
    - _ImagePart given an UNKNOWN imageId (e.g. 'img.nope', which resolves to null) renders the EXISTING hatched stub showing the imageId as Text — exactly today's behavior. A missing/unmapped image never throws and never breaks the header.
    - (Already-passing baa tests in this suite — say/audio/rule, __blank__, reveal, forms, empty header, the FeedbackPanel + ProgressRibbon groups — stay green.)
  </behavior>
  <action>
    In `prompt_header.dart`, make `_ImagePart` resolve `imageId` through the pure resolver `AssetImageResolver.imageAssetFor(imageId)` (import `../../../services/asset_image_resolver.dart`). Keep `_ImagePart` a plain `StatelessWidget` — use the STATIC pure resolver directly so the widget needs no Riverpod wiring (the provider from Task 1 exists for any future Consumer call site but `_ImagePart` itself stays a leaf widget, consistent with how `_AudioPart` takes plain inputs). Refactor the build so the 128×84 box (color softAqua, radius 14, aquaEdge border) is shared, and its CHILD is chosen by resolution: when `imageAssetFor` returns a non-null path, render `Image.asset(path, fit: BoxFit.cover, errorBuilder: (context, error, stack) => <the existing hatched imageId Text chip>)` clipped to the radius-14 box (e.g. wrap the box decoration's child / use ClipRRect so the image honors the rounded corners); when it returns null, render the existing hatched imageId Text chip unchanged. Factor the hatched chip (the inner `surfaceRaised.withValues(alpha:0.85)` rounded container holding `Text(imageId, …)`) into a small private helper so BOTH the unknown-id branch and the Image.asset errorBuilder reuse it — that guarantees the SAME silent-degrade fallback whether the id is unmapped OR the file fails to load. Preserve the caption Column beneath unchanged. Do NOT change `_ImagePart`'s constructor signature, the `_renderPart` switch, or any other part kind.

    Extend `test/features/letter_unit/prompt_header_test.dart` (in the `PromptHeader` group, reusing the existing `_pump` helper): add a test that an `ImagePart('img.door')` renders an `Image` widget (e.g. `find.byType(Image)` finds one, and the stub Text 'img.door' is NOT shown). Add a second test that an `ImagePart('img.nope')` (unknown id) renders the hatched stub — `find.text('img.nope')` finds one widget and `find.byType(Image)` finds nothing — proving the silent fallback. (Image.asset for a bundled-but-unloadable asset in flutter_test will hit the errorBuilder; asserting the unknown-id → stub path is the deterministic check, so prefer the unknown-id case for the fallback assertion.)
  </action>
  <verify>
    <automated>cd "c:/Users/yusse/OneDrive/Desktop/Qalam" && flutter test test/features/letter_unit/prompt_header_test.dart</automated>
  </verify>
  <done>_ImagePart renders Image.asset for a mapped imageId (sized to the 128×84 radius-14 box) and falls back to the existing hatched imageId stub for an unknown id or a load error; the new image-render + image-fallback tests pass and all pre-existing prompt_header tests stay green.</done>
</task>

<task type="auto">
  <name>Task 3: Full-suite regression + analyzer gate</name>
  <files>(no new files — verification only)</files>
  <action>
    Confirm the wiring is non-breaking across the app. Run the analyzer and the full test suite. Resolve any analyzer warning introduced by the new files (unused import, missing trailing comma, etc.). If `flutter` cannot run in this environment (network/SDK restriction, as seen for `flutter pub get` in 07-02), record that clearly in the SUMMARY and capture the exact commands so the verification wave runs them — do NOT silently skip the gate.
  </action>
  <verify>
    <automated>cd "c:/Users/yusse/OneDrive/Desktop/Qalam" && flutter analyze && flutter test</automated>
  </verify>
  <done>`flutter analyze` is clean for the changed files and the full `flutter test` suite passes (or, if Flutter cannot run here, the SUMMARY records the exact gate commands for the verification wave and notes the environment restriction).</done>
</task>

</tasks>

<verification>
- `assets/images/` appears under `flutter.assets` in pubspec.yaml (grep `assets/images/`).
- `lib/services/asset_image_resolver.dart` exposes `imageAssetFor` returning the three `.webp` paths and null for unknown/empty (resolver test green).
- `lib/providers/image_providers.dart` exposes a Riverpod `imageResolverProvider` mirroring `audioPlayerProvider` (Provider, Noop default available for tests).
- `_ImagePart` renders `Image.asset` for a mapped id and the hatched stub for an unmapped id / load error (widget tests green).
- `flutter analyze` clean; full `flutter test` suite passes (or gate commands recorded if Flutter unavailable).
</verification>

<success_criteria>
The baa unit's three vocab images (باب door, بطة duck, the البابُ كبير "the door is big" scene) display in the prompt header. An unknown or unloadable image silently falls back to the existing hatched stub — never an error, never a blocked trace loop — exactly mirroring the audio seam's never-block posture. No schema/engine/manifest/tooling files were touched; the parked manifest id-collision is documented in a code comment, not resolved.
</success_criteria>

<output>
Create `.planning/quick/260615-tqu-wire-baa-unit-vocab-illustrations-into-t/260615-tqu-SUMMARY.md` when done.
</output>
