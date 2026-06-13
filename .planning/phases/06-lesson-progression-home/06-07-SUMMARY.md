---
phase: 06-lesson-progression-home
plan: 07
subsystem: ui
tags: [flutter, riverpod, go_router, l10n, tdd, celebration, progression]

# Dependency graph
requires:
  - phase: 06-lesson-progression-home plan 01
    provides: lesson catalog + progression engine (next-lesson / last-lesson semantics)
  - phase: 06-lesson-progression-home plan 03
    provides: todayLessonProvider / progressionProvider (zero-invalidate S1-09 immediacy) + /practice?lesson= + /journey?highlight= deep links
  - phase: 06-lesson-progression-home plan 06
    provides: live journey map honoring ?highlight= (D-15 handoff target)
provides:
  - "Parameterized MasteryCelebration: glyph/letterName/masteredLetterId/onNextLesson/isLastLesson — speaks the mastered letter (Pitfall 6), never hardcoded alif"
  - "D-14 Next Lesson primary CTA (filled teal) → /practice?lesson=<next>; Back Home demoted to ghost; See journey ghost link → /journey?highlight=<masteredId>"
  - "D-16 last-lesson variant: See Journey primary, Next Lesson absent (no capstone screen)"
  - "D-17 tutor line 'Go show your {letterName} to someone at home.' under the Arabic praise"
  - "Practice surface teaches the resolved lesson's letter (baa+ reachable), not a hardcoded alif; Watch heading + per-rep praise templated on the letter"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Celebrate-phase wiring (_CelebrateView): watches todayLessonProvider — post-mastery the stream already advanced, so today IS the newly unlocked lesson → Next Lesson target; today.hasValue && today==null → last-lesson variant; loading → Next Lesson absent (degradation, never a raw error)"
    - "Per-letter UI copy: templated ARB keys ({letterName}) on the practice surfaces; per-letter coaching WORDING stays Phase-7 content (owner's mother's domain)"
    - "Celebrate-phase widget tests: drive the session controller via container.read(notifier).onLetterResult; bounded pumps (NOT pumpAndSettle — the one-shot star animation + live mastery stream never settle); ValueKey on the test router's /practice mirrors the real router so Next-Lesson re-resolves State (Pitfall 5)"

key-files:
  created: []
  modified:
    - lib/features/practice/widgets/mastery_celebration.dart
    - lib/features/practice/practice_screen.dart
    - lib/l10n/app_en.arb
    - test/features/practice/mastery_celebration_golden_test.dart
    - test/features/practice/practice_screen_test.dart
    - test/features/practice/goldens/mastery_celebration.png

key-decisions:
  - "MasteryCelebration is parameterized on the mastered letter (glyph + romanized name + canonical id) — Pitfall 6 closed: no surface praises alif after mastering another letter."
  - "_CelebrateView derives the Next-Lesson target from todayLessonProvider (catalog-internal, post-mastery already recomputed) — never user input (T-06-03 honored)."
  - "Rule-1 fix: _PracticeBody no longer loads getLetter('alif') hardcoded — it renders the lesson's resolved letter; otherwise every baa+ lesson would teach alif's strokes, defeating S1-09's actionable unlock."
  - "Dead static keys practiceCelebrationLine / practiceMasteredHeading removed (all usages migrated to templated keys). practicePraiseLine kept — still read by the unmounted praise_panel.dart."
  - "The mastery_celebration golden was deliberately re-baked ONCE for the D-14/D-17 layout change (the sanctioned re-bake). Baked on THIS machine — carries the known local-font-drift caveat. glyph_audit golden untouched."

patterns-established:
  - "Any per-letter practice copy reads the letter via a templated ARB key — never a hardcoded letter name on a child-facing surface."

requirements-completed: []  # S1-09 spans the phase; REQUIREMENTS.md updated by the orchestrator at phase close

# Metrics
duration: ~50min
completed: 2026-06-13
---

# Phase 06 Plan 07: Mastery Celebration — Next-Lesson CTA & Per-Letter Copy Summary

**The pass → unlock moment is now real on screen: the celebration speaks the mastered letter, offers a primary "Next Lesson" straight into the newly unlocked practice (D-14), the last-lesson "See Journey" variant (D-16), and one warm "show someone at home" tutor line (D-17) — with the practice surface itself finally teaching the lesson's own letter instead of a hardcoded alif.**

## Performance

- **Tasks:** 2/2 (both TDD)
- **Files modified:** 6 (incl. one deliberately re-baked golden)

## Accomplishments
- `MasteryCelebration` parameterized on `glyph` / `letterName` / `masteredLetterId` / `onNextLesson` / `isLastLesson`. The mastered glyph + heading + tutor line all speak the actual letter (ب / "You learned baa.") — Pitfall 6 closed.
- D-14: a filled-teal "Next Lesson" primary; "Back Home" demoted to a ghost; exactly one primary per variant.
- D-16: last-lesson variant — "See Journey" becomes the primary, "Next Lesson" is absent.
- D-17: one warm tutor line under the Arabic praise, naming the mastered letter.
- D-15 handoff: the "See journey" ghost link navigates `/journey?highlight={masteredLetterId}`.
- `_CelebrateView` reads `todayLessonProvider`: post-mastery the stream already advanced, so today IS the newly unlocked lesson → the Next-Lesson target; null today → last-lesson variant; loading → Next Lesson absent (degradation).
- Rule-1 fix: `_PracticeBody` now teaches the lesson's resolved letter (the hardcoded `getLetter('alif')` is gone). Watch-phase heading + per-rep praise are templated on the letter.
- Stale Phase-3 "no See journey button" debt reconciled — the journey handoff lives on the celebration now; the negative still holds in Watch/Trace.

