---
phase: 19-question-presentation-overhaul-every-question-self-explanato
plan: 03
subsystem: letter-unit-presentation
tags: [flutter, prompt-header, stimulus-zone, rtl, l10n, anti-gamification, tdd]

# Dependency graph
requires:
  - phase: 19
    plan: 01
    provides: "prompt_header_slot_audio_test.dart (QP-04/05), copy_stimulus_test.dart (QP-03), recall_no_model_test.dart (QP-06) — the RED contract this plan greens with zero test edits"
  - phase: 19
    plan: 02
    provides: "instruction bar in ExerciseScaffold._mainColumn; the ARB TOP block (this plan appends at the BOTTOM — merge-clean)"
  - phase: 18
    provides: "presentGraphExercise live-mount seam; the PromptHeader render path"
provides:
  - "PromptHeader hero audio card (D-07) — lone audio → large auto-playing/replayable ink-teal 'Listen' card; silent-degrades on a missing clip/handler"
  - "PromptHeader enlarged gap slot box (D-06) — _GapWord/_GapLetter keyed Key('gapSlot'), 2px ink-teal ring, teal wash, 40px slot word; the __blank__/_letter_ marker never leaks"
  - "CopyStimulus (D-05) — child-controlled reveal→hide→peek widget; _TextPart reveal:'thenHide' renders it (replacing the static opacity dim)"
  - "recall no-model invariant (D-08) held green (assertion is the deliverable, no new UI)"
