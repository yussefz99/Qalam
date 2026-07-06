---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
plan: 02
subsystem: scoring
tags: [scorer, dtw, soft-verdict, shape-match, tolerances, criteria, wave-1]

# Dependency graph
requires:
  - phase: 17-01
    provides: "the RED contract (soft_verdict_scorer_test.dart) this plan turned GREEN with zero test edits"
  - phase: 16-presence-voice-eval-demo
    provides: "shape_match.dart DTW shapeDistance + SoftBand 3-zone core (commit 4e71d6b)"
  - phase: 04-scoring-quality-calibration
    provides: "scoreStroke spine, Tolerances preset+overrides idiom, MistakeId check-string contract"
provides:
  - "scoreStroke soft 3-zone verdict: DTW shapeDistance + SoftBand replaces the chord-curvature proxy; fail ONLY on certainly-wrong (fuzzy PASSES — the F2 per-stroke false-fail fix)"
  - "Direction kept as a criterion (D-C): continuous alignment p in [-1,1] soft-banded by directionCc/directionCw; tap/dot strokes skip direction"
  - "CriterionResult{criterion, zone, score} + StrokeResult.criteria populated on pass AND fail — the structure 17-03's letter scorer aggregates"
  - "Tolerances soft-band knobs as DATA (D-D): shapeTcc/shapeTcw/directionCc/directionCw, PROVISIONAL 0.10/0.15/0.3/-0.3 on all presets, fromJson overrides for shapeTcc/shapeTcw"
  - "shapeDistance anchored unit-box normalization (no zero-extent 0.5-centering) — hairline-width font-extracted references now match straight child strokes"
