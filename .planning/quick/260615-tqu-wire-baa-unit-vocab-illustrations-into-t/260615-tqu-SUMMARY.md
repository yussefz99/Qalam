---
phase: quick-260615-tqu
plan: 01
subsystem: letter-unit
tags: [letter-unit, assets, images, prompt-header, riverpod, silent-degrade]
requires:
  - lib/features/letter_unit/widgets/prompt_header.dart (the _ImagePart stub)
  - assets/images/img.door.webp, img.duck.webp, img.big-door.webp (on disk)
  - lib/services/asset_audio_player.dart (the pattern mirrored)
provides:
  - imageId -> bundled-asset-path resolver (AssetImageResolver.imageAssetFor)
  - Riverpod imageResolverProvider (+ Noop test default)
  - assets/images/ bundled under flutter.assets
  - _ImagePart renders real Image.asset with silent-degrade fallback to the stub
affects:
  - the baa Letter Unit prompt header (door / duck / big-door scenes now display)
tech-stack:
  added: []
  patterns:
    - "image resolver mirrors the audio audioAssetFor seam (pure static resolver + Riverpod provider + Noop)"
    - "silent-degrade: unknown id OR Image load error -> shared hatched stub, never throws"
key-files:
  created:
    - lib/services/asset_image_resolver.dart
    - lib/providers/image_providers.dart
    - test/services/asset_image_resolver_test.dart
  modified:
    - pubspec.yaml
    - lib/features/letter_unit/widgets/prompt_header.dart
    - test/features/letter_unit/prompt_header_test.dart
decisions:
  - "imageId keying is on EXERCISE-CONFIGS ids (img.door/img.duck/img.big-door), NOT the manifest translit canonical ids — the parked manifest id-collision is documented in a code comment, not resolved (out of scope)."
  - "_ImagePart uses the STATIC pure resolver directly (stays a leaf StatelessWidget, no Riverpod wiring), consistent with how _AudioPart takes plain inputs; imageResolverProvider exists for future Consumer call sites."
  - "the hatched stub is factored into _hatchedStub() so the unknown-id branch AND the Image.asset errorBuilder reuse the exact same fallback."
metrics:
  duration: ~12min
  completed: 2026-06-15
  tasks: 3
  files: 6
---

# Quick Task 260615-tqu: Wire baa Unit Vocab Illustrations into the Prompt Header — Summary

Wired the baa Letter Unit's three vocab illustrations (باب door, بطة duck, the
البابُ كبير "the door is big" scene) so they actually render in the prompt
header — replacing the hatched `imageId` stub — by adding a pure
`imageId → bundled-asset-path` resolver (the image twin of the audio seam),
bundling `assets/images/`, and teaching `_ImagePart` to render `Image.asset`
with a silent-degrade fallback to the existing stub.

## What was built

### Task 1 — Image resolver + Riverpod provider + bundle assets/images/ (commit `4a1ef2a`)
- `lib/services/asset_image_resolver.dart` — `AssetImageResolver.imageAssetFor(imageId)`,
  a pure static resolver mirroring `AssetLetterAudioPlayer.audioAssetFor`:
  - `img.door` → `assets/images/img.door.webp`
  - `img.duck` → `assets/images/img.duck.webp`
  - `img.big-door` → `assets/images/img.big-door.webp`
  - unknown id / empty / whitespace / foreign path → `null`
  - a raw `assets/images/...` path passes through unchanged (defensive)
- `lib/providers/image_providers.dart` — `LetterImageResolver` interface,
  `NoopLetterImageResolver` (always null; test default + never-render reference),
  `AssetLetterImageResolver` (delegates to the static resolver), and
  `final imageResolverProvider = Provider<LetterImageResolver>(...)`. Riverpod
  only (D-11); no `dispose` (no native resources, unlike the audio player).
- `pubspec.yaml` — added `- assets/images/` under `flutter.assets` (alphabetical,
  after `assets/icons/`) so the three `.webp` files bundle.
- `test/services/asset_image_resolver_test.dart` — mirrors the audio resolver
  suite: the three known ids resolve to their `.webp` paths, raw-path pass-through,
  and unknown / empty / whitespace / foreign-path inputs resolve to null.
- TDD RED was confirmed by IDE diagnostics (test referenced the not-yet-defined
  `AssetImageResolver`) before the implementation was written.

