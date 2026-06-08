---
phase: 04-scoring-quality-calibration
plan: 05
subsystem: scoring
tags: [dart, scoring, calibration, harness, fixtures, dev-tools, regression]

# Dependency graph
requires:
  - phase: 04-scoring-quality-calibration
    plan: 02
    provides: "scoreLetter spine (Future<LetterResult>, whole multi-stroke letter, count→order→shape→combined-bbox dot→advisory ML Kit gate), data-driven Tolerances"
  - phase: 02.1
    plan: 04
    provides: "Authoring screen (Listener capture + tag panel) and authoring_export (combined-bbox normalizeToStrokeSpecs)"
provides:
  - "Labeled-sample capture mode in the authoring screen (D-02): a label selector over the 7-value failure taxonomy + a letter-id field + an Export-labeled-fixture button"
  - "exportLabeledFixtureJson — serializes a {letterId, label, strokes} calibration fixture from already-normalized StrokeSpecs"
  - "calibration_fixtures.dart — LabeledSample format + a synthetic baa seed (good / wrong_count / wrong_order / taa_when_shown_baa)"
  - "calibration_harness_test.dart — pure-Dart confusion-table harness running the REAL scoreLetter over labeled fixtures, printing per-letter FP/FN and asserting the regression contract"
  - "SC#4 infrastructure: the mechanism the mother uses to tune tolerances and by which named common mistakes become permanent regression tests"
affects: [calibration-tuning, plan-06-real-tablet-samples]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Labeled-fixture export reuses the SAME combined-bbox normalizeToStrokeSpecs the orchestrator's dot check uses (Pitfall 2) — authored == scored coordinate space"
    - "Confusion-table harness: real scoreLetter over labeled fixtures, FN (good rejected) vs FP (named-bad passed), regression-contract asserts + printed table"
    - "Synthetic seed clearly marked; real-tablet captures replace it in Plan 06 without changing the harness or format"

key-files:
  created:
    - test/core/scoring/calibration_harness_test.dart
    - test/core/scoring/calibration_fixtures/calibration_fixtures.dart
    - test/core/scoring/calibration_fixtures/README.md
  modified:
    - lib/dev/authoring_screen.dart
    - lib/dev/authoring_export.dart

key-decisions:
  - "The failure taxonomy const (kCalibrationLabels) is canonical in lib/dev/authoring_screen.dart (the selector's home) and mirrored in calibration_fixtures.dart; the screen calls normalizeToStrokeSpecs directly so the authored fixture lives in the exact 0..1 space scoreLetter consumes"
  - "exportLabeledFixtureJson takes already-normalized List<StrokeSpec> (not raw CapturedStroke) so the screen owns the single normalize call and the serializer stays a thin pure-Dart transform"
  - "Synthetic seed fixtures reuse the EXACT baa shapes already proven in letter_scorer_test.dart (goodBaa body, dot-below, dot-above) so the regression verdicts are grounded in the live contract, not re-guessed"
  - "Harness pins expected MistakeId per named-bad label (wrong_count→wrongStrokeCount, wrong_order→wrongStrokeOrder, taa_when_shown_baa→dotMisplaced); wrong_direction/scribble/wrong_letter land with real samples in Plan 06"

patterns-established:
  - "Confusion-table calibration harness over the real scorer (no Python re-impl — A3): FN-over-FP tuning priority documented, fixtures double as permanent regression tests"

requirements-completed: [S1-05, PLAT-03]

# Metrics
duration: 5min
completed: 2026-06-08
---

# Phase 4 Plan 05: Calibration Infrastructure Summary

**The dev-only labeled-sample capture mode (D-02) and the pure-Dart confusion-table harness that runs the REAL `scoreLetter` over labeled fixtures, reports per-letter false-positive / false-negative counts, and pins each named common mistake as a regression test — green on a clearly-marked synthetic baa seed that Plan 06 swaps for real-tablet child captures.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-08T13:54:52Z
- **Completed:** 2026-06-08T14:00:09Z
- **Tasks:** 2
- **Files modified:** 5 (3 created, 2 modified)

