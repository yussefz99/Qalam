---
phase: 18-build-the-living-tutor-dynamic-exercise-selection
plan: 10
subsystem: ui
tags: [remediation-arc, micro-drills, teacher-margin, spotlight, tutor-insight, anti-gamification, why-line, d-01, d-05, live-path]

# Dependency graph
requires:
  - phase: 18
    plan: 07
    provides: "the live selection path this panel narrates — TutorInsight published at verdict/coach time (criteria + pick + rationale), the D-08 micro-drill scoring, exercise_presenter rendering microDrill through the default scaffold branch, advanceOnFix so the arc RENDERS"
  - phase: 17
    plan: 06
    provides: "TutorInsight (criteria + pick + rationale) + tutorInsightProvider publish mechanism in exercise_scaffold.dart; the AuthoredFallback degradation axis (LLM online, authored offline)"
  - phase: 18
    plan: 02
    provides: "the baa micro-drill exercises (type:microDrill) with the authored spotlightZone strings dot/bowl/start"
  - phase: 07
    provides: "ExerciseScaffold + WriteSurface + StrokeCanvas engine seam the panel/overlay layer onto"
provides:
  - "TeacherMarginPanel — the CHILD-FACING remediation-arc narration + WHY line (D-01, sketch 001 Variant C), reading the SAME TutorInsight the verdict/coach publish (no second insight source), degrading coach-rationale-online → authored-template-offline (D-10)"
  - "SpotlightOverlay — the just-this-part micro-drill chrome (D-05, sketch 002 Variant B): a presentational radial scrim lighting the drilled zone + dimming the rest, IgnorePointer so stroke capture/scoring stay entirely with StrokeCanvas"
  - "Exercise.spotlightZone — the presentational-only lit-region label wired from config (18-02) to the overlay, never to the scorer"
  - "the arc + micro-drill are now VISIBLE and warm on the live path — no reward surface added (anti-gamification held)"
