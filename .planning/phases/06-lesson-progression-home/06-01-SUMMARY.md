---
phase: 06-lesson-progression-home
plan: 01
subsystem: curriculum-domain
tags: [flutter, dart, tdd, curriculum, progression-engine, lessons]

# Dependency graph
requires:
  - phase: 02-curriculum-schema-first-letter-seed
    provides: letters.json canonical 28-letter catalog + Lesson/LessonItem/LessonUnlock models
  - phase: 02.1-stroke-reference-correction
    provides: CurriculumRepository load-time D-04 stroke guard the integrity tests coexist with
provides:
  - "28-lesson catalog (lesson_01..lesson_28) in letters.json array order with linear requires chain (D-01)"
  - "Pure-Dart progression engine: lessonPassed, lessonUnlocked, todayLesson, ProgressionSnapshot.compute (D-02/D-03/D-05/D-06/D-11)"
  - "defaultToleranceRamp file-level data + Lesson.toleranceRamp optional override parsing (D-19)"
  - "CurriculumRepository.getDefaultToleranceRamp() with decided-default fallback"
  - "Pitfall-10 integrity gate: shipped lessons.json refs/requires/orders validated on every suite run (T-06-05)"
affects: [06-02 providers, 06-03 home, 06-04 practice-ramp, 06-05 celebration, 06-06 journey]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave-0 RED contract: progression test file committed before the engine existed (app_database_test.dart idiom)"
    - "Models purity: lesson_progression.dart imports only lesson.dart — no Flutter, no dart:ui, no data/features layers"
    - "Shipped-asset integrity test: File(...).readAsStringSync() both assets into CurriculumRepository.fromStrings"
    - "Defensive data parse: absent/malformed toleranceRamp -> null (lesson) / decided default (repository), never throw"

key-files:
  created:
    - test/models/lesson_progression_test.dart
    - lib/models/lesson_progression.dart
  modified:
    - assets/curriculum/lessons.json
    - lib/models/lesson.dart
    - lib/data/curriculum_repository.dart
    - test/data/curriculum_repository_test.dart
    - test/models/lesson_test.dart

key-decisions:
  - "lessons.json generated programmatically from letters.json (id + name.display) so canonical IDs cannot drift (Pitfall 1)"
  - "Lesson titles use 'Lesson N — {Display}' placeholder wording (content, not code — owner's mother can edit)"
  - "lessonUnlocked treats an unresolvable requires[] entry as locked (defensive), proven by a dedicated test"
  - "ProgressionSnapshot returns unmodifiable sets/maps — immutable snapshot mirroring JourneyProgress conventions"

patterns-established:
  - "Progression semantics live ONLY in lib/models/lesson_progression.dart; later plans are pure wiring"
  - "D-05 encoded as index < startIndex -> unlocked, inside ProgressionSnapshot.compute (not in lessonUnlocked)"

requirements-completed: []

# Metrics
duration: ~25 min
completed: 2026-06-11
---

# Phase 06 Plan 01: Lesson Catalog & Progression Engine Summary

**28-lesson catalog with linear requires chain plus a pure-Dart engine answering passed/unlocked/today per D-02/D-03/D-05/D-06/D-11, built test-first against a Wave-0 RED contract.**

## What was built

- `test/models/lesson_progression_test.dart` — 23-test Wave-0 contract written and committed RED (engine import missing), covering: D-02 generic + multi-prerequisite unlock, allItemsPassed over letter items (non-letter items ignored), D-03 signedOff-never-an-input, D-05 skipped-but-unlocked with explicit requires[]-override proof, D-06 today rule including unknown-startingLessonId fallback to index 0, D-11 all-mastered (including start-offset variant), and the full ProgressionSnapshot shape (unlockedLessonIds, lessonIdByLetterId, masteredLetterIds echo, allMastered).
- `assets/curriculum/lessons.json` — lesson_01..lesson_28 (zero-padded), order 1..28, one per letter in the EXACT letters.json array order (alif → yaa, canonical IDs incl. haa_c/taa_h/zhaa/haa_f), each requiring the previous lesson (lesson_01 empty requires), plus file-level `"defaultToleranceRamp": ["loose", "normal", "strict"]` (D-19).
- `lib/models/lesson.dart` — optional `List<String>? toleranceRamp` parsed defensively (absent/malformed → null, never throw).
- `lib/data/curriculum_repository.dart` — parses file-level defaultToleranceRamp in `_ensureLoaded`; new `getDefaultToleranceRamp()` defaults to `['loose','normal','strict']` when absent (consumed by plan 06-04).
- `test/data/curriculum_repository_test.dart` — Pitfall-10 integrity gate over the SHIPPED assets: exactly 28 lessons; every items[].ref resolves against letters.json; every requires[] resolves against lesson IDs; orders exactly 1..28 with no duplicates; unique lesson IDs; lesson_01 empty-requires + ref alif; ramp parse + fallback.
- `lib/models/lesson_progression.dart` — the pure-Dart engine (120 lines): `lessonPassed`, `lessonUnlocked`, `todayLesson`, `ProgressionSnapshot.compute`. No Flutter/dart:ui/data/features imports; the string "signedOff" appears nowhere in the file (D-03 compile-level guarantee).

## TDD Gate Compliance

- RED: `2a4d458 test(06-01)` — contract committed failing on the missing engine import only.
- GREEN: `a1ff1a1 feat(06-01)` — engine implemented to the unmodified contract; 23/23 pass, zero skips. Test expectations were not weakened.
- REFACTOR: not needed — implementation landed clean on first green (one pre-commit comment reword, see below).

## Verification

- `flutter test test/models/lesson_progression_test.dart test/data/curriculum_repository_test.dart test/models/lesson_test.dart` — 46/46 green.
- `flutter analyze lib/models/lesson_progression.dart lib/models/lesson.dart lib/data/curriculum_repository.dart` — no issues.
- Purity gates: `grep -cE "import 'package:flutter|import 'dart:ui|lib/data/|lib/features/"` → 0; `grep -c "signedOff"` → 0 on the engine file.
- `python3` JSON assert: 28 lessons, defaultToleranceRamp == ['loose','normal','strict'] — exits 0.
- Full suite: 289 passed, 4 failed — exactly the documented pre-existing set, not grown: glyph_audit + mastery_celebration golden font drift (environmental) and stale Phase 03.1 debt (home_screen "Coming soon" nav test, mastery_celebration "no See Journey button" test — both reconciled by later Phase 6 plans).

## Deviations from Plan

None - plan executed exactly as written. (One within-task adjustment during Task 3 verification, before commit: the engine's header comment originally contained the literal strings "lib/data/"/"lib/features/", tripping the acceptance grep; reworded the comment. No semantic change.)

## Known Stubs

- Lesson titles ("Lesson N — {Display}") are placeholder wording by design — content the owner's mother edits, explicitly sanctioned by the plan (CONTEXT discretion; content not code). No code stubs: the catalog and engine are fully wired and consumed by plans 06-02..06-06.

## Self-Check: PASSED

- test/models/lesson_progression_test.dart — FOUND
- lib/models/lesson_progression.dart — FOUND
- assets/curriculum/lessons.json (lesson_28 present) — FOUND
- Commits 2a4d458, 7bb2334, a1ff1a1 — FOUND
