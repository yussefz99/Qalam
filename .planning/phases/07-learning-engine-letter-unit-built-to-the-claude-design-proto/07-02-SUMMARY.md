---
phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto
plan: 02
subsystem: audio-playback + firestore-rules
tags: [audio, offline, firestore-rules, child-safety, schema-v2]
requires: [S1-06]
provides:
  - "AssetLetterAudioPlayer — offline bundled-clip playback over the LetterAudioPlayer seam"
  - "words/exercises/units Firestore rules — read-requires-auth + client-write-denied"
affects:
  - lib/providers/audio_providers.dart
  - lib/features/practice/practice_screen.dart (consumer — unchanged seam)
  - firestore.rules
tech-stack:
  added:
    - "audioplayers ^6.5.0 (offline AssetSource playback, no TTS, no network)"
  patterns:
    - "pure audioId->asset resolver (audioAssetFor) for unit-testable resolution"
    - "never-block silent-degrade: unknown id / missing clip / decode error -> no-op"
    - "single reusable AudioPlayer disposed on provider teardown"
key-files:
  created:
    - lib/services/asset_audio_player.dart
    - assets/audio/README.md
    - assets/audio/snd.baa.mp3
    - assets/audio/word.baab.mp3
    - assets/audio/word.batta.mp3
    - assets/audio/sentence.albaab-kabiir.mp3
    - test/services/asset_audio_player_test.dart
    - test/firestore/rules_v2.test.md
  modified:
    - pubspec.yaml
    - lib/providers/audio_providers.dart
    - firestore.rules
decisions:
  - "audioplayers (not just_audio): owner-approved at the blocking-human package-legitimacy gate; long-standing verified-publisher pub.dev package with offline AssetSource support."
  - "All bundled clips ship as PLACEHOLDER; real recordings are an owner deliverable (owner's-mother's voice). Silent-degrade keeps the build green whether a clip is real or placeholder."
  - "word.haliib is named in the manifest but intentionally absent from the code map (no exercise references it, no recording yet) -> resolves to a silent no-op until supplied."
metrics:
  tasks_completed: 2
  files_created: 8
  files_modified: 3
  completed: 2026-06-15
---

# Phase 07 Plan 02: Offline pronunciation audio + Schema-v2 Firestore rules Summary

Made pronunciation audio real and **offline** (S1-06): added the owner-approved
`audioplayers` package, implemented `AssetLetterAudioPlayer` over the existing
`LetterAudioPlayer` seam (Phase 4 shipped a Noop), bundled the baa clips,
declared `assets/audio/`, and extended `firestore.rules` so the new Schema-v2
`words`/`exercises`/`units` collections inherit the locked read-requires-auth +
client-write-denied child-safety posture.

## What shipped

### Task 1 — AssetLetterAudioPlayer + provider swap + bundled clip manifest
- **Package (post-gate):** `audioplayers: ^6.5.0` added to `pubspec.yaml`. The
  package was **approved by the owner at the blocking-human package-legitimacy
  checkpoint** (objective: *audioplayers, latest stable 6.x*). The `^6.5.0`
  caret resolves to the current latest stable 6.x at `flutter pub get` time.
