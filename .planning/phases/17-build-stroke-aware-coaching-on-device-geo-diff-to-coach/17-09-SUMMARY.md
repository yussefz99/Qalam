---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 09
subsystem: testing
tags: [calibration, harness, per-form, confusion-table, threshold-fit, soft-band, dtw, wave-4]

# Dependency graph
requires:
  - phase: 17-03
    provides: "per-form scoreLetter(strokes, letter, form:) → LetterScore with 5 criteria + weakest; resolveReferenceStrokes — the ONE shared per-form resolver the harness scores/fits against"
  - phase: 17-02
    provides: "scoreStroke soft 3-zone verdict (DTW shapeDistance + SoftBand) + Tolerances shape knobs; the tooCurved shape-certainly-wrong id the flat/F5 fixtures assert"
  - phase: 04-scoring-quality-calibration
    provides: "the Dart confusion-table harness + LabeledSample fixture format (A3: no Python re-impl); FN-over-FP tuning priority"
provides:
  - "Per letter × form calibration harness: the REAL scoreLetter scored over baa (4 forms) + taa, with a per-cell FN/FP confusion table (the mom-facing tuning artifact)"
  - "F5 form-confusion cell asserted ZERO in Dart: an isolated bowl offered for the medial/final slot is rejected (shape certainlyWrong) at the SCORER (D-A), forever — moved out of the LLM eval"
  - "Threshold-FIT report (no in-repo precedent): suggested per-form tcc=max(good)/tcw=min(shape-bad) from the labelled distance distributions, overlap flagged UNSEPARABLE, labelled PROVISIONAL, PRINTS ONLY (never mutates Tolerances/letters.json — D-D, T-17-20)"
  - "Per-form labelled fixtures perturbed from the REAL authored contextualForms points (baa isolated/initial/medial/final + taa isolated), incl. the F5 trap pairs — a SYNTHETIC regression seed (Pitfall 4)"
affects: [17-10, calibration, scorer, coaching-contract]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per letter × form confusion cell keyed 'letterId/form' (form ?? 'base'); the base seed stays a form:null cell so the Phase-4 regression contract is unchanged"
    - "Threshold-FIT over SHAPE-relevant samples only: good vs shape-defective bad (tooCurved), fit tcc=max(good)/tcw=min(bad); dot/count-defective bad excluded (their body shape is correct)"
    - "ONE shared source of authored per-form points: the fixtures export the reference consts; the harness Letter builders and the perturbed fixtures both read them (never two copies that drift)"

key-files:
  created: []
  modified:
    - test/core/scoring/calibration_fixtures/calibration_fixtures.dart
    - test/core/scoring/calibration_harness_test.dart

key-decisions:
  - "The threshold-FIT report fits the SHAPE band from shape-relevant samples only (good + the tooCurved-defective flatBody/F5 traps); dot/count-defective samples (dotAbove/missingDot/wrongDotCount) are EXCLUDED because their body shape is CORRECT — folding them in would collapse min(bad) onto the good range and mask a perfectly separable band. Faithful reading of the plan's SHAPE-band intent (tcc/tcw ARE the shape knobs)."
  - "taa wrongDotCount (bowl + one dot = 2 strokes where 3 are expected) surfaces as MistakeId.wrongStrokeCount — the FIRM strokeCount check fires before the dot check, so that is the id the scorer deterministically emits (the authored dotCountWrong slip resolves to a count mismatch)."
  - "The harness baaLetter()/taaLetter() builders carry the REAL authored contextualForms (built from the exported fixture consts) so resolveReferenceStrokes(letter, form) returns the same per-form reference the scorer uses on device — the F5 trap is scored against the medial tooth / final bowl_tail, not the base line."

patterns-established:
  - "Fixtures export the authored reference point lists; perturbation helpers (densify + shake + flatBody) build variants FROM them, never invented shapes (shape_match_test.dart technique)"
  - "The fit report PRINTS ONLY and asserts nothing about its values (they are PROVISIONAL and mutation-free); regression teeth live in the per-sample good→PASS / bad→expected-MistakeId + F5-zero assertions"

requirements-completed: [STRK-01]

# Metrics
duration: 11min
completed: 2026-07-06
---

# Phase 17 Plan 09: Per-form Calibration Harness + Threshold-Fit Report Summary

