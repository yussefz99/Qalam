---
phase: 04-scoring-quality-calibration
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - lib/core/recognition/handwriting_recognizer.dart
  - lib/core/recognition/ml_kit_recognizer.dart
  - lib/core/scoring/geometric_stroke_scorer.dart
  - lib/core/scoring/letter_scorer.dart
  - lib/core/scoring/scoring_models.dart
  - lib/core/scoring/stroke_validation.dart
  - lib/core/scoring/tolerances.dart
  - lib/dev/authoring_export.dart
  - lib/dev/authoring_screen.dart
  - lib/features/practice/practice_screen.dart
  - lib/features/practice/widgets/feedback_panel.dart
  - lib/features/practice/widgets/stroke_canvas.dart
  - lib/models/letter.dart
  - lib/providers/practice_providers.dart
  - lib/services/model_download_service.dart
  - test/core/recognition/ml_kit_recognizer_test.dart
  - test/core/scoring/calibration_fixtures/calibration_fixtures.dart
  - test/core/scoring/calibration_harness_test.dart
  - test/core/scoring/letter_scorer_test.dart
  - test/core/scoring/mistake_mapping_test.dart
  - test/core/scoring/tolerances_test.dart
  - test/features/practice/getting_ready_test.dart
  - test/features/practice/multi_stroke_capture_test.dart
  - test/features/practice/practice_screen_test.dart
  - test/services/model_download_service_test.dart
findings:
  critical: 2
  warning: 7
  info: 4
  total: 13
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-06-08
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

Reviewed the on-device scoring spine (`scoreLetter` → `scoreStroke` → tolerances),
the advisory ML Kit identity gate, the model download service, and the practice-screen
wiring. The architecture is sound and the security posture is genuinely good: child
coordinates stay in local variables / widget State, nothing is logged or persisted,
and the ML Kit gate is correctly advisory-only and degrades to "no opinion" on every
failure path. The whole-letter normalization preserving the baa↔taa dot signal is
well done and well tested.

Two BLOCKERs found: a native-resource leak (`MlKitRecognizer` constructed per
letter-completion and never `close()`d) that will accumulate native recognizer handles
during a session, and a recognizer-injection design that makes the advisory gate
effectively unreachable in production (the gate is gated on `isReady` but a fresh
recognizer that has never warmed the model will throw and abstain — meaning SC#2 the
scribble net never actually fires, while still paying the leak cost). Plus correctness
edge cases in the ORDER classifier and the dot-position centroid that can mis-feedback
or mis-pass, and several maintainability traps (a `feedbackForMistake` that silently
returns generic copy for whole-letter mistakes, two near-duplicate clean-rep code
paths in the controller).

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: `MlKitRecognizer` constructed per letter-completion and never closed — native resource leak

**File:** `lib/features/practice/practice_screen.dart:100-109`
**Issue:** `_onLetterComplete` constructs a brand-new `MlKitRecognizer()` on **every**
finished letter when `modelReady` is true:

```dart
final HandwritingRecognizer? recognizer =
    modelReady ? MlKitRecognizer() : null;
final LetterResult result = await scoreLetter(childStrokes, letter, recognizer: recognizer);
```

`MlKitRecognizer`'s default constructor builds a real `DigitalInkRecognizer`
(`ml_kit_recognizer.dart:53-55`), which holds a native platform handle and exposes
`close()` (`ml_kit_recognizer.dart:78`). Nothing ever calls `close()` here. During a
practice session a child draws the same letter many times to earn clean reps, so this
leaks one native recognizer per attempt. On a constrained Android tablet (the only
supported platform) this is a memory/native-handle leak that grows for the whole
session.

**Fix:** Construct the recognizer once and dispose it with the screen, or close the
transient instance after scoring. Minimal in-place fix:

