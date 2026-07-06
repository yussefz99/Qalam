---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 01
subsystem: testing
tags: [scorer, dtw, soft-verdict, per-form, red-contract, tdd, wave-0]

# Dependency graph
requires:
  - phase: 16-presence-voice-eval-demo
    provides: "shape_match.dart DTW core (commit 4e71d6b) + SoftBand 3-zone scheme the contract consumes"
  - phase: 04-scoring-quality-calibration
    provides: "scoreStroke/scoreLetter spine, Tolerances preset+overrides idiom, MistakeId check-string contract"
provides:
  - "Executable RED contract for increment 2 (soft 3-zone per-stroke verdict): test/core/scoring/soft_verdict_scorer_test.dart"
  - "Executable RED contract for increment 3 (per-form multi-criteria scoreLetter): test/core/scoring/letter_scorer_per_form_test.dart"
  - "Pinned target API: Tolerances{shapeTcc,shapeTcw,directionCc,directionCw}, CriterionResult{criterion,zone,score}, StrokeResult.criteria, LetterScore extends LetterResult{criteria,weakest}, resolveReferenceStrokes(Letter,String? form)"
affects: [17-02, 17-03, 17-04, 17-05, scorer, coaching-contract]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave-0 RED-by-missing-symbol contract (Nyquist rule; 15-01/16-01 precedent) — compile errors count as RED"
    - "Perturbation fixtures built from the REAL authored curriculum reference (shape_match_test technique), never invented shapes"
    - "Midpoint densify() helper so authored polylines clear the firm minRawPoints floor without changing shape"

key-files:
  created:
    - test/core/scoring/soft_verdict_scorer_test.dart
    - test/core/scoring/letter_scorer_per_form_test.dart
  modified: []

key-decisions:
  - "CriterionResult field pinned as `criterion` (never `name`, never *point*) so the future wire payload passes the non-PII token regex guards by construction (T-17-02)"
  - "Degenerate tooShort strokes are exempt from the shape+direction criteria assertion — the firm raw-point floor short-circuits BEFORE geometry"
  - "STRK-01 deliberately NOT checkbox-marked at this Wave-0 contract plan — it spans plans 17-02..17-09; the plan that lands the last leg flips it"

patterns-established:
  - "Five-criteria set (strokeCount/strokeOrder/shape/direction/dot) is the OWNER-CONFIRMED D-C amendment of 2026-07-05 — kinematics descoped, position folded into the firm dot check"
  - "F5 form-trap fixture pair: isolated-bowl strokes scored against the medial reference must FAIL at the SCORER"

requirements-completed: [STRK-01]

# Metrics
duration: 26min
completed: 2026-07-06
---

# Phase 17 Plan 01: Wave-0 RED Contract for the Scorer Upgrade Summary

**Two RED test files pin the full increment-2/3 scorer API — soft 3-zone DTW per-stroke verdicts (Tolerances soft-band knobs, CriterionResult, StrokeResult.criteria) and per-form multi-criteria scoreLetter (LetterScore/weakest, resolveReferenceStrokes, the F5 form-trap) — over the REAL authored baa isolated+medial references, before any implementation exists.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-07-06T09:55:22Z
- **Completed:** 2026-07-06T10:21:46Z
- **Tasks:** 2
- **Files modified:** 2 (both created)

## Accomplishments

- Every increment-2 behavior 17-02 must implement has a failing executable assertion first: shaky-correct bowl PASSES (F2 fix, fuzzy passes), flat-line bowl fails as the KEPT `MistakeId.tooCurved` with shape zone certainlyWrong, direction stays a criterion (D-C), the tooShort raw-point floor stays firm, and the four `Tolerances` soft-band knobs (`shapeTcc`/`shapeTcw` == `SoftBand.shapeDefault`, `directionCc` 0.3 / `directionCw` -0.3) are data with `fromJson` overrides (D-D).
- Every increment-3 behavior 17-03 must implement has a failing executable assertion first: `scoreLetter(..., form:)` → `Future<LetterScore>` (extends `LetterResult`, source-compatible), the shared `resolveReferenceStrokes` resolver (Pitfall 7: non-null form + non-empty list, else base reference), the exact five-criteria set, `weakest` = minimum-score criterion on pass AND fail (D-B coaching target), firm dot/count checks stay categorical certainlyWrong/0.0, and the F5 trap (isolated bowl offered for the medial slot fails at the SCORER).
- Both files RED by missing symbol (verified non-zero exit, compile errors name only the missing target API); the existing scoring suite (shape_match, geometric_stroke_scorer, letter_scorer, tolerances — 43 tests) untouched and green.
- Fixtures are perturbations of the REAL authored baa references from `assets/curriculum/letters.json` (isolated bowl 12pts, medial tooth 8pts, each + dot) — no child data, no PII (T-17-01); the CriterionResult field is `criterion`, never `name`/`*point*` (T-17-02).

