---
phase: 17-build-stroke-aware-coaching-on-device-geo-diff-to-coach
reviewed: 2026-07-06T00:00:00Z
depth: standard
files_reviewed: 44
files_reviewed_list:
  - docs/architecture/ADR-017-scorer-owns-verdict-derived-facts.md
  - lib/core/exercise_engine/check_result.dart
  - lib/core/exercise_engine/exercise_validator.dart
  - lib/core/scoring/geometric_stroke_scorer.dart
  - lib/core/scoring/letter_scorer.dart
  - lib/core/scoring/reference_resolution.dart
  - lib/core/scoring/scoring_models.dart
  - lib/core/scoring/shape_match.dart
  - lib/core/scoring/tolerances.dart
  - lib/features/letter_unit/sections/meet_section.dart
  - lib/features/letter_unit/widgets/exercise_scaffold.dart
  - lib/features/letter_unit/widgets/feedback_panel_v2.dart
  - lib/features/letter_unit/widgets/write_surface.dart
  - lib/tutor/remote_agent_brain.dart
  - lib/tutor/tutor_decision.dart
  - lib/tutor/tutor_facts.dart
  - lib/tutor/tutor_facts_builder.dart
  - server/app/faithfulness.py
  - server/app/main.py
  - server/app/nodes/coach.py
  - server/app/prompts.py
  - server/app/schema.py
  - server/tests/test_criteria_contract.py
  - server/tests/test_endpoint.py
  - server/tests/test_eval/JUDGE_RUBRIC.md
  - server/tests/test_eval/gold_set.jsonl
  - server/tests/test_eval/run_baseline.py
  - server/tests/test_eval/run_eval.py
  - server/tests/test_eval/run_judge.py
  - server/tests/test_eval/test_eval_harness.py
  - server/tests/test_eval/test_variety.py
  - server/tests/test_grounding.py
  - server/tests/test_payload_nonpii.py
  - test/core/scoring/calibration_fixtures/calibration_fixtures.dart
  - test/core/scoring/calibration_harness_test.dart
  - test/core/scoring/letter_scorer_per_form_test.dart
  - test/core/scoring/letter_scorer_test.dart
  - test/core/scoring/soft_verdict_scorer_test.dart
  - test/core/scoring/tolerances_test.dart
  - test/features/letter_unit/exercise_scaffold_cutover_test.dart
  - test/features/letter_unit/meet_section_ltr_test.dart
  - test/features/letter_unit/stroke_image_grep_guard_test.dart
  - test/tutor/payload_nonpii_test.dart
  - test/tutor/remote_agent_brain_test.dart
  - test/tutor/tutor_facts_builder_test.dart
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-07-06T00:00:00Z
**Depth:** standard
**Files Reviewed:** 44
**Status:** issues_found

## Summary

Phase 17 reverses the 17.1 "AI-owns-pass/fail" arrangement: the on-device deterministic
scorer now owns the verdict, and only a derived, point-free superset (`strokeDiff` +
per-criterion `criteria` + word facts) crosses the wire. The privacy core is solid — I traced
every producer of the `/coach` payload (`stroke_diff.dart`, `letter_scorer.dart`,
`tutor_facts.dart`, `buildTutorFacts`) and confirmed **no raw stroke coordinate can reach the
network**: `computeStrokeDiff` emits only keys in the `StrokeDiffIn` whitelist, `TutorFacts`
has no `Offset`/stroke field, and both `extra="forbid"` DTOs 422 a stray key. GROUND-04 holds.
The scorer-owns-verdict cutover is correctly synchronous and un-overrulable (verified in
`exercise_scaffold.dart` `_onResult` + the cutover widget test). The removal of
`strokeImage`/`image_judge` is intentional and NOT flagged, per the phase brief.

No blockers found. The four warnings are latent correctness/robustness gaps that do not bite
the shipped baa demo (where config is internally consistent) but undermine stated invariants
once the curriculum grows or the mother tunes calibration data. The most substantive is a
cross-file divergence in *which* positional form the guide/diff/scorer each resolve against —
the "one shared resolver" is shared in name only.

No structural pre-pass (`<structural_findings>`) was supplied with this review.

## Warnings

### WR-01: The guide/diff resolve the reference form differently from the scorer — the "one shared resolver" (Pitfall 7) is undermined

