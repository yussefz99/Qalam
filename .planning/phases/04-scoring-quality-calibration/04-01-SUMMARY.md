---
phase: 04-scoring-quality-calibration
plan: 01
subsystem: scoring
tags: [dart, tolerances, scoring, mlkit, tdd, curriculum, validation]

# Dependency graph
requires:
  - phase: 03-handwriting-scoring
    provides: "geometric_stroke_scorer.dart (scoreStroke + threshold consts), scoring_models.dart (MistakeId/StrokeResult), stroke_validation.dart (V5 curriculum validator), HandwritingRecognizer interface seam"
  - phase: 02-curriculum-schema
    provides: "Letter/StrokeSpec/CommonMistake/AudioRef models + Letter.fromJson"
provides:
  - "Data-driven Tolerances class (loose/normal/strict presets + numeric overrides) — normal == today's scorer constants (behavior-preserving)"
  - "Extended MistakeId enum: wrongStrokeCount/wrongStrokeOrder/dotMisplaced/wrongLetterIdentity"
  - "LetterResult value class with .fail(id)/.pass() factories"
  - "Letter.tolerances field (nullable, backward-compat) parsed in Letter.fromJson"
  - "validateTolerances + validateLetter (V5 range-check for the tolerances block)"
  - "RED letter_scorer_test.dart — the SC#1/SC#2/D-04 contract Plan 04-02 must satisfy"
affects: [04-02-letter-scorer, ml-kit-identity-gate, calibration-harness, curriculum-authoring]

# Tech tracking
tech-stack:
  added: ["mocktail ^1.0.5 (dev-dep — HandwritingRecognizer fake in unit tests)"]
  patterns:
    - "Tolerances as DATA not code (preset + numeric overrides); normal preset is a LOCKED behavior-preserving anchor"
    - "LetterResult mirrors StrokeResult one level up (whole-letter verdict object)"
    - "RED-via-skip contract test: skipped tests with a Plan-02 reason keep the suite compiling while encoding the future contract"

key-files:
  created:
    - lib/core/scoring/tolerances.dart
    - test/core/scoring/tolerances_test.dart
    - test/core/scoring/letter_scorer_test.dart
  modified:
    - lib/core/scoring/scoring_models.dart
    - lib/models/letter.dart
    - lib/core/scoring/stroke_validation.dart
    - lib/features/practice/practice_screen.dart
    - lib/features/practice/widgets/feedback_panel.dart
    - pubspec.yaml

key-decisions:
  - "loose/strict presets move ONLY maxCurvature (0.35 / 0.18) for now; minRawPoints+resampleN stay at normal until calibration proves a reason to diverge them"
  - "validateTolerances added as a SIBLING (not folded into validateReferenceStrokes) + a validateLetter convenience that runs both — keeps the existing validator signature stable"
  - "New whole-letter MistakeId values get specific authored placeholder copy in the _feedbackString switches now (never a generic Oops); Plan 02 wires the real l10n getters"

patterns-established:
  - "Tolerances.fromJson defensive parse idiom (reads preset, applies numeric overrides, never throws) mirroring StrokeSpec.fromJson"
  - "RED-via-skip whole-letter contract test pattern for Wave-0 interface-first plans"

requirements-completed: [S1-05, PLAT-03]

# Metrics
duration: 6min
completed: 2026-06-08
---

# Phase 4 Plan 01: Scoring Contract Foundation Summary