### Task 2 — Render real images in _ImagePart with silent-degrade fallback (commit `2cff97e`)
- `lib/features/letter_unit/widgets/prompt_header.dart` — `_ImagePart` now resolves
  `imageId` through `AssetImageResolver.imageAssetFor` (static; the widget stays a
  leaf `StatelessWidget`, no Riverpod wiring). The shared 128×84 / radius-14 aqua
  box now chooses its child by resolution:
  - mapped id → `Image.asset(path, fit: BoxFit.cover, errorBuilder: ...)` clipped to
    the radius-14 box via `ClipRRect`;
  - unknown id → the existing hatched `imageId` Text chip.
  - The hatched chip is factored into a private `_hatchedStub()` so BOTH the
    unknown-id branch AND the `Image.asset` `errorBuilder` reuse the identical
    fallback (a load error degrades exactly like an unmapped id).
  - The caption Column, the `_ImagePart` constructor signature, the `_renderPart`
    switch, and all other part kinds are unchanged.
- `test/features/letter_unit/prompt_header_test.dart` — two new tests in the
  `PromptHeader` group (reusing `_pump`): Test 5a (`ImagePart('img.door')` renders
  an `Image`, no `img.door` stub Text) and Test 5b (`ImagePart('img.nope')` renders
  the hatched stub — `find.text('img.nope')` found, `find.byType(Image)` nothing).

### Task 3 — Full-suite regression + analyzer gate (verification only)
- No code changes. See the gate status below.

## Verification gate status — FLUTTER UNAVAILABLE IN THIS ENVIRONMENT

The Flutter SDK is **not installed / not on PATH** in this execution environment
(consistent with the 07-02 history noted in the plan: network/SDK-restricted).
`flutter --version` returned `command not found`, and no `flutter.bat` was found
under `C:/flutter`, `C:/src/flutter`, `$HOME/flutter`, or `$LOCALAPPDATA`.

Per the task constraints, the gates are **NOT silently skipped** — the exact
commands are recorded here for the human verification wave to run:

| Gate | Command | Status |
|------|---------|--------|
| Task 1 resolver test | `flutter test test/services/asset_image_resolver_test.dart` | NOT RUN — Flutter unavailable |
| Task 2 widget test | `flutter test test/features/letter_unit/prompt_header_test.dart` | NOT RUN — Flutter unavailable |
| Task 3 analyzer | `flutter analyze` | NOT RUN — Flutter unavailable |
| Task 3 full suite | `flutter test` | NOT RUN — Flutter unavailable |

Run all from the repo root: `cd "c:/Users/yusse/OneDrive/Desktop/Qalam"`.

**Static proxy that WAS available (IDE / analyzer diagnostics via the editor):**
- After writing the resolver implementation, the test file's diagnostics cleared
  (the RED `Undefined name 'AssetImageResolver'` errors resolved on file creation).
- After the `_ImagePart` rewrite, the transient `Unused import` warning on
  `asset_image_resolver.dart` cleared (the import is now used).
- No outstanding error/warning diagnostics were reported on any of the three
  changed source files at hand-off.

Expected results when the gates run: the resolver suite (4 tests) GREEN; the
prompt_header suite GREEN including the 2 new image tests and all pre-existing
baa tests; `flutter analyze` clean for the changed files. Note the project has
4 KNOWN pre-existing out-of-scope failures (alif-reference + mastery golden, per
06.1-04 SUMMARY) that are unrelated to this change.

## Scope adherence

- ONLY the three baa-unit images were wired. Schema, exercise/engine model,
  content drafts, `assets/images/manifest.json`, and `tools/illustrations/build_manifest.py`
  were NOT touched.
- `assets/images/*.webp` and `tools/illustrations/` remain UNTRACKED in git — they
  are out of scope for this code-wiring task (assets are the owner/build deliverable);
  only the four code/config files were committed.
- The parked manifest id-collision (`img.door` engine-gloss vs `img.door` translit
  "houses") is documented in `asset_image_resolver.dart`'s class doc comment and was
  deliberately NOT resolved here.
- Riverpod only; no new state-management deps; no new packages added.

## Deviations from Plan

None — plan executed exactly as written. Rules 1–4 did not trigger.

## Known Stubs

The `_hatchedStub()` fallback is an INTENTIONAL silent-degrade path (the original
stub behavior, preserved by design for unmapped / unloadable images), not an
unfinished stub. The three target images (`img.door`/`img.duck`/`img.big-door`)
are wired to real on-disk assets, so the plan's goal is achieved. No blocking stubs.

## Commits

- `4a1ef2a` feat(260615-tqu): add imageId asset resolver + provider, bundle assets/images/
- `2cff97e` feat(260615-tqu): render real baa images in _ImagePart with silent-degrade stub

## Self-Check: PASSED

- FOUND: lib/services/asset_image_resolver.dart
- FOUND: lib/providers/image_providers.dart
- FOUND: test/services/asset_image_resolver_test.dart
- FOUND: lib/features/letter_unit/widgets/prompt_header.dart (modified)
- FOUND: test/features/letter_unit/prompt_header_test.dart (modified)
- FOUND: pubspec.yaml (assets/images/ declared)
- FOUND commit: 4a1ef2a
- FOUND commit: 2cff97e
