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
