---
phase: 06-lesson-progression-home
plan: 06
subsystem: ui
tags: [flutter, riverpod, journey, progression, canonical-ids, tdd]

# Dependency graph
requires:
  - phase: 06-lesson-progression-home plan 01
    provides: ProgressionSnapshot.compute exposing unlockedLessonIds + lessonIdByLetterId
  - phase: 06-lesson-progression-home plan 03
    provides: progressionProvider (live snapshot) + JourneyScreen.highlightId param + Riverpod 3 / repository-seam patterns
provides:
  - "Live Journey map: nodes derived from CurriculumRepository.getLetters() (canonical letters.json ids by construction) — the 19/28-drifted hardcoded _kLetters list deleted"
  - "mockJourneyProgressProvider retired (+ orphaned .g.dart); screen watches progressionProvider + journeyLettersProvider"
  - "Tap matrix (D-05/D-07/S1-09): complete/current/skipped-unlocked nodes navigate /practice?lesson=<owning lesson>; genuinely locked nodes inert"
  - "D-15 just-mastered highlight: a settling star on the ?highlight= node when that node is complete (dignified marker, not a reward animation)"
affects: [06-07 celebration (Next Lesson + journey handoff)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Journey nodes from the curriculum catalog — never a hardcoded letter list (canonical-by-construction; the drift landmine cannot recur)"
    - "Live journey via progressionProvider watch (no keepAlive mock); ?highlight= consumed off the JourneyScreen param 06-03 staged"

key-files:
  created: []
  modified:
    - lib/features/journey/journey_screen.dart
    - lib/features/journey/widgets/journey_node_widget.dart
    - lib/providers/journey_providers.dart
    - test/features/journey/journey_screen_test.dart
  deleted:
    - lib/providers/journey_providers.g.dart (orphaned after the mock retired)

key-decisions:
  - "03.1 D-08 'screen doesn't change' is AMENDED: the journey data source MUST change (canonical-ID fix) or mastered daal/raa/haa_c/taa_h would silently never light — RESEARCH A5. Visuals/layout unchanged; only the data binding."
  - "Node IDs come from getLetters() so they are canonical by construction — there is no second list to drift against."
  - "D-15 highlight only renders on a node that is actually complete; a ?highlight= pointing at a non-complete or unknown node is a silent no-op."

patterns-established:
  - "Catalog-derived progress UI: any per-letter UI list reads the curriculum catalog, never a parallel hardcoded array"

requirements-completed: []  # S1-01/S1-09 span all 8 phase plans; REQUIREMENTS.md updated by orchestrator at phase close

# Metrics
duration: ~40min (interrupted by a model-availability error on the spawning runtime; Task 3 commit + SUMMARY closed out by the orchestrator)
completed: 2026-06-13
---

# Phase 06 Plan 06: Live Journey Map Summary

**The Journey map now lights from live progression with canonical letters.json IDs — retiring both the keepAlive mock and the 19/28-drifted hardcoded letter list — and shows the D-15 just-mastered highlight star.**

## Performance

- **Tasks:** 3/3 (all TDD; RED → GREEN → highlight)
- **Files modified:** 4 (1 generated file deleted)

## Accomplishments
- The journey screen reads `journeyLettersProvider` (from `CurriculumRepository.getLetters()`) and `progressionProvider`; the hardcoded `_kLetters` array — wrong in 19 of 28 cases vs `letters.json` — is deleted. Mastered `daal`/`raa`/`haa_c`/`taa_h` now light (the RED regression that started this plan).
- `mockJourneyProgressProvider` and its orphaned `.g.dart` retired.
- Tap matrix per D-05/D-07/S1-09: complete / current / skipped-but-unlocked nodes navigate to `/practice?lesson=<owning lesson>`; genuinely locked nodes are inert.
- D-15: a settling highlight star on the just-mastered node when arriving via `?highlight=` (consumed off the `JourneyScreen.highlightId` param 06-03 staged); no-op for non-complete or unknown ids.
- 10/10 journey tests green; analyzer clean.

## Task Commits

1. **Task 1: Wave-0 RED — live-journey contract** - `5a5af6f` (test)
2. **Task 2: GREEN — journey lights from live progression, canonical ids, mock retired** - `ddffd09` (feat)
3. **Task 3: D-15 just-mastered highlight star** - `91f5930` (feat)

## Decisions Made
See key-decisions frontmatter. The load-bearing one: **03.1 D-08's "the journey screen doesn't change" is amended** — there is no way to keep that literal AND make S1-09 true, because the old hardcoded IDs would never match live mastery (RESEARCH A5). The change is data-source-only; the visuals and layout are untouched.

## Deviations from Plan
None of substance — the canonical-ID fix and mock retirement are exactly the planned landmine remediation.

## Issues Encountered
- **Spawning runtime hit a model-availability error mid-run** (`claude-fable-5` not accessible) after Tasks 1–2 committed and Task 3's code was written but uncommitted. The orchestrator verified Task 3 in the worktree (10/10 journey tests green, analyzer clean, zero "GREEN in Task 3" skip markers remaining), committed it as `91f5930`, and wrote this SUMMARY. No work was lost or redone.

## User Setup Required
None.

## Next Phase Readiness
- 06-07's celebration "Next Lesson" / journey handoff can rely on the live journey lighting correctly by canonical id and honoring `?highlight=`.

---
*Phase: 06-lesson-progression-home*
*Completed: 2026-06-13*
