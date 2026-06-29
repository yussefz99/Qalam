---
phase: 16-build-presence-voice-eval-gate-demo-harden
plan: 02
subsystem: tutor-voice
tags: [flutter_tts, tts, riverpod, on-device, arabic, android, accessibility]

# Dependency graph
requires:
  - phase: 16-01
    provides: "Wave-0 RED contract test/tutor/tts_coach_speaker_test.dart (segmentByScript + TtsCoachSpeaker over an injectable TtsEngine seam)"
  - phase: 07-02
    provides: "asset_audio_player.dart never-block/silent-degrade posture + audio_providers.dart Provider+onDispose seam (the analogs)"
provides:
  - "segmentByScript: a pure, device-free splitter that maps a mixed Arabic+Latin coach line into ordered (locale, text) runs ('ar' vs 'en-US')"
  - "TtsCoachSpeaker: an on-device coach-voice speaker over an injectable TtsEngine, per-script synthesis with graceful Arabic-voice degrade, never-block/silent-degrade (ADR-014)"
  - "FlutterTtsEngine: the real TtsEngine adapter over a single reusable FlutterTts handle"
  - "NoopTtsCoachSpeaker: test-override impl mirroring NoopLetterAudioPlayer"
  - "ttsCoachSpeakerProvider: Riverpod Provider returning the speaker, disposing the native handle on teardown"
  - "flutter_tts ^4.2.5 pinned + the Android 11+ TTS_SERVICE <queries> discoverability entry"
affects: [16-04, exercise_scaffold-speak-hook, presence-voice, demo-harden]

# Tech tracking
tech-stack:
  added: ["flutter_tts ^4.2.5 (resolved 4.2.5, verified publisher dlutton/eyedeadevelopment.com)"]
  patterns:
    - "Injectable TtsEngine seam so the never-block flow is testable in a headless flutter_test run (no platform TTS backend)"
    - "Pure device-free resolver (segmentByScript) as the analog of audioAssetFor — unit-tested with no device"
    - "Per-run language switch + sequential speak with awaitSpeakCompletion(true) — never one setLanguage for the whole mixed line"

key-files:
  created:
    - "lib/tutor/tts_coach_speaker.dart"
    - "lib/providers/tts_providers.dart"
  modified:
    - "pubspec.yaml"
    - "pubspec.lock"
    - "android/app/src/main/AndroidManifest.xml"

key-decisions:
  - "flutter_tts@4.2.5 human-approved via orchestrator legitimacy gate (verified publisher dlutton/eyedeadevelopment.com on pub.dev — 1586 likes, 150/160 pts, ~267k downloads/30d); pinned ^4.2.5 to match the audioplayers pin style"
  - "TtsEngine is the injectable seam (the RED test drives a _RecordingTtsEngine fake); FlutterTtsEngine wraps the real FlutterTts so the whole surface is testable with no platform TTS in flutter_test"
  - "Arabic-voice availability checked ONCE per line (not per run) — stable for the utterance and the call can be slow; an absent Arabic voice silently skips the 'ar' run while English still speaks (D-06 graceful degrade)"
  - "TTS is display-only (ADR-014): speak() wraps the whole body in a swallow-everything try/catch — never throws, never blocks the trace loop"
  - "ttsCoachSpeakerProvider is a hand-written Riverpod Provider (Riverpod only — CLAUDE.md Decided); ref.onDispose releases the native engine handle, mirroring audioPlayerProvider"

patterns-established:
  - "Coach-voice seam (CoachSpeaker) parallels the audio seam (LetterAudioPlayer): abstract interface + real impl + Noop override + Provider with onDispose"
  - "Arabic-block detection over runes (U+0600–06FF base block + presentation forms U+FB50–FDFF / U+FE70–FEFF) for per-script segmentation"

requirements-completed: [PRES-02]

# Metrics
duration: ~6min
completed: 2026-06-29
---

# Phase 16 Plan 02: On-device coach-voice surface (TTS) Summary

**On-device coach voice via flutter_tts ^4.2.5: a pure per-script segmenter + TtsCoachSpeaker that voices a mixed en/ar coaching line, gracefully skips a missing Arabic voice, and never throws or blocks the trace loop — turning the 16-01 RED tests GREEN.**

## Performance

- **Duration:** ~6 min
- **Completed:** 2026-06-29
- **Tasks:** 3 (Task 1 checkpoint pre-cleared; Tasks 2-3 executed)
- **Files modified:** 5 (2 created, 3 modified)

