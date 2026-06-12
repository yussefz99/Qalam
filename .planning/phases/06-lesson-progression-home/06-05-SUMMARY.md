---
phase: 06-lesson-progression-home
plan: 05
subsystem: home-ui
tags: [flutter, riverpod, home, ink-fill, d-08, d-09, d-11, d-12, d-13, tdd]

# Dependency graph
requires:
  - phase: 06-lesson-progression-home plan 03
    provides: todayLessonProvider / cleanRepsForLetterProvider + the Home ARB copy keys (homeLessonTitleFor, homeAllMastered*, homeInkFillSemantics)
  - phase: 05-profiles-onboarding
    provides: childProfileProvider (startingLessonId for error degradation) + the _GreetingHeader 3-layer scope-aware pattern
provides:
  - "Live _TodaysLessonCard: scope guard → _TodaysLessonCardReader → _TodayCardLayout; today's REAL lesson (glyph + 'The Letter {name}') with the whole card as the single Start (S1-01, D-08, D-12)"
  - "_todayCardDataProvider: composes todayLessonProvider + curriculum letter lookup with startingLessonId error degradation (T-06-08)"
  - "Ink-fill rendering (D-09): deep-ink alpha 0.25 + 0.75×(reps/total), a11y-only semantics label, zero visible rep numerals, never gold"
  - "All-mastered end state (D-11): calm factual copy, card taps to /journey"
  - "Prepared-desk entrance (D-13): _PreparedDeskEntrance + _GlyphEntranceFade, once per arrival, reduced-motion renders settled immediately"
