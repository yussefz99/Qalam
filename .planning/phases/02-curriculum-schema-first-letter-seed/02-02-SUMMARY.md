---
phase: 02-curriculum-schema-first-letter-seed
plan: 02
status: complete
completed_at: "2026-05-31"
---

# Plan 02-02 Summary — Dart Domain Models

## What was built

- `lib/models/letter.dart` — pure Dart (zero Flutter imports): `Letter`, `LetterName`, `LetterForms`, `StrokeSpec`, `CommonMistake`, `AudioRef` — all with `const` constructors and `fromJson` factories. `LetterForms.final_` uses trailing underscore to avoid the `final` keyword clash.
- `lib/models/lesson.dart` — pure Dart: `Lesson`, `LessonTitle`, `LessonItem`, `LessonUnlock` — all with `const` constructors and `fromJson` factories.
- `test/models/letter_test.dart` — 5 unit tests: full-data letter, placeholder letter (empty arrays), StrokeSpec points mapping, CommonMistake fields, AudioRef nullable letter.
- `test/models/lesson_test.dart` — 3 unit tests: lesson_01 shape, LessonItem fields, LessonUnlock empty requires.

## Key decisions made

- `StrokeSpec.fromJson` casts point coordinates via `(pair[n] as num).toDouble()` rather than direct `as double` to handle JSON integers (which decode as `int`, not `double`).
- No `dart:convert` in model files — callers pass already-decoded `Map<String, dynamic>`; models are pure deserializers.
- Import rule enforced: `grep -rn "package:qalam/data" lib/models/` and `grep -rn "package:flutter/" lib/models/` both return nothing.

## Verification

- `flutter test test/models/` → 8/8 passed.
- `flutter analyze lib/models/` → no issues.
