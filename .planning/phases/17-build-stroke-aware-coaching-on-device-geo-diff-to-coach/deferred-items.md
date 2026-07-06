# Phase 17 — Deferred Items (out-of-scope discoveries)

Logged per executor scope boundary: pre-existing failures in unrelated files are
NOT fixed by plan executors; they are recorded here for triage.

## Observed during 17-02 (2026-07-06)

Pre-existing full-suite failures verified NOT caused by the 17-02 scorer rewrite
(none of these files consume `scoreStroke`/`shapeDistance`; all fail on
curriculum data or golden/font drift):

1. `test/curriculum/all_letters_validation_test.dart` — expects
   `['alif','baa','taa']` signed off but letters.json currently signs only
   `['baa','taa']`: alif's `signedOff` flag regressed to false at some point
   (curriculum-data drift, same root family as the long-known
   `alif_reference_test` failure).
2. `test/curriculum/reference_overlay_golden_test.dart` — alif pen-path overlay
   golden fails (same alif curriculum-data root; rendering-only test).
3. Known baseline (already in MEMORY/STATE): `alif_reference_test`,
   `glyph_audit_golden_test` + `mastery_celebration_golden_test` (local font
   drift — do NOT re-bake), `meet_section_test` Test 1,
   `write_surface_test` Test 5 (pinned as pre-existing in 17-PATTERNS.md §9).
4. `test/core/scoring/letter_scorer_per_form_test.dart` — RED **by design**
   (17-01 Task-2 contract; 17-03 turns it green). Not a defect.

## Observed during 17-03 (2026-07-06)

1. `lib/core/exercise_engine/check_result.dart:43` — info-level
   `prefer_initializing_formals` lint (a constructor assigns a parameter to a
   field instead of using an initializing formal). Surfaced when analyzing the
   whole `lib/core/exercise_engine/` directory; the file is NOT touched by 17-03
   (out of scope per the executor SCOPE BOUNDARY). The two files 17-03 actually
   modified (`exercise_validator.dart`, `write_surface.dart`) analyze clean.
   Pre-existing; left for a lint-sweep quick task.
   - `letter_scorer_per_form_test.dart` is now GREEN (contract satisfied); item 4
     above is resolved by 17-03.

## Observed during 17-07 (2026-07-06)

1. `lib/features/letter_unit/letter_unit_screen.dart` (lines 389–484) — 12
   info-level `unnecessary_brace_in_string_interps` lints. Surfaced when running
   the plan's verify `flutter analyze lib/tutor/ lib/features/letter_unit/`. The
   file is NOT in 17-07's touch set (out of scope per the executor SCOPE
   BOUNDARY). The six files 17-07 actually modified — `exercise_scaffold.dart`,
   `write_surface.dart`, `tutor_facts.dart`, `tutor_facts_builder.dart`,
   `tutor_decision.dart`, `remote_agent_brain.dart` — analyze clean ("No issues
   found!"). Pre-existing; left for a lint-sweep quick task.
2. `write_surface_test.dart` Test 5 is now GREEN (the hanging `toImage` PNG
   render is deleted by the cutover) — the 17-02/17-03 deferred item #3 line
   about it being pre-existing-failing is RESOLVED by 17-07. Full-suite failure
   count dropped 9 → 8 (baseline minus write_surface, recorded for 17-10).
3. `applyVerdict` in `lib/features/letter_unit/exercise_controller.dart` is now
   DEAD (its only caller — the deleted aiJudge block — is gone). Left in place:
   `exercise_controller.dart` is NOT in 17-07's file scope, and an unused public
   method raises no analyze warning. Flagged for a follow-up removal alongside
   the ADR-017 cleanup (17-10).