## Accomplishments
- Extended `lib/dev/authoring_screen.dart` into a **labeled-sample capture mode**: a **Letter id** field, a **Label** dropdown over the 7-value failure taxonomy (`good`, `wrong_order`, `wrong_direction`, `wrong_count`, `scribble`, `wrong_letter`, `taa_when_shown_baa`), and an **Export labeled fixture** button alongside the existing reference-export. The labeled export runs the shared combined-bbox `normalizeToStrokeSpecs` (the same Pitfall-2 whole-letter normalization the orchestrator's dot check uses), then serializes a `{letterId, label, strokes}` fixture. It stays behind `/dev/authoring` + `kDebugMode` — the router is unchanged, so it is never child-facing (T-02.1-07); in-memory-only, nothing logged/transmitted (T-01-05).
- Added `exportLabeledFixtureJson` to `lib/dev/authoring_export.dart` — a thin pure-Dart serializer that emits the `LabeledSample` shape (`{letterId, label, strokes: List<List<List<double>>>}`) from already-normalized `StrokeSpec`s.
- Created `test/core/scoring/calibration_fixtures/calibration_fixtures.dart` — the `LabeledSample` format + a **synthetic baa seed** (clearly marked synthetic) encoding each named baa mistake: a `good` boat+dot-below, a `wrong_count` (boat only), a `wrong_order` (dot before boat), and a `taa_when_shown_baa` (right boat, dot above). The shapes reuse the exact captures already proven in `letter_scorer_test.dart`.
- Created `test/core/scoring/calibration_harness_test.dart` — a **pure-Dart confusion-table harness** that loads every labeled fixture, runs the **REAL `scoreLetter`** (no re-implementation — A3), tallies per-letter **false negatives** (`good` rejected) and **false positives** (named-bad passed), **prints the confusion table** to the test console, and **asserts the regression contract**: every `good` seed passes, every named-bad seed is rejected with its expected `MistakeId`.
- Documented the fixture format, the FN-over-FP tuning priority, and the Plan-06 real-sample replacement path in `calibration_fixtures/README.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Labeled-sample capture mode in the authoring screen (D-02)** — `b49cb7c` (feat)
2. **Task 2: Pure-Dart calibration harness + seed regression fixtures** — `07f6f3d` (test)

## Files Created/Modified
- `lib/dev/authoring_screen.dart` (modified) — added `kCalibrationLabels` (canonical taxonomy const), `_letterId` / `_label` state + a Letter-id field + a Label dropdown + an Export-labeled-fixture button, and `_exportLabeled` (calls `normalizeToStrokeSpecs` then `exportLabeledFixtureJson`). New test-seam keys: `letterIdFieldKey`, `labelSelectorKey`, `exportLabeledButtonKey`.
- `lib/dev/authoring_export.dart` (modified) — added `exportLabeledFixtureJson({letterId, label, specs})`; takes already-normalized `StrokeSpec`s and serializes the `LabeledSample` JSON shape. No logging/persistence (returns a String only).
- `test/core/scoring/calibration_fixtures/calibration_fixtures.dart` (created) — `LabeledSample` class + `kCalibrationLabels` + the synthetic baa seed + `calibrationSamplesByLetter`.
- `test/core/scoring/calibration_harness_test.dart` (created) — the confusion-table harness with inline baa `Letter` builder, expected-rejection map, regression asserts, and the printed per-letter FP/FN table.
- `test/core/scoring/calibration_fixtures/README.md` (created) — fixture format, label taxonomy, FN/FP definitions, FN-over-FP tuning priority, and the Plan-06 real-capture workflow.

## Decisions Made
- **Taxonomy const lives in the screen, mirrored in fixtures.** `kCalibrationLabels` is canonical in `authoring_screen.dart` (where the selector renders) and re-declared in `calibration_fixtures.dart` so authored fixtures and the harness agree. This keeps the UI's source of truth co-located with the widget and satisfies the plan's grep contract (`taa_when_shown_baa` + `scribble` in the screen file) honestly.
- **The screen runs `normalizeToStrokeSpecs` directly; the serializer takes `StrokeSpec`s.** Rather than re-normalize inside the export helper, the screen owns the single combined-bbox normalize call and passes the result in. This makes the reuse of the orchestrator's normalization explicit in the screen (the dot up/down signal survives — Pitfall 2) and keeps `exportLabeledFixtureJson` a thin transform.
- **Synthetic seed reuses live-contract shapes.** The baa fixtures replicate `letter_scorer_test.dart`'s `goodBaa()` body, dot-below, and dot-above captures, so the expected verdicts (`good` passes; `wrong_count`/`wrong_order`/`taa_when_shown_baa` reject with their MistakeIds) are grounded in the already-green spine contract, not independently re-guessed.
- **Three of seven labels are seeded now.** `good`, `wrong_count`, `wrong_order`, `taa_when_shown_baa` have synthetic fixtures with pinned MistakeIds. `wrong_direction`, `scribble`, and `wrong_letter` are in the taxonomy (selectable, documented) but get fixtures from real-tablet captures in Plan 06 — synthetic adult-imagined versions of those would risk a Pitfall-3 mis-tune and add no regression value the spine tests don't already cover.

## Deviations from Plan

### Auto-fixed Issues
None.

### Scope notes (not deviations)
- The plan's Task-2 action describes the labeled export as `{letterId, label, List<List<List<double>>>}`; the serializer accepts already-normalized `StrokeSpec`s (from the screen's `normalizeToStrokeSpecs` call) and emits exactly that JSON shape. The `StrokeSpec` intermediate is an internal detail of where the single normalize call lives — the on-disk fixture format is unchanged.
- Task 1's verify greps `authoring_screen.dart` for `normalizeToStrokeSpecs` and `taa_when_shown_baa`. Both are present there because the screen owns the normalize call and the canonical taxonomy const — a design choice that also keeps the selector's source of truth beside the widget.

**Total deviations:** 0 auto-fixed. Two scope notes, both within the plan's stated latitude.

## Issues Encountered
None — the work composed cleanly over the Plan 02 spine and the Phase 02.1 authoring base. No package-manager installs (T-04-SC N/A).

## Known Stubs
The synthetic calibration seed is an **intentional, documented stub**: `calibration_fixtures.dart` is hand-crafted (clearly marked `⚠ SYNTHETIC SEED ⚠`), not real-tablet data. Per RESEARCH (Pitfall 3), synthetic strokes are too smooth to *set* tolerances against; they exist only to make the harness green and pin the regression contract. **Plan 06** replaces the seed with real-tablet child captures exported from the Task-1 labeled-capture mode — the harness and fixture format do not change, only the data. This is the plan's explicit design (objective + must_haves), not an accidental stub.

## User Setup Required
None. (To capture real samples in Plan 06: open `/dev/authoring` in a debug build on a tablet, set the Letter id, trace, pick a Label, and tap Export labeled fixture.)

## Next Phase Readiness
- The labeled-capture mode is live behind `/dev/authoring`; Plan 06 uses it on a real Android tablet to capture ~15–20 samples per letter per label.
- The harness and fixture format are stable — Plan 06 pastes exported `{letterId, label, strokes}` objects into `calibration_fixtures.dart` and extends `calibrationSamplesByLetter` / `_lettersById`; no harness change needed.
- The FN/FP confusion table is the tuning instrument: the mother adjusts `letters.json` `tolerances`, re-runs the harness, reads the table.

## Threat Flags
None — no new network endpoints, auth paths, or trust-boundary surface. The labeled-capture mode honors T-04-11 (dev-only via `/dev/authoring` + `kDebugMode`, never in child nav; only coordinate fixtures written, no PII, nothing transmitted/logged) and T-04-12 (the harness runs the same validated `scoreLetter`; malformed fixtures surface as test failures, pure-Dart headless).

## Self-Check: PASSED

- Created files verified present: `test/core/scoring/calibration_harness_test.dart`, `test/core/scoring/calibration_fixtures/calibration_fixtures.dart`, `test/core/scoring/calibration_fixtures/README.md`.
- Commits verified in git log: `b49cb7c` (Task 1), `07f6f3d` (Task 2).
- `flutter test test/core/scoring/` → all passed (incl. 4 harness tests + printed confusion table); `flutter analyze lib/dev/` and `flutter analyze test/core/scoring/` → 0 issues; harness greps real `scoreLetter` (3 hits); no new child-facing route (router unchanged).

---
*Phase: 04-scoring-quality-calibration*
*Completed: 2026-06-08*
