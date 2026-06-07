// JourneyProgress model + JourneyNodeState enum (Phase 03.1, plan 01).
//
// Pure-Dart file — no Flutter import. Follows the plain-class pattern from
// lib/models/letter.dart (final fields, const constructor, no dart:ui).
//
// JourneyNodeState represents the four visual states of a letter node on the
// Journey Map screen:
//   complete — child has mastered this letter (3+ clean reps)
//   current  — this is the letter the child is working on now
//   future   — letter not yet reached
//   locked   — reserved for edge cases; used only when letterId is empty

/// Four visual states a journey map node can have.
enum JourneyNodeState {
  complete,
  current,
  future,
  locked;

  /// Compute the node state for [letterId] given the current progress snapshot.
  ///
  /// Rules:
  ///   - Empty [letterId] → [locked] (defensive edge guard).
  ///   - [letterId] in [masteredIds] → [complete].
  ///   - [letterId] == [currentId] → [current].
  ///   - Otherwise → [future].
  static JourneyNodeState compute(
    String letterId,
    Set<String> masteredIds,
    String currentId,
  ) {
    if (letterId.isEmpty) return JourneyNodeState.locked;
    if (masteredIds.contains(letterId)) return JourneyNodeState.complete;
    if (letterId == currentId) return JourneyNodeState.current;
    return JourneyNodeState.future;
  }
}

/// Immutable snapshot of a child's journey progress.
///
/// [masteredIds] — set of letter IDs the child has fully mastered.
/// [currentId]   — the letter the child is currently working on.
///
/// Use [JourneyProgress.empty()] for the initial / unauthenticated state.
class JourneyProgress {
  final Set<String> masteredIds;
  final String currentId;

  const JourneyProgress({
    required this.masteredIds,
    required this.currentId,
  });

  factory JourneyProgress.empty() =>
      const JourneyProgress(masteredIds: {}, currentId: '');
}