**The Dart calibration harness now scores the REAL `scoreLetter` per letter × form over baa's four positional forms plus taa (the D-E generalization proof — same bowl skeleton, dots differ), prints a per-cell FN/FP confusion table, asserts the F5 form-confusion cell to ZERO (an isolated bowl offered for the medial/final slot is rejected at the SCORER, D-A), and derives suggested per-form soft-band tcc/tcw from the labelled distance distributions — labelled PROVISIONAL and PRINTS ONLY (no production value changed, `git diff lib/` empty).**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-07-06T13:06:19Z
- **Completed:** 2026-07-06T13:17:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- **Verdict correctness per letter × form is now a Dart test concern (D-A demands it).** The harness threads `sample.form` into `scoreLetter(strokes, letter, form:)` and scores against the SAME per-form reference the scorer resolves (`resolveReferenceStrokes`). All six cells (baa base + isolated/initial/medial/final + taa isolated) report `FN=0 FP=0`: every `good` shaky-but-correct attempt PASSES, every named-bad rejects with its expected `MistakeId` (flatBody→tooCurved, dotAbove→dotMisplaced, missingDot→wrongStrokeCount, taa wrongDotCount→wrongStrokeCount).
- **The F5 form-confusion gate lives in Dart now, asserted ZERO.** A dedicated assertion offers the ISOLATED bowl (a correct isolated baa) for the medial AND the final slot with the dot still correctly below — so the DOT check passes and the SHAPE criterion is the sole failure. Both are rejected (`shape.zone == certainlyWrong`; measured d ≈ 0.277 / 0.281 vs the shipped tcw 0.15), zero passes. This moves the F5 gate out of the LLM eval into the scorer, where D-A says it belongs.
- **A threshold-FIT report exists (no in-repo precedent — 17-PATTERNS No-Analog).** Per letter × form it computes `shapeDistance(sample body stroke, resolved reference body)` for good vs shape-defective-bad samples and prints `suggested tcc = max(good)`, `suggested tcw = min(bad)`, flagging overlap as UNSEPARABLE. All four shape-fittable cells are cleanly SEPARABLE (good max 0.030–0.052 ≪ shape-bad min 0.163–0.421). The whole block is labelled `PROVISIONAL — synthetic seed; production values require the owner's-mother-labelled child captures (D-D)`.
- **Report-only, mutation-free (T-17-20).** `git diff lib/` is EMPTY for this plan — the fit report never changes `Tolerances` or `letters.json`; the shipped PROVISIONAL band (tcc 0.10 / tcw 0.15) is printed for reference only. Synthetic values stay a regression seed, never production values (Pitfall 4).
- **Fixtures grounded in the REAL authored data.** Every per-form sample is perturbed from the authored `contextualForms` points (baa isolated bowl 12pts / initial head 9pts / medial tooth 8pts / final bowl_tail 11pts; taa = the byte-identical bowl skeleton + two dots above) using the `shape_match_test.dart` technique — midpoint-densify (clears the raw-point floor), ±~0.012 child-hand wobble, a collinear flat body — never an invented shape. The existing Phase-4 base seed is byte-untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Per-form labelled fixtures (baa 4 forms + taa), incl. the F5 trap** — `3a112e5` (test)
2. **Task 2: Letter × form harness loop, F5-cell assertion, threshold-fit report** — `85818f8` (test)

## Files Created/Modified

- `test/core/scoring/calibration_fixtures/calibration_fixtures.dart` — `LabeledSample` gains an optional `form` field (null = base seed, every existing sample unchanged); exported authored reference consts (`kBaa*` bowls/heads/teeth/tails + dots, `kTaa*`); perturbation helpers (`_densify`/`_shake`/`_goodBody`/`_flatBody`/`_dotAboveBody`); per-form baa sample groups (good + flatBody + dotAbove + missingDot each), the F5 `formConfusion` trap pairs (isolated bowl for medial + final), and taa (good + wrongDotCount); `calibrationSamplesByLetter` now spreads base + per-form for baa and adds taa.
- `test/core/scoring/calibration_harness_test.dart` — loop widened to letter × form (`scoreLetter(..., form: sample.form)`); confusion tally keyed per cell; `_expectedRejection` extended with the five new labels; the `baaLetter()`/`taaLetter()` builders carry the REAL authored `contextualForms` (via the exported fixture consts); an explicit F5 zero-pass assertion (shape certainlyWrong over the isolated-for-medial/final traps); the PROVISIONAL threshold-fit report (`resolveReferenceStrokes` + `shapeDistance`, print-only).

## Decisions Made