affects: [17-03, 17-05, 17-06, 17-07, scorer, coaching-contract, calibration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Soft 3-zone criterion verdict: compute ALL criteria, fail only on the first certainly-wrong (direction, then shape), return criteria on pass AND fail"
    - "Anchored unit-box normalization for cross-stroke DTW comparison (bbox-min anchor, continuous as extent → 0) — private to shape_match; the shared normalizeToUnitBox keeps its 0.5 centerline convention for its other consumers"
    - "Threshold-as-data extension: new scoring knobs enter as Tolerances fields with constructor defaults so every existing const call site keeps compiling"

key-files:
  created: []
  modified:
    - lib/core/scoring/scoring_models.dart
    - lib/core/scoring/tolerances.dart
    - lib/core/scoring/geometric_stroke_scorer.dart
    - lib/core/scoring/shape_match.dart
    - lib/core/scoring/letter_scorer.dart
    - test/core/scoring/tolerances_test.dart
    - test/core/scoring/letter_scorer_test.dart

key-decisions:
  - "shapeDistance normalization ANCHORED (bbox-min, no zero-extent 0.5-centering): the shared convention is discontinuous at zero width and false-failed a PERFECT straight alif vs the hairline font-extracted reference (d 0.4998 → 0.0002); flat-line-vs-bowl separation strengthened 0.161 → 0.371"
  - "All presets share the PROVISIONAL soft-band defaults — the loose/strict ramp temporarily has no shape discrimination until mom-labelled calibration sets per-preset bands (D-D)"
  - "strokeDirectionInverted re-expressed over the soft alignment (fails only at p <= directionCw); chord-curvature predicate removed (no callers); the tooCurved ↔ strokeCurvatureExceedsThreshold check-string pairing preserved (Pitfall 2)"

patterns-established:
  - "criteria list order pinned [shape, direction]; every geometrically scored stroke carries both; the firm tooShort floor short-circuits before geometry and carries none"

requirements-completed: [STRK-01]

# Metrics
duration: 26min
completed: 2026-07-06
---

# Phase 17 Plan 02: scoreStroke Soft Verdict via shapeDistance Summary

**Per-stroke scoring is now soft, DTW-driven and data-thresholded: scoreStroke scores shape (DTW shapeDistance + SoftBand from Tolerances.shapeTcc/shapeTcw) and direction (continuous alignment vs directionCc/directionCw) as CriterionResults, fails only on certainly-wrong, and the 17-01 RED contract went GREEN with zero test edits — plus an anchored-normalization fix in shapeDistance that un-false-fails a perfect straight alif against the hairline font-extracted reference.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-07-06T11:41:37Z
- **Completed:** 2026-07-06T12:07:40Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- The UAT F2 per-stroke false-fail is fixed at the leaf: a shaky-but-correct bowl (d 0.036) passes certainlyCorrect, the fuzzy middle passes, and only certainly-wrong fails — while a flat "line" bowl (d 0.371 under anchored normalization) still fails as the KEPT `MistakeId.tooCurved` and an inverted stroke still fails as `wrongDirection` (D-C: direction stays a criterion).
- `StrokeResult.criteria` now carries `[shape, direction]` `CriterionResult{criterion, zone, score}` on pass AND fail — the exact structure the 17-03 letter scorer aggregates; `passed`/`mistakeId` unchanged (Pitfall 2), the firm `tooShort` raw-point floor short-circuits before geometry.
- Thresholds are DATA (D-D): `shapeTcc`/`shapeTcw`/`directionCc`/`directionCw` live on `Tolerances` with PROVISIONAL defaults (0.10/0.15/0.3/-0.3, `==SoftBand.shapeDefault`, asserted) on ALL presets, `fromJson` overrides for shapeTcc/shapeTcw in the same defensive idiom as maxCurvature; `maxCurvature` kept parse-compat with a deprecation note.
- 17-01 Task-1 RED contract (`soft_verdict_scorer_test.dart`) GREEN with ZERO edits (`git diff --stat` empty); `geometric_stroke_scorer_test.dart` survived the rewrite completely unchanged — every behavioral case (tooShort, wrongDirection, curved→tooCurved, pass cases, latency <50ms) held under DTW.
- Rule-1 fix with real product impact: `shapeDistance` now uses an ANCHORED unit-box normalization. The shared `normalizeToUnitBox` centers an exactly-zero-width axis at 0.5 but anchors a hairline (0.001) width at 0 — so a PERFECT straight child alif scored d≈0.4998 (certainlyWrong) against the real font-extracted alif reference. Anchoring both sides at bbox-min is continuous as extent → 0: straight-vs-real-alif d = 0.0002, and every pinned zone contract holds or strengthens (measured before/after for all 10 critical fixture pairs).

## Task Commits

Each task was committed atomically:

1. **Task 1: CriterionResult model + soft-band Tolerances knobs** - `acc851b` (feat)
2. **Task 2: scoreStroke soft verdict via shapeDistance** - `9a5f8b4` (feat)

## Files Created/Modified

- `lib/core/scoring/scoring_models.dart` - CriterionResult (wire-safe `criterion` field, T-17-02), StrokeResult.criteria, tooCurved re-documented as DTW shape-certainly-wrong
- `lib/core/scoring/tolerances.dart` - four PROVISIONAL soft-band knobs (defaults on all presets via constructor defaults, so every existing const call site compiles), fromJson overrides, maxCurvature deprecation note
- `lib/core/scoring/geometric_stroke_scorer.dart` - scoreStroke rewritten: firm floor → soft direction criterion → soft DTW shape criterion → criteria-carrying verdict; chord proxy removed; pure-Dart header + T-17-03 no-log posture
- `lib/core/scoring/shape_match.dart` - private `_anchoredUnitBox` (no 0.5 zero-extent special case) used by shapeDistance; docs updated with why
- `lib/core/scoring/letter_scorer.dart` - `library;` added (analyze gate fix only; scoring logic untouched — 17-03 owns its rewrite)
- `test/core/scoring/tolerances_test.dart` - knob defaults on every preset, SoftBand.shapeDefault equality, shapeTcc/shapeTcw override round-trip
- `test/core/scoring/letter_scorer_test.dart` - sanctioned reconciliation of the chord-proxy-pinned override-wins test (see Deviations)

## Decisions Made

- **Anchored normalization lives in shape_match, not stroke_resampler:** the shared `normalizeToUnitBox` keeps its documented 0.5 centerline convention (other consumers, STROKE-REFERENCE §7.3); only the cross-stroke DTW comparison needs continuity at zero extent, so the fix is private to `shapeDistance`.
- **Direction reported for tap strokes as a benign certainlyCorrect/1.0 entry** so `criteria` always carries both entries for geometrically scored strokes (the contract's completeness assertion) without faking a direction axis for dots.
- **`strokeDirectionInverted` kept as the named check-string predicate**, re-expressed over the same soft alignment scoreStroke uses (`p <= directionCw`) — one displacement-math home, no dead sign-based variant.
- **`shapeDistance` is fed the RAW child stroke** (it resamples/normalizes internally) while the direction leg uses the locally resampled+normalized copy — no double-normalization (read_first note honored).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] shapeDistance false-failed a perfect straight alif (normalization discontinuity)**
- **Found during:** Task 2 (post-rewrite regression run — `alif_feedback_test.dart` "a straight vertical line PASSES alif" was a NEW failure vs the pre-task baseline)
- **Issue:** `normalizeToUnitBox` maps an exactly-zero-width axis to x=0.5 but anchors a hairline width (the real font-extracted alif reference: x 0.5..0.501) at 0 — two visually identical vertical lines land ~0.5 apart on every DTW-aligned point → d=0.4998 → certainlyWrong → a perfect stroke false-fails, the exact defect class this phase exists to fix
- **Fix:** private `_anchoredUnitBox` in shape_match.dart (bbox-min anchor, no special case — continuous as extent → 0); verified against all 10 critical fixture pairs before applying (bowls/baa bodies unchanged, flat-line separation improved 0.161 → 0.371, straight-vs-real-alif 0.4998 → 0.0002, curved cases stay certainlyWrong)
- **Files modified:** lib/core/scoring/shape_match.dart
- **Verification:** alif_feedback_test green; shape_match_test (all zone contracts) green; soft_verdict contract green with zero edits
- **Committed in:** 9a5f8b4 (Task 2 commit)

**2. [Rule 3 - Blocking] Pre-existing dangling library doc comment failed the plan's analyze gate**
- **Found during:** Task 1 verification (`flutter analyze lib/core/scoring/` must exit 0 per plan `<verification>`)
- **Issue:** letter_scorer.dart (untouched by this plan's logic) had a library-level doc comment with no `library;` directive — an info-level diagnostic that makes `flutter analyze` exit 1
- **Fix:** added `library;` after the header doc comment (one line, no behavior change)
- **Files modified:** lib/core/scoring/letter_scorer.dart
- **Verification:** `flutter analyze lib/core/scoring/` → "No issues found!", exit 0
- **Committed in:** 9a5f8b4 (Task 2 commit)

**3. [Sanctioned reconciliation] letter_scorer_test.dart override-wins test pinned the retired chord proxy**
- **Found during:** Task 2 (pre-implementation analysis + measured d=0.0226 for the bowed baa)
- **Issue:** "override WINS over letter.tolerances: strict fails the same bow" relied on `Tolerances.preset('strict')`'s maxCurvature 0.18 tripping the chord proxy on a 0.21 bow; under DTW the bow is d≈0.023 — inside every preset's default soft band (plan pins identical soft-band defaults on ALL presets), so the test would fail for a retired-mechanism reason. The plan sanctions re-expressing chord-proxy-pinned tests but listed only geometric_stroke_scorer_test.dart (which needed zero edits); this test is the same category one file over
- **Fix:** re-expressed with an explicitly tighter shape band (`shapeTcc 0.005 / shapeTcw 0.015 < d≈0.023` → tooCurved) — the override-beats-letter.tolerances plumbing intent is proven unchanged; fixture doc + sibling reasons updated to the DTW mechanism
- **Files modified:** test/core/scoring/letter_scorer_test.dart
- **Verification:** all letter_scorer_test tests green (override fails the bow as tooCurved; no-override and loose paths pass)
- **Committed in:** 9a5f8b4 (Task 2 commit)

### Deliberate Process Deviation

**4. [Judgment call] STRK-01 not checkbox-marked (17-01 precedent)**
- **Issue:** STRK-01 spans plans 17-02..17-09; flipping the REQUIREMENTS.md checkbox now would falsely show a core requirement Complete
- **Fix:** `requirements mark-complete` skipped; frontmatter records the plan's `requirements` array verbatim per template. The plan landing the final STRK-01 leg (or the phase verifier) flips it
- **Files modified:** none (REQUIREMENTS.md untouched)

---

**Total deviations:** 3 auto-fixed (1 bug, 1 blocking, 1 sanctioned test reconciliation) + 1 process judgment call
**Impact on plan:** The Rule-1 fix was necessary for correctness of the plan's own goal (no false-fails) on the shipped alif path; the others are gate/contract hygiene. No scope creep, no new packages (pubspec.yaml untouched — T-17-SC gate green).

## Issues Encountered

None beyond the deviations above. Full-suite run after Task 2: 703 passed; the 11 remaining failures are all pre-existing or by-design, individually attributed (see `deferred-items.md`): letter_scorer_per_form_test (17-03's RED contract, by design), alif_reference/all_letters_validation/reference_overlay_golden (alif curriculum-data drift, no scorer involvement), glyph_audit + mastery_celebration goldens (known font drift), meet_section Test 1, write_surface Test 5 (pinned pre-existing in 17-PATTERNS.md §9). The spike-era SC-4 durable-layers guard trips on uncommitted working-tree diffs in lib/core/scoring/ — green again after the task commit.

## Known Stubs

None — no placeholder values flow to any UI or runtime path. The soft-band values themselves are labeled PROVISIONAL in code/docs by design (D-D: production values come from the mom-labelled calibration, plan 17-05+).

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. T-17-03 posture preserved (child points live only in locals; nothing printed/logged/persisted; only zone/score scalars leave scoreStroke). T-17-04 mitigated (<2-point degenerate input → infinity → certainlyWrong, never a throw; firm tooShort floor first). T-17-SC accepted (zero new packages).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 17-03 (per-form multi-criteria scoreLetter) can start immediately: `CriterionResult`/`StrokeResult.criteria` exist exactly as the RED contract names them, and `scoreStroke` returns criteria on pass AND fail for aggregation.
- Calibration note for 17-05: presets currently share identical soft-band defaults — the loose/strict ramp has no shape discrimination until per-preset bands are fitted from labelled samples.
- Anchored-normalization note for 17-03's per-form work: `shapeDistance` semantics changed for degenerate-axis strokes only (documented in shape_match.dart); all four baa form references have non-degenerate bodies, alif is the hairline case and now scores correctly.

## Self-Check: PASSED

- All 7 modified files exist on disk; SUMMARY exists.
- Commits acc851b + 9a5f8b4 present in git log.
- Acceptance criteria re-verified: soft_verdict_scorer_test green with zero edits (empty `git diff --stat`); `shapeDistance(` + `tolerances.shapeTcc` present in geometric_stroke_scorer.dart; chord proxy absent from scoreStroke (only the check-string mapping remains); inverted stroke → wrongDirection green; `flutter test test/core/scoring/` fails ONLY letter_scorer_per_form_test.dart (17-03's RED contract); `flutter analyze lib/core/scoring/` exit 0; pubspec.yaml untouched.

---
*Phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach*
*Completed: 2026-07-06*
