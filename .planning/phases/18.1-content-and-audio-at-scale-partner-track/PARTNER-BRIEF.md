# Phase 18.1 — Partner Brief: Content & Audio at Scale

**Who this is for:** the partner joining Qalam to build the content/audio track in
parallel with Phase 19. Everything you need is in this document. If you use Claude
Code, paste this whole file (or point Claude at it) as your working instructions.

**What Qalam is:** an Android tablet app that teaches children to *write* Arabic by
hand, stroke by stroke, with a warm AI tutor. "Real Arabic. Not a game." No points,
no streaks, no badges — ever. The curriculum (stroke order, word choice, what counts
as mastery) is authored by the owner's mother, a veteran Arabic teacher. **You never
invent pedagogy or child-facing content — you draft, structure, and pipeline it; she
signs it.** Anything model- or partner-authored is marked draft/unsigned until then.

---

## Setup

```bash
git clone https://github.com/yussefz99/Qalam.git && cd Qalam   # or: git pull on main
git checkout -b content/18.1-audio-content main
```

- **Python 3.11+** for ALL tooling (project rule: Python over TypeScript/Dart for tools).
- **ffmpeg** installed (audio processing).
- Flutter is OPTIONAL — you only need it to run the app, not for this work. If you do:
  `flutter pub get && flutter gen-l10n` first (generated l10n files are gitignored).

**Workflow:** small commits, push your branch, open PRs to `main` — one track per PR.
The owner merges. Don't commit directly to `main`.

---

## HARD BOUNDARIES — read first

Phase 19 (the owner's parallel work) owns these paths. **Never edit them:**

- `lib/features/letter_unit/` — all exercise presentation widgets
- `lib/data/` — the local database layer (a migration is in flight)
- `assets/curriculum/exercises.json` and `assets/curriculum/curriculum_graph.json`
- `server/` — the deployed tutor backend
- `.planning/` — project orchestration state (except adding files inside THIS phase's folder)

The **only** file you and the owner both touch is `lib/services/asset_audio_player.dart`,
and only its generated map block (Track A explains how). Reading anything anywhere is fine.

Also standing rules you must respect in anything you produce:
- **No gamification language or imagery** anywhere (no points, stars-as-score, streaks, badges).
- **Children's data is sacred** — your tools must never collect, log, or need any.
- **Nothing unsigned ships**: your outputs are drafts until the mother signs them.

---

## Track A — Audio pipeline + real pronunciation clips

**Today:** `assets/audio/` has 40 mp3s — 28 letter sounds (`snd.<letterId>.mp3`),
8 words, 3 sentences — and **every one is a placeholder** (see `assets/audio/README.md`).
The app plays them offline via `AssetLetterAudioPlayer`
(`lib/services/asset_audio_player.dart`), which resolves an `audioId` through a
hand-maintained `_audioIdToAsset` map that must stay in lockstep with the README
table. Hand-maintained lockstep will not survive 28 letters × N words. Fix that.

**Build `tools/audio_pipeline/` (Python):**

1. **Single manifest** — `tools/audio_pipeline/audio_manifest.json`, the one source of
   truth. Per entry: `audioId`, `assetPath`, `description`, `usedBy`, and
   `status: "real" | "placeholder" | "draft-tts"`. Seed it from the current README table.
2. **Ingest + normalize** — take raw recordings (wav/m4a/mp3, any sane format) from a
   staging folder, then per clip: trim leading/trailing silence, loudness-normalize
   (EBU R128, target ≈ −16 LUFS, mono), resample 44.1 kHz, encode mp3, write to
   `assets/audio/` under the naming convention:
   - `snd.<letterId>.mp3` — the letter's sound. The 28 letterIds (from
     `assets/curriculum/letters.json`): alif, baa, taa, thaa, jeem, haa_c, khaa, daal,
     dhaal, raa, zaay, seen, sheen, saad, daad, taa_h, zhaa, ayn, ghayn, faa, qaaf,
     kaaf, laam, meem, noon, haa_f, waaw, yaa.
   - `word.<wordId>.mp3` / `sentence.<sentenceId>.mp3` — ids are lowercase
     transliterations (see existing files).
3. **Generators** — from the manifest, regenerate:
   - the audioId table in `assets/audio/README.md`, and
   - the `_audioIdToAsset` map in `lib/services/asset_audio_player.dart`.
   Wrap both regions in `// BEGIN GENERATED (audio_manifest)` / `// END GENERATED`
   markers on first run (markdown comments in the README) and only ever rewrite
   between the markers. Touch nothing else in the Dart file.
4. **Check mode** — `python -m audio_pipeline check` exits non-zero if any manifest
   entry lacks a file, any file lacks an entry, or the generated blocks are stale.

**Voice:** whose voice records the real clips is the owner + mother's decision — build
the pipeline voice-agnostic. You MAY produce interim clips with high-quality Arabic
TTS to prove the pipeline end-to-end, but they get `status: "draft-tts"` — never
`"real"`. The definition of done for the 28 letter sounds is real human recordings.

---

## Track B — Vocabulary bank + word validator

**Today:** `assets/curriculum/words.json` has **8 words** for a 28-letter curriculum.
The schema is exactly this (keep it):

```json
{ "id": "baab", "text": "باب", "audio": "word.baab", "image": "img.door",
  "gloss": { "en": "door" }, "letters": ["baa", "alif", "baa"] }
```

**Build `tools/content/` (Python):**

1. **Draft bank** — `tools/content/words_draft.json`, same schema per word plus
   `"source"` (which teaching document it came from) and `"signedOff": false`.
   **Do NOT edit the live `assets/curriculum/words.json`** — the owner promotes words
   there only after the mother signs. Sources: the mother's teaching materials (the
   owner will drop exports into `docs/curriculum/source/`) and
   `docs/curriculum/national-curriculum-grade1.md` (already in the repo).
   Target: meaningful coverage for all 28 letters (a handful of good words each beats
   an exhaustive list).
