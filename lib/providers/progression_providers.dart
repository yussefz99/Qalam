// Live progression providers — Phase 06, plan 03 (S1-01 / S1-09).
//
// The phase's reactivity spine: drift `.watch()` streams (06-02, via the
// ProgressRepository seam) feed AsyncNotifiers, and the derived Future
// providers recompute on every emission BY CONSTRUCTION — `ref.watch(masteredLetterIdsProvider.future)`
// re-executes the computation whenever the stream pushes a new mastery set.
// No caller ever needs `ref.invalidate` to see a pass reflected (S1-09
// "immediate on pass"; proven by test/providers/progression_providers_test.dart,
// which contains zero manual refresh calls).
//
// NOTE (deviation, Rule 3 — same as profile_providers.dart): these are
// HAND-WRITTEN providers, not `@riverpod` codegen. riverpod_generator 4.0.3
// throws `InvalidTypeException` for functional providers in Drift's orbit
// (Pitfall 3 policy: hand-write anything touching Drift types), and we keep
// the whole file on one style for consistency.
//
// NEVER keep-alive (Pitfall 4): a kept-alive live provider would cache a stale
// "today" across sessions/navigation. All four providers below are autoDispose
// by default — the UI keeps them alive while listening, and they rebuild fresh
// from the database streams when re-listened.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../data/drift_progress_repository.dart';
import '../models/lesson.dart';
import '../models/lesson_progression.dart';
import 'profile_providers.dart';

/// Bridges a drift `.watch()` stream into an [AsyncNotifier]: the build
/// future completes with the stream's FIRST emission, and every later
/// emission is pushed through `state`.
///
/// Why not a plain `StreamProvider`: Riverpod 3 pauses a StreamProvider's
/// subscription while it has no active listeners, which leaves a bare
/// `container.read(provider.future)` hanging forever — the drift query never
/// runs (verified against flutter_riverpod 3.3.1). An AsyncNotifier's build
/// runs to completion on first read, so `.future` resolves with or without
/// listeners, while `state = AsyncData(...)` keeps live listeners updated on
/// every subsequent database write.
Future<T> _bindDriftStream<T>(
  Ref ref,
  Stream<T> source,
  void Function(AsyncValue<T>) push,
) {
  final completer = Completer<T>();
  final sub = source.listen((value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    } else {
      push(AsyncData(value));
    }
  }, onError: (Object error, StackTrace stackTrace) {
    if (!completer.isCompleted) {
      completer.completeError(error, stackTrace);
    } else {
      push(AsyncError(error, stackTrace));
    }
  });
  ref.onDispose(sub.cancel);
  return completer.future;
}

/// Resolve the active in-file child id (ADR-018 / D-13) for the live progress
/// streams, defensively (T-05-07 degradation pattern already used by
/// [progressionProvider] below): a missing profile, a read error, OR a profile
/// read that never completes (platform-channel hang in headless test envs)
/// degrades to [kUnassignedChildProfileId] — the ribbon/unlock streams never
/// hang or error out. The `ref.watch` dependency stays live so the streams
/// re-key automatically if the profile resolves later. A LOCAL int, never a
/// wire field.
Future<int> _resolveChildProfileId(Ref ref) async {
  try {
    final profile = await ref
        .watch(childProfileProvider.future)
        .timeout(const Duration(seconds: 3));
    return profile?.id ?? kUnassignedChildProfileId;
  } catch (_) {
    return kUnassignedChildProfileId;
  }
}

class _MasteredLetterIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final childProfileId = await _resolveChildProfileId(ref);
    return _bindDriftStream(
      ref,
      // Through the ProgressRepository seam (not appDatabaseProvider
      // directly) so widget tests can fake the streams without a database.
      ref
          .watch(progressRepositoryProvider)
          .watchMasteredLetterIds(childProfileId: childProfileId),
      (value) => state = value,
    );
  }
}

/// The set of mastered letter ids, live from the LetterMastery table.
///
/// Emits the current set immediately, then a new set on every
/// `recordMastery` write — the S1-09 immediacy substrate.
final masteredLetterIdsProvider =
    AsyncNotifierProvider<_MasteredLetterIdsNotifier, Set<String>>(
  _MasteredLetterIdsNotifier.new,
);

class _CleanRepsNotifier extends AsyncNotifier<int> {
  _CleanRepsNotifier(this.letterId);

  /// The family argument — which letter's banked rep count to watch.
  final String letterId;

  @override
  Future<int> build() async {
    final childProfileId = await _resolveChildProfileId(ref);
    return _bindDriftStream(
      ref,
      // D-15 fold (19-04): the folded LetterExerciseReps MAX aggregate
      // replaces the legacy LetterReps `watchCleanReps`. Still through the
      // ProgressRepository seam (not appDatabaseProvider directly) so widget
      // tests can fake the stream without a database, and STILL via
      // `_bindDriftStream` — never a bare StreamProvider.future (Pitfall 5).
      // Re-keyed by childProfileId in 19-06 (ADR-018).
      ref
          .watch(progressRepositoryProvider)
          .watchLetterCleanReps(letterId, childProfileId: childProfileId),
      (value) => state = value,
    );
  }
}

/// The banked partial clean-rep count for one letter (D-10), live from the
/// folded LetterExerciseReps aggregate (D-15). Emits 0 while the letter has
/// never been practiced.
final cleanRepsForLetterProvider =
    AsyncNotifierProvider.family<_CleanRepsNotifier, int, String>(
  _CleanRepsNotifier.new,
);

/// The full progression snapshot for the active child: today's lesson (D-06),
/// unlocked lessons (D-02 + D-05), and the letter→lesson map.
///
/// Watching `masteredLetterIdsProvider.future` is what makes this recompute
/// on every mastery emission — the no-invalidation guarantee.
final progressionProvider = FutureProvider<ProgressionSnapshot>((ref) async {
  final mastered = await ref.watch(masteredLetterIdsProvider.future);
  final lessons = await ref.watch(curriculumRepositoryProvider).getLessons();
  final ordered = [...lessons]..sort((a, b) => a.order.compareTo(b.order));
  // Defensive on ALL branches (T-05-07 degradation pattern): a missing
  // profile, a profile-read error, OR a profile read that never completes
  // (platform-channel hang — observed in headless test envs) degrades to the
  // first lesson; never an error surface to the child. The `ref.watch`
  // dependency stays live, so if the profile resolves AFTER the timeout the
  // snapshot recomputes with the real startingLessonId automatically.
  // (D-06's "unknown startingLessonId → index 0" covers the empty-string
  // fallback.)
  String? startingLessonId;
  try {
    final profile = await ref
        .watch(childProfileProvider.future)
        .timeout(const Duration(seconds: 3));
    startingLessonId = profile?.startingLessonId;
  } catch (_) {
    startingLessonId = null;
  }
  startingLessonId ??= ordered.isEmpty ? '' : ordered.first.id;
  return ProgressionSnapshot.compute(ordered, startingLessonId, mastered);
});

/// Today's lesson for the active child — null when all mastered (D-11).
final todayLessonProvider = FutureProvider<Lesson?>(
  (ref) async => (await ref.watch(progressionProvider.future)).today,
);
