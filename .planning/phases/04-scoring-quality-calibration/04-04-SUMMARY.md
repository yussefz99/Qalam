---
phase: 04-scoring-quality-calibration
plan: 04
subsystem: practice-ui
tags: [dart, flutter, riverpod, scoring, mlkit, l10n, capture, getting-ready]

# Dependency graph
requires:
  - phase: 04-scoring-quality-calibration
    plan: 02
    provides: "scoreLetter — the async whole-letter orchestrator (count→order→shape→dot→advisory ML Kit gate) returning Future<LetterResult>, taking a whole multi-stroke letter"
  - phase: 04-scoring-quality-calibration
    plan: 03
    provides: "MlKitRecognizer (advisory-only HandwritingRecognizer over a whole letter) + ModelDownloadService.isReady + overridable inkModelManagerProvider"
provides:
  - "StrokeCanvas accumulates a WHOLE multi-stroke letter (no per-pointer-down clear) and fires onLetterComplete(List<List<Offset>>) at count-reached"
  - "practice_screen scores the whole accumulated letter via scoreLetter (single-stroke referenceStrokes.first path removed)"
  - "PracticeSessionController.onLetterResult — whole-letter verdict drives clean-rep / named-fix (onStrokeResult retained for the per-stroke path)"
  - "Authored l10n for the four whole-letter MistakeIds + getting-ready copy — never the generic fallback (Pitfall 7 / PLAT-03)"
  - "D-05 getting-ready banner — calm, non-blocking model-download wait that overlays the trace workspace; lesson runs underneath"
  - "D-04 advisory ML Kit gate consulted from the UI only when ModelDownloadService.isReady"
affects: [calibration-harness, curriculum-authoring, practice-loop]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Whole-letter capture: accumulate completed strokes, fire one letter-complete callback at count-reached (Open Q1)"
    - "Score-once-per-letter via scoreLetter on the letter-complete signal, not stroke-by-stroke"
    - "Best-effort, non-blocking getting-ready overlay (D-05) — ref.watch(modelDownloadServiceProvider).isReady gates an advisory recognizer, never the lesson"
    - "Authored-only feedback: every MistakeId resolves to an l10n string, never the generic fallback"

key-files:
  created:
    - test/features/practice/multi_stroke_capture_test.dart
    - test/features/practice/getting_ready_test.dart
    - .planning/phases/04-scoring-quality-calibration/deferred-items.md
  modified:
    - lib/features/practice/widgets/stroke_canvas.dart
    - lib/features/practice/practice_screen.dart
    - lib/providers/practice_providers.dart
    - lib/l10n/app_en.arb
    - test/core/scoring/mistake_mapping_test.dart
    - test/features/practice/practice_screen_test.dart

key-decisions:
  - "Letter-complete signal = count-reached: onLetterComplete fires once when accumulated strokes == referenceStrokes.length (Open Q1 recommendation), guarded against double-fire"
  - "onStrokeSubmitted kept as an optional per-stroke callback for immediate feedback; onLetterComplete carries the whole letter to scoreLetter (Open Q2 — count/order/identity are whole-letter verdicts)"
  - "dispose() retains _completedStrokes.clear() — it is in-memory-only discard discipline (T-01-05/T-04-08), NOT the accumulation bug; the bug-clears in _onDown and _commitStroke are gone"
  - "Getting-ready is a non-blocking OVERLAY banner (top of the trace workspace), not a replacement screen — the lesson + geometric scorer keep working (D-05)"
  - "MlKitRecognizer constructed in the UI only when isReady; the D-04 gating policy stays in scoreLetter, never in the screen"

patterns-established:
  - "Whole-letter accumulating capture surface with a count-reached completion signal"
  - "Advisory external gate wired from the UI only behind a readiness flag, with a calm degradation banner"

requirements-completed: [S1-05, PLAT-03]

# Metrics
duration: 11min
completed: 2026-06-08
---

# Phase 4 Plan 04: Wire the Spine into the UI Summary

**StrokeCanvas now ACCUMULATES a whole multi-stroke letter (the per-pointer-down clear bug is gone) and fires a single count-reached `onLetterComplete`; `practice_screen` scores that whole letter via `scoreLetter` (the `referenceStrokes.first` single-stroke path is removed), every new failure category resolves to an authored l10n string in the tutor's voice — never the generic fallback — the advisory ML Kit gate is consulted only when the model is ready, and a calm non-blocking getting-ready banner replaces any hard block while the model downloads (D-05).**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-06-08T13:40:10Z
- **Completed:** 2026-06-08T13:51:35Z
- **Tasks:** 2
- **Files modified:** 9 (3 created, 6 modified)

