---
phase: 19-question-presentation-overhaul-every-question-self-explanato
plan: 01
subsystem: testing
tags: [flutter-test, wave-0, nyquist, presentation, drift-migration, curriculum-lint, rtl]

# Dependency graph
requires:
  - phase: 18
    provides: "presentGraphExercise live-mount seam, LetterUnitController, the 6 progress tables, remediation arc"
  - phase: 15
    provides: "curriculum_graph.json, the dead-wire lesson (live-path widget tests mandatory)"
provides:
  - "Wave-0 RED contract: a failing automated test for every locked Phase-19 behavior across Tracks A (presentation), B (content lint), C (keying migration)"
  - "exercise_scaffold_instruction_bar_test.dart (QP-01/02) — live-path instruction-bar contract via presentGraphExercise"
  - "copy_stimulus_test.dart (QP-03) — CopyStimulus reveal→hide→peek contract (RED-by-missing-symbol)"
  - "prompt_header_slot_audio_test.dart (QP-04/05) — gapSlot + audioCard contract"
  - "recall_no_model_test.dart (QP-06) — recall-no-model regression guard (green by construction)"
  - "learned_letters_lint_test.dart (QP-07) — introOrder-ranked learned-letters lint"
  - "app_database_test.dart v6→v7 two-profile migration case (QP-09) — temp-file, raw-SQL, skip-marked"