affects: ["19-04 LetterReps fold", "19-05 card rewrite/gate", "19-06 keying migration"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Prompt-derivable variant discriminator: a LONE audio visual renders the D-07 hero card; audio alongside other parts keeps the small Hear/Play button (no scaffold flag needed — the 19-01 test constructs PromptHeader directly and expects the hero card by default)"
    - "Mount-time auto-play-once via a post-frame callback guarded by a bool (mirrors the scaffold initState auto-speak); silent-degrade to a no-op on a null handler"
    - "Static-highlight substitution for a continuous pulse — a repeating ticker would hang the many pumpAndSettle widget tests that drive real completeWord/fillBlank nodes"

key-files:
  created:
    - lib/features/letter_unit/widgets/copy_stimulus.dart
  modified:
    - lib/features/letter_unit/widgets/prompt_header.dart
    - lib/l10n/app_en.arb
    - test/features/letter_unit/prompt_header_test.dart
    - test/features/letter_unit/watch_trace_section_test.dart

key-decisions:
  - "Hero audio card is scoped to a LONE audio visual (the listen-and-write shape). This spares the meet teachCard (audio + image + forms → small 'Hear' button, no auto-play) and prompt_header_test Test 1 (audio + rule → 'Play' button). watch_trace's lone trace audio becomes the hero card (Test 5 reconciled)."
  - "The UI-SPEC §3 slot 'gentle pulse' is rendered as a strong STATIC teal-wash highlight, NOT a repeating animation — a repeating ticker breaks pumpAndSettle across the suite (real completeWord/fillBlank nodes render in exercise_scaffold/cutover/resume tests). The tested contract (Key('gapSlot'), no marker leak, 40px word) is fully met."
  - "First-stroke hide is a ready hook (CopyStimulus.hideSignal) but NOT wired to the scaffold: WriteSurface exposes no stroke-start seam and the plan forbids inventing a new capture path. 'I'm Ready' fully delivers the child-controlled hide; the copy_stimulus_test contract is green."
  - "recall_no_model_test (QP-06) stayed green-by-construction (per 19-01) — no writeLetter/writeWord recall config authors a model part; the assertion is the deliverable, no new UI (as 19-03 anticipated)."

patterns-established:
  - "Lone-audio fast path in PromptHeader.build mirrors the lone-image fast path (full stimulus-zone treatment for a single dominant part)"

requirements-completed: [QP-03, QP-04, QP-05, QP-06]

# Metrics
duration: 17min
completed: 2026-07-17
---

# Phase 19 Plan 03: Stimulus Zone Renderers Summary

**The `PromptHeader` stimulus zone becomes self-explanatory per type — a big highlighted RTL slot box at the gap (the `__blank__`/`_letter_` marker retired), a large auto-playing/replayable "Listen" audio card for the sound-to-write, and a child-controlled reveal→hide→peek `CopyStimulus` replacing the old timed opacity dim — greening the 19-01 slot/audio/copy RED contract with ZERO edits to those test files, and holding the recall-no-model invariant.**

## Performance

- **Duration:** 17min
- **Started:** 2026-07-17T21:25:59Z
- **Tasks:** 2
- **Files:** 5 (1 created, 2 source modified, 2 Phase-07 tests reconciled; generated l10n is gitignored, not counted)

## Accomplishments

- **Task 1 — gap slot box (D-06/QP-04) + hero audio card (D-07/QP-05):**
  - `_GapWord`/`_GapLetter` enlarged to the UI-SPEC §3 slot: `Key('gapSlot')`, radius 14, 2px ink-teal outline, gentle teal wash, min-width 72 (word) / 56 (letter) × min-height 64; the surrounding slot word renders at 40px. The `_TextPart._tokens()` marker split is preserved so `__blank__`/`_letter_` never reach the screen (Pitfall 6).
  - `_AudioPart` gained a HERO variant: for a LONE audio visual (the listen-and-write shape) PromptHeader renders a large ink-teal card (`Key('audioCard')`, radius 28, min-height 96, white 40px speaker + "Listen"), auto-playing the clip ONCE on mount (post-frame callback, mirroring the scaffold auto-speak) and replaying on tap. A missing clip/handler silent-degrades to a no-op — the card still renders, no error surface (T-19-07). Audio ALONGSIDE other parts keeps the small "Hear"/"Play" button.
  - `promptAudioListen` (+ semantics) ARB key appended at the BOTTOM of `app_en.arb`.
- **Task 2 — copy hide+peek (D-05/QP-03) + recall no-model (D-08/QP-06):**
  - New `lib/features/letter_unit/widgets/copy_stimulus.dart` — a `StatefulWidget` with three states (`revealed`/`hidden`/`peeking`): the word (40px Arabic) + "I'm Ready" → hidden (calm placeholder) + "Peek" → peeking (word back) + "Hide". NOTHING hides on a timer (D-05); Semantics labels carry the full verb+noun intent behind the single-word visible labels. `_TextPart` now renders `CopyStimulus` for `reveal == 'thenHide'`, replacing the static `Opacity(0.18)` dim.
  - `copy*` ARB keys (+ semantics) appended at the BOTTOM of `app_en.arb`.
  - Recall no-model (D-08): held green-by-construction — no `writeLetter`/`writeWord` recall config authors a model/ghost part, so the assertion over the configs is the deliverable (no new UI), exactly as 19-03 anticipated.
- **Greened the 19-01 contract with ZERO test edits** — `prompt_header_slot_audio_test.dart` (5 cases), `copy_stimulus_test.dart` (4 cases), and `recall_no_model_test.dart` (1 case) all pass untouched. `flutter gen-l10n` regenerates clean; `flutter analyze` on both widget files exits 0.

## Task Commits

1. **Task 1 + Task 2 source (renderers)** — `d1d864e` (feat) — `copy_stimulus.dart`, `prompt_header.dart`, `app_en.arb`. Both tasks' source is co-located in `prompt_header.dart` (`_TextPart`, `_AudioPart`, `_GapWord`/`_GapLetter` are interleaved) and interactive hunk staging is unavailable in this environment, so the inseparable renderer code lands in one compilable commit.
2. **Phase-07 test reconciliations** — `44bec3c` (test) — `prompt_header_test.dart`, `watch_trace_section_test.dart`.

**Plan metadata:** _(this SUMMARY + STATE/ROADMAP/REQUIREMENTS — final docs commit)_

## RED/GREEN Evidence

| Test | Status | Note |
|------|--------|------|
| `prompt_header_slot_audio_test.dart` (5) | RED → **GREEN** | `Key('gapSlot')` + `Key('audioCard')`, no `__blank__`/`_letter_` leak, min-height ≥96, auto-play-once, silent-degrade — greened with zero test edits |
| `copy_stimulus_test.dart` (4) | RED → **GREEN** | `CopyStimulus` reveal→hide→peek; no-timer long-pump; greened with zero test edits |
| `recall_no_model_test.dart` (1) | **GREEN** (held) | invariant already held (19-01); assertion is the deliverable |
| `prompt_header_test.dart` (Test 3) | reconciled → **GREEN** | Opacity 0.18 → CopyStimulus (Rule 1) |
| `watch_trace_section_test.dart` (Test 5) | reconciled → **GREEN** | empty-until-'Play' → hero auto-play + 'Listen' replay (Rule 1) |
| `flutter test test/features/letter_unit/` | **128 pass / 1 fail** | the 1 fail is the pre-existing `meet_section` Test 1 `img.door` (documented baseline, not this plan) |

## Decisions Made

- **Hero-vs-normal audio discriminator = lone audio visual.** The 19-01 test constructs `PromptHeader` directly with `[say, audio]` and expects the hero card, so the hero treatment must be the default for a lone audio part (no scaffold flag). This cleanly spares `meet` (audio + image + forms → small "Hear", no auto-play, Test 2 green) and `prompt_header_test` Test 1 (audio + rule → "Play" button, green) and the presenter test (no audio). `watch_trace`'s lone trace audio becomes the hero card — a deliberate reconciliation (auto-play the letter sound on entering trace).
- **Static slot highlight, not a repeating pulse.** UI-SPEC §3 offers dotted OR pulse; the continuous pulse is rendered as a strong static teal-wash highlight because a repeating `AnimationController` would hang `pumpAndSettle` in every suite test that drives a real completeWord/fillBlank node (exercise_scaffold/cutover/resume). The audio card is likewise animation-free for the same reason (listen_write/forms use `pumpAndSettle`). The tested contract is fully met.
- **First-stroke hide is a ready hook, not wired.** `CopyStimulus.hideSignal` (a `Listenable`) can hide a revealed word on the first stroke, but `WriteSurface` exposes no stroke-start seam and the plan forbids inventing a new capture path. "I'm Ready" fully delivers the child-controlled hide; wiring `hideSignal` to a real stroke-start event is left for a future scaffold pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — obsolete test contradicts a locked decision] Reconciled `prompt_header_test` Test 3**
- **Found during:** Task 2 (running the letter_unit suite after the `_TextPart` reveal change).
- **Issue:** Test 3 asserted the removed static `Opacity 0.18` dim on a `reveal:'thenHide'` word — D-05 explicitly replaces it with the child-controlled `CopyStimulus`.
- **Fix:** Rewrote Test 3 to assert the CopyStimulus contract (word + "I'm Ready"), no Opacity. NOT a 19-01 protected test.
- **Files modified:** `test/features/letter_unit/prompt_header_test.dart`
- **Committed in:** `44bec3c`

