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
