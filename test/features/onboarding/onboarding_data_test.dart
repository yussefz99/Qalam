// Plan 05-01 (Wave 0) — onboarding fixed-set + grade-map tests (TDD, starts RED).
//
// INTENTIONALLY RED at Wave 0: imports
//   package:qalam/features/onboarding/onboarding_data.dart
// which does not yet exist. A later wave creates the avatar set, nickname set,
// and the grade→startingLessonId resolver, turning this green. Do NOT add a stub.
//
// Pins the MECHANISM (S1-02 / S1-03 fixed sets). The actual per-grade entry
// points and the final nickname wording are the owner's mother's domain — these
// tests assert the SHAPE (every grade key present, default = 'lesson_01', 6
// avatars, 8–10 nicknames), not the pedagogy.
//
// NAMESPACE (Phase 6, Plan 06-02): startingLessonId values are LESSON ids
// ('lesson_01'), not letter ids — decided this phase, enforced here.
//
// SECURITY (T-05-02): pins the exact fixed sets so out-of-set tampering is
// detectable; only fixed-set IDs ever flow into a profile (no free text, S1-03).

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/features/onboarding/onboarding_data.dart';

void main() {
  group('gradeToStartingLessonId (S1-02)', () {
    test('maps every grade option', () {
      expect(
        gradeToStartingLessonId.keys,
        containsAll(<String>['kg', 'grade1', 'grade2', 'grade3', 'grade4plus']),
        reason: 'every selectable grade must have a starting-lesson entry',
      );
    });

    test('every grade currently resolves to the default lesson "lesson_01"',
        () {
      for (final entry in gradeToStartingLessonId.entries) {
        expect(entry.value, 'lesson_01',
            reason: 'all grades → lesson_01 until the owner specifies real '
                'per-grade entry points (D-5/S1-02); values are LESSON ids '
                '(Plan 06-02 namespace decision)');
      }
    });

    test('resolveStartingLessonId returns lesson_01 for a known grade', () {
      expect(resolveStartingLessonId('grade2'), 'lesson_01');
    });

    test('resolveStartingLessonId falls back to lesson_01 for an unknown grade',
        () {
      expect(resolveStartingLessonId('unknown'), 'lesson_01',
          reason: 'unmapped grades must default to the first lesson, never '
              'crash');
    });
  });

  group('fixed sets (S1-03)', () {
    test('there are exactly 6 avatar IDs', () {
      expect(kAvatarIds.length, 6);
    });

    test('the nickname set has between 8 and 10 entries inclusive', () {
      expect(kNicknames.length, greaterThanOrEqualTo(8));
      expect(kNicknames.length, lessThanOrEqualTo(10));
    });

    test('avatar and nickname IDs are unique', () {
      expect(kAvatarIds.toSet().length, kAvatarIds.length,
          reason: 'avatar IDs must be unique');
      final nicknameIds = kNicknames.map((n) => n.id).toList();
      expect(nicknameIds.toSet().length, nicknameIds.length,
          reason: 'nickname IDs must be unique');
    });
  });
}
