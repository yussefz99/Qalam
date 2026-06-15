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

Every `audioId` the player resolves maps to a bundled file here. The
`_audioIdToAsset` map in `asset_audio_player.dart` is the code-side mirror of
this table — **keep them in lockstep.**

| audioId | asset path | used by (baa unit) | real vs placeholder |
|---------|-----------|--------------------|---------------------|
| `snd.baa` | `assets/audio/snd.baa.mp3` | Meet card + `baa.traceLetter.isolated` + `baa.teachCard.meet` (the letter's sound) | **PLACEHOLDER** |
| `word.baab` | `assets/audio/word.baab.mp3` | `baa.writeWord.dictation` (باب — "door") | **PLACEHOLDER** |
| `word.batta` | `assets/audio/word.batta.mp3` | `baa.writeLetter.fromSound` (بطة — "duck") | **PLACEHOLDER** |
| `sentence.albaab-kabiir` | `assets/audio/sentence.albaab-kabiir.mp3` | `baa.buildSentence.hear` (البابُ كبير — "the door is big") | **PLACEHOLDER** |
| `word.haliib` | `assets/audio/word.haliib.mp3` | the حليب ("milk") card in the Words-with-Baa grid (`WordsSection`) | **PLACEHOLDER** (interim ElevenLabs) |

### Real vs placeholder — and why the build stays green

All clips above are currently **PLACEHOLDER**. The **real** recordings are an
**owner deliverable**: the pronunciations are the owner's-mother's voice saying
each sound/word (the same source-of-truth that owns the curriculum). Until she
records them, placeholder clip files ship in their place.

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
