# Bundled pronunciation clips — `assets/audio/`

These are the **bundled, offline** pronunciation clips for the baa (ب) Letter
Unit (S1-06). A tappable Play button across the unit sections (Meet, the Listen
card, Words, Listen & write) plays one of these clips **with no network round-trip
and no TTS** (PLAT-01 / T-07-02-04). They are loaded by
[`AssetLetterAudioPlayer`](../../lib/services/asset_audio_player.dart), which
resolves a Schema-v2 `audioId` to the asset path in the manifest below.

## Audio package

| Package | Constraint (pubspec.yaml) | Resolved version |
|---------|---------------------------|------------------|
| [`audioplayers`](https://pub.dev/packages/audioplayers) | `^6.5.0` | latest stable **6.x** (see note) |

- **Approval:** the package was approved by the owner at the blocking-human
  package-legitimacy gate (07-02 Checkpoint): *audioplayers, latest stable 6.x*.
  `audioplayers` is a long-standing, verified-publisher community package on
  pub.dev with strong pub-points/likes and active releases; it plays a bundled
  Flutter asset offline on Android via `AssetSource` — exactly the offline,
  no-TTS posture this unit requires.
- **Resolved version note:** the `^6.5.0` caret constraint resolves to the
  current latest stable 6.x at `flutter pub get` time. The exact resolved
  version is pinned in `pubspec.lock` after `pub get` runs; see
  `07-02-SUMMARY.md` for the value recorded by the verification wave (the
  executor environment could not run `flutter pub get` — network-restricted —
  so the lockfile pin is captured when the flutter gates run).

## audioId → asset manifest

Every `audioId` the player resolves maps to a bundled file here. **This table
and the `_audioIdToAsset` map in `asset_audio_player.dart` are both GENERATED**
from `tools/audio_pipeline/audio_manifest.json` — the single source of truth.
Do not hand-edit either; edit the manifest and run `python -m audio_pipeline
generate` (from `tools/`). `python -m audio_pipeline check` fails on any drift.

<!-- BEGIN GENERATED (audio_manifest) -->
<!-- Generated from tools/audio_pipeline/audio_manifest.json — do not edit by hand. -->
<!-- Regenerate: `python -m audio_pipeline generate` (from tools/). -->

| audioId | asset path | used by | status |
|---------|-----------|---------|--------|
| `snd.alif` | `assets/audio/snd.alif.mp3` | alif Letter Unit (Meet / trace) | draft-tts (interim AI voice) |
| `snd.baa` | `assets/audio/snd.baa.mp3` | baa Letter Unit (Meet / trace / teach card) | draft-tts (interim AI voice) |
| `snd.taa` | `assets/audio/snd.taa.mp3` | taa Letter Unit (Meet / trace / teach card) | draft-tts (interim AI voice) |
| `snd.thaa` | `assets/audio/snd.thaa.mp3` | Reserved — thaa unit not authored yet | draft-tts (interim AI voice) |
| `snd.jeem` | `assets/audio/snd.jeem.mp3` | Reserved — jeem unit not authored yet | draft-tts (interim AI voice) |
| `snd.haa_c` | `assets/audio/snd.haa_c.mp3` | Reserved — haa unit not authored yet | draft-tts (interim AI voice) |
| `snd.khaa` | `assets/audio/snd.khaa.mp3` | Reserved — khaa unit not authored yet | draft-tts (interim AI voice) |
| `snd.daal` | `assets/audio/snd.daal.mp3` | Reserved — daal unit not authored yet | draft-tts (interim AI voice) |
| `snd.dhaal` | `assets/audio/snd.dhaal.mp3` | Reserved — dhaal unit not authored yet | draft-tts (interim AI voice) |
| `snd.raa` | `assets/audio/snd.raa.mp3` | Reserved — raa unit not authored yet | draft-tts (interim AI voice) |
| `snd.zaay` | `assets/audio/snd.zaay.mp3` | Reserved — zaay unit not authored yet | draft-tts (interim AI voice) |
| `snd.seen` | `assets/audio/snd.seen.mp3` | Reserved — seen unit not authored yet | draft-tts (interim AI voice) |
| `snd.sheen` | `assets/audio/snd.sheen.mp3` | Reserved — sheen unit not authored yet | draft-tts (interim AI voice) |
| `snd.saad` | `assets/audio/snd.saad.mp3` | Reserved — saad unit not authored yet | draft-tts (interim AI voice) |
| `snd.daad` | `assets/audio/snd.daad.mp3` | Reserved — daad unit not authored yet | draft-tts (interim AI voice) |
| `snd.taa_h` | `assets/audio/snd.taa_h.mp3` | Reserved — taa_h unit not authored yet | draft-tts (interim AI voice) |
| `snd.zhaa` | `assets/audio/snd.zhaa.mp3` | Reserved — zhaa unit not authored yet | draft-tts (interim AI voice) |
| `snd.ayn` | `assets/audio/snd.ayn.mp3` | Reserved — ayn unit not authored yet | draft-tts (interim AI voice) |
| `snd.ghayn` | `assets/audio/snd.ghayn.mp3` | Reserved — ghayn unit not authored yet | draft-tts (interim AI voice) |
| `snd.faa` | `assets/audio/snd.faa.mp3` | Reserved — faa unit not authored yet | draft-tts (interim AI voice) |
| `snd.qaaf` | `assets/audio/snd.qaaf.mp3` | Reserved — qaaf unit not authored yet | draft-tts (interim AI voice) |
| `snd.kaaf` | `assets/audio/snd.kaaf.mp3` | Reserved — kaaf unit not authored yet | draft-tts (interim AI voice) |
| `snd.laam` | `assets/audio/snd.laam.mp3` | Reserved — laam unit not authored yet | draft-tts (interim AI voice) |
| `snd.meem` | `assets/audio/snd.meem.mp3` | Reserved — meem unit not authored yet | draft-tts (interim AI voice) |
| `snd.noon` | `assets/audio/snd.noon.mp3` | Reserved — noon unit not authored yet | draft-tts (interim AI voice) |
| `snd.haa_f` | `assets/audio/snd.haa_f.mp3` | Reserved — haa_f unit not authored yet | draft-tts (interim AI voice) |
| `snd.waaw` | `assets/audio/snd.waaw.mp3` | Reserved — waaw unit not authored yet | draft-tts (interim AI voice) |
| `snd.yaa` | `assets/audio/snd.yaa.mp3` | Reserved — yaa unit not authored yet | draft-tts (interim AI voice) |
| `word.baab` | `assets/audio/word.baab.mp3` | baa unit (writeWord dictation) | draft-tts (interim AI voice) |
| `word.batta` | `assets/audio/word.batta.mp3` | baa unit (writeLetter fromSound) | draft-tts (interim AI voice) |
| `word.haliib` | `assets/audio/word.haliib.mp3` | baa unit (Words-with-Baa grid) | draft-tts (interim AI voice) |
| `word.taaj` | `assets/audio/word.taaj.mp3` | taa unit | draft-tts (interim AI voice) |
| `word.tuut` | `assets/audio/word.tuut.mp3` | taa unit | draft-tts (interim AI voice) |
| `word.bayt` | `assets/audio/word.bayt.mp3` | baa/taa vocab | draft-tts (interim AI voice) |
| `word.asad` | `assets/audio/word.asad.mp3` | alif unit | draft-tts (interim AI voice) |
| `word.umm` | `assets/audio/word.umm.mp3` | alif unit | draft-tts (interim AI voice) |
| `sentence.albaab-kabiir` | `assets/audio/sentence.albaab-kabiir.mp3` | baa unit (buildSentence hear) | draft-tts (interim AI voice) |
| `sentence.attaaj-jamiil` | `assets/audio/sentence.attaaj-jamiil.mp3` | taa unit (buildSentence) | draft-tts (interim AI voice) |
| `sentence.alasad-kabiir` | `assets/audio/sentence.alasad-kabiir.mp3` | alif unit (buildSentence) | draft-tts (interim AI voice) |
<!-- END GENERATED -->

### Real vs draft-tts — and why the build stays green

The `status` column above is the honest state of each clip. Today every clip is
**draft-tts**: an interim AI voice (ElevenLabs, via `tools/tts/generate_audio.py`),
not the real recording. The **real** recordings are an **owner deliverable**: the
owner's + mother's voice saying each sound/word (the same source-of-truth that
owns the curriculum). A clip is only marked **real** once a human recording drops
in — normalize it through `tools/audio_pipeline/` and set its `status` to `real`
in the manifest. Until then the draft-tts clips ship in their place.

The build, tests, and trace loop are **green regardless** of whether a given clip
is real or placeholder, because:

- An `audioId` that is **not** in `_audioIdToAsset` (e.g. a clip for another
  letter not yet wired, or any typo) resolves to `null` → `playLetter` is a
  **silent no-op** (never throws, never blocks the child — T-07-02-04).
- A mapped clip that is missing or undecodable is caught and swallowed inside
  `playLetter` — same silent degrade.

So Play is always safe to tap; a missing recording simply produces no sound
rather than an error.

## Owner deliverable — replacing a placeholder with a real recording

1. Record the clip (short, clean, the owner's-mother's voice). Export to `.mp3`.
2. Replace the placeholder file at the asset path above (keep the same filename
   so no code change is needed), **or** add a new file + a new row here and a new
   entry in `_audioIdToAsset` for a brand-new `audioId` (e.g. `word.<new>`).
3. `assets/audio/` is already declared in `pubspec.yaml` (`flutter.assets`), so a
   replaced or added file is bundled on the next build — no pubspec change for a
   like-named replacement.
