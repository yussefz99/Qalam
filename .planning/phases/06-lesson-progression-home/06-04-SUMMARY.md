---
phase: 06-lesson-progression-home
plan: 04
subsystem: scoring + session-controller
tags: [flutter, riverpod, scoring, tolerance-ramp, persistence, tdd]

# Dependency graph
requires:
  - phase: 06-lesson-progression-home plan 01
    provides: CurriculumRepository.getDefaultToleranceRamp + Lesson.toleranceRamp (D-19 data)
  - phase: 06-lesson-progression-home plan 02
    provides: ProgressRepository setCleanReps/getCleanReps (overwrite semantics, incl. explicit 0)
  - phase: 06-lesson-progression-home plan 03
    provides: progressRepositoryProvider seam pattern (providers never touch the DB directly)
provides:
  - "Tolerances.preset(name): public ramp-preset lookup, unknown/empty → normal (never throws)"
  - "scoreLetter optional `tolerances:` override — resolution: override ?? letter.tolerances ?? normal; Phase-4 behavior byte-for-byte when omitted"
  - "PracticeState.tolerancePreset: ramp[min(cleanReps, ramp.length-1)] recomputed on every rep change (D-18/D-20)"
  - "Controller seeds cleanReps from the persisted LetterReps row on load and writes EVERY change through, incl. explicit 0 on a miss (D-10, Pitfall 7)"