**2. [Rule 1 — obsolete test contradicts a locked decision] Reconciled `watch_trace_section_test` Test 5**
- **Found during:** Task 1 (the trace audio is a lone audio visual → hero card).
- **Issue:** Test 5 asserted `audio.played` empty until a "Play" tap — D-07's hero card auto-plays the clip once on mount and labels the affordance "Listen".
- **Fix:** Rewrote Test 5 to assert auto-play on mount + replay on the "Listen" tap. NOT a 19-01 protected test.
- **Files modified:** `test/features/letter_unit/watch_trace_section_test.dart`
- **Committed in:** `44bec3c`

**Total deviations:** 2 (both Rule 1 — test/contract reconciliation, mirroring the 19-02 `_HearAgainCta` reconciliation). No scope creep beyond the plan's stimulus renderers.

## Threat Surface

- **T-19-07 (Denial of service — missing-clip audio) MITIGATED** per the register: the hero audio card silent-degrades to a no-op on a null handler / missing clip (mirrors the `_ImagePart` errorBuilder posture); it never crashes the loop. Verified by the 19-01 unknown-clip-id test.
- **T-19-08 (Information disclosure — copy/slot render) ACCEPTED**: renders only authored curriculum content; no PII, no child data, no user input stored or transmitted.
- No new network endpoint, auth path, file access, or schema surface. No threat flags.

## Known Stubs

None. The slot box, audio card, and copy widget all render real per-type stimulus content. The hidden-state placeholder in `CopyStimulus` is intentional (D-05 — the word is deliberately withheld until the child peeks), not an unwired stub.

## Issues Encountered

- **Out-of-scope pre-existing failure** (logged to `deferred-items.md`, NOT fixed): `meet_section_test` Test 1 `find.textContaining('img.door')` — an `_ImagePart` image-caption assertion obsoleted when `img.door` became a mapped bundled asset. Untouched by this plan's renderers (`_AudioPart`/`_TextPart`/`_GapWord`/`_GapLetter`); the plan's own notes flag it as "not yours".
- Goldens NOT re-baked (pre-existing font drift, per 19-01/19-02 guidance).

## User Setup Required

None — no packages added; `flutter gen-l10n` regenerates the (gitignored) localizations from the ARB additions.

## Next Phase Readiness

- **19-04** (LetterReps fold), **19-05** (card rewrite/gate — greens `learned_letters_lint_test`), **19-06** (keying migration — un-skips the v6→v7 case) proceed on the greened presentation contract.
- ARB discipline held: this plan's keys sit at the BOTTOM of `app_en.arb` (19-02's block is at the TOP) — merge-clean for any parallel Wave-2 edits.
- Cold device UAT of each stimulus type (sound off) remains the end-of-phase human gate.

---
*Phase: 19-question-presentation-overhaul-every-question-self-explanato*
*Completed: 2026-07-17*

## Self-Check: PASSED

- Files: all FOUND (copy_stimulus.dart, prompt_header.dart, app_en.arb, 19-03-SUMMARY.md).
- Commits: d1d864e FOUND, 44bec3c FOUND.
- Target tests GREEN: prompt_header_slot_audio_test (5), copy_stimulus_test (4), recall_no_model_test (1) — zero test edits. Full letter_unit suite 128 pass / 1 pre-existing `img.door` fail.