## Accomplishments
- **Closed the structural multi-stroke gap (SC#1 now reachable by a child).** `StrokeCanvas` no longer wipes prior strokes on each pointer-down; completed strokes accumulate into a whole-letter `List<List<Offset>>`. A new `onLetterComplete(List<List<Offset>>)` callback fires exactly once at the count-reached signal (accumulated strokes == `referenceStrokes.length`), guarded against double-fire. `onStrokeSubmitted` is kept (now optional) for immediate per-stroke feedback. The in-memory-only SECURITY discipline (T-01-05/T-04-08) is preserved — accumulated points are never logged/persisted, only the callbacks carry them, and dispose still clears.
- **Wired the spine.** `practice_screen` converts the accumulated Offsets to `List<List<List<double>>>` and calls `scoreLetter(childStrokes, letter, recognizer: …)` once on the letter-complete signal — the single-stroke `scoreStroke(…, referenceStrokes.first)` path is gone (`referenceStrokes.first` grep == 0; `scoreLetter` grep == 6). Only the `LetterResult` enters the controller; raw points stay local (T-04-08).
- **Advisory ML Kit gate from the UI (D-04 / SC#2).** A `MlKitRecognizer` is passed to `scoreLetter` only when `ModelDownloadService.isReady`; otherwise the gate abstains and the geometric scorer runs unchanged. The gating policy stays entirely in `scoreLetter`.
- **Getting-ready state (D-05).** A calm, non-blocking `_GettingReadyBanner` overlays the trace workspace (surface/ink tokens, no coral/red, no emoji) while the model downloads — never an error, never a hard block. The lesson and geometric scoring run underneath.
- **Authored feedback for every new failure (PLAT-03 / Pitfall 7).** Added four l10n strings (`practiceFeedbackWrongStrokeCount` / `…WrongStrokeOrder` / `…DotMisplaced` / `…WrongLetterIdentity`) + getting-ready copy in the tutor's warm, specific placeholder voice (the mother refines in Plan 06). `_feedbackString` now reads them; no whole-letter failure falls through to the generic fallback. Ran `flutter gen-l10n`.
- **State machine.** Added `PracticeSessionController.onLetterResult(LetterResult)` — a clean letter is a clean rep (praise/mastery via the shared `_registerCleanRep`), any miss resets the streak and shows the named fix. `onStrokeResult` is retained unchanged for the per-stroke path.
- **Tests.** `multi_stroke_capture_test` (two strokes accumulate; `onLetterComplete` fires once with a 2-element list, not 1, not cleared). `getting_ready_test` (model-not-ready → getting-ready banner shown, not an error, lesson still present). `mistake_mapping_test` extended (each new MistakeId → non-empty, specific authored l10n string, not fallback, not "Oops"; getting-ready copy is calm).

## Task Commits

Each task was committed atomically (explicit file paths only — pre-existing unrelated working-tree changes left untouched):

1. **Task 1: accumulate whole multi-stroke letter in StrokeCanvas** — `c7853db` (feat)
2. **Task 2: score whole letter via scoreLetter + getting-ready + ML Kit gate** — `9df97b9` (feat)

## Files Created/Modified
- `lib/features/practice/widgets/stroke_canvas.dart` (modified) — accumulation fix + `onLetterComplete` count-reached signal; `onStrokeSubmitted` made optional; SECURITY header updated; dispose retains in-memory clear.
- `lib/features/practice/practice_screen.dart` (modified) — `_onLetterComplete` calls `scoreLetter` (recognizer only when `isReady`); `_TraceWorkspace`/`_PracticeBody` re-threaded to `onLetterComplete`; `_GettingReadyBanner` overlay (D-05); four new `_feedbackString` arms read authored l10n.
- `lib/providers/practice_providers.dart` (modified) — `onLetterResult(LetterResult)` + shared `_registerCleanRep`; `onStrokeResult` retained.
- `lib/l10n/app_en.arb` (modified) — four whole-letter feedback strings + getting-ready title/body, all with `@`-descriptions in the tutor's voice.
- `test/features/practice/multi_stroke_capture_test.dart` (created) — Task 1 widget test.
- `test/features/practice/getting_ready_test.dart` (created) — Task 2 widget test (mocked model manager via `inkModelManagerProvider`).
- `test/core/scoring/mistake_mapping_test.dart` (modified) — whole-letter MistakeId → authored l10n group + getting-ready copy check.
- `test/features/practice/practice_screen_test.dart` (modified) — overrides `inkModelManagerProvider` (model ready) so pre-banner assertions hold headless.
- `.planning/phases/04-scoring-quality-calibration/deferred-items.md` (created) — logs the out-of-scope mastery-celebration golden font-drift.

## Decisions Made
- **Letter-complete = count-reached.** For a 2-part letter the canvas fires `onLetterComplete` once the second stroke lands. Simple, deterministic, and matches the reference's own stroke count — no extra "Done" button for the child (Open Q1).
- **Two callbacks, two purposes (Open Q2).** `onStrokeSubmitted` stays for optional immediate per-stroke feedback; `onLetterComplete` carries the whole letter to `scoreLetter` for the count/order/dot/identity verdicts. The screen uses only the whole-letter path today; the per-stroke seam is left in place for future warm coaching.
- **dispose keeps `_completedStrokes.clear()`.** See Deviations — this is the in-memory discard discipline the same plan's threat model mandates (T-04-08), not the accumulation bug.
- **Getting-ready is an overlay, not a gate.** The banner sits over the working trace surface so geometric scoring is never blocked (D-05).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] practice_screen_test trace/watch tests hung on the new model-provider dependency**
- **Found during:** Task 2
- **Issue:** `_PracticeBody.build` now `ref.watch`es `modelDownloadServiceProvider`. In `practice_screen_test` (which does not override `inkModelManagerProvider`) the real `DigitalInkRecognizerModelManager` issues a platform `MethodChannel` call that never completes headless, so `pumpAndSettle()` timed out across all 6 cases.
- **Fix:** `_buildScreen` now overrides `inkModelManagerProvider` with a mocked manager reporting already-downloaded, so the service resolves ready and the getting-ready banner is absent — the pre-banner assertions hold deterministically without a device.
- **Files modified:** test/features/practice/practice_screen_test.dart
- **Verification:** `flutter test test/features/practice/practice_screen_test.dart` → all green.
- **Committed in:** 9df97b9 (Task 2 commit)

### Scope notes (not deviations)
- **Acceptance criterion `grep -c "_completedStrokes.clear()" == 0` was met as `== 1`.** The single remaining occurrence is in `dispose()` — legitimate in-memory-only discard discipline (T-01-05 / T-04-08), which the SAME plan's threat model requires. Removing it would violate the security mandate to discard points on teardown. The two ACCUMULATION-BUG clears (in `_onDown` and `_commitStroke`) — the criterion's real intent — are both gone. The accumulation behavior is proven by `multi_stroke_capture_test` (two strokes survive).

**Total deviations:** 1 auto-fixed (1 bug). No architectural changes, no scope creep.

## Issues Encountered
- **Pre-existing golden font-drift (out of scope).** `mastery_celebration_golden_test.dart` golden snapshot fails with a 0.26% (~1235px) pixel diff. This is the documented local headless-font rendering drift (MEMORY: "golden tests font drift"), not a regression — Plan 04-04 does not touch `MasteryCelebration`. Logged to `deferred-items.md`; NOT re-baked (per the memory note and the scope-boundary rule).
- No package-manager installs (T-04-SC N/A).

## Known Stubs
None introduced. The four whole-letter feedback strings are placeholder copy in the tutor's authored voice (warm + specific, never generic) — explicitly the mother refines them in Plan 06. They are honest, specific guidance reachable by the scorer, not dead stubs.

## User Setup Required
None for code/test. (Operationally, the ~20 MB `ar` model downloads once on first launch; until then the getting-ready banner shows and the geometric scorer works — D-05.)

## Next Phase Readiness
- The practice loop now scores whole multi-stroke letters end to end — the calibration harness (later plan) can exercise the same `scoreLetter` over labeled fixtures, and curriculum authoring (baa/taa/thaa) flows straight into the live loop.
- The getting-ready + advisory-gate wiring is complete; once baa/taa/thaa are signed off, the SC#2 net activates the moment the model is ready, with no further UI work.

## Threat Flags
None beyond the plan's threat model. T-04-08 (raw multi-stroke points stay in-memory only; only `LetterResult` crosses into the controller), T-04-09 (getting-ready degrades gracefully, never errors), and T-04-10 (ML Kit gate consulted only when ready, advisory-only) are all honoured. No new network endpoint beyond the one-time model fetch already in the register.

## Self-Check: PASSED

- Created files verified present: multi_stroke_capture_test.dart, getting_ready_test.dart, deferred-items.md, 04-04-SUMMARY.md.
- Commits verified in git log: c7853db (Task 1), 9df97b9 (Task 2).
- `referenceStrokes.first` grep == 0; `scoreLetter` grep == 6; accumulation-bug clears removed.
- `flutter test` over practice + scoring + services + recognition suites → all green except the documented out-of-scope mastery_celebration golden (font drift, logged).

---
*Phase: 04-scoring-quality-calibration*
*Completed: 2026-06-08*