## Accomplishments
- Pinned `flutter_tts: ^4.2.5` (resolved 4.2.5) — the on-device coach-voice package; legitimacy human-approved at the blocking-human gate before install.
- Added the Android 11+ `TTS_SERVICE` `<intent>` as a sibling inside the single existing `<queries>` element so the platform TTS engine is discoverable.
- Built `segmentByScript` — a pure, device-free splitter mapping a mixed Arabic+Latin line into ordered `(locale, text)` runs (Arabic-block → `'ar'`, everything else → `'en-US'`).
- Built `TtsCoachSpeaker` over an injectable `TtsEngine` seam: `awaitSpeakCompletion(true)` once, `isLanguageAvailable('ar')` once, then per-run `setLanguage` + sequential `speak`; the Arabic run is skipped when no Arabic voice is installed so the English guidance still speaks (D-06 graceful degrade).
- Never-block / silent-degrade posture (ADR-014 display-only): `speak()` swallows every error, never throws, never stalls the trace loop — mirroring `asset_audio_player.dart`.
- Wired `ttsCoachSpeakerProvider` (Riverpod only) with `ref.onDispose(speaker.dispose)` to release the native engine handle; added `NoopTtsCoachSpeaker` for test overrides.
- All 6 of the 16-01 RED cases turn GREEN with **zero test edits**; `flutter analyze` clean on both new files.

## Task Commits

Each task was committed atomically:

1. **Task 1: Package legitimacy gate (flutter_tts)** — pre-cleared. The orchestrator obtained human approval: the user verified flutter_tts on pub.dev and approved pinning `flutter_tts@4.2.5` (verified publisher dlutton/eyedeadevelopment.com). Recorded as **human-approved flutter_tts@4.2.5 via orchestrator legitimacy gate** — no autonomous proceed past an unverified gate.
2. **Task 2: Install flutter_tts + TTS_SERVICE manifest query** — `3cacac8` (chore)
3. **Task 3: TtsCoachSpeaker + ttsCoachSpeakerProvider (16-01 RED → GREEN)** — `8ad6448` (feat)

_Note: This `tdd="true"` task shipped as a single GREEN commit because the RED commit already landed in 16-01 (the Wave-0 contract); see TDD Gate Compliance below._

## Files Created/Modified
- `lib/tutor/tts_coach_speaker.dart` — `segmentByScript` pure splitter, `TtsEngine` seam, real `FlutterTtsEngine` (single reusable `FlutterTts` handle), `CoachSpeaker` seam, `TtsCoachSpeaker` (per-script + graceful degrade + never-block), `NoopTtsCoachSpeaker`.
- `lib/providers/tts_providers.dart` — `ttsCoachSpeakerProvider` (Riverpod `Provider` + `ref.onDispose`).
- `pubspec.yaml` — `flutter_tts: ^4.2.5` pin with a documenting comment (separate coach-voice surface from the audioplayers pronunciation clips).
- `pubspec.lock` — resolved `flutter_tts 4.2.5`.
- `android/app/src/main/AndroidManifest.xml` — sibling `<intent>` `TTS_SERVICE` inside the single `<queries>` element.

## Decisions Made
- See `key-decisions` frontmatter. In short: injectable `TtsEngine` seam for testability; per-line (not per-run) Arabic-voice check; display-only swallow-everything posture; hand-written Riverpod `Provider`.

## Deviations from Plan

None - plan executed exactly as written. (Task 1 was a blocking-human package-legitimacy checkpoint, pre-cleared by the orchestrator with documented human approval — this is normal gated flow, not a deviation.)

## Issues Encountered
None. The 16-01 RED contract specified the exact symbols (`TtsEngine` methods, `segmentByScript` return shape, `TtsCoachSpeaker(engine)` constructor); the implementation satisfied them with zero test edits on the first run.

## TDD Gate Compliance
This `tdd="true"` task is the GREEN half of a cross-plan RED/GREEN cycle: the RED commit (`test(16-01): … add failing test for tts_coach_speaker`) landed in plan 16-01 as the Wave-0 contract; this plan supplies the GREEN implementation commit (`feat(16-02): … 16-01 RED tests GREEN`). The RED→GREEN ordering holds across the two plans; no test was edited to force GREEN. No refactor commit was needed (the first GREEN implementation is clean and analyze-passing).

## User Setup Required
None - no external service configuration required. (On-device TTS uses the platform engine; no network, no API key. A stock Pixel Tablet may lack an installed Arabic voice — handled by the silent-skip degrade, verified on device in a later presence/voice plan.)

## Next Phase Readiness
- The coach-voice surface is ready for the `exercise_scaffold.dart` speak-hook (PATTERNS: fire-and-forget `ref.read(ttsCoachSpeakerProvider).speak(line)` a beat after the visual verdict, on both pass and miss) — the next presence/voice wave.
- Device verification of real Arabic-voice availability + the PRES-01 latency budget is deferred to on-device measurement (no code analog; the silent-degrade path is already proven by unit test).

## Self-Check: PASSED
- FOUND: lib/tutor/tts_coach_speaker.dart
- FOUND: lib/providers/tts_providers.dart
- FOUND: .planning/phases/16-build-presence-voice-eval-gate-demo-harden/16-02-SUMMARY.md
- FOUND commit: 3cacac8 (Task 2)
- FOUND commit: 8ad6448 (Task 3)
