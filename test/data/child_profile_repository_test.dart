// Plan 05-01 (Wave 0) — ChildProfile persistence tests (TDD, starts RED).
//
// INTENTIONALLY RED at Wave 0: imports
//   package:qalam/data/child_profile_repository.dart
// and references the not-yet-built ChildProfiles table + ChildProfileRepository.
// A later wave builds the Drift table, the repository, and the
// grade→startingLessonId resolver, turning this green. Do NOT add a lib/ stub.
//
// Pins the API (S1-02):
//   ChildProfileRepository(AppDatabase db)
//   Future<bool>            hasProfile()
//   Future<ChildProfile?>   getProfile()
//   Future<int>             create({nicknameId, avatarId, grade, startingLessonId})
//
// SECURITY (T-05-01): only fixed-set IDs (nicknameId/avatarId/grade) and a
// resolved startingLessonId are persisted — NO real name, NO free text (S1-03).
//
// Pattern: shared NativeDatabase.memory() executor — the same close-then-reopen
// restart simulation as test/data/progress_repository_test.dart.

// Hide the Drift query-builder matchers that collide with flutter_test's
// `isNull`/`isNotNull` expectation matchers.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/data/app_database.dart';
import 'package:qalam/data/child_profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test 1: a created profile round-trips and survives a simulated restart
  // ---------------------------------------------------------------------------
  test(
    'create persists a profile that survives a simulated restart (S1-02)',
    () async {
      // Shared in-memory executor — stays alive after db1.close() so db2 can
      // re-open it, exactly as in progress_repository_test.dart.
      final shared = DatabaseConnection(NativeDatabase.memory());

      final db1 = AppDatabase(shared.executor);
      final repo1 = ChildProfileRepository(db1);

      // No profile yet.
      expect(
        await repo1.hasProfile(),
        isFalse,
        reason: 'a fresh database has no child profile',
      );

      await repo1.create(
        nicknameId: 'nick_star',
        avatarId: 'avatar_1',
        grade: 'kg',
        startingLessonId: 'lesson_01',
      );

      // Confirm before restart.
      expect(await repo1.hasProfile(), isTrue);
      final created = await repo1.getProfile();
      expect(created, isNotNull);
      expect(created!.nicknameId, 'nick_star');
      expect(created.avatarId, 'avatar_1');
      expect(created.grade, 'kg');
      expect(created.startingLessonId, 'lesson_01');
      await repo1.update(nicknameId: 'نور', avatarId: 'avatar_6');
      final updated = await repo1.getProfile();
      expect(updated!.nicknameId, 'نور');
      expect(updated.avatarId, 'avatar_6');
      await db1.close(); // injected executor stays open (P1 contract)

      // "Restart": fresh AppDatabase over the same underlying store.
      final db2 = AppDatabase(shared.executor);
      final repo2 = ChildProfileRepository(db2);

      expect(
        await repo2.hasProfile(),
        isTrue,
        reason: 'the child profile must survive a simulated restart',
      );
      final reopened = await repo2.getProfile();
      expect(reopened, isNotNull);
      expect(
        reopened!.nicknameId,
        'نور',
        reason: 'nicknameId must survive simulated restart',
      );
      expect(reopened.avatarId, 'avatar_6');
      expect(reopened.grade, 'kg');
      expect(
        reopened.startingLessonId,
        'lesson_01',
        reason: 'resolved startingLessonId must survive (S1-02)',
      );
      await db2.close();
    },
  );

  // ---------------------------------------------------------------------------
  // Test 2: a fresh empty database reports hasProfile() == false
  // ---------------------------------------------------------------------------
  test(
    'a fresh database reports hasProfile() false until a profile is created',
    () async {
      final shared = DatabaseConnection(NativeDatabase.memory());
      final db = AppDatabase(shared.executor);
      final repo = ChildProfileRepository(db);

      expect(await repo.hasProfile(), isFalse);
      expect(await repo.getProfile(), isNull);
      await db.close();
    },
  );
}
