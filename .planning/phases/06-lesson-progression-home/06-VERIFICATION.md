---
phase: 06-lesson-progression-home
verified: 2026-06-13T00:00:00Z
status: human_needed
score: 3/3 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Device UAT — launch-to-today's-lesson flow on a real tablet"
    expected: "Fresh app launch lands directly on today's lesson card with one Start and no navigation; trace the letter to its clean-reps-to-advance count; the celebration appears; tapping Next Lesson opens the newly unlocked letter, and returning Home shows that letter as today's lesson."
    why_human: "Stylus capture + real-device launch/scoring/unlock behavior is not emulatable in flutter_test; on-device confirmation is the canonical end-of-phase gate per 06-VALIDATION.md."
---

# Phase 6: Lesson Progression & Home Verification Report

**Phase Goal:** On opening the app the child immediately sees today's prepared lesson — the next unlocked lesson for the active child — with a single prominent Start and no navigation; the next lesson unlocks only after the child passes the current one per the curriculum's clean-reps-to-advance rule.
**Verified:** 2026-06-13
**Status:** human_needed
**Re-verification:** No — initial verification
**Mode:** mvp (goal is a narrative user-centric outcome, not strict "As a… I want… so that…" form — see note below)

## MVP Mode Note

The phase has `mode: mvp` in ROADMAP.md, but the goal is a narrative user-outcome statement rather than the strict User Story grammar (`As a … I want … so that …`). Per `references/verify-mvp-mode.md` this is a discrepancy worth surfacing (the goal could be reformatted via `/gsd mvp-phase 6`). It is NOT a verification blocker: the three ROADMAP Success Criteria are well-formed, observable, and used as the verification contract below. The User Flow Coverage table is provided since the goal is fully user-centric.

## User Flow Coverage

User flow: «Open the app → see today's lesson with one Start → trace and pass it → next lesson unlocks and becomes today's lesson.»

| Step | Expected | Evidence | Status |
|------|----------|----------|--------|
| Open app | Lands on Home showing today's REAL lesson for the active child — live glyph + "The Letter {name}" — whole card is the single Start, no nav needed | `lib/screens/home_screen.dart:585-722` (`_todayCardDataProvider` → `_TodaysLessonCardReader`), router default route `/` → `HomeScreen` (`app_router.dart:55`) | ✓ |
| Single Start | Card tap routes to `/practice?lesson=<today's id>`; no required navigation chrome | `home_screen.dart:694` route; `Key('todaysLessonCard')` GestureDetector `:789-791` | ✓ |
| Trace + pass | Whole-letter scored; N clean reps in a row (reset on miss) reach mastery per curriculum rule | `practice_providers.dart:226-265` (`onLetterResult`→`_registerCleanRep`, gate `newReps >= state.cleanRepsToAdvance`); rule sourced from `Letter.cleanRepsToAdvance` (curriculum JSON) `:60-61,173` | ✓ |
| Unlock + next-as-today | Mastery persists → stream emits → today recomputes → "Next Lesson" CTA opens the newly unlocked lesson; returning Home shows it as today | `_recordMastery` `:319-336` → `recordMastery` DB write `app_database.dart:143-153` → `watchMasteredLetterIds()` `:234` → `progressionProvider`/`todayLessonProvider` `progression_providers.dart:112-140` → `_CelebrateView` `practice_screen.dart:279-320` | ✓ |
| Outcome (device) | The full launch→pass→unlock loop behaves on a real tablet with stylus | Human-gated device UAT (06-VALIDATION.md line 74) | ? human |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | On launch the child lands on today's lesson for the active child with one clear Start and no navigation required (SC1 / S1-01) | ✓ VERIFIED | `_todayCardDataProvider` composes `todayLessonProvider` (computed for the ACTIVE child from `profile.startingLessonId` + mastered set + 28-lesson catalog) with a curriculum letter lookup; renders live glyph + "The Letter {name}", whole card is the single Start to `/practice?lesson=<id>`. Ink-fill alpha = 0.25 + 0.75×(reps/total), a11y-only semantics, never gold. All-mastered → calm card routing to `/journey`. Loading/error degrade silently. (`home_screen.dart:585-722`, `progression_providers.dart:112-140`) |
| 2 | Locked lessons are visibly unavailable until their prerequisite is passed (SC2 / S1-09) | ✓ VERIFIED | `lessonUnlocked` (D-02): unlocked iff every `unlock.requires[]` lesson is passed; empty requires = unlocked. Journey renders 28 live nodes; a node is tappable only when its lesson is `complete`/`current`/skipped-but-unlocked-future; genuinely locked future nodes (prerequisite unpassed) are inert (no `onTap`) — "visibly unavailable" via the future visual + inert tap. (`lesson_progression.dart:29-37,84-119`, `journey_screen.dart:381-418`) |
| 3 | Passing a lesson (meeting its clean-reps-to-advance rule) immediately unlocks the next lesson, which then appears as today's lesson (SC3 / S1-09) | ✓ VERIFIED | Clean-rep gate `newReps >= state.cleanRepsToAdvance` (in a row; miss resets to 0) → `_recordMastery` → `recordMastery` DB write → drift `watchMasteredLetterIds()` stream emits → `masteredLetterIdsProvider`/`progressionProvider`/`todayLessonProvider` recompute BY CONSTRUCTION (no `ref.invalidate`) → `_CelebrateView` reads the new today as the "Next Lesson" target; last lesson → "See Journey" variant. (`practice_providers.dart:226-336`, `progression_providers.dart:43-140`, `practice_screen.dart:279-320`, `mastery_celebration.dart:205-216`) |

