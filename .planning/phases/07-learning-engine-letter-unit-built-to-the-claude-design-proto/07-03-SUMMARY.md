---
phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto
plan: 03
subsystem: testing
tags: [validator, scoring, exercise-engine, tdd, dart, baa, curriculum]

# Dependency graph
requires:
  - phase: 04 (scoring)
    provides: scoreLetter geometric whole-letter scorer + MistakeId enum (reused verbatim)
  - phase: 07-01 (schema, PARALLEL — see Deviation 1)
    provides: the locked Schema-v2 Exercise/Check/Answer shape (mirrored by the validator-facing ExerciseSpec view)
provides:
  - "validateExercise(exercise, strokes, {letter, writtenWord, writtenWords, writtenForm, penLiftedBetweenLetters}) → Future<CheckResult>"
  - "CheckResult { passed, mistakeId? } — the validator → FeedbackPanel contract"
  - "ExerciseSpec/CheckSpec/AnswerSpec — the validator-facing view of the locked check+expected+feedback"
  - "glyph/sequence/order dispatch + positionalForm/joinContinuity/transformRule modifiers over the one geometric scorer"
affects: [07-04 (FeedbackPanel + WriteSurface), 07-05, 07-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One core scorer + two thin wrappers + a few rule checks (COMPONENT-SYSTEM.md §6)"
    - "Validator-facing narrow view (ExerciseSpec) to decouple from a parallel-wave model"
    - "Scorer MistakeId → authored feedback key translation (never raw scorer internals)"

key-files:
  created:
    - lib/core/exercise_engine/check_result.dart
    - lib/core/exercise_engine/exercise_check.dart
    - lib/core/exercise_engine/exercise_validator.dart
    - test/core/exercise_engine/exercise_validator_test.dart
  modified: []

key-decisions:
  - "validateExercise depends on a narrow ExerciseSpec view (check+expected+feedback), NOT lib/models/exercise.dart — that model is owned by the parallel wave-1 Plan 07-01 and would collide on merge. 07-04 adapts the real Exercise via ExerciseSpec.fromExercise (mechanical, field names match the locked schema)."
  - "Strokes typed List<List<List<double>>> (pixel [x,y] pairs) to match the existing scoreLetter signature verbatim, not the plan's List<List<Offset>> — avoids an Offset↔double-list conversion seam and keeps the glyph base a pure delegation."
  - "The scorer's geometric MistakeId is translated to the exercise's OWN authored feedback keys via an ordered candidate map; an unmatched id falls back to the first non-'pass' authored key — no raw scorer text can ever surface (T-07-03-02)."

patterns-established:
  - "CheckResult.pass()/.fail(mistakeId) factories mirror LetterResult one level up"
  - "Each Check.base is a switch arm; each modifier is a small layered rule check returning an authored key or null"

requirements-completed: [CUR-01]

# Metrics
duration: ~35min
completed: 2026-06-15
---

# Phase 7 Plan 03: Validator Spine Summary

**One `validateExercise` entry point dispatches on the structured `Check.base` (glyph / sequence / order) and layers the positionalForm / joinContinuity / transformRule modifiers, reusing the Phase-4 `scoreLetter` for the glyph case, returning a `CheckResult { passed, mistakeId? }` whose mistakeId is always one of the exercise's authored feedback keys.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-15 (worktree-agent-a97d8ebcfcc3e2d73)
- **Completed:** 2026-06-15
- **Tasks:** 2 (TDD: RED then GREEN)
- **Files modified:** 4 created

## Accomplishments

- `CheckResult` contract — `{ passed, mistakeId? }`, the validator → FeedbackPanel bridge (07-04 resolves `mistakeId` to `feedback[mistakeId]`, `feedback['pass']` on a pass).
- `validateExercise` — one data-driven entry point covering every baa question type: glyph (delegates to `scoreLetter`), sequence (per-letter glyph in order + written-word compare), order (word-order compare), plus all three modifiers.
- A full RED→GREEN test suite (12 tests) over the REAL 19 baa `EXERCISE-CONFIGS.json` configs; every fail-case asserts an ACTUAL authored feedback key (no invented mistakeIds), tied to the genuine `feedback` maps.
- Scorer-`MistakeId` → authored-feedback-key translation so the child always gets the owner's-mother's specific wording, never a generic "try again", and a tampered/unknown scorer id can never inject raw text.

## The contract for Plan 07-04 (FeedbackPanel + WriteSurface)

```dart
Future<CheckResult> validateExercise(
  ExerciseSpec exercise,
  List<List<List<double>>> strokes, {   // pixel [x,y] pairs — same shape scoreLetter takes
  Letter? letter,                        // reference geometry for the glyph base
  String? writtenWord,                   // recogniser transcription (sequence)
  List<String>? writtenWords,            // recogniser transcription (order)
  String? writtenForm,                   // matched contextual form (positionalForm)
  bool penLiftedBetweenLetters = false,  // joinContinuity signal
});

class CheckResult { final bool passed; final String? mistakeId; }
```

- **`mistakeId` → authored line:** the panel reads `exercise.feedback[result.mistakeId!]` on a miss and `exercise.feedback['pass']` on a pass. `mistakeId` is GUARANTEED to be an authored key of THAT exercise (or the sentinel `'tryAgain'` only if an exercise authored no miss lines at all).
- **Scorer-id mapping:** `wrongStrokeCount/wrongStrokeOrder/dotMisplaced → [noDot, missingDot, …]`, `tooShort/tooCurved/wrongDirection → [shallowBowl, …]`, `wrongLetterIdentity → [wrongLetter, wrongForm, wrongWord]`; the first candidate the exercise authored wins.
- **Adapter 07-04 must write:** `ExerciseSpec.fromExercise(Exercise e)` mapping `e.check`(base+modifiers) → `CheckSpec`, `e.expected`(glyph/word/words) → `AnswerSpec`, `e.feedback` → the map. Field names already match the locked Schema-v2 §2, so it is mechanical.

## Task Commits

> **BLOCKED — see "Issues Encountered." `git commit` is hard-denied in this worktree environment, so the atomic RED/GREEN commits could NOT be created by the agent.** All four files are STAGED (`git add` succeeded) and ready to commit. The intended commit sequence:

1. **Task 1 (RED):** `test(07-03): add failing validateExercise contract + CheckResult` — `check_result.dart`, `exercise_check.dart`, `exercise_validator_test.dart` (fails by missing `validateExercise` symbol — RED-CONFIRMED).
2. **Task 2 (GREEN):** `feat(07-03): implement validateExercise over the existing scorer` — `exercise_validator.dart` (suite goes GREEN, 12/12).

**Plan metadata:** this SUMMARY + `deferred-items.md`.

## Files Created/Modified

- `lib/core/exercise_engine/check_result.dart` — immutable `CheckResult { passed, mistakeId? }` + `.pass()`/`.fail()` factories; the FeedbackPanel contract.
- `lib/core/exercise_engine/exercise_check.dart` — `ExerciseSpec`/`CheckSpec`/`AnswerSpec`/`GlyphAnswer`: the validator-facing view of the locked check+expected+feedback (parses both the `"base+mod"` string and the structured `{base, modifiers[]}` map).
- `lib/core/exercise_engine/exercise_validator.dart` — `validateExercise`: glyph/sequence/order dispatch + 3 modifiers, reusing `scoreLetter`; the MistakeId→authored-key translation.
- `test/core/exercise_engine/exercise_validator_test.dart` — RED→GREEN suite (12 tests) over the real 19 baa configs.

## Decisions Made

See `key-decisions` frontmatter. Core: a narrow `ExerciseSpec` view to decouple from the parallel-wave Exercise model; pixel-`double`-list strokes to match the real scorer; authored-key-only mistakeIds.

## Deviations from Plan

### Auto-fixed / structural

**1. [Rule 3 - Blocking] Decoupled the validator from `lib/models/exercise.dart` via a narrow `ExerciseSpec` view**
- **Found during:** Task 1 (RED setup).
- **Issue:** The plan's `<context>` and `read_first` assume `lib/models/exercise.dart` (Exercise/Check/Answer) already exists, but Plan 07-01 — which OWNS and CREATES that file — runs in the SAME wave (wave 1) in a separate worktree. The model does not exist here, and creating it would (a) be outside this plan's `files_modified` and (b) collide with 07-01 on merge.
- **Fix:** Defined `ExerciseSpec/CheckSpec/AnswerSpec` inside `lib/core/exercise_engine/` — a structural mirror of SCHEMA-V2.md §2's `Check`+`Answer`+`feedback` (verbatim field names). `validateExercise` takes this view; the RED test builds it straight from `EXERCISE-CONFIGS.json`. 07-04 adapts the real `Exercise` with a one-line `ExerciseSpec.fromExercise`. Every file touched stays within this plan's owned set.
- **Files modified:** `lib/core/exercise_engine/exercise_check.dart` (new).
- **Verification:** 12/12 tests GREEN against the real configs.
- **Committed in:** (pending — commit blocked, staged).

**2. [Rule 3 - Blocking] Stroke parameter typed `List<List<List<double>>>`, not `List<List<Offset>>`**
- **Found during:** Task 2 (GREEN).
- **Issue:** The plan text suggests `List<List<Offset>>`, but the Phase-4 `scoreLetter` the glyph base must reuse takes `List<List<List<double>>>` (pixel `[x,y]` pairs) and forbids `dart:ui`/Offset (pure-Dart core rule).
- **Fix:** Matched the scorer's signature exactly so the glyph base is a pure delegation with no conversion seam.
- **Verification:** glyph tests pass; `scoreLetter` called unmodified.
- **Committed in:** (pending — commit blocked, staged).

---

**Total deviations:** 2 (both Rule 3 blocking, both structural alignment with the real codebase). No scope creep — the validator's behavior matches the plan's spec for all three bases and three modifiers.

## Issues Encountered

- **`git commit` is hard-denied in this worktree environment (BLOCKER).** Every `git commit` invocation — minimal message, multi-`-m`, and with the sandbox override — was denied at the policy level (not a sandbox toggle). `git restore --staged`, `flutter gen-l10n`, and `flutter analyze` are likewise denied (any index-mutating / file-writing external command). Only `flutter test`, `git add`, and read-only git succeed. **Consequence:** the atomic RED/GREEN commits and the SUMMARY commit could not be created by the agent. All work is **staged** and verified GREEN; the orchestrator or user must run the two commits (sequence above). The TDD RED→GREEN gate was followed and verified in-test (RED-CONFIRMED, then 12/12 GREEN) even though it is not yet reflected as two separate commits in git history.
- **`test/core/scoring/mistake_mapping_test.dart` fails to COMPILE** — pre-existing gitignored-l10n issue (`lib/l10n/app_localizations.dart` absent in a fresh worktree; fix is `flutter gen-l10n`, which is denied here). NOT a regression from 07-03 — no scoring/l10n file was touched, and the other 44+ `test/core/scoring/` tests pass. Logged to `deferred-items.md`.

## TDD Gate Compliance

This is a `type: tdd` plan. The RED gate (failing `validateExercise` contract — RED-CONFIRMED) and the GREEN gate (12/12 passing) were both executed and verified. **WARNING:** because `git commit` is denied in this environment, the mandatory `test(...)` (RED) and `feat(...)` (GREEN) commits do NOT yet exist in git history — the work is staged, not committed. The orchestrator/user must create them (sequence under "Task Commits") to restore gate-sequence compliance in the log.

## Next Phase Readiness

- The `validateExercise` + `CheckResult` contract is ready for Plan 07-04 (FeedbackPanel resolves `mistakeId` → authored line; WriteSurface supplies strokes + the recogniser transcription).
- **Blocker to clear before merge:** create the two staged commits (RED, GREEN). Once `lib/models/exercise.dart` lands from 07-01, add the `ExerciseSpec.fromExercise` adapter in 07-04.

## Self-Check: PASSED (files) / BLOCKED (commits)

- All 4 source/test files + SUMMARY + deferred-items exist on disk (verified).
- 12/12 validator tests GREEN; RED was confirmed before GREEN.
- Commit verification N/A — `git commit` is denied in this environment; no
  commit hashes exist yet. All changes are STAGED. Orchestrator/user must commit.

---
*Phase: 07-learning-engine-letter-unit-built-to-the-claude-design-proto*
*Completed: 2026-06-15*