```dart
final HandwritingRecognizer? recognizer =
    modelReady ? MlKitRecognizer() : null;
try {
  final result = await scoreLetter(childStrokes, letter, recognizer: recognizer);
  // ...forward result...
} finally {
  if (recognizer is MlKitRecognizer) await recognizer.close();
}
```
Preferred: expose `MlKitRecognizer` behind a `@Riverpod(keepAlive: true)` provider that
owns its lifecycle (mirroring `inkModelManagerProvider`) and `close()`s in `onDispose`,
then `ref.read` it here.

### CR-02: The advisory ML Kit gate (SC#2 scribble net) cannot fire in production as wired

**File:** `lib/features/practice/practice_screen.dart:100-109`, `lib/core/recognition/ml_kit_recognizer.dart:59-75`
**Issue:** The gate is only attached when `modelDownloadServiceProvider.isReady` is
true. But the recognizer attached is a **fresh** `MlKitRecognizer()` whose underlying
`DigitalInkRecognizer` has never been primed. ML Kit's `recognize()` requires the model
to be loaded; on the first call against a cold recognizer (and on any platform hiccup)
`identify` catches the throw and returns "no opinion" (`ml_kit_recognizer.dart:69-74`).
Combined with `ModelDownloadService` only flipping `isReady` based on
`isModelDownloaded`/`downloadModel` (never actually exercising recognition), the result
is that the gate is *requested* (paying the CR-01 leak) but reliably *abstains* — SC#2,
the "is this a completely different letter / scribble?" safety net, never actually
rejects anything in production. The unit tests pass because they inject a fake
recognizer; the real wiring is untested end-to-end. This is a correctness gap against
the phase goal ("the advisory-only ML Kit gate ... rejects only a confidently-different
letter"), not merely a perf issue.

**Fix:** Verify on-device that a freshly constructed `DigitalInkRecognizer` recognizes
after the model is downloaded; if it needs warm-up, drive the gate through a single
long-lived recognizer instance (see CR-01 provider fix) created only after the model is
confirmed present. Add a device/integration test (Plan 06) that proves a confidently-
wrong capture is actually rejected, not silently abstained. Until proven on-device,
treat SC#2 as unimplemented rather than complete.

## Warnings

### WR-01: ORDER classifier mislabels a fast/short body stroke as a dot → wrong feedback

**File:** `lib/core/scoring/letter_scorer.dart:75-81, 117-119`
**Issue:** The ORDER check classifies each child stroke purely by point count
(`_looksLikeDot` = `stroke.length <= _kDotPointCeiling` = ≤3 points). A child who draws
the baa body quickly (few captured samples) produces a ≤3-point body stroke. At `i=0`
the reference is a body (`refIsDot=false`) but the child stroke is classified as a dot
(`childIsDot=true`) → returns `MistakeId.wrongStrokeOrder` ("Draw the boat first, then
the dot underneath"). The child actually drew in the right order but too fast; the
correct coaching is "too short / slower," which the SHAPE predicate (`minRawPoints=10`)
would have given — but ORDER runs first and short-circuits. Mis-feedback violates the
"name the exact fix" requirement.

**Fix:** Make dot classification reference-aware: a child stroke at a position where the
reference is a body should be treated as a (possibly incomplete) body, letting the SHAPE
predicate report `tooShort`. E.g. only treat a child stroke as a dot when the reference
at that index is a dot, and reserve a separate "you tapped where a line goes" check, or
raise the bar so an obviously-attempted line isn't mistaken for a tap.

### WR-02: `feedbackForMistake` silently returns generic copy for all whole-letter mistakes

**File:** `lib/core/scoring/geometric_stroke_scorer.dart:67-81`
**Issue:** `feedbackForMistake` maps only `tooShort`, `wrongDirection`, `tooCurved`. The
four whole-letter IDs added this phase (`wrongStrokeCount`, `wrongStrokeOrder`,
`dotMisplaced`, `wrongLetterIdentity`) fall through to the generic
`'Something looks off — try again, slower this time.'`. Production currently routes
through `_feedbackString` (practice_screen.dart) which is correct, so this is latent —
but `feedbackForMistake` is public API and the obvious helper a future caller will
reach for, at which point whole-letter failures silently lose their specific voice
(violates Pitfall 7 / "never generic"). The two parallel mapping functions
(`feedbackForMistake`, `_feedbackString` ×2 copies) are a maintenance hazard.

**Fix:** Either extend `feedbackForMistake` to cover all `MistakeId` values (and assert
exhaustiveness with a `switch` over the enum so adding an ID forces a copy decision), or
delete it if `_feedbackString` is the real path and it's only kept alive by tests.

### WR-03: Three copies of the MistakeId→feedback mapping drift independently

**File:** `lib/features/practice/widgets/feedback_panel.dart:130-156`, `lib/features/practice/practice_screen.dart:1230-1261`, `lib/core/scoring/geometric_stroke_scorer.dart:67-81`
**Issue:** `_feedbackString` exists verbatim in two files plus `feedbackForMistake` as a
third variant. They already disagree: `feedback_panel.dart` returns hardcoded English
placeholders for the whole-letter IDs (e.g. `'This letter has a few parts...'`) while
`practice_screen.dart` returns l10n-backed strings (`practiceFeedbackWrongStrokeCount`).
A change to authored copy must be made in up to three places; missing one ships
inconsistent tutor voice.

**Fix:** Extract a single `feedbackString(AppLocalizations?, MistakeId)` into one shared
location and have FeedbackPanel and PracticeScreen both call it.

### WR-04: Duplicate clean-rep logic in `onStrokeResult` and `onLetterResult`/`_registerCleanRep`

**File:** `lib/providers/practice_providers.dart:160-220`
**Issue:** `_registerCleanRep` (used by `onLetterResult`) and the pass branch of the
legacy `onStrokeResult` are near-identical mastery/praise/record-mastery logic, copied.
They can diverge (e.g. a future fix to the best-effort `_recordMastery` swallow applied
to only one). `onStrokeResult` appears to be dead in the Plan-04 whole-letter flow
(practice_screen calls only `onLetterResult`).

**Fix:** Route `onStrokeResult`'s pass branch through `_registerCleanRep`, or remove
`onStrokeResult` entirely if no caller remains (confirm via grep) to eliminate the
duplicate.

### WR-05: Dot-position check can mis-rule when the body stroke is degenerate

**File:** `lib/core/scoring/letter_scorer.dart:130-169, 172-181`
**Issue:** `_centroidY` returns `0.5` when the combined-bbox height is ≤0
(`h <= 0`) or the point list is empty. If a child's body stroke collapses to a near-
horizontal line and the dot sits very close in y, the body centroid and dot centroid can
land on the same side of each other in ways the strict `>` comparison (`refDotBelow !=
childDotBelow`) flips unexpectedly. There's no tolerance band around the body baseline —
a dot drawn level with the body (`childDotY == childBodyY`) is treated as "above," which
for a wobbly real capture could produce a false `dotMisplaced`. The synthetic fixtures
all have a clear vertical gap, so this is untested at the boundary.

**Fix:** Compare against the body's lower extent (or add a small dead-band epsilon)
rather than the body centroid, and add a fixture where the dot sits near the baseline to
pin the boundary behavior before real captures arrive in Plan 06.

### WR-06: `validateStroke` accepts `direction: "tap"` only for dots but never flags a missing/invalid `direction` consistently for non-known strings before the switch

**File:** `lib/core/scoring/stroke_validation.dart:141-207`
**Issue:** For a non-dot stroke with an unknown direction string, the code adds an
"unknown direction" violation (line 141-145) **and then** the `switch` at 168 has no
matching case, so no further direction-vs-points check runs — fine. But if `direction`
is `'tap'` on a non-dot stroke, it is NOT in `_knownDirections`? It is
(`_knownDirections` includes `'tap'`), so line 141 does not flag it; only the
`case 'tap'` arm (line 201) flags it. This is correct but fragile: the set membership
and the switch are two sources of truth for the same validity question. A future edit to
one (e.g. removing `'tap'` from the set) silently changes behavior.

**Fix:** Drive both the membership check and the direction-vs-points check from one
table/enum so "which directions are valid, and for which stroke types" lives in a single
place.

### WR-07: `_inferDirection` ties (`dx.abs() == dy.abs()`) always pick horizontal, mislabeling perfect diagonals

**File:** `lib/dev/authoring_screen.dart:146-153`
**Issue:** `if (dx.abs() >= dy.abs())` resolves a 45° diagonal stroke to a horizontal
direction. For an authoring tool feeding the validator, a diagonal alif-like stroke
authored at exactly 45° would be tagged `leftToRight`/`rightToLeft`, which then must
agree with first→last x — usually fine, but a near-vertical stroke captured with slight
horizontal jitter where `dx.abs()` momentarily ties could be mislabeled, producing a
reference whose `direction` disagrees with the intended teaching direction. Dev-only, so
WARNING not BLOCKER, but authored reference data is curriculum-critical.

**Fix:** Bias ties toward vertical (the common Arabic downstroke case) or surface the
inferred direction to the owner for confirmation (the dropdown already allows override,
so at minimum document the tie behavior).

## Info

### IN-01: `_kIdentityConfidenceFloor` (0.5) and `_kTopCandidateConfidence` (0.9) make the floor a no-op

**File:** `lib/core/scoring/letter_scorer.dart:38`, `lib/core/recognition/ml_kit_recognizer.dart:44`
**Issue:** The recognizer always reports `0.9` for any top candidate (raw ML Kit score
is unreliable, by design), and the orchestrator's floor is `0.5`. So the floor
comparison (`result.confidence < _kIdentityConfidenceFloor`) is always false whenever a
candidate exists — the "weak evidence" branch is structurally dead in production with
the real recognizer. The unit tests exercise it only via injected fakes. This is the
intended design (confidence is a fixed advisory signal), but the two constants create the
illusion of a tunable threshold that does nothing.

**Fix:** Document explicitly that with the real recognizer the floor is exercised only by
the fixed `0.9`, or collapse to a boolean "has candidate" decision to avoid implying a
tunable knob.

### IN-02: `_Bounds` class doc-comment says "Mutable" but it is immutable

**File:** `lib/core/scoring/letter_scorer.dart:227-231`
**Issue:** Comment reads "Mutable bounding box helper" but all fields are `final` and the
constructor is `const`. Misleading.

**Fix:** Change the comment to "Immutable bounding box helper."

### IN-03: `StrokeSpec.fromJson` will throw on a malformed point pair before the validator can report it gracefully

**File:** `lib/models/letter.dart:57-72`
**Issue:** `pair[0] as num` / `pair[1] as num` will throw a runtime cast/range error if a
point is not a 2-element numeric list, before `validateStroke` (which is specifically
written to report malformed points as strings, stroke_validation.dart:96-119) ever runs.
The validator's graceful path is therefore unreachable for the worst malformed inputs at
load time. Curriculum is owner-authored so low likelihood, but the defensive validator
implies a non-throwing load path that `fromJson` does not actually provide.

**Fix:** Make `fromJson` tolerant (skip/flag malformed pairs) so the validator can do the
human-readable reporting, or wrap the curriculum load in a try/catch that surfaces the
validator output.

### IN-04: Skipped/RED-contract comments in `letter_scorer_test.dart` are now stale

**File:** `test/core/scoring/letter_scorer_test.dart:10-27, 229-241`
**Issue:** The header still says the `scoreLetter` tests are "intentionally RED" and
"skipped (not deleted)" and to "Remove the `skip:`," but the tests are live (no `skip:`)
and pass. Stale guidance can mislead the next maintainer into thinking the contract
isn't wired.

**Fix:** Update the comments to reflect that the contract is implemented and live.

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
