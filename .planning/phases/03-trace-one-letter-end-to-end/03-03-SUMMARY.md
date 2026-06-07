---
plan: 03-03
phase: 03-trace-one-letter-end-to-end
status: complete
completed: 2026-06-07
---

# Plan 03-03 Summary — Trace Surface & Animation Widgets

## What Was Done
- Created lib/config/debug_flags.dart (DebugFlags.allowFingerInput)
- Created lib/core/recognition/handwriting_recognizer.dart (empty seam, D-16)
- Created lib/features/practice/widgets/stroke_canvas.dart (Listener capture, stylus filter, dotted guide, onStrokeSubmitted callback)
- Created lib/features/practice/widgets/stroke_order_animation.dart (PathMetric animation, auto-play-once, replay())
- Created stroke_canvas_test.dart and stroke_order_animation_test.dart

## Key Decisions
- acceptTouch is injectable via constructor (default: DebugFlags.allowFingerInput) so tests can drive both branches
- Guide is drawn as a Path from ReferencePath.resolve (NOT Text) — Pitfall 5
- Animation auto-plays once in initState; replay() via public method on state

## Verification
- flutter test tests pass (stylus accepted, touch rejected in prod, touch accepted in debug)
- Animation auto-plays once + replays on demand
- No ML Kit / network imports in recognizer seam
- flutter analyze clean
