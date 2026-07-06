---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 03
subsystem: scoring
tags: [scorer, per-form, multi-criteria, letter-score, reference-resolver, validator, wave-3]

# Dependency graph
requires:
  - phase: 17-01
    provides: "the RED contract (letter_scorer_per_form_test.dart) this plan turned GREEN with zero test edits"
  - phase: 17-02
    provides: "CriterionResult{criterion,zone,score} + StrokeResult.criteria on pass AND fail (aggregated here); SoftBand/ShapeZone; Tolerances soft-band knobs"
  - phase: 04-scoring-quality-calibration
    provides: "scoreLetter spine (count→order→shape→dot→advisory ML-Kit gate), Tolerances resolution idiom, MistakeId check-string contract, _checkDots combined-bbox"
  - phase: 07-letter-unit
    provides: "validateExercise glyph/sequence spine, ExerciseSpec view + adapter, WriteSurface trace/write canvas"
provides:
  - "resolveReferenceStrokes(Letter, String? form) + resolveTolerances — the ONE shared per-form resolver (Pitfall 7): scorer, validator path, canvas completion count, and computeStrokeDiff all consume it"
  - "scoreLetter is form-aware (Future<LetterScore>, optional String? form): scores against the ASKED positional form's reference — the F5 form-blind verdict fails at the scorer (D-A), not the LLM"
  - "LetterScore extends LetterResult: five per-criterion results (strokeCount/strokeOrder/shape/direction/dot) + weakest (min-score) — the structured coaching input D-B requires; passed/mistakeId semantics unchanged (source-compatible with every caller)"
  - "COUNT/ORDER/dot stay FIRM (categorical certainlyWrong/0.0); only shape+direction are SOFT (aggregated over body strokes, worst-zone/min-score wins)"
  - "validateExercise threads the asked form (expected.glyph.form ?? surface.guideForm) into scoreLetter on every glyph validation"
affects: [17-05, 17-06, 17-07, scorer, coaching-contract, validator, canvas]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One shared per-form resolver (resolveReferenceStrokes/resolveTolerances): every consumer that needs the reference-for-a-form calls the same pure function — no duplicated contextualForms lookup (Pitfall 7)"
    - "Structured-result-as-subclass: LetterScore extends LetterResult so passed/mistakeId reads and explicit LetterResult annotations stay source-compatible while criteria[]+weakest are additive"
    - "Soft-criterion aggregation over body strokes: worst zone / min score wins; the firm tooShort floor (empty scoreStroke criteria) folds into shape as certainly-wrong while keeping its mistakeId"
    - "Firm-check short-circuit still emits structured output: a count/order fail returns LetterScore with the failing firm criterion (+ weakest), not a bare fail"

key-files:
  created:
    - lib/core/scoring/reference_resolution.dart
  modified:
    - lib/core/scoring/scoring_models.dart
    - lib/core/scoring/letter_scorer.dart
    - lib/core/exercise_engine/exercise_validator.dart
    - lib/features/letter_unit/widgets/write_surface.dart

key-decisions:
  - "The five criteria are ALWAYS present on a full evaluation (count+order pass); a firm short-circuit emits only the criteria that ran (count-fail → [strokeCount]; order-fail → [strokeCount, strokeOrder]) — the RED contract only pins the full-5 set on a PASS, and requires weakest non-null + the failing firm criterion present on a fail"
  - "mistakeId precedence preserves Phase-4 section order: strokeCount → strokeOrder → (body: direction-then-shape, first failing stroke) → dot → advisory identity; verdict parity held on every currently-failing case"
  - "The dot criterion is reported even for a no-dot letter (trivially certainlyCorrect/1.0) so the criteria list is uniform; weakest can never point at dot for such a letter"
  - "Validator resolves the asked form as expected.glyph.form ?? guideForm (a new optional validateExercise param), keeping the VALIDATOR the owner of scoring form resolution (RESEARCH Pattern 2); alif/base letters with identical base+isolated strokes are unaffected"

patterns-established:
  - "resolveReferenceStrokes is the single home for per-form reference selection; write_surface._formStrokes and computeStrokeDiff both delegate to it (canvas count == scorer expected count)"

requirements-completed: [STRK-01]

# Metrics
duration: 9min
completed: 2026-07-06
---

# Phase 17 Plan 03: Per-form Multi-criteria scoreLetter Summary

**`scoreLetter` is now form-aware and emits a structured `LetterScore`: it resolves the reference for the ASKED positional form via one shared resolver (`resolveReferenceStrokes`), scores the five owner-confirmed criteria (strokeCount/strokeOrder/shape/direction/dot — COUNT/ORDER/dot FIRM, shape/direction SOFT), and names the weakest one for the coach (D-B) — turning the 17-01 RED contract GREEN with zero test edits, fixing the F5 form-blind verdict at the scorer (D-A), while the validator threads the asked form and the canvas/diff/scorer all share one resolution (Pitfall 7).**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-07-06T12:26:55Z
- **Completed:** 2026-07-06T12:35:38Z
- **Tasks:** 2
- **Files created:** 1 · **Files modified:** 4

