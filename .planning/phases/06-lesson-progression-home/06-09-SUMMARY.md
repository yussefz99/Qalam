---
phase: 06-lesson-progression-home
plan: 09
subsystem: testing
tags: [curriculum, stroke-validation, d-04, dart, flutter-test, threshold-tuning]

# Dependency graph
requires:
  - phase: 02-curriculum-engine
    provides: D-04 closed-loop guard (stroke_validation.dart), CurriculumRepository load path
  - phase: 04-scoring-quality-calibration
    provides: validateLetter / validateReferenceStrokes / validateStroke validator chain
provides:
  - "kClosedLoopEpsilon lowered 0.30 -> 0.06 (owner sign-off) so 9 curl letters load through the D-04 guard"
  - "Load-time-only scope documented on the guard threshold (validates authored data, not the child's live trace)"
  - "Centerline-sanity regression coverage proving each of the 9 curl letters is an open centerline (>=0.121), not an edge-trace"
affects: [07-tutor-pipeline, curriculum-authoring, stroke-scoring]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Split-the-gap threshold tuning: center the value in the gap between the bug case (~=0.0) and the tightest valid case (taa_h 0.121) for equal margin + drift absorption"
    - "Centerline-sanity assertion decoupled from the exact admission threshold (>=0.12) so it proves shape, not just admission"

key-files:
  created: []
  modified:
    - lib/core/scoring/stroke_validation.dart
    - test/data/curriculum_repository_test.dart

key-decisions:
  - "kClosedLoopEpsilon = 0.06 (owner-directed, NOT the plan's 0.10): split-the-gap margin between a ~=0.0 closed outline and taa_h's 0.121, absorbing re-author drift across all 28 letters about to be redrawn"
  - "Guard scope confirmed LOAD-TIME-only: sole production caller is the D-04 guard via validateReferenceStrokes -> validateStroke; the live scorer references stroke_validation.dart only in a doc-comment, never calls the guard"
  - "Centerline-sanity bound raised to >=0.12 (from the threshold-tied 0.10) so it stays a meaningful shape proof after the threshold dropped to 0.06"

patterns-established:
  - "Curriculum/scoring threshold changes carry an owner sign-off gate (autonomous: false); owner may direct a value different from the plan and the executor records it as a Rule-1 owner-decision deviation"

requirements-completed: [S1-01, S1-09]

# Metrics
duration: ~6min
completed: 2026-06-14
---

# Phase 06 Plan 09: Curl-letter validator threshold (kClosedLoopEpsilon -> 0.06) Summary

**D-04 closed-loop guard threshold lowered 0.30 -> 0.06 (owner sign-off, split-the-gap margin) so the 9 legitimate curl letters load through the load-time validator without false-positiving as closed outlines, while a genuine ~=0.0 closed outline is still rejected.**

## Performance

- **Duration:** ~6 min (continuation segment only; Tasks 1-2 were a prior segment)
- **Completed:** 2026-06-14T15:41:26Z
- **Tasks:** 3 (Tasks 1-2 prior segment; Task 3 owner-decision resolved this segment)
- **Files modified:** 2

## Accomplishments
- Resolved the blocking Task 3 owner-decision checkpoint: owner approved shipping the curl-admitting threshold, directing **0.06** instead of the plan's 0.10.
- Set `kClosedLoopEpsilon = 0.06` and rewrote the doc-comment with the split-the-gap rationale plus a load-time-only scope note.
- Updated `curriculum_repository_test.dart` so no assertion or comment is tied to the old 0.10 value; the centerline-sanity test now proves shape (>=0.12) independent of the admission threshold.
- Gate `flutter test test/data/curriculum_repository_test.dart` green: all 28 tests pass; 9 curl letters load; the true ~=0.0 outline fixture is still rejected.

## Task Commits

1. **Task 1 (RED): curl-letter admission test** - `e5e0e2f` (test) — prior segment
2. **Task 1 (GREEN): lower kClosedLoopEpsilon 0.30 -> 0.10 + curl-vs-outline doc** - `646c47f` (fix) — prior segment
3. **Task 2: curl-letter centerline-sanity diagnostic** - `de7077c` (test) — prior segment
4. **Task 3 (owner-directed change): set kClosedLoopEpsilon to 0.06** - `d03b1bd` (fix) — this segment

_Note: Task 2's name in 06-FIXES context = "confirm-before-shipping". Tasks 1-2 were committed in the prior execution segment; this segment carried the owner's sign-off into a fourth atomic commit that supersedes the 0.10 value with 0.06._

## Files Created/Modified
- `lib/core/scoring/stroke_validation.dart` - `kClosedLoopEpsilon` 0.10 -> 0.06; doc-comment rewritten with split-the-gap rationale, the load-time-reference-only scope note, the curl-vs-outline distinction, taa_h's 0.121, and the retained enclosed-area future-alternative note. `kLoopLengthRatio` (1.8) and `kCoordTolerance` untouched.
- `test/data/curriculum_repository_test.dart` - comments updated from 0.10 to 0.06; centerline-sanity admission bound raised 0.10 -> 0.12 (decoupled from the threshold) with reason text updated; all 9 curl letters (>=0.121) remain admitted; gate stays green.