affects: [06-05 home, 06-07 celebration (controller untouched surface), any future plan touching practice_providers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ref.mounted guard after EVERY await before a state write in autoDispose notifiers — Riverpod 3 throws on state-after-dispose (extends 06-03's pause landmine)"
    - "Controller test harness: container.listen keep-alive subscription before async settling — an unlistened autoDispose provider is torn down mid-settle and silently rebuilt fresh"
    - "Best-effort persistence: await inside try/swallow (deterministic for tests, never blocks the session)"

key-files:
  created: []
  modified:
    - lib/core/scoring/tolerances.dart
    - lib/core/scoring/letter_scorer.dart
    - lib/providers/practice_providers.dart
    - lib/features/practice/practice_screen.dart
    - test/core/scoring/letter_scorer_test.dart
    - test/features/practice/session_controller_test.dart

key-decisions:
  - "PracticeState.tolerancePreset defaults to 'normal' (the Phase-4 anchor) until the lesson's ramp resolves — pre-load reps can never score looser than the locked behavior-preserving preset"
  - "Empty per-lesson toleranceRamp is treated as ABSENT (falls back to the global default) — defensive against hand-edited data (T-06-07)"
  - "onStrokeResult's duplicated pass/miss logic unified into _registerCleanRep/_registerMiss so the D-10 write-through lives in exactly one place per direction"
  - "The screen passes the preset as STATE (Tolerances.preset(state.tolerancePreset)) — no loose/strict literal exists anywhere in lib/features/practice (UI-SPEC: invisible to the child)"

patterns-established:
  - "ref.mounted-after-await: required in any async method of an autoDispose notifier that assigns state"

requirements-completed: []  # S1-09 spans all 8 phase plans; REQUIREMENTS.md updated by orchestrator at phase close

# Metrics
duration: ~35min
completed: 2026-06-11
---

# Phase 06 Plan 04: Tolerance Ramp + Durable Rep Counts Summary

**The scaffolding fade and durable reps: each rep scores at the data-driven ramp preset for its PERSISTED index (loose → normal → strict, per-lesson overridable), clean-rep counts seed from and write through to LetterReps on every change including the reset-to-0 on a miss — all invisible to the child, with the Phase-4 scoring contract untouched when no override is passed.**

## Pedagogy Flags for the Owner's Mother (carry forward)

These ship as MECHANISMS with documented defaults — the RULES are hers to set:

- **D-10 cross-session persistence default:** a miss resets the banked clean-rep
  count to 0 even across sittings (mastery = N clean reps IN A ROW, period).
  Whether a fresh sitting should soften this is her call.
- **D-19 ramp semantics:** the shipped default ramp is `[loose, normal, strict]`
  indexed by the persisted rep count, clamped at the end. Both the global ramp
  (lessons.json `defaultToleranceRamp`) and per-lesson `toleranceRamp` overrides
  are hand-editable data, not code.

## Performance

- **Tasks:** 2/2 (both TDD)
- **Files modified:** 6

## Accomplishments

- `Tolerances.preset(name)` public accessor; unknown/empty name → normal (mirrors the fromJson defensive idiom; T-06-07 mitigation)
- `scoreLetter` gains optional `tolerances:` override; proven override-wins via a 0.21-curvature fixture that passes the letter's own 0.30 but fails strict's 0.18; all 60 pre-existing scoring tests green unmodified
- Controller seeds `cleanReps` from `getCleanReps` on load (D-20: a child resuming at rep 2 scores at rep 2's preset — proven across container restarts)
- Write-through on every transition: increments persist, a miss writes an EXPLICIT 0 (Pitfall 7 — a row, not an absence); failures swallowed, session never blocked
- Screen passes `Tolerances.preset(state.tolerancePreset)` into the existing scoreLetter call — single-line wiring, nothing rendered

## Task Commits

1. **Task 1 RED — Tolerances.preset + scoreLetter override contract** - `4acc253` (test)
2. **Task 1 GREEN — preset accessor + default-preserving override** - `8235052` (feat)
3. **Task 2 RED — rep persistence + ramp contract** - `7ecb0ce` (test)
4. **Task 2 GREEN — seeding, write-through, ramp resolution, screen wiring** - `5856120` (feat)

## TDD Gate Compliance

Both tasks: RED commit (verified failing) precedes GREEN commit (verified passing). Gate sequence intact in git log.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Riverpod 3 state-after-dispose in the controller's async paths**
- **Found during:** Task 2 GREEN (the pre-existing "initial state" test started failing)
- **Issue:** `_loadLetter`'s now-longer await chain (getCleanReps + getDefaultToleranceRamp) outlives an unlistened autoDispose provider; Riverpod 3 THROWS on assigning `state` after dispose (the latent bug existed before — the shorter chain just won the race)
- **Fix:** `if (!ref.mounted) return;` after every await preceding a state write (`_loadLetter`, `_registerCleanRep` x2, `_registerMiss`) — the exact remedy Riverpod's own error message prescribes
- **Verification:** all 16 controller tests green
- **Committed in:** 5856120

**2. [Rule 1 - Test harness] New controller tests needed keep-alive listeners**
- **Found during:** Task 2 GREEN (all 7 new tests read state as defaults)
- **Issue:** `container.read` does not keep an autoDispose provider alive across `_settle()`'s timer events — the provider disposed mid-load and a later read built a FRESH instance
- **Fix:** `_keepAlive` helper (`container.listen` subscription) in every new test — the faithful harness, since the production screen always `ref.watch`es the controller
- **Committed in:** 5856120

### Plan-Acceptance Discrepancy (documented, no code change)

The acceptance grep `grep -c "List<Offset>" lib/providers/practice_providers.dart` → 0 is unsatisfiable as written: the ANTI-PATTERN 3 GUARD header — which the same plan requires preserved VERBATIM — itself contains the literal twice (comment lines 6 and 8). Count is 2 before and after this plan, both in that comment; **zero occurrences in code**, which is the guard's intent. The `ANTI-PATTERN 3 GUARD` header grep (== 1) holds.

---

**Total deviations:** 2 auto-fixed (Rule 1), 1 acceptance-criterion discrepancy documented
**Impact on plan:** Robustness improved (mounted guards); no scope creep.

## Issues Encountered

- **getting_ready_test failure is PRE-EXISTING, not 06-04's** — verified by running the test against the base-commit (5e910d6) versions of every lib file this plan touched: identical failure. Root cause is 06-03's lessonId-resolution await under widget-test fixed pumps. Logged to `deferred-items.md`; not fixed (scope boundary).
- Full-suite known-failing set otherwise unchanged: glyph_audit + mastery_celebration goldens (font drift), home_screen Test 4 (06-05's debt).

## Known Stubs

None — `tolerancePreset`'s pre-load `'normal'` default is a documented defensive anchor, not a stub; no UI surface was added.

## User Setup Required

None.

## Next Phase Readiness

- 06-07 (celebration) consumes the unchanged celebrate-phase surface; the write-through means LetterReps is already current when celebration fires
- The `ref.mounted` + keep-alive-listener patterns apply to any plan extending practice_providers or its tests

## Self-Check: PASSED

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-11*
