// Plan 05-01 (Wave 0) — onboarding fixed-set + grade-map tests (TDD, starts RED).
//
// INTENTIONALLY RED at Wave 0: imports
//   package:qalam/features/onboarding/onboarding_data.dart
// which does not yet exist. A later wave creates the avatar set, nickname set,
// and the grade→startingLessonId resolver, turning this green. Do NOT add a stub.
//
// Pins the MECHANISM (S1-02 / S1-03 fixed sets). The actual per-grade entry
// points and the final nickname wording are the owner's mother's domain — these
// tests assert the SHAPE (every grade key present, default = 'alif', 6 avatars,
// 8–10 nicknames), not the pedagogy.
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

    test('every grade currently resolves to the Phase-5 default "alif"', () {
      for (final entry in gradeToStartingLessonId.entries) {
        expect(entry.value, 'alif',
            reason: 'Phase 5 ships all grades → alif until the owner specifies '
                'real per-grade entry points (D-5/S1-02)');
      }
    });

    test('resolveStartingLessonId returns alif for a known grade', () {
      expect(resolveStartingLessonId('grade2'), 'alif');
    });

    test('resolveStartingLessonId falls back to alif for an unknown grade', () {
      expect(resolveStartingLessonId('unknown'), 'alif',
          reason: 'unmapped grades must default to alif, never crash');
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