**Score:** 3/3 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/models/lesson_progression.dart` | Pure-Dart engine: passed/unlocked/today + snapshot | ✓ VERIFIED | No Flutter/DB imports; `lessonPassed`, `lessonUnlocked` (D-02), `todayLesson` (D-06), `ProgressionSnapshot.compute` (D-05 skip + letter→lesson map). Imported by progression_providers + journey_screen. |
| `lib/providers/progression_providers.dart` | Live drift-stream providers, recompute on mastery without invalidation | ✓ VERIFIED | `_bindDriftStream` AsyncNotifiers; `masteredLetterIdsProvider`, `cleanRepsForLetterProvider`, `progressionProvider`, `todayLessonProvider`. Bounded 3s profile await degrades to first lesson. autoDispose (Pitfall 4). |
| `lib/screens/home_screen.dart` | Live today-card: ink-fill, prepared desk, all-mastered, single Start | ✓ VERIFIED | Live providers wired; data/loading/error/all-mastered variants; ink-fill on deep-ink (never gold); no rep numerals; single-Start GestureDetector. (Router uses THIS file, not the orphaned `lib/screens/practice_screen.dart`.) |
| `lib/features/journey/journey_screen.dart` | 28 live nodes; locked inert; skipped-but-unlocked tappable; highlight arrival | ✓ VERIFIED | `progressionProvider` + `journeyLettersProvider`; tappability gate on `unlockedLessonIds`; D-15 settle on `?highlight=`. |
| `lib/features/practice/practice_screen.dart` | `?lesson=` resolution (allowlist→today→lesson_01); celebration wiring | ✓ VERIFIED | `_resolveLessonId` allowlist degrade; `_CelebrateView` wires Next Lesson from live `todayLessonProvider`; last-lesson variant; Pitfall-6 letter parameterization. |
| `lib/features/practice/widgets/mastery_celebration.dart` | Parameterized celebration: Next Lesson / See Journey / tutor line | ✓ VERIFIED | `glyph`/`letterName`/`masteredLetterId` params; one primary CTA (Next Lesson or See Journey on `isLastLesson`); D-17 tutor line; one gold star (reward-exclusive). |
| `lib/data/app_database.dart` | Schema v4: LetterReps, watch streams, startingLessonId migration | ✓ VERIFIED | `schemaVersion => 4`; idempotent `onUpgrade` creates `letterReps` + rewrites `starting_lesson_id` 'alif'→'lesson_01'; `recordMastery`, `setCleanReps`, `watchMasteredLetterIds`, `watchCleanReps`. |
| `assets/curriculum/lessons.json` | 28 lessons, prerequisite chain, one letter each | ✓ VERIFIED | 28 lessons; `lesson_01` empty requires; each subsequent requires exactly the previous (zero chain violations); one letter item per lesson. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| Home card | todayLessonProvider | `_todayCardDataProvider` `ref.watch(todayLessonProvider.future)` | ✓ WIRED | `home_screen.dart:597` |
| practice controller | DB | `_recordMastery` → `progressRepo.recordMastery` → `into(letterMastery).insertOnConflictUpdate` | ✓ WIRED | `practice_providers.dart:319-336`, `app_database.dart:143` |
| DB write | progression recompute | drift `watchMasteredLetterIds()` → `masteredLetterIdsProvider` → `progressionProvider` (`ref.watch(...future)`) | ✓ WIRED | no `ref.invalidate` anywhere in the chain |
| Celebration | Next Lesson route | `_CelebrateView` reads recomputed `todayLessonProvider` → `context.go('/practice?lesson=${nextLesson.id}')` | ✓ WIRED | `practice_screen.dart:301-318` |
| Router | PracticeScreen/JourneyScreen | `?lesson=`/`?highlight=` query params + per-id `ValueKey` | ✓ WIRED | `app_router.dart:70-89` |
| Journey node | practice (only if unlocked) | tappable gate on `unlockedLessonIds`; locked → inert | ✓ WIRED | `journey_screen.dart:394-416` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| Home today-card | `todayLessonProvider` snapshot | `progressionProvider` ← `masteredLetterIdsProvider` (drift `watch`) + curriculum + active profile | Yes — live drift query over LetterMastery + lessons.json + ChildProfiles | ✓ FLOWING |
| Home ink-fill | `cleanRepsForLetterProvider(letterId)` | drift `watchCleanReps` over LetterReps | Yes — live banked count | ✓ FLOWING |
| Journey nodes | `progressionProvider.masteredLetterIds`/`unlockedLessonIds` | same live snapshot | Yes | ✓ FLOWING |
| Celebration Next Lesson | recomputed `todayLessonProvider` | post-mastery stream emission | Yes — target reflects the just-recorded mastery | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| lessons.json = 28, prerequisite chain intact | python json validation over `assets/curriculum/lessons.json` | 28 lessons; lesson_01 empty requires; each requires the previous; zero violations | ✓ PASS |
| Pure-Dart engine has no Flutter/DB imports | grep imports in `lesson_progression.dart` | only imports `models/lesson.dart` | ✓ PASS |
| Stroke points never in providers (T-03-01) | grep `List<Offset>` in `practice_providers.dart` | only in comments; no live state | ✓ PASS |
| Full test suite | `flutter test` | 351 passing, 1 failing | ✓ PASS (see Anti-Patterns) |

### Probe Execution

No `scripts/*/tests/probe-*.sh` exist for this Flutter phase; verification uses `flutter test` (the project's declared full-suite command). Not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| S1-01 | 06-01,02,03,05 | On opening the app, the child immediately sees today's lesson already prepared, with one clear way to start | ✓ SATISFIED | Truth 1 + Home today-card live data-flow + single Start |
| S1-09 | 06-01,02,03,04,06,07,08 | The next lesson unlocks only after the child passes the current one | ✓ SATISFIED | Truths 2 & 3 + recordMastery→stream→recompute chain + locked-inert journey nodes |

No orphaned requirements: REQUIREMENTS.md maps only S1-01 and S1-09 to Phase 6, and both are claimed across the plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/features/journey/journey_screen.dart` | 312 | `// TODO(03.1): dashed border for fidelity` | ℹ️ Info | Cosmetic-only debt tagged to Phase 03.1 (Level-2 locked banner border style); references the originating phase; no functional impact on any phase-6 success criterion. Not a TBD/FIXME/XXX blocker. |
| `lib/screens/practice_screen.dart` | — | Orphaned legacy `PracticeScreen` (no `lessonId`) | ℹ️ Info | Unreferenced by the router (which uses `lib/features/practice/practice_screen.dart`). Dead code, not in the wired path; no stub flows to the user. |
| `test/glyph_audit_golden_test.dart` | — | Golden mismatch (Noto Naskh contextual forms) | ℹ️ Info | The single failing test. Documented environmental font-rendering drift (project memory "golden-tests-font-drift"), not a phase-6 regression. The deliberate D-14 mastery_celebration golden was re-baked in 06-07 and passes. |

No 🛑 blocker debt markers (no `TBD`/`FIXME`/`XXX` anywhere in `lib/`).

### Human Verification Required

#### 1. Device UAT — launch-to-today's-lesson flow on a real tablet

**Test:** Fresh-launch the app on an Android tablet with a stylus. Confirm you land directly on the today's-lesson card (no navigation), tap the single Start, trace the letter for its clean-reps-to-advance count, see the celebration, tap "Next Lesson", and confirm the newly unlocked letter opens and then appears as today's lesson on returning Home.
**Expected:** The full launch → pass → unlock loop behaves as the code wires it, with real stylus capture and on-device scoring.
**Why human:** Stylus capture, real-device launch, ML-Kit-gated scoring, and unlock timing are not emulatable in `flutter_test`; this is the canonical end-of-phase gate per 06-VALIDATION.md (line 74).

### Gaps Summary

No goal-blocking gaps. All three ROADMAP success criteria are observably true in the codebase and wired end-to-end with live data: today's lesson is computed for the active child and rendered as a single-Start card with no required navigation (SC1); locked lessons are inert/visibly unavailable until their prerequisite is passed (SC2); and passing a lesson persists mastery that immediately recomputes the next lesson through drift streams with no manual invalidation, surfacing it as the celebration's "Next Lesson" and as the new today's lesson (SC3). Both phase requirements (S1-01, S1-09) are satisfied with no orphans. The automated suite is green except one documented environmental golden-font-drift failure (not a phase-6 regression). The only outstanding item is the legitimately human-gated device UAT for the real-tablet stylus loop, so the verdict is `human_needed` rather than `passed`.

---

_Verified: 2026-06-13_
_Verifier: Claude (gsd-verifier)_
