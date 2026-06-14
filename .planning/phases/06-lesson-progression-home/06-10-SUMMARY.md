---
phase: 06-lesson-progression-home
plan: 10
subsystem: practice-trace-render
tags: [render, dots, watch-animation, trace-guide, anti-gamification, gap-closure]
requires:
  - StrokeSpec.type (lib/models/letter.dart)
  - ReferencePath.resolve (point-geometry identity)
provides:
  - Watch animation renders type==dot strokes as calm ink circles
  - Trace guide renders type==dot strokes as calm ink circles
affects:
  - lib/features/practice/widgets/stroke_order_animation.dart
  - lib/features/practice/widgets/stroke_canvas.dart
  - lib/core/scoring/reference_path.dart (doc-only)
tech-stack:
  added: []
  patterns:
    - Painters iterate the typed StrokeSpec list directly for dot detection (NOT ReferencePath.resolve, which discards type)
    - Single-point dots excluded from PathMetric length math; rendered as filled circles with a fixed progress beat each
key-files:
  created: []
  modified:
    - lib/features/practice/widgets/stroke_order_animation.dart
    - lib/features/practice/widgets/stroke_canvas.dart
    - lib/core/scoring/reference_path.dart
    - test/features/practice/stroke_order_animation_test.dart
    - .planning/phases/06-lesson-progression-home/06-HUMAN-UAT.md
decisions:
  - Dot rendering reads StrokeSpec.type directly in the painters; ReferencePath.resolve stays a point-geometry identity (T-06-10-01) so the scorer contract is untouched.
  - Each dot gets a small fixed beat (_dotBeat = 0.12 of body length) in the Watch animation instead of zero polyline length; it calmly appears just after its body stroke — no bounce (anti-gamification).
  - The dot is painted in inkColor (~stroke-width radius), never QalamColors.reward; gold stays reward-exclusive (start-dot + pen-tip).
  - Tests compare colors via toARGB32() — Flutter's Color `==` is colorSpace-unreliable (two identical sRGB colors can compare unequal).
metrics:
  duration: ~7min
  completed: 2026-06-14
---

# Phase 06 Plan 10: Render dots in Watch animation + Trace guide Summary

Dotted-letter dot strokes (`type == "dot"`) now paint a calm filled ink circle in both the "Watch me write" stroke-order animation and the dotted Trace guide, fixing 15 letters (baa, taa, thaa, jeem, khaa, dhaal, zaay, sheen, daad, zhaa, ghayn, faa, qaaf, noon, yaa) whose dots were invisible.

## What was built

Fix B from 06-FIXES.md had two compounding root causes: (1) `ReferencePath.resolve()` discards the `type` field, so painters couldn't tell a `dot` from a 1-point line; and (2) a single-point dot became a `moveTo`-only zero-length subpath that `computeMetrics()` never draws.

Both painters now iterate the **typed** `referenceStrokes` directly, split them into body (line/curve) strokes vs dot strokes, keep dots out of the polyline length math, and paint each dot as a filled ink circle.

- **Task 1 (TDD):** `_AnimationPainter` splits body/dot strokes; body strokes animate via PathMetric exactly as before, dots are excluded from `_buildScaledPath` + `totalLength` and instead get a small fixed beat each (`_dotBeat`), appearing just after their body stroke as a filled `inkColor` circle. Gold start-dot/pen-tip unchanged. A new recording-canvas test proves a baa-like dotted fixture paints an ink circle at the dot's scaled point and asserts it is NOT gold.
- **Task 2:** `_CanvasPainter` mirrors the same split — dots excluded from the dotted-guide `_buildScaledPath`, painted as calm ink circles. Capture logic, `referenceStrokes.length` letter-complete signal, and live child ink are all unchanged (render-only).
- **Task 3:** `ReferencePath.resolve` doc-comment now states `type` is deliberately not carried (point-geometry only, scorer's source of truth) and dot detection lives in the typed-StrokeSpec painters — guarding T-06-10-01 (a future maintainer breaking the scorer to "fix" dots). No signature/behavior change.
- **Task 4:** Re-armed the device UAT in `06-HUMAN-UAT.md` with two pending items: Fix A (curl letters load without crashing) and Fix B (dots visible in Watch + Trace on baa/taa/thaa), and noted the glyph_audit golden as an expected environmental residual.

## Verification

- `flutter test test/features/practice/ test/core/` → 121 tests, all green.
- `stroke_order_animation_test.dart` → 6/6 green, including the new dot-render test.
- `grep -c "== 'dot'"` → 1 in each painter.
- `ReferencePath.resolve` signature `List<List<List<double>>>` unchanged.
- `flutter analyze` clean on all three modified lib files.
- `assets/curriculum/letters.json` and every `signedOff` flag are unmodified (left in the working tree per 06-FIXES.md; never staged).

## Anti-gamification compliance

The dot is a calm filled ink-color circle (deep-ink, ~stroke-width radius). The gold reward color stays reward-exclusive: the start-dot and animated pen-tip remain gold; the dot itself is ink. No bounce, no scale animation, no hype — the dot calmly appears.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Color equality in the new test compared via `==`, which is colorSpace-unreliable**
- **Found during:** Task 1 (GREEN)
- **Issue:** The implementation correctly painted the ink dot (verified by recording-canvas debug: circle at (200,320) with the exact ink color), but the test's `c.color == QalamColors.inkStroke` returned false. Flutter's `Color.==` compares float components + colorSpace and can return false for two visually identical sRGB colors (`toARGB32()` matched, `==` did not).
- **Fix:** Compare via `c.color.toARGB32() == QalamColors.inkStroke.toARGB32()` in the new test. This was part of reaching GREEN and is committed with the implementation.
- **Files modified:** test/features/practice/stroke_order_animation_test.dart
- **Commit:** 4a1e35a

## TDD Gate Compliance

- RED gate: `ed2b011` — `test(06-10): add failing test for dot-stroke rendering...` (test fails: no dot circle painted).
- GREEN gate: `4a1e35a` — `feat(06-10): render type==dot strokes as calm ink circles in Watch animation` (test passes).
- No REFACTOR commit needed.

## Known Stubs

None — dot rendering is fully wired; both painters read live curriculum `StrokeSpec.type`.

## Commits

- `ed2b011` test(06-10): add failing test for dot-stroke rendering in Watch animation (RED)
- `4a1e35a` feat(06-10): render type==dot strokes as calm ink circles in Watch animation (GREEN)
- `74ca66d` feat(06-10): render type==dot strokes as ink circles in the Trace guide
- `eebd066` docs(06-10): pin ReferencePath.resolve as point-geometry-only (T-06-10-01)
- `7897b0d` test(06-10): re-arm device UAT for curl-load (Fix A) + dot-visibility (Fix B)

## Self-Check: PASSED

All 5 modified/created files exist; all 5 task commits found in git history.
