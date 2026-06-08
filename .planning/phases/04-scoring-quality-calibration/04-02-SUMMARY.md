---
phase: 04-scoring-quality-calibration
plan: 02
subsystem: scoring
tags: [dart, scoring, orchestrator, tolerances, mlkit, tdd, normalization]

# Dependency graph
requires:
  - phase: 04-scoring-quality-calibration
    plan: 01
    provides: "Tolerances class (loose/normal/strict + overrides), extended MistakeId (count/order/dot/identity), LetterResult, Letter.tolerances, validateTolerances/validateLetter, RED scoreLetter contract test"
  - phase: 03-handwriting-scoring
    provides: "scoreStroke leaf + named predicates, StrokeResult, HandwritingRecognizer seam, stroke_resampler primitives"
provides:
  - "scoreLetter — the pure-Dart whole-letter orchestrator: count → order → per-stroke shape → dot → advisory ML Kit identity gate"
  - "scoreStroke parameterized by Tolerances (defaults to Tolerances.normal; A5 behavior-preserving) — the file-level threshold consts are gone"
  - "Combined-bbox whole-letter dot-position check (baa-dot-below vs taa-dots-above, Pitfall 2)"
  - "Advisory-only ML Kit identity gate (D-04 / Pitfall 1): rejects a confidently-different letter, never overrides a pass on weak evidence"
  - "SC#3 multi-stroke normalization regression pair (small/offset baa passes; same baa dot-above fails dotMisplaced)"
affects: [ml-kit-identity-gate, calibration-harness, practice-screen-scoring, curriculum-authoring]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "First-failing-predicate orchestrator returning a value object (LetterResult), mirroring scoreStroke one level up"
    - "Tolerances threaded as a positional arg (default Tolerances.normal) so single-stroke alif callers are untouched"
    - "Combined-bbox normalization (replicating authoring_export._combinedBounds) for relative dot position, NOT per-stroke normalizeToUnitBox"
    - "ML Kit gate is async + advisory-only: scoreLetter returns Future<LetterResult>"

key-files:
  created:
    - lib/core/scoring/letter_scorer.dart
  modified:
    - lib/core/scoring/geometric_stroke_scorer.dart
    - test/core/scoring/letter_scorer_test.dart

key-decisions:
  - "scoreLetter returns Future<LetterResult> (async) because the advisory ML Kit identity gate is async; geometric-only callers await a synchronously-resolved future"
  - "Child stroke classified as a dot/tap when it carries <= 3 points (_kDotPointCeiling) — used for ORDER-sequence matching against the reference body/dot pattern"
  - "Identity gate confidence floor = 0.5: below it the candidate is ignored (Pitfall 1); at/above AND a different char from letter.char → wrongLetterIdentity"
  - "SC#3 multi-stroke coverage placed in letter_scorer_test.dart (the orchestrator owns multi-stroke); geometric_stroke_scorer_test.dart keeps its single-stroke smallCorrect invariance and is unchanged"

patterns-established:
  - "Whole-letter combined-bbox normalization for relative-position predicates (the dot up/down signal that distinguishes baa from taa)"
  - "Advisory-only async gate pattern: consult external judge AFTER a local pass, allow it to reject only on strong evidence, never to rescue"

requirements-completed: [S1-05, PLAT-03]

# Metrics
duration: 5min
completed: 2026-06-08
---

# Phase 4 Plan 02: The scoreLetter Spine Summary

**The pure-Dart `scoreLetter` orchestrator (count → order → per-stroke shape → combined-bbox dot → advisory ML Kit identity gate) that turns the Plan 01 RED contract GREEN, with `scoreStroke` now reading per-letter `Tolerances` instead of file-level constants and an SC#3 multi-stroke normalization regression pair proving size/offset leniency without erasing the baa↔taa dot distinction.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-08T13:22:27Z
- **Completed:** 2026-06-08T13:27:26Z
- **Tasks:** 2
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- Built `lib/core/scoring/letter_scorer.dart` — the whole-letter SPINE. `scoreLetter` partitions the reference into body/dot exactly as `stroke_validation` does, then runs COUNT (firm even when shape tolerance is generous — Pitfall 4) → ORDER (body/dot draw-sequence match) → per-stroke SHAPE (delegated to `scoreStroke` threaded with `letter.tolerances`) → DOT (count + relative position via whole-letter combined-bbox normalization — Pitfall 2) → an advisory-only ML Kit identity gate (D-04 / Pitfall 1).
- Refactored `geometric_stroke_scorer.dart` so `scoreStroke` and its two threshold predicates (`strokeLengthBelowThreshold`, `strokeCurvatureExceedsThreshold`) read knobs from a `Tolerances` argument (defaulting to `Tolerances.normal`), removing the file-level `_kMinRawPoints`/`_kResampleN`/`_kMaxCurvature` consts. Predicate function names are untouched — the check-string contract is binding. alif under `normal` scores identically (A5 behavior-preserving).
- Turned the 6 Plan 04-01 RED scoreLetter contract tests GREEN: wrong-count → `wrongStrokeCount`, wrong-order (dot before body) → `wrongStrokeOrder`, taa-dots-for-baa → `dotMisplaced`, confidently-different ML Kit candidate → `wrongLetterIdentity`, low-confidence candidate does NOT override a geometric pass, and the sub-50 ms latency budget. Added an explicit good-faith-baa-passes assertion.
- Added the SC#3 + Pitfall-2 regression pair: a ~40%-scale, corner-offset, correct baa passes (combined-bbox normalization absorbs size + offset), while the SAME small baa with the dot ABOVE the body still fails with `dotMisplaced`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build scoreLetter spine + parameterize scoreStroke tolerances** - `82a4661` (feat)
2. **Task 2: Add SC#3 multi-stroke normalization regression pair** - `7199bf6` (test)