## Task Commits

Each task was committed atomically:

1. **Task 1: RED contract for the soft per-stroke verdict (increment 2)** - `f24c26b` (test)
2. **Task 2: RED contract for per-form multi-criteria letter scoring (increment 3)** - `94d58f0` (test)

## Files Created/Modified

- `test/core/scoring/soft_verdict_scorer_test.dart` - RED contract for scoreStroke soft verdict via shapeDistance + Tolerances soft-band knobs (210 lines)
- `test/core/scoring/letter_scorer_per_form_test.dart` - RED contract for per-form scoreLetter, LetterScore/CriterionResult, weakest selection, F5 form-trap (372 lines)

## Decisions Made

- **`criterion`, not `name`:** the CriterionResult construction and every read in both files use the `criterion` field name — `name` trips the non-PII token regex in the payload guards (pattern-map warning), so the wire-safe naming is pinned at the contract layer.
- **Degenerate-stroke exemption:** the "every scored stroke carries shape AND direction criteria" assertion covers strokes that reach geometry (shaky/flat/reversed); the 1-point tooShort tap is exempt because the firm floor short-circuits before geometric scoring — this keeps the contract implementable without faking geometry on degenerate input.
- **Medial fixture densification:** the authored medial tooth has 8 points, below the firm `minRawPoints` floor (10); the good-medial fixture midpoint-densifies to 15 points before adding the shake jitter — arc-length resampling makes the densified polyline geometrically identical, so the fixture stays a faithful perturbation of the REAL authored reference.
- **STRK-01 not checkbox-marked:** see Deviations.

## Deviations from Plan

### Deliberate Process Deviation

**1. [Judgment call] Skipped `requirements mark-complete STRK-01` at this plan**
- **Found during:** Close-out (requirements step)
- **Issue:** The mechanical step marks every frontmatter requirement complete per plan, but STRK-01 ("the coach names the SPECIFIC geometry of the child's actual attempt") appears on 8 of the 10 phase plans (through 17-09). A Wave-0 RED contract does not satisfy it; flipping the checkbox now would show a core requirement Complete in REQUIREMENTS.md traceability while 9 plans remain.
- **Fix:** Left the STRK-01 checkbox/traceability row Pending; the SUMMARY frontmatter still records the plan's `requirements` array verbatim per template. The plan that lands the final STRK-01 leg (or the phase verifier) flips it.
- **Files modified:** none (REQUIREMENTS.md deliberately untouched)
- **Verification:** `grep "STRK-01" .planning/REQUIREMENTS.md` still shows `- [ ]` and `Pending`
- **Committed in:** n/a

---

**Total deviations:** 1 (process-level judgment call; zero code deviations — both tasks executed exactly as written)
**Impact on plan:** None on the RED contract itself. Prevents a false-complete requirement signal for downstream planning/verification.

## Issues Encountered

None — both files landed RED for exactly the right reason (missing target symbols only: `shapeTcc`/`shapeTcw`/`directionCc`/`directionCw`, `CriterionResult`, `StrokeResult.criteria`, `LetterScore`, `resolveReferenceStrokes`/`reference_resolution.dart`, `form:`), verified via analyzer diagnostics and non-zero `flutter test` exits.

## Known Stubs

None — both files are executable test contracts; no placeholder values flow to any UI or runtime path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 17-02 (Wave 1) can start immediately: implement the soft per-stroke verdict to turn `soft_verdict_scorer_test.dart` GREEN with zero test edits.
- 17-03 can follow: implement per-form `scoreLetter` + `reference_resolution.dart` to turn `letter_scorer_per_form_test.dart` GREEN with zero test edits.
- Branch discipline honored: all commits on `gsd/phase-17-stroke-aware-coaching` (created from the phase-16 tip `cadcdad`; dependency commits 4e71d6b + 09d2cde verified ancestors). Never touched the phase-16 branch or main.

## Self-Check: PASSED

- Both created test files exist on disk; SUMMARY exists.
- Commits f24c26b + 94d58f0 present in git log.
- RED verification: both new files exit non-zero (`RED-CONFIRMED`); existing 4-suite scoring run (43 tests) exits 0.
- `git diff --stat cadcdad..HEAD` shows only the two new test files (582 insertions, no lib/ changes).

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
