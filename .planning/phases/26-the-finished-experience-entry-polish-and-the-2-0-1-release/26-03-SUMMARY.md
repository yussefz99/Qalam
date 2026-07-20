---
phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release
plan: 03
subsystem: testing
tags: [scorer, tolerances, soft-band, dtw, calibration, dart-flutter-test]

# Dependency graph
requires:
  - phase: 17-tutor-redesign
    provides: "SoftBand three-zone TCC/TCW shape scorer + Tolerances-as-DATA single source"
  - phase: (scorer bugfix)
    provides: "painter-stretch fix (commit 972427e) that made the tighter band safe to restore"
provides:
  - "Shape soft-band reverted to the ORIGINAL tighter tcc=0.10 / tcw=0.15 (D-04 code half)"
  - "In-source D-04 decision record: reason (painter-stretch fix) + on-device FALLBACK clause"
  - "Calibration harness proven green at 0.10/0.15 (FN==0 good, FP==0 named-bad, F5 zero passes)"
affects: [26-06-device-pass, scorer-calibration, future-mother-labelled-calibration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scorer thresholds stay a single source (SoftBand.shapeDefault mirrored by Tolerances defaults); revert touches one constant per file and the pins follow"
    - "Dart flutter-test calibration harness is the regression guard for threshold changes (deliberate deviation from the Python-tooling rule)"

key-files:
  created:
    - ".planning/phases/26-.../26-03-SUMMARY.md"
  modified:
    - "lib/core/scoring/shape_match.dart"
    - "lib/core/scoring/tolerances.dart"
    - "test/core/scoring/tolerances_test.dart"
    - "test/core/scoring/soft_verdict_scorer_test.dart"

key-decisions:
  - "D-04 code half closed: tcc/tcw reverted 0.12/0.16 -> 0.10/0.15; on-device feel deferred to the 26-06 device pass where the D-04 FALLBACK lives"
  - "The widened-value pins in soft_verdict_scorer_test.dart (NOT in the plan's files_modified) were retightened to 0.10/0.15 rather than left failing — Rule 3 blocking-issue fix, don't weaken the guard"

patterns-established:
  - "Threshold reverts record a dated decision + reason + fallback in-source next to the constant, not only in planning docs"

requirements-completed: [PLAT-01]

# Metrics
duration: ~20min
completed: 2026-07-20
---

# Phase 26 Plan 03: Scorer re-tighten (D-04) Summary

**Shape soft-band DTW thresholds reverted to the original tighter tcc=0.10 / tcw=0.15, with the D-04 decision + painter-stretch reason + on-device fallback recorded in-source and the Dart calibration harness proving clean good-vs-bad separation at the tighter band.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-20T14:55Z (approx)
- **Completed:** 2026-07-20T15:14:44Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `SoftBand.shapeDefault` and the `Tolerances` default ctor args reverted from the pre-demo widened 0.12/0.16 back to the ORIGINAL 0.10/0.15 (single-source invariant preserved — `Tolerances.normal` still equals `SoftBand.shapeDefault`).
- The WIDENED-2026-07-07 comments in both source files rewritten as a dated **D-04 REVERT** note: they cite the painter-stretch bug work-around, its fix in **commit 972427e**, that the Dart calibration harness is the regression guard, and the on-device **FALLBACK** (re-affirm 0.12/0.16 WITH a recorded device reason only if real clean strokes false-fail on the 26-06 pass).
- Whole scoring suite green at 0.10/0.15 — **123 tests pass**. The calibration harness confirms every cell **FN==0** (good seeds pass), **FP==0** (named-bad seeds reject with the expected MistakeId), and the **F5 form-confusion cell is zero passes**.

## Task Commits

Each task was committed atomically:

1. **Task 1: Revert the two soft-band defaults to 0.10/0.15 + record the D-04 decision** — `e4bf3fb` (fix)
2. **Task 2: Pin the scoring tests to the reverted band + prove the harness green** — `1f23a4b` (test)

_TDD note: Task 1 was tagged `tdd="true"`, but this is a revert of an existing, already-covered constant. The behavior is pinned by the existing `tolerances_test` / `soft_verdict_scorer_test` value tests (updated in Task 2) and guarded by the calibration harness; no new RED test file was authored._

## Files Created/Modified
- `lib/core/scoring/shape_match.dart` — `SoftBand.shapeDefault` reverted to `SoftBand(tcc: 0.10, tcw: 0.15)`; the WIDENED note rewritten as the D-04 REVERT record (reason + 972427e + harness guard + fallback).
- `lib/core/scoring/tolerances.dart` — default ctor `shapeTcc = 0.10`, `shapeTcw = 0.15`; both knob doc-comments rewritten as D-04 REVERT notes. `directionCc/directionCw`, `maxCurvature`, and the `fromJson` override path left unchanged.
- `test/core/scoring/tolerances_test.dart` — preset + no-override pins updated `0.12/0.16 → 0.10/0.15`; the single-source equality test and the `0.08/0.20` override round-trip test left untouched.
- `test/core/scoring/soft_verdict_scorer_test.dart` — **(deviation, see below)** its `Tolerances.normal` and `fromJson` value pins were also hard-asserting the widened 0.12/0.16; retightened to 0.10/0.15 so the suite stays green.

## Decisions Made
- **D-04 code half only.** This plan changes the code and pins; on-device feel is the 26-06 device pass's job, where the D-04 FALLBACK lives. Explicitly NOT gated on a mother-labelled calibration set (deferred — she is the Phase-25 bottleneck).
- **Retighten, don't weaken.** Where a test pinned the widened values, the expectation was moved to the originals (0.10/0.15), never relaxed to a range or removed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Retightened the widened-value pins in `soft_verdict_scorer_test.dart`**
- **Found during:** Task 2 (pin the scoring tests)
- **Issue:** The plan's `files_modified` listed only `tolerances_test.dart` for the pin update, but `test/core/scoring/soft_verdict_scorer_test.dart` ALSO hard-asserts `Tolerances.normal.shapeTcc == 0.12` / `shapeTcw == 0.16` (and the `fromJson` no-override pins). After the Task 1 revert these assertions fail — directly caused by this plan's change. Task 2's own acceptance criteria require "the whole scoring suite shows no new failures."
- **Fix:** Updated the two value-pin assertions (and the header doc comment) to the reverted `0.10/0.15`, matching the critical-context guidance ("if the harness pins the widened values, update the expectation to the originals — don't weaken it"). This test file is squarely in the scorer domain owned by this plan; no other wave-1 plan touches it.
- **Files modified:** `test/core/scoring/soft_verdict_scorer_test.dart`
- **Verification:** `flutter test test/core/scoring/` → 123 tests pass.
- **Committed in:** `1f23a4b` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking / Rule 3).
**Impact on plan:** Necessary to satisfy Task 2's "no new failures" criterion. No scope creep — the fix is the same threshold revert applied to a second copy of the same pin. Stayed within the scorer test domain.