## Decisions Made

### Task 3 owner sign-off (decision: confirm, value 0.06)
The owner approved shipping the curl-admitting guard but directed the value be **0.06**, not the plan's 0.10. This closes the blocking `checkpoint:decision` gate (selected option: confirm, with an amended value).

**Owner's rationale (recorded verbatim per checkpoint):** 0.10 hugs the valid cases — it clears a true ~=0.0 closed outline by 0.10 but clears the tightest real curl (taa_h at 0.121) by only 0.021. Centering at ~0.06 splits the gap, keeping roughly equal margin on both sides while still rejecting the Phase-2 alif closed-outline bug. This matters because the guard validates AUTHORED reference data and all 28 letters are about to be re-authored; taa_h's 0.121 is a property of the current rough draft and could drift tighter when redrawn — 0.06 absorbs that drift, 0.10 does not.

### Owner's blocking question — ANSWERED (load-time-only finding)
The closed-loop guard runs **ONLY** on authored reference data at load time. The sole production caller is the D-04 guard in `lib/data/curriculum_repository.dart`, via `validateReferenceStrokes` -> `validateStroke`. It does **NOT** touch the child's live trace during scoring — the live scorer (`geometric_stroke_scorer.dart` / `letter_scorer.dart`) references `stroke_validation.dart` only in a doc-comment and never calls the guard. So the threshold's margin affects curriculum-data validation only, not live scoring. This is why the 0.06 sign-off stands without any live-scoring impact assessment.

### Task 2 centerline-sanity result (recorded for the record)
All 9 curl letters are genuine open centerlines, every one ending well clear of a ~=0.0 return-to-start outline (jeem 0.289, haa_c 0.270, khaa 0.272, saad 0.193, daad 0.189, taa_h 0.121, ayn 0.268, ghayn 0.258, faa 0.265). None is an edge-trace being masked by the threshold; none required owner re-authoring. taa_h at 0.121 is the tightest, and 0.06 clears it by 0.061.

## Deviations from Plan

### Owner-directed value change (Rule 1 - owner decision, not a defect)

**1. [Rule 1 - Owner decision] Ship kClosedLoopEpsilon at 0.06 instead of the plan's 0.10**
- **Found during:** Task 3 (owner sign-off checkpoint)
- **Issue:** The plan specified 0.10 and the must_haves/artifacts text references `kClosedLoopEpsilon = 0.10`. At the sign-off gate the owner approved the change but directed 0.06.
- **Fix:** Set the constant to 0.06; rewrote the doc-comment to explain the split-the-gap rationale and the load-time-only scope; updated the test's comment/assertion so nothing is pinned to the obsolete 0.10. The plan's intent (admit all 9 curl letters, still reject a ~=0.0 outline) is fully satisfied — 0.06 admits the same 9 (all >=0.121) and rejects the outline fixture.
- **Files modified:** lib/core/scoring/stroke_validation.dart, test/data/curriculum_repository_test.dart
- **Verification:** `flutter test test/data/curriculum_repository_test.dart` exits 0 (28/28); the closed-loop-outline rejection test still passes.
- **Committed in:** d03b1bd

---

**Total deviations:** 1 (owner-directed value change at the sign-off gate)
**Impact on plan:** The owner-directed 0.06 is within and beyond the plan's safety intent (wider rejection margin on the outline side, more drift headroom on the curl side). No scope creep; curriculum stroke data and `signedOff` flags untouched.

## Issues Encountered
None. The pre-existing uncommitted `assets/curriculum/letters.json` working-tree change (the owner's unsigned curl-letter drafts from the 06-FIXES handoff) was deliberately NOT staged or committed — files were staged individually, never `git add -A`.

## Threat Model Compliance
- T-06-09-01 (re-loosened by mistake): doc-comment now self-documents the split-the-gap rationale, names taa_h's 0.121, and records the 0.06 margin — mitigated.
- T-06-09-02 (outline slips through): the "closed-loop reference stroke makes load throw" test still passes at 0.06; centerline-sanity test (>=0.12) retained — mitigated.
- T-06-09-03 (changed without owner authority): blocking owner sign-off obtained at Task 3 (autonomous: false); choice recorded above — mitigated.

## Next Phase Readiness
- The 9 curl letters now load on-device; the launch -> today's-lesson -> pass -> unlock loop (S1-01, S1-09) is restored for them.
- Note for future curriculum authoring: the guard's 0.06 margin assumes curl centerlines stay >=~0.06 from start; the centerline-sanity test (>=0.12) will catch any re-authored stroke that drifts toward an edge-trace.
- Sibling gap-closure plan 06-10 (dot rendering, Fix B) is already complete per STATE.

## Self-Check: PASSED

- FOUND: .planning/phases/06-lesson-progression-home/06-09-SUMMARY.md
- FOUND commits: e5e0e2f, 646c47f, de7077c, d03b1bd

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-14*