_TDD note: Task 1 was RED-first — the contract test was un-skipped and wired to a not-yet-existing `scoreLetter` (compile-RED), then the orchestrator was implemented to GREEN. Task 2 added two new failing-then-passing regression assertions._

## Files Created/Modified
- `lib/core/scoring/letter_scorer.dart` (created) — pure-Dart `scoreLetter` orchestrator. Count/order/shape/dot/identity, combined-bbox dot-position normalization, advisory-only async ML Kit gate. No `dart:ui`/Flutter imports; no `referenceStrokes.first` shortcut.
- `lib/core/scoring/geometric_stroke_scorer.dart` (modified) — `scoreStroke` + two predicates now take a `Tolerances` arg (default `Tolerances.normal`); removed the three file-level threshold consts (rationale doc-comments now live beside `Tolerances.normal`'s fields). Predicate names unchanged.
- `test/core/scoring/letter_scorer_test.dart` (modified) — un-skipped + wired the 6 RED contract tests, added a good-faith-baa-passes test, added the SC#3 regression group (2 tests) with small/offset multi-stroke baa fixtures and a `registerFallbackValue` for the mocktail `any()` arg.

## Decisions Made
- `scoreLetter` is **async** (`Future<LetterResult>`). The advisory ML Kit identity gate calls the async `HandwritingRecognizer.identify`; making the whole orchestrator async keeps the gate inline rather than forcing a two-call split. Geometric-only callers simply `await` a future that resolves without I/O.
- A child stroke is classified as a **dot/tap** when it has `<= 3` points (`_kDotPointCeiling`). The reference tells us which draw positions are dots; comparing the child's body/dot classification sequence against the reference's catches "dot drawn before the boat" as `wrongStrokeOrder`.
- The **identity-gate confidence floor is 0.5**. Below it, the candidate is ignored entirely (Pitfall 1 — never gate a pass on weak evidence); at/above it AND a different `char` than the letter → `wrongLetterIdentity`. A matching or null candidate never conflicts.
- **Relative dot position** is decided by combined-bbox-normalized **y-centroid** of the dot vs the body: `dotY > bodyY` means "below" (y increases downward). The reference's own geometry supplies the expected side, so the check generalizes to taa/thaa (dots above) without hardcoding baa.

## Deviations from Plan

### Auto-fixed Issues
None.

### Scope notes (not deviations)
- The plan's `files_modified` listed `test/core/scoring/geometric_stroke_scorer_test.dart`. The SC#3 **multi-stroke** coverage belongs to the orchestrator, so both new tests landed in `letter_scorer_test.dart` (the Task 2 action text explicitly permits "or a shared fixture file"). `geometric_stroke_scorer_test.dart` already proves single-stroke size/offset invariance (`smallCorrect`) and remains GREEN and unchanged under the `normal` preset — the A5 behavior-preserving guarantee is intact.
- `scoreLetter` became `Future`-returning (see Decisions). The Plan 01 contract test sketch called it synchronously in comments; the live tests `await` it. No contract semantics changed — the same MistakeIds are returned.

**Total deviations:** 0 auto-fixed. Two scope notes, both within the plan's stated latitude.

## Issues Encountered
None — the work composed cleanly over the Plan 01 foundation. No package-manager installs (T-04-SC N/A).

## Known Stubs
None introduced by this plan. (The Plan 01 `_feedbackString` placeholder copy for the new MistakeId values remains pending its authored l10n strings — that is owned by a later plan in this phase, not regressed here. The scorer now returns those MistakeIds, so the placeholder copy is reachable; it is honest letter-level guidance in the tutor's voice, never a generic "Oops".)

## User Setup Required
None.

## Next Phase Readiness
- `scoreLetter` is the live spine subsequent plans wire into the practice screen (replacing the `referenceStrokes.first` single-stroke call) and the calibration harness (running the REAL scorer over labeled fixtures).
- The ML Kit identity gate seam is in place and advisory-only; the real `MlKitRecognizer` (Plan 03) plugs into the same `HandwritingRecognizer` interface the gate already consumes.
- `scoreStroke` reads `Tolerances` — curriculum authoring can now tune per-letter leniency via the `tolerances` block with no code change (SC#4).

## Threat Flags
None — no new network endpoints, auth paths, or trust-boundary surface beyond the in-memory child-strokes → `scoreLetter` boundary already in the plan's threat model. T-04-03 (no logging/persistence of raw points) and T-04-04 (count-first + resample cap + latency assert) are honored: child points live only in local variables, nothing is printed/persisted, and the < 50 ms latency assertion guards the DoS budget.

## Self-Check: PASSED

- Created file verified present: lib/core/scoring/letter_scorer.dart.
- Commits verified in git log: 82a4661 (Task 1), 7199bf6 (Task 2).
- `flutter test test/core/scoring/` → 44 passed / 0 failed; pure-Dart grep = 0; `referenceStrokes.first` grep = 0; `flutter analyze lib/` → 0 errors.

---
*Phase: 04-scoring-quality-calibration*
*Completed: 2026-06-08*
