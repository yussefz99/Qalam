# TASK (for the partner + agent): Generate the interim ElevenLabs audio set

**Owner of this task:** Partner (running an agent).
**Goal:** Generate **interim pronunciation audio** for the whole curriculum via **ElevenLabs**,
keyed by `audioId`, so the app's audio is functional now. These are **placeholders** — the owner's
mother's real recordings replace them later by overwriting the file of the same name (no code change).

The pipeline is already built and portable: **`tools/tts/generate_audio.py`** (uses `curl`, works on
any machine, no Python TLS setup). This task = pick a voice, build the full manifest from the
inventory, run it.

---

## Prereqs (owner provides)
- **ElevenLabs API key with API access.** Put it in **`tools/tts/.env`** (gitignored — never commit):
  ```
  ELEVENLABS_API_KEY=sk_...
  ELEVENLABS_VOICE_ID=<set in step 1>
  ```
  *(The owner has a working key; he shares it with you securely — not via git/chat. Free-tier API may
  require a card; the ~$5 Starter plan covers the whole curriculum, one-time.)*

## Steps
1. **Pick + lock a voice.** Run `python3 tools/tts/generate_audio.py --list-voices`.
   **Recommended:** add a **native Arabic voice** from the ElevenLabs **Voice Library**
   (Voices → Library → filter Arabic → Add to my voices) for correct pronunciation — the default
   English voices speak Arabic with an accent. Put its id in `ELEVENLABS_VOICE_ID`.
2. **Build the full manifest** `tools/tts/manifest.full.json` — a JSON list of `{ "id", "text" }`:
   - **Letter sounds:** `snd.<letter>` for all 28 (e.g. `snd.baa`).
   - **Vocab:** `word.<translit>` for every vocab word in
     `.planning/research/learning-experience/CONTENT-INVENTORY.json` (dedupe).
   - **Sentences:** `sentence.<id>` — baa's exist in `EXERCISE-CONFIGS.json`; others land as content
     is drafted (re-run later to add them).
   - **Match existing `audioId`s** already used in
     `docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json` (`snd.baa`, `word.baab`, `word.batta`, `sentence.albaab-kabiir`).
   - **Tashkeel:** vowel the Arabic text where you can — ElevenLabs pronounces `بَابٌ` far better than
     `باب`. (Interim quality only; final is her voice.)
3. **Generate:** `python3 tools/tts/generate_audio.py tools/tts/manifest.full.json assets/audio`
   → writes `assets/audio/<audioId>.mp3`.
4. **Spot-check** a handful (especially letter sounds — those are the hardest for any TTS; flag the
   bad ones as first candidates for the mother's real recording).

## Canonical refs
- `tools/tts/generate_audio.py` — the pipeline (curl-based; already works).
- `.planning/research/learning-experience/CONTENT-INVENTORY.json` — the vocab source.
- `docs/design/prototypes/letter-unit-baa/EXERCISE-CONFIGS.json` — existing `audioId`s to match.
- `.planning/research/learning-experience/SCHEMA-V2.md` — the `audioId` field these map to.

## Guardrails
- **Never commit the key** — `tools/tts/.env` is gitignored; keep it that way.
- **One consistent voice** for the whole set.
- Audio is a **placeholder, swappable by `audioId`** — same pattern as the illustrations.
- This task only adds `assets/audio/*` + the manifest. **Don't touch** `lib/`, the schema, the
  content drafts, or the illustration assets. *(The `pubspec.yaml` `assets/audio/` declaration is an
  engine concern — coordinate, it's a one-line add.)*

## Acceptance criteria
- A locked `ELEVENLABS_VOICE_ID` (ideally a native Arabic voice).
- Every vocab word + all 28 letter sounds have an `assets/audio/<audioId>.mp3`, in one voice.
- `tools/tts/manifest.full.json` exists and is re-runnable (so new sentences regenerate easily).
- The key is not committed.

## Dependency note
Letter sounds + **all vocab** can be generated **now** (the inventory exists). **Sentences /
exercise-specific clips** for letters beyond baa arrive as the content is drafted (Track B) — just
re-run the script after adding them to the manifest; existing files are overwritten idempotently.

---

## Paste-ready agent prompt (partner runs this)

> Read `.planning/research/learning-experience/TASK-audio.md` and do it. The ElevenLabs key is in
> `tools/tts/.env` (gitignored — never commit it). First run `python3 tools/tts/generate_audio.py
> --list-voices`; add a **native Arabic voice** from the ElevenLabs Voice Library and set its id as
> `ELEVENLABS_VOICE_ID` in `.env`. Then build `tools/tts/manifest.full.json` ({id,text}) covering all
> 28 letter sounds (`snd.<letter>`) + every vocab word in `CONTENT-INVENTORY.json` (`word.<translit>`,
> deduped, voweled where possible), matching existing `audioId`s in `EXERCISE-CONFIGS.json`. Run
> `python3 tools/tts/generate_audio.py tools/tts/manifest.full.json assets/audio`. Keep one voice,
> flag bad letter-sounds for the mother, never commit the key, and don't touch engine code, the
> schema, the content drafts, or the image assets.