- **`lib/services/asset_audio_player.dart`** — `AssetLetterAudioPlayer implements
  LetterAudioPlayer`. A pure `audioAssetFor(id)` resolver maps a Schema-v2
  `audioId` (`snd.baa`, `word.baab`, `word.batta`, `sentence.albaab-kabiir`) to a
  bundled `assets/audio/*.mp3` path (and passes a raw `assets/audio/...` path
  through). `playLetter` plays it from the bundle via `AssetSource`, reusing one
  player instance and `stop()`-ing before each play so a rapid re-tap restarts
  cleanly. **Every failure path (unknown id, missing/undecodable clip, platform
  error) is swallowed → silent no-op** — the child is never shown an audio error
  or blocked (T-07-02-04, mirrors the Noop's posture).
- **`lib/providers/audio_providers.dart`** — `audioPlayerProvider` now returns
  `AssetLetterAudioPlayer` (interface + `NoopLetterAudioPlayer` kept for tests);
  the single player is disposed on provider teardown. `practice_screen.dart`'s
  consumer (`ref.read(audioPlayerProvider).playLetter(...)`) is **unchanged** —
  the seam shape is stable.
- **`assets/audio/README.md`** — the audioId → asset → real-vs-placeholder
  manifest, plus the package-version table and the owner-deliverable replacement
  procedure. `assets/audio/` added to `pubspec.yaml` `flutter.assets`.
- **Placeholder clips** shipped for the four mapped ids (owner deliverable; all
  PLACEHOLDER until the owner's mother records the real pronunciations).
- **`test/services/asset_audio_player_test.dart`** — asserts known ids resolve to
  their expected paths, a raw path passes through, unknown/empty/foreign inputs
  resolve to `null`, and `playLetter('does.not.exist')` / `playLetter('')`
  **complete without throwing** (the silent-degrade contract).

### Task 2 — Firestore rules for words/exercises/units
- **`firestore.rules`** — added `match /words/{wordId}`, `match
  /exercises/{exerciseId}`, `match /units/{letterId}`, each with `allow read: if
  request.auth != null;` + `allow write: if false;` and the same commented v2
  custom-claim seam used for letters/lessons (D-10). The deny-by-default catch-all
  `match /{document=**}` remains **LAST** and unchanged (D-11 — no child-data
  path added). Header comment updated to note the v2 collections inherit the same
  read-requires-auth + write-denied curriculum policy. Total `allow write: if
  false;` count is now **6** (letters, lessons, meta, words, exercises, units).
- **`test/firestore/rules_v2.test.md`** — a 4-check Rules-Playground verification
  checklist (ALLOW signed-in read of an exercises doc; DENY unauth read; DENY any
  client write to exercises/words/units; DENY a fictitious child-data path),
  mirroring 06.1's `rules.test.md`, marked **PENDING HUMAN VERIFICATION**
  (rules are server-enforced; `fake_cloud_firestore` does not evaluate them).

## audioId → asset map (real vs placeholder)

| audioId | asset | status |
|---------|-------|--------|
| `snd.baa` | `assets/audio/snd.baa.mp3` | PLACEHOLDER |
| `word.baab` | `assets/audio/word.baab.mp3` | PLACEHOLDER |
| `word.batta` | `assets/audio/word.batta.mp3` | PLACEHOLDER |
| `sentence.albaab-kabiir` | `assets/audio/sentence.albaab-kabiir.mp3` | PLACEHOLDER |
| `word.haliib` | _(not bundled)_ | NOT YET RECORDED → silent no-op |

## Deviations from Plan

**1. [Rule 3 - Blocking issue] Bundled clip files were absent from the worktree.**
- **Found during:** Task 1, when staging the clips named in the manifest.
- **Issue:** The placeholder `.mp3` files existed in the main checkout but not in
  this isolated worktree's `assets/audio/`.
- **Fix:** Copied the four placeholder clips into the worktree so the asset paths
  resolve to real bundled files (matching the manifest + `flutter.assets`).
- **Files:** `assets/audio/{snd.baa,word.baab,word.batta,sentence.albaab-kabiir}.mp3`

Otherwise the plan executed as written.

## ENVIRONMENT BLOCKER — commits and flutter gates could not run

This executor's Bash sandbox **denied `git commit`** (every form — single `-m`,
multi-`-m`, `-F -`, heredoc) and **denied all network/flutter commands**
(`flutter pub get`, `flutter test`, `flutter analyze`, `curl`, `grep`/`ls` against
the worktree absolute path). `git add`, `git status`, `git log`, and file
Read/Write/Edit all worked.

**Consequence:**
- **All Task 1 + Task 2 file changes are written to disk and the Task-1 set is
  staged** (`git add` succeeded), but **no commit could be created.** A human or
  the orchestrator must run the commits (and this SUMMARY's commit) outside the
  sandbox.
- **`flutter pub get` could not run**, so `pubspec.lock` does NOT yet pin the
  resolved `audioplayers` version. The exact resolved 6.x version must be captured
  from `pubspec.lock` when the verification wave runs `flutter pub get`.
- **`flutter test` / `flutter analyze` could not be run** by the executor; the
  automated acceptance gates are deferred to the verifier wave.

### Suggested commit sequence (to run outside the sandbox)
```
# Task 1
git add pubspec.yaml lib/services/asset_audio_player.dart \
  lib/providers/audio_providers.dart assets/audio/README.md \
  assets/audio/snd.baa.mp3 assets/audio/word.baab.mp3 \
  assets/audio/word.batta.mp3 assets/audio/sentence.albaab-kabiir.mp3 \
  test/services/asset_audio_player_test.dart
git commit -m "feat(07-02): AssetLetterAudioPlayer + provider swap + bundled clip manifest"

# Task 2
git add firestore.rules test/firestore/rules_v2.test.md
git commit -m "feat(07-02): Firestore rules for words/exercises/units (read-auth, writes denied)"

# Then: flutter pub get  (records the resolved audioplayers version in pubspec.lock)
#       flutter test test/services/asset_audio_player_test.dart
#       flutter analyze lib/services/asset_audio_player.dart lib/providers/audio_providers.dart
# Update assets/audio/README.md + this SUMMARY with the resolved audioplayers version.

git add .planning/phases/07-learning-engine-letter-unit-built-to-the-claude-design-proto/07-02-SUMMARY.md
git commit -m "docs(07-02): complete offline audio + v2 rules plan"
```

## Rules deploy

`firebase deploy --only firestore:rules` was **not run** by this executor
(network/Firebase-auth restricted in the sandbox). It is human-gated; the
Rules-Playground checks in `rules_v2.test.md` are PENDING HUMAN VERIFICATION.

## Verification status (acceptance criteria)

| Criterion | Status |
|-----------|--------|
| `implements LetterAudioPlayer` in asset_audio_player.dart | ✅ present |
| `AssetLetterAudioPlayer` in audio_providers.dart (provider swapped) | ✅ present |
| `assets/audio/` in pubspec.yaml | ✅ present |
| README lists snd.baa/word.baab/word.batta with real-vs-placeholder column | ✅ present |
| `match /words/` + `match /exercises/` + `match /units/` in firestore.rules | ✅ present |
| `allow write: if false;` count ≥ 6 | ✅ 6 (letters, lessons, meta, words, exercises, units) |
| catch-all `match /{document=**}` remains LAST | ✅ unchanged, last |
| rules_v2.test.md documents the 4 Playground checks | ✅ present |
| `flutter test` passes | ⚠️ NOT RUN (sandbox) — deferred to verifier wave |
| `flutter analyze` clean | ⚠️ NOT RUN (sandbox) — deferred to verifier wave |
| per-task commits created | ❌ BLOCKED (sandbox denies `git commit`) — must be run outside the sandbox |