- **Fit the SHAPE band from shape-relevant samples only.** `tcc`/`tcw` ARE the shape knobs, so the fit uses good vs the tooCurved-defective bad (flatBody + F5). The dot/count-defective bad samples are excluded (their body shape is correct — they fail dot/count, not shape); including them would put `min(bad)` at ~0.04 and spuriously flag every cell UNSEPARABLE, defeating the report. The report prints the exclusion + counts so the reasoning is legible to the mother. (See Deviations #1 — this is a faithful reading of the plan's "labelled-bad" in the SHAPE-band context.)
- **taa's single-dot slip is a stroke-count rejection.** With 2 strokes where the taa reference has 3, the FIRM `strokeCount` check short-circuits before the dot check, so `wrongDotCount` → `MistakeId.wrongStrokeCount` (what the scorer actually emits). Documented at the label and in `_expectedRejection`.
- **One shared source of the authored points.** The fixtures export the reference consts; the harness Letter builders reuse them for `contextualForms`. No second copy of the authored points to drift out of sync (mirrors Pitfall 7's one-resolution discipline at the data layer).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Local helper name collided with the existing base-seed `_dotAbove`**
- **Found during:** Task 1 (fixtures compile)
- **Issue:** The existing Phase-4 seed already defines a no-arg `_dotAbove()`; my new per-form dot-above helper reused the name → duplicate-definition compile error.
- **Fix:** Renamed the new helper `_dotAboveBody(authoredDot)`; the base seed's `_dotAbove()` is untouched.
- **Files modified:** test/core/scoring/calibration_fixtures/calibration_fixtures.dart
- **Verification:** `flutter analyze test/core/scoring/calibration_fixtures/` → "No issues found!"
- **Committed in:** 3a112e5 (Task 1 commit)

### Deliberate Interpretation

**2. [Judgment call] Threshold-fit report scoped to SHAPE-relevant bad samples**
- **Issue:** The plan says the fit computes over "all labelled-good vs labelled-bad samples". Taken literally, the dot/count-defective bad samples (dotAbove/missingDot/wrongDotCount) — whose BODY shape is correct — would collapse `min(bad)` onto the good range (~0.04), flagging every cell UNSEPARABLE and producing a meaningless shape band.
- **Fix:** The fit uses good vs the SHAPE-defective bad (expected rejection == tooCurved: flatBody + F5). `tcc`/`tcw` are the shape knobs, so "labelled-bad" in the shape-band context means shape-bad. The report prints the exclusion + per-cell counts so the mother sees exactly which samples fit the band. Result: all four fittable cells are cleanly SEPARABLE.
- **Files modified:** test/core/scoring/calibration_harness_test.dart
- **Verification:** fit report renders 4/4 separable; the per-sample dot/count rejections are still asserted in the main loop (they gate on their OWN criteria).

**3. [Judgment call] STRK-01 not checkbox-marked (17-01/02/03/05 precedent)**
- **Issue:** STRK-01 spans plans 17-02..17-09; flipping the REQUIREMENTS.md checkbox here would falsely show a core requirement Complete before the phase verifier / final leg.
- **Fix:** `requirements mark-complete` skipped; the frontmatter records the plan's `requirements` array verbatim per template. The plan landing the final STRK-01 leg (or the phase verifier) flips it.
- **Files modified:** none (REQUIREMENTS.md untouched)

---

**Total deviations:** 1 auto-fixed (blocking) + 2 judgment calls
**Impact on plan:** The blocking fix was a trivial rename with no behavior change; the fit-report scoping is what makes the report meaningful (and honors the plan's SHAPE-band intent); STRK-01 tracking follows established phase precedent. No scope creep, no new packages (pubspec.yaml untouched — T-17-SC green), `git diff lib/` empty (T-17-20 mitigated).

## Issues Encountered

None beyond the deviations above. Pre-implementation, a throwaway probe test measured every planned DTW distance against the shipped band before the fixtures were finalized, so the good/flat/F5 samples provably land in their expected zones (good 0.03–0.05 certainlyCorrect; flat 0.16–0.42 and F5 0.28 certainlyWrong). The probe was deleted before committing (never staged). Full scoring suite after Task 2: `flutter test test/core/scoring/` — 114 passed, 0 failed.

## Known Stubs

None — no placeholder values flow to any UI or runtime path. The suggested tcc/tcw in the fit report are labelled PROVISIONAL by design (D-D: production values come from the mom-labelled calibration; 17-10 HUMAN-UAT records the gate). The soft-band values in code remain the shipped PROVISIONAL defaults (unchanged this plan).

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. T-17-19 mitigated: every fixture is a synthetic perturbation of authored `letters.json` points — no real child strokes in the repo. T-17-20 mitigated: the fit report PRINTS ONLY, `git diff lib/` empty, PROVISIONAL asserted in output. T-17-SC accepted: zero new packages.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **17-10 (ADR-017 + HUMAN-UAT + gold-set re-sign) can consume this directly:** the harness is the mom-facing tuning artifact the D-D production calibration runs against — she reads the per-cell confusion table + the suggested per-form tcc/tcw, labels real-child captures, and the fit report re-derives production bands from HER distributions (this seed is replaced, the harness does not change — only the data does).
- **Calibration note:** the shipped soft-band is a single PROVISIONAL band shared across all presets/forms (0.10/0.15). The fit report shows the synthetic per-form good/shape-bad ranges are wide apart (separable at 0.03–0.05 vs 0.16–0.42), i.e. the current band is safe on the seed — but per-form/per-preset production bands still require labelled child captures before they diverge (D-D).
- **Curriculum note:** initial/medial/final baa forms are scored while `signedOff:false` (A2, owner-confirmed 2026-07-05 — the demo may score unsigned forms); the mother's per-form sign-off stays the recorded production gate (17-HUMAN-UAT + ADR-017).

## Self-Check: PASSED

- Both modified files exist on disk; SUMMARY exists.
- Commits 3a112e5 + 85818f8 present in git log.
- Acceptance re-verified: `flutter test test/core/scoring/calibration_harness_test.dart` exits 0 (26 tests); the harness contains an explicit F5 zero-pass assertion over the isolated-for-medial/final traps; the printed output has a per letter × form confusion table AND a threshold-fit block containing the literal `PROVISIONAL`; `git diff lib/` EMPTY (report-only); `flutter test test/core/scoring/` exits 0 (114 passed); `flutter analyze` on both touched files → "No issues found!"; the base Phase-4 seed (baaSamples + its helpers) is byte-untouched; pubspec.yaml untouched.

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
