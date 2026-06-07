---
plan: 03-01
phase: 03-trace-one-letter-end-to-end
status: complete
completed: 2026-06-07
---

# Plan 03-01 Summary — Geometric Stroke Scorer (TDD)

## What Was Done
- Created `test/core/scoring/scoring_fixtures.dart` — 5 synthetic alif strokes (cleanAlif, tooShort, inverted, curved, smallCorrect)
- Created RED test suite: `geometric_stroke_scorer_test.dart`, `stroke_resampler_test.dart`, `mistake_mapping_test.dart`
- Implemented `lib/core/scoring/scoring_models.dart` — `enum MistakeId` + `StrokeResult`
- Implemented `lib/core/scoring/stroke_resampler.dart` — `resample(pts, n)` + `normalizeToUnitBox(pts)` (fixed: zero-width axis centers at 0.5)
- Implemented `lib/core/scoring/geometric_stroke_scorer.dart` — `scoreStroke()` with 3 named predicates + `feedbackForMistake()`

## Key Decisions
- All thresholds in one documented block at top of scorer (D-15 — Phase 4 calibrates)
- `strokeLengthBelowThreshold`: raw input point count < 10 (proxy for "pen lifted too early"); Phase 4 replaces with canvas-aware arc-length check
- `strokeCurvatureExceedsThreshold`: max perpendicular distance from chord in unit-box > 0.25
- Predicate FUNCTION names equal authored `commonMistakes[].check` strings (data↔code contract)
- Zero `dart:ui` / `package:flutter` imports in all three scoring files
- `normalizeToUnitBox` uses per-axis width check to center zero-width axes at 0.5 (not raw scale division)

## Verification
- `flutter test test/core/scoring/` — 20/20 pass, exit 0
- Predicate names match authored check strings confirmed
- Pure Dart confirmed (no dart:ui / Flutter imports)
- Latency: scoreStroke(cleanAlif) completes well under 50ms (single-digit ms in practice)
