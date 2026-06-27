# Phase 15 — Deferred / Out-of-Scope Items

Items discovered during execution that are OUT OF SCOPE for the current task
(pre-existing failures in unrelated files). Logged, not fixed (executor scope
boundary).

## Pre-existing test failures (NOT caused by Phase 15 work)

Observed while running `flutter test test/curriculum/` during Plan 15-03. All
three pre-date this plan (present on parent commit `e30e097`) and live in files
this plan never touched. They are the same known issues recorded in MEMORY
("Golden tests font drift") and 06.1-04 SUMMARY ("4 known pre-existing
out-of-scope failures: alif-reference + mastery golden").

| Test | File | Cause | Status |
|------|------|-------|--------|
| alif resolved pen path overlays the glyph in draw order (D-07) | `test/curriculum/reference_overlay_golden_test.dart` | Golden pixel diff 1.47% — local font rendering drift, not a regression | Pre-existing; do NOT re-bake to "fix" (MEMORY: golden-tests-font-drift) |
| alif corrected centerline first/last point + monotonic y | `test/curriculum/alif_reference_test.dart` | alif-reference shipped-letters.json data | Pre-existing (06.1-04) |
| alif corrected centerline normalized total length ≈ 1.0 | `test/curriculum/alif_reference_test.dart` | alif-reference shipped-letters.json data | Pre-existing (06.1-04) |

Plan 15-03 added only `lib/curriculum/{curriculum_graph,curriculum_graph_walker,mastery_condition}.dart`
and extended the `lib/tutor/` import guard; its 11 target tests are all GREEN.

## Full-suite failures observed during Plan 15-04 (7 total — none caused by 15-04)

`flutter test` (full client suite) after 15-04's two tasks: **+629 -7**. All 7
failures are pre-existing golden/data drift OR by-design Wave-0 RED tests owned
by a LATER plan. None reference any symbol 15-04 changed (verified: no failing
test except `dynamic_selection_test.dart` imports
`clearedTiers`/`clearedCompetencies`/`graph_position_repository`/`LetterGraphPosition`/
`LetterExerciseReps`/`getPosition`/`setPosition`, and that one fails on a
DIFFERENT missing symbol owned by 15-05).

| Test | File | Cause | Status |
|------|------|-------|--------|
| Noto Naskh shapes all four contextual forms (D-12) | `test/glyph_audit_golden_test.dart` | Golden pixel diff 1.19% — local font rendering drift | Pre-existing (MEMORY: golden-tests-font-drift); do NOT re-bake |
| alif resolved pen path overlays the glyph (D-07) | `test/curriculum/reference_overlay_golden_test.dart` | Golden pixel diff 1.47% — font drift | Pre-existing (logged in 15-03) |
| alif corrected centerline first/last + monotonic y | `test/curriculum/alif_reference_test.dart` | alif-reference shipped-letters.json data | Pre-existing (06.1-04 / 15-03) |
| alif corrected centerline normalized length ≈ 1.0 | `test/curriculum/alif_reference_test.dart` | alif-reference shipped-letters.json data | Pre-existing (06.1-04 / 15-03) |
| meet section renders door image (Test 1) | `test/features/letter_unit/meet_section_test.dart` | `img.door` widget text not found — image rendering, unrelated to 15-04 | Pre-existing |
| MasteryCelebration golden snapshot | `test/features/practice/mastery_celebration_golden_test.dart` | Golden pixel diff 0.00% (2px) — font drift | Pre-existing (MEMORY: golden-tests-font-drift) |
| exerciseSelectorProvider selection seam | `test/features/letter_unit/dynamic_selection_test.dart` | Compile fail: `lib/tutor/exercise_selector_provider.dart` absent | By-design Wave-0 RED — 15-05 owns this symbol (15-01 SUMMARY) |