affects: [18-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Child-facing narration reuses the demo TutorInsight channel: the production Teacher's Margin reads the SAME tutorInsightProvider the 17.2 demo Teacher's Eye strip does — one insight source, two presentations (diagnostic demo strip + warm child note)"
    - "WHY line rides the coaching degradation axis by construction: insight.rationale (coach LLM) when present, else an authored template keyed by the verdict-time targeted criterion (D-10) — offline parity with zero new plumbing"
    - "Presentational overlay = IgnorePointer + CustomPaint radial scrim: the spotlight paints over the canvas but every pointer event falls straight through to the StrokeCanvas — the score path is byte-unchanged (D-05 verified by a capture-still-fires test)"

key-files:
  created:
    - lib/features/letter_unit/widgets/teacher_margin_panel.dart
    - lib/features/letter_unit/widgets/spotlight_overlay.dart
    - test/features/letter_unit/teacher_margin_test.dart
    - test/features/letter_unit/spotlight_overlay_test.dart
  modified:
    - lib/features/letter_unit/widgets/exercise_scaffold.dart
    - lib/features/letter_unit/widgets/write_surface.dart
    - lib/models/exercise.dart

key-decisions:
  - "TeacherMarginPanel derives the arc step-down from insight.pick (a microDrill.* id IS the step-down) — keeping the panel reading purely from TutorInsight so the acceptance 'no new insight/publish source' holds; the controller's private _sessionArc is never exposed"
  - "The panel COEXISTS with the demo _teacherEye() strip (both agent-path gated, both silent until an insight publishes) rather than replacing it — minimal blast radius on the working shell; whether the demo strip retires is a device-UAT call at 18-11"
  - "No QalamMascot inside the panel — the tutor column already owns the one mascot; a second would flip the scaffold's findsOneWidget mascot assertions. The margin is a pencil-note (text + ink tokens), not a second mascot surface"
  - "SpotlightOverlay maps spotlightZone → a fractional Alignment (dot lower-centre, bowl centre, start upper-right for R→L baa), not reference-path geometry — the micro-drill surface is write-mode (no dotted guide to reuse); exact pixel fidelity is a 18-11 device-UAT refinement"
  - "Overlay layered ABOVE the ink but BELOW the chrome (surface tag / Watch-me) so those stay bright; only for type=='microDrill', inert for any non-drill / unknown zone"
  - "requirements-completed left [] following the phase precedent (18-01..18-09 all left []): SPEC-18-R1/R3/R4 are now VISIBLE on the client but the arc/step-down framing copy is signed:false (mother signs at 18-11) and the deploy gates remain; the phase verifier / 18-11 flips the boxes"

patterns-established:
  - "Presentational-only overlay proof: a widget test asserts NO GestureDetector inside the overlay + IgnorePointer present AND that StrokeCanvas.onLetterComplete still forwards a verdict — the D-05 'the child still writes' invariant is regression-locked, not just asserted structurally"
  - "Anti-gamification token guard on any new tutor-facing surface: the test concatenates every rendered Text and asserts no streak/points/badge/+/score token renders (CLAUDE.md Decided)"

requirements-completed: []

# Metrics
duration: 8min
completed: 2026-07-11
---

# Phase 18 Plan 10: Make the Living Tutor Visible — Teacher's Margin + Spotlight Summary

**The remediation arc and the just-this-part micro-drill are now VISIBLE and warm on the live path: a child-facing Teacher's Margin panel narrates the WHY line + the named step-down beside the canvas (reusing the SAME TutorInsight the verdict/coach already publish, degrading coach-online → authored-offline), and a presentational Spotlight overlay lights the drilled criterion's zone over the unchanged WriteSurface/scorer path — with zero reward surface added.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-07-11T15:39:38Z
- **Completed:** 2026-07-11T15:47:39Z
- **Tasks:** 2 (both `tdd="true"` — RED then GREEN)
- **Files modified:** 7 (4 created, 3 modified)

## Accomplishments

- **Task 1 — Teacher's Margin panel (D-01):** `TeacherMarginPanel` is the CHILD-FACING production panel (unlike the 17.2 demo-only "Teacher's Eye" strip). It reads the SAME `tutorInsightProvider` the scaffold already publishes — no second insight source — and is silent until the first verdict. The WHY line rides the coaching degradation axis by construction: `insight.rationale` (the coach LLM line) when online, else an authored template keyed by the verdict-time targeted criterion (D-10, offline parity). During an arc it narrates the named step-down ("Let's practice just the dot for a moment — then we'll come back") derived from `insight.pick` naming a `microDrill.*` node (the D-03 register, provisional copy `signed:false`). Parchment/ink tokens only; a widget test concatenates every rendered `Text` and asserts no `streak`/`points`/`badge`/`+`/`score` token renders (anti-gamification). Wired into `exercise_scaffold.dart` beside the canvas on the agent path.
- **Task 2 — Spotlight overlay (D-05):** `SpotlightOverlay` paints a soft radial scrim — transparent in the drilled zone (dot/bowl/start), a gentle ink dim beyond — so the whole letter stays visible while the eye is drawn to the drilled part (sketch 002 Variant B). It is presentational ONLY: wrapped in `IgnorePointer` with no `GestureDetector`, so stroke capture + scoring stay entirely with `StrokeCanvas` (a test drives `onLetterComplete` and confirms the verdict still forwards — the D-05 "the child still writes" invariant is regression-locked). `WriteSurface` layers it ABOVE the ink and BELOW the chrome, ONLY for a `type=='microDrill'` exercise; inert for any non-drill / unknown zone. `Exercise.spotlightZone` now carries the drill's authored lit-region string from config to the overlay (presentational only, never the scorer).

## Task Commits

Each task committed atomically (TDD: RED test → GREEN feat):

1. **Task 1 RED: failing Teacher's Margin test** — `5f81ff9` (test)
2. **Task 1 GREEN: Teacher's Margin panel + scaffold wiring** — `e8e3259` (feat)
3. **Task 2 RED: failing Spotlight test + Exercise.spotlightZone** — `cc7382c` (test)
4. **Task 2 GREEN: Spotlight overlay + WriteSurface layering** — `6972028` (feat)

## Files Created/Modified

- `lib/features/letter_unit/widgets/teacher_margin_panel.dart` (NEW) — child-facing WHY line + arc step-down narration, reads `tutorInsightProvider`, degrades coach→authored (D-10)
- `lib/features/letter_unit/widgets/spotlight_overlay.dart` (NEW) — presentational radial-scrim spotlight, `IgnorePointer` + `CustomPaint`, zone→Alignment mapping
- `test/features/letter_unit/teacher_margin_test.dart` (NEW) — 5 tests: silent-until-insight / online WHY / offline authored WHY / arc step-down / anti-gamification guard
- `test/features/letter_unit/spotlight_overlay_test.dart` (NEW) — 3 tests: drill lights the zone / non-drill inert / capture not intercepted
- `lib/features/letter_unit/widgets/exercise_scaffold.dart` — renders `TeacherMarginPanel` in the tutor column beside the canvas (agent path)
- `lib/features/letter_unit/widgets/write_surface.dart` — layers `SpotlightOverlay` for `type=='microDrill'` (above ink, below chrome)
- `lib/models/exercise.dart` — adds presentational-only `spotlightZone` (parsed from config, additive/non-breaking)

## Decisions Made

- **The panel reads the arc from `TutorInsight.pick`, not a new controller accessor.** A `microDrill.*` pick IS the arc's step-down, so the panel narrates it while still reading purely from the existing insight channel — satisfying the acceptance "no new insight/publish source added" without exposing the controller's private `_sessionArc`.
- **The Teacher's Margin COEXISTS with the demo Teacher's Eye strip** rather than replacing it — both agent-path gated, both silent until an insight publishes. Minimal blast radius on the working shell; whether the diagnostic strip retires for production is a device-UAT call at 18-11.
- **No mascot inside the panel.** The tutor column already owns the one `QalamMascot`; a second would flip the scaffold's `findsOneWidget` mascot assertions. The margin is a text pencil-note (ink tokens), keeping the mascot count at exactly one.
- **Zone → fractional Alignment, not reference geometry.** The micro-drill surface is write-mode (no dotted guide to reuse), so the lit zone is a fractional position keyed by the authored string (matching the sketch's fractional radial-gradient centre). Exact pixel fidelity is a 18-11 device-UAT refinement.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `Exercise.spotlightZone` so the drill's lit-region string reaches the overlay**
- **Found during:** Task 2 (Spotlight overlay)
- **Issue:** The plan's `key_links` require the overlay to read `microDrill.spotlightZone`, but the `Exercise` model did not parse the `spotlightZone` field that already exists in `exercises.json` (18-02) — so the string could never reach `WriteSurface` / the overlay. `lib/models/exercise.dart` was not in the plan's `files_modified`.
- **Fix:** Added a presentational-only `String? spotlightZone` to `Exercise` + its `fromJson` parse (additive, defaulted null, non-breaking). Documented in the field doc that it drives only the overlay, never the scorer (the D-08 verdict stays owned by `criteria.first`).
- **Files modified:** lib/models/exercise.dart
- **Verification:** The Task-2 fixture constructs `Exercise(type:'microDrill', spotlightZone:'dot')` and the overlay reads `overlay.spotlightZone == 'dot'`; `flutter analyze` added zero new lints; `flutter test test/features/` no new regression.
- **Committed in:** `cc7382c` (Task 2 RED commit — the enabling data-carrier for the test)

---

**Total deviations:** 1 auto-fixed (1 Rule 3 blocking).
**Impact on plan:** The one deviation is a minimal additive data-carrier required for the plan's own `key_links` to hold; the field is presentational-only and touches no scorer/wire/PII surface. No scope creep — no new packages, no schema/wire change.

## Issues Encountered

- **2 pre-existing baseline failures in `test/features/` (NOT caused by this plan):** `meet_section_test` (the `img.door` image-caption assertion in the teachCard section) and `mastery_celebration_golden_test` (the documented local font-drift golden). Both are the SAME known baseline the 18-07 SUMMARY recorded, unchanged by this plan (confirmed by naming the failing tests). Left untouched per the SCOPE BOUNDARY rule. `test/features/` = +153 / −2 (the 2 are the known baseline; +8 new tests from this plan, zero new failures).

## Known Stubs

None new. The Teacher's Margin WHY templates + the arc step-down framing copy are `signed:false` (the owner-mother signs them at the 18-11 HUMAN-UAT gate, D-03) — provisional pedagogy copy, not stubs that block this plan's goal (the panel renders and degrades correctly today; the flip is a copy edit). The micro-drill exercises + their `spotlightZone` strings remain `signed:false` (18-02), also mother-gated at 18-11.

## Threat Flags

None — no security-relevant surface beyond the plan's `<threat_model>`. T-18-10-01 (reward-surface creep) is mitigated: the anti-gamification token guard is green in the Teacher's Margin test. T-18-10-02 (overlay alters scoring) is mitigated: the Spotlight is `IgnorePointer`/`CustomPaint` only and the capture-still-fires test proves the verdict path is untouched. T-18-10-03 (unsigned arc/step-down copy) is mitigated: the framing copy ships `signed:false` for the mother's 18-11 sign-off. `Exercise.spotlightZone` is a fixed-vocabulary presentational label (dot/bowl/start), non-PII, never on the wire.

## Next Phase Readiness

- **18-11 (HUMAN-UAT + deploy):** the intelligence is now VISIBLE — the mother reviews the Teacher's Margin WHY templates + the arc step-down framing + the micro-drill copy at the device UAT (sketches 001/002 fidelity confirmed there per the plan's verification note), and the single Cloud Run re-deploy carries the wire fields live; the verifier flips SPEC-18-R1/R3/R4.
- No blockers. No new packages. No wire/schema change.

## Self-Check: PASSED

- All 4 created files present on disk (verified below).
- All 4 task commits present in git history: `5f81ff9`, `e8e3259`, `cc7382c`, `6972028`.
- Verification suite green: `teacher_margin_test` (5) + `spotlight_overlay_test` (3) = 8 passed together; `flutter test test/features/` = +153 / −2 (the 2 = the known baseline: meet_section `img.door` + mastery golden font-drift, unchanged). `flutter analyze` on all changed lib files added zero new lints (only the pre-existing `exercise.dart:100` null-aware info remains).

---
*Phase: 18-build-the-living-tutor-dynamic-exercise-selection*
*Completed: 2026-07-11*