affects: ["19-02 instruction bar", "19-03 stimulus renderers", "19-04 LetterReps fold", "19-05 card rewrite/gate", "19-06 keying migration"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave-0 RED contract (Nyquist): failing test before code, greened with zero test edits (18-01/15-01/09-01 lineage)"
    - "Live-path widget mount via presentGraphExercise (never a bare scaffold — Phase-15 dead-wire lesson)"
    - "Signature-independent skip-marked migration case: pure raw SQL so it compiles today (v6 API) AND passes after 19-06 (v7 API) with skip-removal as the only edit"
    - "Disposition-agnostic content lint: scope to LIVE graph nodes so it self-greens for BOTH rewrite (letters ⊆ learned) and gate (removed from graph)"

key-files:
  created:
    - test/features/letter_unit/exercise_scaffold_instruction_bar_test.dart
    - test/features/letter_unit/copy_stimulus_test.dart
    - test/features/letter_unit/prompt_header_slot_audio_test.dart
    - test/features/letter_unit/recall_no_model_test.dart
    - test/curriculum/learned_letters_lint_test.dart
  modified:
    - test/data/app_database_test.dart

key-decisions:
  - "recall_no_model_test (QP-06) is GREEN-by-construction, not RED — the D-08 no-model invariant already holds in the authored data (no writeLetter/writeWord recall config carries guideForm/demo/given). Authored as a regression guard; 19-03 keeps it green (assertion is the deliverable, no new UI)."
  - "The v6→v7 migration case is pure raw SQL (signature-independent) + skip-marked 'v6→v7 lands in 19-06 (QP-09)' so app_database_test.dart exits 0 whole-file; 19-06 un-skips it (its only permitted test edit)."
  - "The learned-letters lint scopes to LIVE baa graph nodes so it self-greens for BOTH dispositions (rewrite → letters ⊆ learned; gate → removed from curriculum_graph.json)."
  - "QP-01..09 requirements deliberately NOT checkbox-marked at this Wave-0 contract plan (17-01 precedent) — 19-02..19-06 (or the phase verifier) flip them once the code lands."

patterns-established:
  - "Instruction-bar RED test mounts the real scaffold through presentGraphExercise + a CoachSpeaker spy that records speak/stop"
  - "Migration RED case reshapes a fresh db to the EXACT v6 DDL, seeds v6 rows in raw SQL, rewinds PRAGMA user_version, then asserts v7 keying via customSelect over child_profile_id"

requirements-completed: []

# Metrics
duration: 26min
completed: 2026-07-17
---

# Phase 19 Plan 01: Wave-0 RED Contract Summary

**Five new failing tests + one skip-marked v6→v7 migration case that pin every locked Phase-19 behavior (instruction bar, copy hide+peek, gap slot, audio card, recall-no-model, learned-letters lint, per-child keying) before any implementation lands — the Nyquist RED contract for Tracks A/B/C.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-07-17T20:24:49Z
- **Completed:** 2026-07-17T20:51:25Z
- **Tasks:** 2
- **Files modified:** 6 (5 created, 1 extended)

## Accomplishments

- **Track A (presentation, QP-01..06):** four widget tests. The instruction-bar test mounts the real scaffold through the live `presentGraphExercise` seam (not a bare scaffold — the Phase-15 dead-wire lesson) and pins `Key('instructionBar')`, the per-type template ("Write the missing letter", NOT the `say` line), exactly one replay affordance (the old "Hear again" pill absorbed), tap-to-replay via a `CoachSpeaker` spy, and the teachCard-hidden case. `copy_stimulus_test` is RED-by-missing-symbol against the not-yet-created `CopyStimulus`. `prompt_header_slot_audio_test` pins `Key('gapSlot')`/`Key('audioCard')`, the `__blank__`/`_letter_` no-leak rule, min-height ≥96, and auto-play-once. `recall_no_model_test` is a green-by-construction data guard.
- **Track B (content, QP-07):** `learned_letters_lint_test` ranks letters by `letters.json` `introOrder` and flags every LIVE baa-unit graph node whose `letters` ⊄ {alif, baa} — RED today on exactly the 7 enumerated cards.
- **Track C (keying, QP-09):** a complete v6→v7 two-profile migration case on a temp-FILE `NativeDatabase`, authored in raw SQL and skip-marked so `app_database_test.dart` stays green whole-file until 19-06 un-skips it.
- **Verified RED/GREEN status** of every test by running it (evidence below); confirmed `app_database_test.dart` exits 0 whole-file.

## Task Commits

Each task was committed atomically:

1. **Task 1: Presentation RED tests (Track A — QP-01..06)** — `fa1bda5` (test)
2. **Task 2: Content-lint + migration RED tests (Tracks B/C — QP-07, QP-09)** — `db37465` (test)

**Plan metadata:** _(this SUMMARY + STATE/ROADMAP — final docs commit)_

## Files Created/Modified

- `test/features/letter_unit/exercise_scaffold_instruction_bar_test.dart` — QP-01/02 live-path instruction-bar RED contract (mounts via `presentGraphExercise`, spies TTS `speak`/`stop`)
- `test/features/letter_unit/copy_stimulus_test.dart` — QP-03 `CopyStimulus` reveal→hide→peek RED contract (compile-error until 19-03 creates the widget)
- `test/features/letter_unit/prompt_header_slot_audio_test.dart` — QP-04/05 gap-slot + hero-audio-card RED contract
- `test/features/letter_unit/recall_no_model_test.dart` — QP-06/D-08 recall-no-model data regression guard
- `test/curriculum/learned_letters_lint_test.dart` — QP-07/D-12 `introOrder`-ranked learned-letters lint (RED on 7 live cards)
- `test/data/app_database_test.dart` — extended with the v6→v7 two-profile migration case (temp-file, raw-SQL, skip-marked)

## RED/GREEN Evidence (recorded per the plan — RED verify commands are expected to exit non-zero)

| Test | Status | Reason |
|------|--------|--------|
| `exercise_scaffold_instruction_bar_test.dart` | **RED** (3 fail, 1 pass) | `Key('instructionBar')` findsNothing; old "Hear again" pill still present; tap target absent. TeacherCard-hidden guard passes. |
| `copy_stimulus_test.dart` | **RED** (compile error) | `lib/.../copy_stimulus.dart` / `CopyStimulus` does not exist yet |
| `prompt_header_slot_audio_test.dart` | **RED** (5 fail) | `Key('gapSlot')` + `Key('audioCard')` findNothing |
| `recall_no_model_test.dart` | **GREEN** (regression guard) | no recall write config authors a model/ghost part in the authored data |
| `learned_letters_lint_test.dart` | **RED** (flags 7) | `kitaab`, `transformWord.{dual,plural,opposite}`, `fillBlank.adjective`, `buildSentence.{hear,picture}` demand unlearned letters |
| `app_database_test.dart` (whole file) | **GREEN** (exit 0) | v6→v7 case reported `Skip: v6→v7 lands in 19-06 (QP-09)`; `+8 ~1 All tests passed!` |

## Decisions Made

- **recall_no_model_test (QP-06) authored GREEN, not RED** — the D-08 "no letter model on recall write types" invariant already holds in the authored data (a full scan across all letters found no `writeLetter`/`writeWord` config carrying `guideForm`/`demo`/`given`). It is authored as a rigorous, non-vacuous regression guard (asserts ≥1 recall config exists, iterates real configs) that locks the invariant so 19-05's card rewrites can never reintroduce a model. 19-03 explicitly anticipates this ("otherwise the assertion over the configs is the deliverable — no new UI").
- **Migration case is signature-independent raw SQL** — because 19-06 re-keys five tables (changing every typed accessor signature), a body written against the typed API would fail to compile after 19-06 and could not be greened by skip-removal alone. Pure `customStatement`/`customSelect` compiles today (v6) AND passes after 19-06 (v7) with the skip marker as the only edit.
- **Lint scopes to live graph nodes** — disposition-agnostic: a rewritten card becomes compliant (`letters ⊆ {alif,baa}`); a gated card (D-19: removed from `curriculum_graph.json`) leaves the linted set. Either way the lint self-greens with zero test edits.
- **Requirements NOT checkbox-marked** — per the 17-01 Wave-0 precedent, a RED-contract plan authors failing tests but does not complete requirements; QP-01..09 flip when 19-02..19-06 land the code.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Plan/data mismatch] recall_no_model_test authored GREEN (regression guard) rather than RED**
- **Found during:** Task 1 (Presentation RED tests)
- **Issue:** 19-01's acceptance calls for "all four presentation tests FAIL (RED)". A full data scan proved the D-08 no-model invariant already holds — no `writeLetter`/`writeWord` recall config authors a `guideForm`/`demo`/`given` model part in any letter. A pure "no model" data assertion is therefore green today; fabricating a RED (e.g. inventing a dodgeable symbol) would test nothing real.
- **Fix:** Authored a rigorous, non-vacuous regression guard (asserts ≥1 recall config exists, iterates real configs, checks all model-part fields) that locks the invariant for 19-05's rewrites. This is exactly the outcome 19-03 anticipates ("the assertion over the configs is the deliverable — no new UI"). The other four RED tests (instruction bar, copy_stimulus, slot/audio, lint) are genuinely RED.
- **Files modified:** test/features/letter_unit/recall_no_model_test.dart
- **Verification:** `flutter test .../recall_no_model_test.dart` → All tests passed (1 non-vacuous assertion over real configs).
- **Committed in:** fa1bda5 (Task 1 commit)