2. **Letter decomposition** — compute `letters[]` from the Arabic string, mapped to
   the 28 letterIds. Handle the traps explicitly rather than silently: hamza forms
   (أ إ آ ء ؤ ئ), taa marbuta (ة), alif maqsura (ى), lam-alif (لا), shadda/diacritics
   (strip harakat before decomposing). Any character you can't map to the 28 →
   flag the word in a report, don't guess.
3. **Validator** — `python -m content.validate` reads `letters.json` intro order
   (`introOrder` field) and reports, per letter/unit: which draft words are legal
   (all their letters already introduced) and which are not, with the earliest unit
   each word becomes legal. Also run it read-only against the LIVE
   `assets/curriculum/words.json` + `exercises.json` and report any existing content
   that demands unlearned letters — that report goes straight into the owner's
   Phase 19 card-rewrite session with the mother.

---

## Track C — Sign-off review packets

**Today:** all 28 letters in `assets/curriculum/letters.json` have model-drafted
stroke data (`referenceStrokes`, `commonMistakes`, `forms`, `cleanRepsToAdvance`)
but only 2 (baa, taa) are signed off. The bottleneck is the mother's review time.
Make each review take minutes, not half an hour.

**Build `tools/review_packets/` (Python):**

1. For each letter with `signedOff: false` (26 of them), generate one self-contained
   HTML page: the letter char + name, its four forms, the reference strokes drawn as
   SVG paths with **stroke-order numbering and direction arrows**, the
   `commonMistakes` list, and `cleanRepsToAdvance` — followed by a review checklist
   (approve / needs-correction + a notes line per section).
2. Every page is stamped clearly: **"DRAFT — model-authored, awaiting review"**.
   RTL-correct Arabic rendering; print-friendly (she may mark up on paper or iPad).
3. Output to `docs/curriculum/review-packets/<introOrder>-<letterId>.html` plus an
   `index.html` ordered by `introOrder`. Regenerable at any time from `letters.json`.

---

## Definition of done (mirrors ROADMAP Phase 18.1 success criteria)

1. Manifest-driven audio pipeline works end-to-end; README table + Dart map are
   generated, with a `check` mode that catches drift.
2. 28/28 real letter-sound recordings in `assets/audio/` (TTS drafts marked as such
   in the interim).
3. Draft vocab bank covers all 28 letters; validator report exists for the live content.
4. 26/26 review packets generated and handed to the owner for the mother's sessions.
5. `git log` shows zero commits touching the forbidden paths.

Questions or anything ambiguous: ask the owner — in this project a question is always
cheaper than a wrong autonomous build.