## Issues Encountered
- **Pre-existing environmental compile failure (out of scope, NOT fixed as source).** On the fresh worktree checkout `mistake_mapping_test.dart` failed to compile because the gitignored generated l10n (`lib/l10n/app_localizations*.dart`) was absent — the known `l10n-generated-gitignored` condition, unrelated to the threshold revert. Resolved by running `flutter gen-l10n`, which writes only gitignored files (no tracked changes, nothing staged). After codegen the whole scoring suite is green.

## Known Stubs
None — this plan changes two numeric constants and their pins; no placeholder or unwired data introduced.

## Calibration Evidence (harness output at the reverted band)
```
(shipped band for reference: tcc=0.1 tcw=0.15)
confusion table: baa/{base,isolated,initial,medial,final} + taa/isolated — all FN=0, FP=0
F5 form-confusion cell: isolated-bowl-for-medial AND isolated-bowl-for-final BOTH rejected — zero passes
threshold-fit (SEPARABLE, all cells):
  baa/final   good max=0.0300 | shape-bad min=0.1626  (bad stays above tcw=0.15)
  baa/initial good max=0.0523 | shape-bad min=0.4209
  baa/isolated good max=0.0373 | shape-bad min=0.3713
  baa/medial  good max=0.0441 | shape-bad min=0.2356
```
Good-seed distances (max 0.052) sit below the tighter tcc=0.10; the tightest shape-bad (0.1626) sits above tcw=0.15 — separation holds with margin, and tightening only strengthens the F5 gate.

## Note for a follow-up (not blocking; outside this plan's files_modified)
Two files carry now-stale doc-comment references to the old `0.12/0.16` band but are NOT functionally affected (no value assertion breaks): `test/core/scoring/letter_scorer_test.dart` (bowedBaa comment, d≈0.023 still passes below tcc=0.10) and `lib/features/practice/widgets/guide_geometry.dart` (line-13 comment "shapeTcw 0.16"). Left untouched to respect the plan's `files_modified` boundary; flagged here so a later doc-sweep can align the comments.

## Next Phase Readiness
- **26-06 device pass** owns the D-04 on-device validation (alif→thaa walk on the REAL build, no `--dart-define=DEMO=true`). If the reverted originals demonstrably false-fail real clean strokes there, the in-source FALLBACK clause tells the executor exactly how to re-affirm 0.12/0.16 WITH the device reason logged.
- Phase 26 Success Criterion 3 (scorer half) is met: tcc/tcw re-tightened with the decision recorded against calibration data.

## Self-Check: PASSED
- Files verified present: shape_match.dart, tolerances.dart, tolerances_test.dart, soft_verdict_scorer_test.dart, 26-03-SUMMARY.md
- Commits verified: e4bf3fb (Task 1), 1f23a4b (Task 2)

---
*Phase: 26-the-finished-experience-entry-polish-and-the-2-0-1-release*
*Completed: 2026-07-20*
