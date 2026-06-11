// Lesson progression engine (Phase 06, plan 01).
//
// Pure-Dart file — no Flutter import, nothing from the data or features
// layers (models-purity convention from journey_progress.dart).
//
// Encodes the decided progression semantics:
//   D-02 — generic unlock: a lesson is unlocked iff every lesson listed in
//          unlock.requires[] is passed; empty requires[] = unlocked.
//   D-03 — draft status is never consulted: mastery alone decides pass/unlock,
//          so the API takes only lessons + the mastered-letter set.
//   D-05 — lessons earlier than startingLessonId are skipped-but-unlocked,
//          regardless of their requires[].
//   D-06 — today = first non-passed lesson AT OR AFTER startingLessonId;
//          unknown startingLessonId is defensively treated as index 0.
//   D-11 — today is null when every lesson at/after the start is passed
//          (the all-mastered state).

import 'package:qalam/models/lesson.dart';

/// passRule "allItemsPassed": every items[] entry of type 'letter' has its
/// ref in [masteredLetterIds]. Non-letter items (e.g. exercises) are ignored.
bool lessonPassed(Lesson lesson, Set<String> masteredLetterIds) => lesson.items
    .where((i) => i.type == 'letter')
    .every((i) => masteredLetterIds.contains(i.ref));

/// D-02: a lesson is unlocked iff every lesson in unlock.requires[] is passed.
/// Empty requires[] = unlocked. A requires[] entry that resolves to no lesson
/// in [lessonsById] keeps the lesson locked (defensive).
bool lessonUnlocked(
  Lesson lesson,
  Map<String, Lesson> lessonsById,
  Set<String> masteredLetterIds,
) =>
    lesson.unlock.requires.every((id) {
      final required = lessonsById[id];
      return required != null && lessonPassed(required, masteredLetterIds);
    });

/// D-06: the first non-passed lesson AT OR AFTER [startingLessonId] in
/// [ordered] (lessons sorted by order). Unknown [startingLessonId] is
/// defensively treated as index 0. Returns null when every lesson at/after
/// the start is passed (D-11).
Lesson? todayLesson(
  List<Lesson> ordered,
  String startingLessonId,
  Set<String> masteredLetterIds,
) {
  final startIndex = ordered.indexWhere((l) => l.id == startingLessonId);
  final from = startIndex < 0 ? 0 : startIndex;
  for (final lesson in ordered.skip(from)) {
    if (!lessonPassed(lesson, masteredLetterIds)) return lesson;
  }
  return null;
}

/// Immutable snapshot of a child's lesson progression — the single computed
/// answer consumed by Home, Journey, and the celebration flow.
///
/// [today]              — the lesson to practice now; null = all mastered (D-11).
/// [masteredLetterIds]  — the input mastery set, echoed for consumers.
/// [unlockedLessonIds]  — every lesson id the child may open (D-02 + D-05).
/// [lessonIdByLetterId] — letter id → owning lesson id (Journey taps, 06-06).
/// [allMastered]        — true iff [today] is null.
class ProgressionSnapshot {
  final Lesson? today;
  final Set<String> masteredLetterIds;
  final Set<String> unlockedLessonIds;
  final Map<String, String> lessonIdByLetterId;
  final bool allMastered;

  const ProgressionSnapshot({
    required this.today,
    required this.masteredLetterIds,
    required this.unlockedLessonIds,
    required this.lessonIdByLetterId,
    required this.allMastered,
  });

  /// Compute the full snapshot for [ordered] lessons given the child's
  /// [startingLessonId] and [masteredLetterIds].
  ///
  /// D-05 is encoded here explicitly: a lesson whose index is before the
  /// start index is unlocked regardless of its requires[] chain.
  static ProgressionSnapshot compute(
    List<Lesson> ordered,
    String startingLessonId,
    Set<String> masteredLetterIds,
  ) {
    final lessonsById = {for (final l in ordered) l.id: l};

    final startIndex = ordered.indexWhere((l) => l.id == startingLessonId);
    final from = startIndex < 0 ? 0 : startIndex; // unknown id → index 0

    final unlocked = <String>{};
    for (var i = 0; i < ordered.length; i++) {
      final lesson = ordered[i];
      final skippedBeforeStart = i < from; // D-05: forced unlocked
      if (skippedBeforeStart ||
          lessonUnlocked(lesson, lessonsById, masteredLetterIds)) {
        unlocked.add(lesson.id);
      }
    }

    final lessonIdByLetterId = <String, String>{
      for (final lesson in ordered)
        for (final item in lesson.items)
          if (item.type == 'letter') item.ref: lesson.id,
    };

    final today = todayLesson(ordered, startingLessonId, masteredLetterIds);

    return ProgressionSnapshot(
      today: today,
      masteredLetterIds: Set.unmodifiable(masteredLetterIds),
      unlockedLessonIds: Set.unmodifiable(unlocked),
      lessonIdByLetterId: Map.unmodifiable(lessonIdByLetterId),
      allMastered: today == null,
    );
  }
}
