import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/features/parent/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'account database filenames are unique and do not expose Firebase UIDs',
    () {
      const accountA = 'firebase-user-a';
      const accountB = 'firebase-user-b';

      final fileA = AppDatabase.accountDatabaseFileName(accountA);
      final fileB = AppDatabase.accountDatabaseFileName(accountB);

      expect(fileA, isNot(fileB));
      expect(fileA, isNot(contains(accountA)));
      expect(fileB, isNot(contains(accountB)));
    },
  );

  test(
    'PIN, child profile, and progress are isolated between accounts',
    () async {
      final executorA = NativeDatabase.memory();
      final executorB = NativeDatabase.memory();
      addTearDown(executorA.close);
      addTearDown(executorB.close);

      final accountA = AppDatabase(executorA);
      final accountB = AppDatabase(executorB);
      final pin = PinService();

      await pin.setPin(accountA, '1234');
      final childA = await accountA.createProfile(
        nicknameId: 'nick_star',
        avatarId: 'avatar_1',
        grade: 'kg',
        startingLessonId: 'lesson_01',
      );
      await accountA.recordMastery(
          childProfileId: childA, letterId: 'alif', cleanReps: 3);

      expect(await pin.isPinSet(accountA), isTrue);
      expect(await accountA.hasProfile(), isTrue);
      expect(await accountA.isMastered('alif', childProfileId: childA), isTrue);

      expect(await pin.isPinSet(accountB), isFalse);
      expect(await accountB.hasProfile(), isFalse);
      // The other account's DB file has no rows at all — different file, D-17.
      expect(await accountB.isMastered('alif', childProfileId: childA), isFalse);
    },
  );
}