## TDD Gate Compliance
- **RED:** `7668e8d test(06-07)` — parameterized-celebration contract + reconciled golden test, failing to compile on the missing params.
- **GREEN (Task 1):** `3af8db5 feat(06-07)` — celebration widget + practice wiring; the practice_screen call-site change was folded in here because the package must compile for the golden test to run (TDD-gate nuance: the Task-2 wiring tests were written against this already-present wiring; documented below).
- **GREEN (Task 2):** `00e894a feat(06-07)` — per-letter copy templating, the `_PracticeBody` alif fix, and the celebrate-phase behavior tests (Next-Lesson navigation, last-lesson variant, highlight handoff). All 9 practice_screen tests + 8 golden tests green.

## Verification
- `flutter test test/features/practice/mastery_celebration_golden_test.dart test/features/practice/practice_screen_test.dart` — 17/17 green.
- `flutter analyze lib/features/practice/ test/features/practice/...` — no issues.
- Acceptance greps: `celebrationNextLesson|celebrationShowSomeone` present; no hardcoded glyph in celebration CODE (only doc comments mention 'ا'); `grep -rn "You learned alif" lib/` returns no source/ARB matches; Next-Lesson test asserts the literal route to `lesson_02`; last-lesson variant test present and green.
- Full suite: **343 passed, 1 failed** — the single failure is `glyph_audit_golden_test.dart`, the known environmental font drift (per MEMORY: never re-bake). The known-failing set SHRANK from 4 → 1: the mastery_celebration golden was deliberately re-baked, and both the mastery_celebration "no See Journey button" and home_screen Phase-3.1 stale-debt failures are now cleared.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PracticeScreen taught a hardcoded alif for every lesson**
- **Found during:** Task 2 (replacing alif-hardcoded copy)
- **Issue:** `_PracticeBody` loaded `curriculumRepo.getLetter('alif')` regardless of the resolved lesson. With Phase 6 making baa+ reachable, tapping "Next Lesson" into lesson_02 would still trace alif's strokes — defeating S1-09's actionable unlock.
- **Fix:** Resolve the lesson's first letter item in `_resolveLessonId` (`_lessonLetter`) and pass it into `_PracticeBody`, which now renders that letter (neutral loading while it resolves). The celebrate path reuses the same resolved letter.
- **Files modified:** lib/features/practice/practice_screen.dart
- **Commit:** 00e894a

### Within-task notes (not deviations)
- The Task-1 GREEN commit (`3af8db5`) necessarily included the practice_screen `_CelebrateView` wiring because the package must compile for the golden test to run. The Task-2 behavior tests were therefore authored against already-present wiring rather than a strict RED-before-wiring boundary; the parameterized-celebration contract itself was committed RED first (`7668e8d`). All behaviors are independently asserted and green.
- Removed two now-dead static ARB keys (`practiceCelebrationLine`, `practiceMasteredHeading`) whose only purpose was the old hardcoded "You learned alif." line; all call sites migrated to the templated keys. `practicePraiseLine` was kept (still referenced by the unmounted `praise_panel.dart`).

**Total deviations:** 1 auto-fixed (Rule 1 correctness).
**Impact on plan:** Scope unchanged; the fix is required for S1-09 to be true on screen.

## Golden Re-bake Provenance
`test/features/practice/goldens/mastery_celebration.png` was re-baked ONCE
(`flutter test --update-goldens test/features/practice/mastery_celebration_golden_test.dart`)
for the legitimate D-14/D-17 layout change (Next Lesson primary + demoted Back
Home + tutor line). This is the plan's sanctioned deliberate re-bake — distinct
from the environmental local-font drift that affects Arabic-glyph goldens on
this machine. The baseline therefore carries the known local-font caveat. The
`glyph_audit` golden was NOT touched (`git diff` shows no change to it).

## Known Stubs
- Per-letter celebration/praise WORDING is generic ({letterName} templates) by design — the per-letter coaching voice is Phase-7 content, the owner's mother's domain. Flagged for Phase 7. No code stubs: the celebration and practice surfaces are fully wired and letter-true.

## Threat Flags
None — no new network endpoints, auth paths, file access, or schema changes. The Next-Lesson route id comes only from the curriculum-derived `todayLessonProvider` (T-06-03 mitigation intact); the celebration adds no star deltas/totals (T-06-09 mitigation intact).

## Self-Check: PASSED

- lib/features/practice/widgets/mastery_celebration.dart — FOUND
- lib/features/practice/practice_screen.dart — FOUND
- test/features/practice/practice_screen_test.dart — FOUND
- test/features/practice/goldens/mastery_celebration.png — FOUND
- Commits 7668e8d, 3af8db5, 00e894a — FOUND

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-13*