**File:** `lib/features/letter_unit/widgets/write_surface.dart:157-158`, `lib/features/letter_unit/widgets/write_surface.dart:215-217`, `lib/core/exercise_engine/exercise_validator.dart:128`
**Issue:** The stated invariant (reference_resolution.dart header: "Canvas completion count,
`computeStrokeDiff`, and the scorer must ALL resolve the reference strokes for the asked
positional form the SAME way") is not actually enforced, because the two call sites pass
DIFFERENT `form` keys into the shared resolver:

- The canvas guide **and** `computeStrokeDiff` resolve against `surface.guideForm` only
  (`_formStrokes` = `resolveReferenceStrokes(letter, surface.guideForm)`, used for both the
  painted `_referenceStrokes` and the `computeStrokeDiff(pixelStrokes, _referenceStrokes)` call).
- The **scorer** (via the validator) resolves against `exercise.expected?.glyph?.form ?? guideForm`
  (exercise_validator.dart:128).

If an exercise is authored with `expected.glyph.form != surface.guideForm`, the child traces a
guide for form A, the coach's geometry diff describes deviation from form A, but the verdict is
computed against form B's reference — yielding a false shape/count failure and a coaching diff
that contradicts the verdict. For letters whose forms differ in stroke count, the canvas would
also auto-complete at form A's count while the scorer expects form B's, producing a spurious
`wrongStrokeCount`. baa (all forms = body+dot) and the demo configs (both fields `'isolated'`)
mask this today, so it is latent, not live.
**Fix:** Resolve the asked form ONCE in `WriteSurface` and thread that single value into the
guide, the diff, and the validator, so all three agree:
```dart
// in _WriteSurfaceState
String? get _askedForm =>
    widget.exercise.expected?.glyph?.form ?? widget.surface.guideForm;

List<StrokeSpec> get _formStrokes =>
    resolveReferenceStrokes(widget.letter, _askedForm);

// in _onLetterComplete, pass the same form the scorer will use:
final result = await validateExercise(
  spec, pixelStrokes, letter: widget.letter,
  writtenWord: writtenWord, guideForm: _askedForm,   // was surface.guideForm
);
```
(Or have the validator return the form it resolved and reuse it for the diff.)

### WR-02: `Tolerances.fromJson` silently discards `directionCc` / `directionCw` overrides

**File:** `lib/core/scoring/tolerances.dart:130-144`
**Issue:** ADR-017 §4 and the field docs (tolerances.dart:53-67) state the direction soft-band
thresholds are calibratable DATA ("PROVISIONAL (D-D): synthetic; production values come from
the mom-labelled calibration"). But `fromJson` only reads `shapeTcc`/`shapeTcw` from
`overrides` and hard-wires direction from the base preset:
```dart
directionCc: base.directionCc,
directionCw: base.directionCw,
```
A curriculum author (or the mother's calibration pass) who writes
`overrides: {"directionCc": 0.5}` in `letters.json` gets no effect and no error — the value is
silently dropped. The calibration story the ADR promises for direction cannot be delivered
through data.
**Fix:** Parse the two direction knobs like the shape knobs:
```dart
final directionCcOv = overrides['directionCc'] as num?;
final directionCwOv = overrides['directionCw'] as num?;
// ...
directionCc: directionCcOv?.toDouble() ?? base.directionCc,
directionCw: directionCwOv?.toDouble() ?? base.directionCw,
```

### WR-03: No ordering/range guard on the new soft-band knobs — an inverted authored band silently disables shape-failure detection in release builds

**File:** `lib/core/scoring/tolerances.dart:69-77`, `lib/core/scoring/tolerances.dart:133-141`, `lib/core/scoring/shape_match.dart:56-58`
**Issue:** `shapeTcc`/`shapeTcw` ARE authorable via `overrides` (tolerances.dart:133-141) but
receive no validation. The only ordering guard is `SoftBand`'s `assert(tcc < tcw)`
(shape_match.dart:57), and Dart strips asserts from release builds. If authored data inverts the
band (`shapeTcc >= shapeTcw`), release-mode `zoneFor` returns `certainlyCorrect` for any distance
`<= tcc` and `scoreFor` returns `1.0` — so the shape criterion **can never fail**, silently
disabling the primary shape-failure mechanism (the F5 form-blind fix and the flat-bowl reject)
in production while all debug/test runs stay green. This is exactly the surface the mother is
expected to tune (D-D), so malformed input is a realistic path.
**Fix:** Validate the band where the other knobs are validated (extend `validateTolerances`):
reject `shapeTcc < 0`, `shapeTcw <= shapeTcc`, and out-of-`[0,1]` direction thresholds, returning
a string violation (the existing no-throw idiom). Alternatively, clamp/repair in `fromJson` and
log, so a bad band cannot reach `SoftBand` in release.

### WR-04: `/coach` logs the full derived attempt (geometry summary + the child-facing line) at WARNING level on every request

**File:** `server/app/main.py:133-143`
**Issue:** Every successful `/coach` call emits `logger.warning("coach decision: ... strokeDiff=%s
criteria=%s ... line=%r", ...)`, logging the derived stroke-geometry `summary` (a natural-language
description of the specific child's handwriting) and the coaching `line` on the success path.
Two problems: (1) WARNING is the wrong level for routine success telemetry — it drowns genuine
warnings and inflates Cloud Run log cost/retention; (2) though ADR-017 deems the derived diff
non-PII, persisting a per-request description of each child's attempt in server logs is a
data-minimization smell that should be a deliberate, level-gated choice, not the default.
**Fix:** Demote to `logger.info` (or `logger.debug`) and gate behind an env flag so it is off in
production:
```python
if os.environ.get("COACH_DEBUG_LOG"):
    logger.info("coach decision: passed=%s mistakeId=%s tool=%s grounded=%s", ...)
```
Drop `strokeDiff`/`line` from the always-on record, or log only the criterion labels/zones, not
the free-text summary and the child-facing sentence.

## Info

### IN-01: Stale field-count comments after the Phase-17 wire enlargement

**File:** `lib/tutor/tutor_facts.dart:22`, `test/tutor/payload_nonpii_test.dart:293-294`
**Issue:** `tutor_facts.dart` still says `toMap`/`toJson` "emit ONLY the ten whitelisted ...
fields (the eight base fields plus the two Phase-15 graph-position fields)", and the client
payload test comments "the only emitted keys are the 8 whitelisted server-DTO fields" — both
predate the five Phase-17 fields (`strokeDiff`/`criteria`/`weakestCriterion`/`expectedWord`/
`writtenWord`). The assertions still pass against the up-to-date `_whitelist`, but the counts in
prose now mislead a maintainer about the true wire surface.
**Fix:** Update the counts (15 keys / "eight base + two graph-position + five Phase-17 derived")
in both comments.

### IN-02: `FeedbackPanelV2` doc references a non-existent `arabicLine` parameter

**File:** `lib/features/letter_unit/widgets/feedback_panel_v2.dart:38-40`
**Issue:** The class doc says '[line] may contain a small Arabic island ... pass it as the
`arabicLine` so it renders through [ArabicText] beside the English', but there is no `arabicLine`
constructor parameter; Arabic is detected heuristically inside `_Line` (the `_arabic` regex).
The doc describes an API that does not exist.
**Fix:** Delete the `arabicLine` sentence and document the actual behavior (mixed Arabic/English
in `line` is auto-detected and routed through `ArabicText`).

### IN-03: On a clean PASS, `weakestCriterion` resolves to a perfect (1.0) criterion the coach is told to "nudge"

**File:** `lib/core/scoring/letter_scorer.dart:264-270`, `server/app/prompts.py:71-73`
**Issue:** `_weakest` returns the minimum-score criterion; on a flawless pass all five criteria
are `1.0`, so `weakest` is the first entry (`strokeCount`, score 1.0). The stroke addendum then
instructs the coach "On a PASS, gently nudge the weakest one (`weakestCriterion`)". Nudging a
perfect criterion invites the coach to manufacture a non-defect, in mild tension with the same
prompt's "do NOT invent a defect the verdict did not flag". The `zone: certainlyCorrect, score:
1.0` payload gives the model enough signal to avoid it, so this is a coaching-quality risk, not
a grounding break.
**Fix:** Only send `weakestCriterion` on a pass when it is genuinely sub-ceiling (e.g. omit it,
or null it, when `weakest.score >= 1.0` or `weakest.zone == certainlyCorrect`), so the coach
never receives a "nudge target" that is already perfect.

---

_Reviewed: 2026-07-06T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