## Accomplishments

- **The F5 trap fails at the scorer (D-A), deterministically.** An isolated-bowl shape submitted for the medial slot is now scored against the medial-tooth reference (`resolveReferenceStrokes(baa, 'medial')`), lands `shape` in `ShapeZone.certainlyWrong`, and `passed` is false — the verdict lives in the scorer, not the LLM. Proven by the RED contract's `isolatedShapedAttempt` case.
- **`scoreLetter` returns a structured `LetterScore`.** It emits the five owner-confirmed D-C-amendment criteria (kinematics descoped — capture has no timestamps; position folded into the firm dot check; strokeCount is the fifth), plus `weakest` = the minimum-score criterion — the coaching target (D-B). `passed`/`mistakeId` keep exact Phase-4 semantics, so every existing caller (validator `result.passed`/`result.mistakeId`, practice_screen's explicit `LetterResult` annotation) compiles and behaves unchanged.
- **Firm stays firm, soft stays soft.** COUNT, ORDER and the dot side/count check are categorical (`certainlyWrong`/0.0, never fuzzy); only shape and direction are soft-banded, aggregated over the body strokes (worst zone / min score wins). The advisory ML-Kit identity gate is kept verbatim (reject-only, 0.5 confidence floor).
- **One shared reference resolution (Pitfall 7).** New `reference_resolution.dart` hoists the `contextualForms[form]` lookup verbatim; the scorer, the validator's asked-form threading, `write_surface._formStrokes` (canvas completion count + demo animation), and `computeStrokeDiff` now all resolve the per-form reference through the SAME function — a taa medial completing at 3 strokes agrees with the scorer's expected count.
- **The validator threads the asked form.** `validateExercise` gained an optional `guideForm`; `_validateGlyph` and the sequence single-glyph leg resolve `expected.glyph.form ?? guideForm` and pass it to `scoreLetter(strokes, letter, form:)`. `WriteSurface` passes `widget.surface.guideForm`. The `onStrokeImage`/`_renderStrokesToBase64Png` cutover seams were left untouched — that is Plan 17-07's.
- **17-01 Task-2 RED contract GREEN with ZERO edits** (`letter_scorer_per_form_test.dart`, 14 tests). The existing `letter_scorer_test.dart` (SC#1/SC#2/SC#3/D-04 + the 06-04 tolerance-override suite) passed completely unchanged — no assertion needed the removed chord proxy re-expressed.

## Task Commits

Each task was committed atomically:

1. **Task 1: per-form multi-criteria scoreLetter + shared resolver** — `bb57071` (feat)
2. **Task 2: validator threads the asked form; surface shares one resolver** — `67ef9d6` (feat)

## Files Created/Modified

- `lib/core/scoring/reference_resolution.dart` *(created)* — `resolveReferenceStrokes(Letter, String? form)` (non-empty `contextualForms[form].referenceStrokes` else base; unknown/empty/null form all fall back to base) + `resolveTolerances` (override → form → letter → normal). Pure Dart, scorer register.
- `lib/core/scoring/scoring_models.dart` — `LetterScore extends LetterResult` adding `criteria` (List<CriterionResult>) + `weakest` (CriterionResult?); const constructor forwarding `passed`/`mistakeId` (source-compatible, Pitfall 2).
- `lib/core/scoring/letter_scorer.dart` — `scoreLetter` now `Future<LetterScore>` with `String? form`; per-form reference/tolerances via the shared resolver; five-criteria accumulation (firm count/order short-circuits emit structured output; shape/direction aggregated over body strokes; firm dot; advisory identity gate kept); `_pickCriterion`/`_worst`/`_weakest` helpers; security no-log posture preserved (T-17-06).
- `lib/core/exercise_engine/exercise_validator.dart` — `validateExercise` gains `guideForm`; `_validateGlyph` + sequence single-glyph leg pass `form: expected.glyph.form ?? guideForm` to `scoreLetter`; `_mapMistake`/CheckResult mapping untouched.
- `lib/features/letter_unit/widgets/write_surface.dart` — imports `reference_resolution.dart`; `_formStrokes` delegates to `resolveReferenceStrokes` (canvas/diff/scorer share one resolution); passes `guideForm` into `validateExercise`; trace guard + best-effort diff/try-catch seams unchanged; cutover seams untouched.
- `.planning/phases/17-.../deferred-items.md` — logged the out-of-scope `check_result.dart` analyze info.

## Decisions Made

- **Full-5 criteria on a full evaluation; short-circuit emits what ran.** The RED contract pins the exact 5-entry set only on a PASS (`goodMedial`); on a firm count-fail it asserts the `strokeCount` criterion present + `weakest` non-null. So a count-fail returns `criteria: [strokeCount]`, an order-fail `[strokeCount, strokeOrder]` — honest (the later criteria can't be aligned to the reference) and contract-satisfying. The plan sanctioned this ("emit only the strokeCount criterion plus certainlyWrong placeholders").
- **Body-stroke tooShort folds into the shape criterion.** `scoreStroke`'s firm `tooShort` floor returns empty criteria; the letter scorer folds it into the aggregate `shape` criterion as certainly-wrong (score 0.0) while preserving `mistakeId == tooShort`, so the aggregate reflects the failure without inventing a sixth criterion.
- **mistakeId precedence = Phase-4 section order.** count → order → (body: direction-then-shape, first failing stroke via `??=`) → dot → advisory identity. Verified against every currently-failing case (dot-above → dotMisplaced; dot-first → wrongStrokeOrder; single-stroke → wrongStrokeCount; confident ML-Kit → wrongLetterIdentity).
- **No `requirements mark-complete` for STRK-01** — same judgment as 17-01/17-02: STRK-01 spans 17-02..17-09; the frontmatter records it verbatim, the final leg (or the phase verifier) flips the checkbox.

## Deviations from Plan

### None — plan executed as written.

No Rule 1/2/3 auto-fixes were needed: the 17-02 foundation (`CriterionResult`, `StrokeResult.criteria` on pass AND fail, the anchored shapeDistance normalization) was exactly as its SUMMARY promised, so the aggregation landed on the first implementation and the existing `letter_scorer_test.dart` needed zero edits (unlike 17-02, no chord-proxy-pinned assertion survived into this plan's surface).

## Out-of-Scope Discoveries (SCOPE BOUNDARY — logged, NOT fixed)

- `lib/core/exercise_engine/check_result.dart:43` carries a pre-existing info-level `prefer_initializing_formals` lint (surfaced only when analyzing the whole `exercise_engine/` directory). I did NOT touch that file; the two files 17-03 modified analyze clean. Logged to `deferred-items.md` for a lint-sweep quick task.

## Issues Encountered

None beyond the out-of-scope item above. Baseline discipline held:
- `flutter test test/core/scoring/` — 92 passed (whole scoring suite green; no remaining RED).
- `flutter test test/core/` — 115 passed.
- `flutter test test/features` — 124 passed / 3 failed; the 3 are the KNOWN pre-existing baseline (`meet_section_test` Test 1, `write_surface_test` Test 5 — both pinned in 17-PATTERNS.md §9 — and `mastery_celebration_golden_test`, the local font-drift golden per MEMORY). Not worsened; the `write_surface_test` +4 -1 count is byte-identical to the pre-plan baseline, and `alif_feedback_test` stays GREEN (alif's base and isolated-form reference strokes are byte-identical, so threading `form: 'isolated'` changes nothing for the alif path).

## Known Stubs

None — no placeholder values flow to any UI or runtime path. The soft-band values inherited from 17-02 remain labeled PROVISIONAL by design (D-D: production values come from the mom-labelled calibration, plan 17-05+).

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. T-17-05 (form-blind F5) is MITIGATED: the per-form reference reaches the scorer and the F5 trap fails deterministically (the RED test case proves the medial slot rejects the isolated bowl). T-17-06 posture preserved: `LetterScore.criteria` holds only `{criterion, zone, score}` scalars — no coordinate representable; the no-log security comment is intact in `letter_scorer.dart`. T-17-07 accept unchanged (no `signedOff` flags flipped). T-17-SC green (pubspec.yaml untouched — zero new packages).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **17-05/17-06 (coach) can consume `LetterScore.criteria` + `weakest` now:** the structured per-criterion output exists end-to-end from the validator to the scorer; the weakest criterion is the coaching target (D-B). The criteria transport to the coach FACTS is 17-05/17-06's wire work — this plan stops at producing the structure.
- **17-07 (cutover):** the `onStrokeImage`/`_renderStrokesToBase64Png` seams in `write_surface.dart` are deliberately untouched; the canvas/diff/scorer now share `resolveReferenceStrokes`, which is the seam 17-07 builds the geo-diff cutover on.
- **Calibration note (17-05):** presets still share the 17-02 PROVISIONAL soft-band defaults — the loose/strict ramp has no per-form shape discrimination until per-form bands are fitted from labelled samples (`resolveTolerances` already reads `contextualForms[form].tolerances` when authored).

## Self-Check: PASSED

- All 5 files (1 created + 4 modified) exist on disk; SUMMARY exists.
- Commits `bb57071` + `67ef9d6` present in git log.
- Acceptance criteria re-verified: `letter_scorer_per_form_test.dart` GREEN with zero edits (empty `git diff` on that file); `scoreLetter` signature contains `String? form` and returns `Future<LetterScore>`; `reference_resolution.dart` exports `resolveReferenceStrokes` + `resolveTolerances`; `letter_scorer_test.dart` passes unchanged; `flutter test test/core/scoring/` and `test/core/` exit 0; `exercise_validator.dart` contains `scoreLetter(strokes, letter, form:`; `write_surface.dart` imports `reference_resolution.dart` and `_formStrokes` no longer duplicates the contextualForms lookup; the write_surface diff contains NO onStrokeImage/_renderStrokesToBase64Png change; the write_surface baseline failure count is unchanged (+4 -1); `flutter analyze` on the two touched files exits 0; pubspec.yaml untouched.

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