**Data-driven Tolerances (loose/normal/strict, normal == today's constants), extended MistakeId + LetterResult, backward-compatible Letter.tolerances with a load-time validator, and the RED scoreLetter contract test that pins SC#1/SC#2/D-04 for Plan 02.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-08T13:13:23Z
- **Completed:** 2026-06-08T13:19:14Z
- **Tasks:** 2
- **Files modified:** 9 (3 created, 6 modified)

## Accomplishments
- Relocated the geometric scorer's hardcoded thresholds (`_kMinRawPoints=10`, `_kResampleN=32`, `_kMaxCurvature=0.25`) into a pure-Dart `Tolerances` class whose `normal` preset equals those exact values (SC#4 foundation, behavior-preserving — A5).
- Extended `MistakeId` with the four whole-letter failure categories and added a `LetterResult` value class with `.fail(id)`/`.pass()` factories — the enum-name == `commonMistakes[].check` contract holds for all four (PLAT-03 / Pitfall 7).
- Added `Letter.tolerances` (nullable, backward-compat for Phase-2 entries) parsed in `Letter.fromJson`, plus `validateTolerances`/`validateLetter` that range-check the block and return violation strings without throwing (V5 / T-04-01).
- Wrote the RED `letter_scorer_test.dart`: the live Task-2 tests (backward-compat parse + validator) are green, and 6 skipped contract tests encode SC#1 (count/order/dot), SC#2 (ML Kit identity), and the D-04 advisory-only rule for Plan 02.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend MistakeId + LetterResult, create data-driven Tolerances** - `c31af8e` (feat)
2. **Task 2: Letter.tolerances field, validator, RED scoreLetter contract** - `ad4499b` (feat)

_TDD note: Task 1's tolerances_test was written RED-first (Tolerances undefined), then turned green by the implementation in the same logical unit. Task 2's RED contract tests are intentionally skipped pending Plan 02._

## Files Created/Modified
- `lib/core/scoring/tolerances.dart` (created) - Tolerances class: loose/normal/strict presets + numeric overrides, pure Dart, normal == A5 constants.
- `test/core/scoring/tolerances_test.dart` (created) - 7 tests pinning presets, the normal anchor, and overrides.
- `test/core/scoring/letter_scorer_test.dart` (created) - Live backward-compat + validator tests (green) + 6 RED scoreLetter contract tests (skipped, Plan 02).
- `lib/core/scoring/scoring_models.dart` (modified) - Added 4 MistakeId values + LetterResult.
- `lib/models/letter.dart` (modified) - Added `Tolerances? tolerances` field + fromJson parse; imports tolerances.dart.
- `lib/core/scoring/stroke_validation.dart` (modified) - Added validateTolerances + validateLetter (V5 range-check).
- `lib/features/practice/practice_screen.dart` (modified) - 4 new _feedbackString switch cases (Rule 3).
- `lib/features/practice/widgets/feedback_panel.dart` (modified) - 4 new _feedbackString switch cases (Rule 3).
- `pubspec.yaml` (modified) - Added mocktail ^1.0.5 dev-dep.

## Decisions Made
- `loose`/`strict` presets move only `maxCurvature` (0.35 / 0.18); the other two knobs stay at `normal` until calibration data justifies diverging them — keeps the surface area minimal for Plan 02.
- `validateTolerances` is a sibling function (plus a `validateLetter` convenience that runs both stroke + tolerances checks) rather than being folded into `validateReferenceStrokes`, preserving the existing validator signature its callers depend on.
- Tolerance range bounds chosen generously (`minRawPoints` 1..256, `resampleN` 2..512, `maxCurvature` (0,1]) — reject nonsense without second-guessing the owner's calibrated presets.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Non-exhaustive MistakeId switches broke the build after the enum was extended**
- **Found during:** Task 2 (after extending MistakeId in Task 1)
- **Issue:** Dart exhaustiveness made `_feedbackString` in `practice_screen.dart:1118` and `feedback_panel.dart:131` non-compiling (`non_exhaustive_switch_statement`) once the four new enum values existed — `flutter analyze lib/` reported 2 errors.
- **Fix:** Added the four new `case` arms to both switches with specific, warm placeholder copy in the tutor's voice (never a generic "Oops" — Pitfall 7 / PLAT-03). The authored l10n getters are wired by Plan 02 per PATTERNS; the placeholders are honest letter-level guidance until then.
- **Files modified:** lib/features/practice/practice_screen.dart, lib/features/practice/widgets/feedback_panel.dart
- **Verification:** `flutter analyze lib/` → 0 errors; `flutter test test/core/scoring/` → 35 passed / 6 skipped.
- **Committed in:** ad4499b (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required to keep the build compiling after the planned enum extension; PATTERNS already flagged these two switches as needing the new cases. No scope creep — placeholder copy is intentionally replaced by Plan 02's authored l10n strings.

## Issues Encountered
None — planned work proceeded as written. The mocktail dev-dep (a pre-vetted pub.dev package per STACK.md, not an npm/pip/cargo install — T-04-SC) resolved cleanly via `flutter pub get`.

## Known Stubs
- `_feedbackString` placeholder copy for the four new whole-letter MistakeId values (practice_screen.dart, feedback_panel.dart) is specific but not yet the mother's authored l10n strings. **Resolved by Plan 04-02**, which wires the scorer and the authored l10n getters (documented in 04-PATTERNS.md §practice_screen). Not a goal-blocking stub for this Wave-0 contract plan — no scoring path returns these values yet (scoreLetter unimplemented).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 04-02 can implement `scoreLetter` against the live types (`LetterResult`, extended `MistakeId`, `Letter.tolerances`) and turn the 6 skipped contract tests green by removing their `skip:` and wiring the real call.
- `Tolerances` threads into the geometric predicates next (Plan 02 reads `letter.tolerances` instead of the file-level consts in geometric_stroke_scorer.dart).
- ML Kit `HandwritingRecognizer` implementation + model-download service remain downstream (later plans in this phase).

## Threat Flags
None — no new network endpoints, auth paths, or trust-boundary surface beyond the curriculum-JSON → Letter boundary already in the plan's threat model (T-04-01 mitigated by validateTolerances).

## Self-Check: PASSED

- Created files verified present: tolerances.dart, tolerances_test.dart, letter_scorer_test.dart, 04-01-SUMMARY.md.
- Commits verified in git log: c31af8e (Task 1), ad4499b (Task 2).

---
*Phase: 04-scoring-quality-calibration*
*Completed: 2026-06-08*
