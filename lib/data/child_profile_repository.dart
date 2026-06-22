// Plan 05-02 — repository wrapper over the ChildProfiles Drift table (S1-02).
//
// SECURITY (T-05-01 / S1-03): delegates to AppDatabase, which persists ONLY
// fixed-set IDs (nicknameId/avatarId/grade) + a resolved startingLessonId +
// createdAt. No real name, no free text is ever passed in or stored, and
// profile values are never logged.
//
// Mirrors lib/data/drift_progress_repository.dart exactly: a thin class wrapping
// AppDatabase + a keepAlive Riverpod-codegen provider.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'child_profile_repository.g.dart';

/// Thin delegation layer over [AppDatabase]'s ChildProfiles accessors.
class ChildProfileRepository {
  const ChildProfileRepository(this._db);
  final AppDatabase _db;

  /// True once a child profile exists.
  Future<bool> hasProfile() => _db.hasProfile();

  /// The single child profile, or null if onboarding has not run yet.
  Future<ChildProfile?> getProfile() => _db.getProfile();

  /// Persist the single child profile from fixed-set IDs + resolved lesson.
  Future<int> create({
    required String nicknameId,
    required String avatarId,
    required String grade,
    required String startingLessonId,
  }) => _db.createProfile(
    nicknameId: nicknameId,
    avatarId: avatarId,
    grade: grade,
    startingLessonId: startingLessonId,
  );

  Future<void> update({required String nicknameId, required String avatarId}) =>
      _db.updateProfile(nicknameId: nicknameId, avatarId: avatarId);
}

/// Riverpod provider for [ChildProfileRepository] — keepAlive mirrors the
/// appDatabaseProvider / progressRepository pattern (D-11).
@Riverpod(keepAlive: true)
ChildProfileRepository childProfileRepository(Ref ref) =>
    ChildProfileRepository(ref.watch(appDatabaseProvider));