affects: [06-06 journey, 06-07 celebration, 06-08 phase verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Entrance-once-per-arrival: animation State lives ABOVE the provider reader (and the in-layout fade wraps at a stable tree position), so provider rebuilds never replay the entrance — a State-held played flag decided in didChangeDependencies (MediaQuery needed for disableAnimations)"
    - "Semantics(container: true) + ExcludeSemantics for a11y-only progress labels — without container:true the label merges into the card's tap node"
    - "Provider-internal error degradation: the composing FutureProvider catches the chain failure and resolves the startingLessonId lesson itself, so the reader's .when(error:) is only the final static fallback"

key-files:
  created: []
  modified:
    - lib/screens/home_screen.dart
    - test/screens/home_screen_test.dart

key-decisions:
  - "Glyph entrance second beat implemented as a self-contained _GlyphEntranceFade with one controller over durSlow+durBase and an Interval hold — no animation plumbing across the reader boundary"
  - "Loading state keeps the eyebrow visible (static copy) with blank title + empty glyph container, mirroring the _GreetingHeader degradation; tap is inert until data resolves"
  - "Two pre-existing comments contained the literal token 'QalamColors.reward' and broke the acceptance grep — reworded (comments only, no code change)"

patterns-established:
  - "_PreparedDeskEntrance/_GlyphEntranceFade: the project's once-per-arrival entrance recipe with reduced-motion bypass"

requirements-completed: []  # S1-01 spans the phase; REQUIREMENTS.md updated by orchestrator at phase close

# Metrics
duration: ~35min
completed: 2026-06-12
---

# Phase 06 Plan 05: Live Home Today-Card Summary

**Home's today-card is live: real lesson from todayLessonProvider with the D-09 ink-fill (the letter IS the progress), the calm D-11 all-mastered end state, the D-13 prepared-desk entrance with reduced-motion support, and the stale Test 4 reconciled (Journey navigates, Parent stays Coming soon).**

## Performance

- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments
- S1-01 landing: launch → today's REAL lesson (live glyph + "The Letter {name}"), whole card = the single Start → `/practice?lesson={id}`, zero navigation required
- Ink-fill (D-09): deep-ink opacity `0.25 + 0.75 × (persistedReps / cleanRepsToAdvance)`, a11y label "{n} of {N} clean reps", NO visible rep numerals, never gold (grep-enforced)
- All-mastered (D-11/D-12): "YOUR LETTERS / You've mastered all your letters." card taps to `/journey`; factual copy, no totals, no hype punctuation
- Error degradation (T-06-08): provider failure resolves the profile's startingLessonId lesson — the child always has a working Start; tested with an erroring mastery stream
- Prepared-desk entrance (D-13): slide-up 24px + fade over durSlow, glyph fade over durBase after settle; once per arrival (live rep updates proven not to replay it); `disableAnimations` renders settled on the first frame
- Test 4 reconciled: Journey nav item NAVIGATES (live since 03.1), Parent shows the only "Coming soon" — the known-failing suite set shrank by one
- Home stays single-purpose: exactly one today-card, no secondary practice CTA (D-12)

## Task Commits

1. **Task 1 RED: failing live today-card tests + reconciled Test 4** - `4e3e13f` (test)
2. **Task 1 GREEN: live today-card — provider wiring, ink-fill, all-mastered variant** - `1fc47ef` (feat)
3. **Task 2: prepared-desk entrance (D-13) with reduced-motion support** - `e87310b` (feat)

## Verification

- `flutter test test/screens/home_screen_test.dart` — 13/13 green (incl. the rewritten Test 4; zero remaining "Journey Coming soon" references)
- Full suite: 310 passing; the only 4 failures are the documented pre-existing set (glyph_audit + mastery_celebration golden font drift, mastery_celebration "no See Journey" = 06-07's debt, getting_ready = already in deferred-items.md) — the known-failing set SHRANK by the reconciled home test
- Acceptance greps: `QalamColors.reward` 0, bare `context.go('/practice')` 0, `todaysLessonCard` key present, `disableAnimations` 3, `Duration(milliseconds:` 0
- `flutter analyze lib/screens/home_screen.dart` — No issues found

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Ink-fill semantics label merged into the card's tap node**
- **Found during:** Task 1 GREEN verification (Test 6 found 0 nodes for "1 of 3 clean reps")
- **Issue:** `Semantics(label:)` without `container: true` merges the label upward into the GestureDetector's combined semantics, so the a11y contract was unreadable
- **Fix:** `Semantics(container: true)` + `ExcludeSemantics` so the ink-fill owns its node
- **Files modified:** lib/screens/home_screen.dart
- **Commit:** 1fc47ef

**2. [Rule 3 - Blocking] Pre-existing comments broke the reward-token acceptance grep**
- **Found during:** Task 1 acceptance check (`grep -c "QalamColors.reward"` returned 2)
- **Issue:** Two doc comments (file header + _GreetingLayout) contained the literal token while asserting it is NOT used
- **Fix:** Reworded both comments ("reward-gold token" / "the reward gold"); zero code change
- **Files modified:** lib/screens/home_screen.dart
- **Commit:** 1fc47ef

---

**Total deviations:** 2 auto-fixed
**Impact on plan:** None — plan scope unchanged; both fixes are within the planned files.

## Notes

- Test-file analyzer shows 2 `scoped_providers_should_specify_dependencies` warnings on the new overrides — identical to the committed practice_screen_test baseline (the riverpod_lint plugin does not honor `ignore_for_file` for this rule in the pinned analyzer); lib file is clean.
- The drift "multiple databases" debug warning during tests is pre-existing (unoverridden `appDatabaseProvider` via `_PersistenceProof`), not introduced by this plan.

## Known Stubs

None — the loading state's blank glyph/title is the UI-SPEC loading contract (silent degradation), not a stub; every rendered path is wired to live providers or the prescribed fallback.

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. T-06-08 (raw error to a child) and T-06-09 (gamification creep) mitigations are implemented and test/grep-enforced per the plan's threat register.

## User Setup Required

None.

## Next Phase Readiness

- 06-06 (Journey) can rely on the `/journey` tap-through from the all-mastered card and the reconciled nav contract
- 06-07 (Celebration) returns Home to a card that already reflects the new today lesson (S1-09 immediacy via 06-03's stream providers)

## Self-Check: PASSED

- lib/screens/home_screen.dart — FOUND
- test/screens/home_screen_test.dart — FOUND
- Commits 4e3e13f / 1fc47ef / e87310b — FOUND

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-12*