---

**Total deviations:** 1 (Rule 1 — plan/data reconciliation)
**Impact on plan:** No scope creep. Nyquist coverage intact — QP-06 has a real, meaningful automated check that exists before the code; it guards the invariant rather than driving it from red. All other Wave-0 gaps are genuinely RED.

## Issues Encountered

- **Migration-case compile/pass tension** — the case must compile today (v6 typed API) yet pass after 19-06 changes those signatures, with skip-removal as the only permitted edit. Resolved by writing the entire case in raw SQL over `child_profile_id`, reshaping a fresh db to the exact captured v6 DDL before seeding. Confirmed the whole file exits 0 with the case skipped.

## User Setup Required

None — no external service configuration required (no packages added; RESEARCH: "No new external packages").

## Next Phase Readiness

- **Nyquist RED contract complete.** Every downstream `<verify>` in 19-02..19-06 now references a real automated check that exists before the code:
  - 19-02 greens `exercise_scaffold_instruction_bar_test.dart` (QP-01/02).
  - 19-03 greens `copy_stimulus_test.dart`, `prompt_header_slot_audio_test.dart`, keeps `recall_no_model_test.dart` green (QP-03/04/05/06).
  - 19-05 greens `learned_letters_lint_test.dart` by rewriting/gating exactly the 7 flagged cards (QP-07).
  - 19-06 un-skips the v6→v7 migration case (its ONLY permitted edit to `app_database_test.dart`) and greens it (QP-09).
- **Do NOT re-bake goldens** (alif_reference, mastery/glyph) — pre-existing font drift, not regressions.
- **Requirements QP-01..09 remain open** (checkbox-flip deferred to the implementing plans / phase verifier).

---
*Phase: 19-question-presentation-overhaul-every-question-self-explanato*
*Completed: 2026-07-17*

## Self-Check: PASSED

- Files: all 6 FOUND (4 presentation tests, 1 lint test, 1 extended migration test).
- Commits: fa1bda5 FOUND, db37465 FOUND.
