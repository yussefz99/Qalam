---
phase: 06-lesson-progression-home
plan: 08
subsystem: ui
tags: [flutter, practice, animation, d21, ghost-comparison, tdd, privacy, refactor]

# Dependency graph
requires:
  - phase: 06-lesson-progression-home plan 03
    provides: practice screen wiring + childProfileProvider override pattern (headless tests)
  - phase: 06-lesson-progression-home plan 07
    provides: per-letter practice surface (lesson's resolved letter, ShowFix zone)
  - phase: 04 (scoring) plan 02.1-04
    provides: combined-bbox normalization in authoring_export (now extracted)
provides:
  - "lib/core/strokes/stroke_normalization.dart: shared combined-bbox 0..1 normalization over List<List<List<double>>> — one home for the Pitfall-2 math (authoring + child in-memory strokes)"
  - "StrokeOrderAnimation parameterized: optional duration + color (default-preserving — durWrite + inkStroke when omitted)"
  - "GhostComparison (D-21): side-by-side half-speed replay — child stroke coral, reference deep-ink; replayable; widget-State-only stroke points (T-03-01)"
  - "Practice ShowFix zone gains 'Watch the Difference' (offered only when failing strokes are held)"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Reuse-via-parameterization: the ghost comparison rides on StrokeOrderAnimation's existing PathMetric replay machinery (color/duration params) — no duplicated path code"
    - "Privacy-by-State-retention: the child's failing strokes live as normalized StrokeSpecs in _TraceWorkspace State ONLY, cleared on retry/pass/continue/dispose; never persisted, never lifted to provider scope (T-03-01 / T-06-04)"
    - "Combined-bbox normalization has a single home (lib/core/strokes/) serving both CapturedStroke authoring and raw child strokes — no re-derivation"

key-files:
  created:
    - lib/core/strokes/stroke_normalization.dart
    - lib/features/practice/widgets/ghost_comparison.dart
    - test/features/practice/ghost_comparison_test.dart
  modified:
    - lib/dev/authoring_export.dart
    - lib/features/practice/widgets/stroke_order_animation.dart
    - lib/features/practice/practice_screen.dart
    - lib/l10n/app_en.arb
    - test/features/practice/stroke_order_animation_test.dart

key-decisions:
  - "Combined-bbox normalization extracted to lib/core/strokes/stroke_normalization.dart as a pure function over List<List<List<double>>>; authoring_export.normalizeToStrokeSpecs now delegates (no bbox math re-derived). Pitfall 2 (dot above/below) preserved."
  - "StrokeOrderAnimation gained optional duration/color params; null defaults resolve to durWrite + inkStroke internally so every existing caller is byte-for-byte unchanged (default-preserving)."
  - "The ghost comparison reuses StrokeOrderAnimation (coral child @ durWrite*2 / deep-ink reference @ durWrite*2, linear) — no new path/PathMetric code."
  - "Child failing strokes are retained as normalized StrokeSpecs in _TraceWorkspace State only; cleared on retry/pass/continue/dispose. The 'Watch the Difference' button appears only when those strokes are held (onWatchDifference != null)."

patterns-established:
  - "lib/core/strokes/stroke_normalization.dart is the canonical combined-bbox normalizer for any 0..1 stroke mapping."

requirements-completed: []  # S1-09 spans the phase; REQUIREMENTS.md updated by the orchestrator at phase close

# Metrics
duration: ~12min
completed: 2026-06-13
---

# Phase 06 Plan 08: D-21 Ghost Comparison Summary

**After a wobbly letter the child can tap "Watch the Difference" and see their own stroke (coral, half speed) replayed beside Qalam's reference (deep-ink) — a teaching moment, never error-shaming — built by parameterizing the existing StrokeOrderAnimation and extracting the combined-bbox normalization to one shared home, with the child's stroke points provably staying in widget State only (T-03-01).**

## Performance

- **Tasks:** 2/2 (Task 2 TDD)
- **Files modified:** 8 (3 created, 5 modified)

## Accomplishments
- Shared `normalizeStrokesToUnitBox` core extracted; `authoring_export` delegates — the combined-bbox / Pitfall-2 math now has exactly one home, serving both authoring `CapturedStroke`s and the child's raw in-memory strokes.
- `StrokeOrderAnimation` gained optional `duration` + `color`, threaded to the controller and ink Paint; null defaults preserve every existing caller's behavior exactly (Watch phase, corner loop, ghost-cast overlay all unchanged).
- `GhostComparison` (D-21): two labeled panels ("Yours" coral / "Qalam's" deep-ink), title "Watch the difference.", half speed (durWrite × 2 = 2800ms, linear), replayable via one affordance — never "wrong vs right", never red.
- Practice ShowFix zone: the child's failing strokes are normalized and held in `_TraceWorkspace` State only; "Watch the Difference" appears beside "Show Me Again" (>= 16px gap) only when strokes are held; the panel overlays the canvas card and closes back to ShowFix; strokes cleared on retry/pass/continue/dispose.

## TDD Gate Compliance
- **RED:** `754e712 test(06-08)` — ghost-comparison contract + ARB keys, failing to compile on the missing `GhostComparison` widget.
- **GREEN:** `1f060f5 feat(06-08)` — `GhostComparison` widget + practice-screen ShowFix wiring; 15/15 green (6 ghost_comparison + 9 practice_screen).
- Task 1 is a default-preserving refactor (`2437cdf refactor(06-08)`), committed before the TDD task.

## Verification
- `flutter test test/features/practice/stroke_order_animation_test.dart test/features/authoring/ test/curriculum/` — 61/61 green (Task 1: defaults + custom duration/color, authoring + curriculum untouched).
- `flutter test test/features/practice/ghost_comparison_test.dart test/features/practice/practice_screen_test.dart` — 15/15 green.
- `flutter analyze` on the four touched lib files — no issues.
- Acceptance greps: `warnSoft` in ghost widget = 3 (>=1); `Colors.red` = 0; ghost widget 186 lines (>=60); normalization core 94 lines; core has no Flutter-widget import; authoring delegates via a single import with `_combinedBounds` count = 0 (no duplicated bbox math); `duration` wired to the controller.
- Full suite: **351 passed, 1 failed** — the single failure is `glyph_audit_golden_test.dart`, the known environmental font drift (per MEMORY: never re-bake). No new failures introduced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verification interpretation] `grep -c "List<Offset>" practice_providers.dart` returns 2, not 0**
- **Found during:** Task 2 verification (the plan's `<verify>` pipes the raw grep to `grep -qx "0"`).
- **Issue:** `practice_providers.dart` is untouched by this plan (confirmed: not in any 06-08 commit), but it has carried 2 `List<Offset>` matches since Phase 3 — BOTH are in the ANTI-PATTERN-3 SECURITY guard *comments*, which literally name the prohibited type to document the invariant ("NEVER holds List<Offset>", "grep ... must return 0"). The raw substring grep cannot tell a guard comment from real code.
- **Fix:** The no-persistence proof (`ghost_comparison_test.dart` test 4) asserts the invariant correctly — it strips comment lines and asserts zero `List<Offset>` in **CODE** (result: 0). The faithful T-03-01 intent ("no stroke points in provider scope") is fully proven; the literal `grep -qx "0"` on the comment-bearing file would be a false alarm.
- **Verification:** `grep` of CODE lines = 0; provider file untouched by the plan; 15/15 tests green incl. the proof.
- **Commit:** proof in `754e712` (RED) / `1f060f5` (GREEN).

**Total deviations:** 1 (Rule 1 — verification method refined to match T-03-01 intent; no behavioral or scope change).
**Impact on plan:** None — the privacy invariant is intact and demonstrably proven.

## Known Stubs
None. The ghost comparison is fully wired: the child's actual failing strokes (normalized) feed the coral panel, the letter's authored reference feeds the deep-ink panel.

## Threat Flags
None — no new network endpoints, auth paths, file access, or schema changes. T-06-04 (stroke-persistence creep) is mitigated as planned: strokes retained in `_TraceWorkspace` State only, cleared on retry/pass/continue/dispose, no storage seam imported into the widget, `practice_providers` untouched (0 `List<Offset>` in code). T-06-09 (shaming creep) mitigated: "Yours"/"Qalam's" framing, coral not red, no "wrong/right" copy (asserted green).

## Self-Check: PASSED

- lib/core/strokes/stroke_normalization.dart — FOUND
- lib/features/practice/widgets/ghost_comparison.dart — FOUND
- test/features/practice/ghost_comparison_test.dart — FOUND
- lib/features/practice/practice_screen.dart — FOUND
- Commits 2437cdf, 754e712, 1f060f5 — FOUND

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-13*
