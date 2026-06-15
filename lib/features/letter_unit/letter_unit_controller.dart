// LetterUnitController — the section-sequencing + resume state machine for the
// baa Letter Unit shell (Plan 07-06). Riverpod-only (CLAUDE.md Decided:
// Riverpod, never BLoC/GetX). Mirrors the prototype's `go(n)` + the `visited`
// set + `cur` index (unit.js): it holds WHICH section the child is on, the set
// of sections they have VISITED (for the R→L ribbon's done/active dots), and
// advances forward through the 6 ordered sections.
//
// RESUME-AWARE: the controller is keyed per letterId and KEEP-ALIVE for the app
// lifetime, so exiting the unit and re-entering returns to the section the child
// left off on (the prototype's "Your place is saved"). The per-letter resume
// index is held in-memory across navigations; durable cross-session persistence
// can layer on later via the ProgressRepository seam without changing this API.
//
// MASTERY WRITE (T-07-06-02): reaching the Mastery section records the letter
// mastered through the EXISTING ProgressRepository seam — a LOCAL Drift write
// only (no child data leaves the device). The write is idempotent (recordMastery
// overwrites), so re-entering Mastery never double-counts anything.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/drift_progress_repository.dart';

/// The immutable unit state: the section [index] within the [total] sections,
/// and the set of [visited] section indices (for the ribbon's done dots).
class LetterUnitState {
  const LetterUnitState({
    required this.index,
    required this.total,
    required this.visited,
  });

  /// The current section index (0-based; 0 = Meet … total-1 = Mastery).
  final int index;

  /// How many sections this unit has (baa = 6).
  final int total;

  /// Every section index the child has visited this unit (resume + ribbon).
  final Set<int> visited;

  /// True when the child is on the final (Mastery) section.
  bool get atMastery => total > 0 && index == total - 1;

  LetterUnitState copyWith({int? index, int? total, Set<int>? visited}) {
    return LetterUnitState(
      index: index ?? this.index,
      total: total ?? this.total,
      visited: visited ?? this.visited,
    );
  }

  static const LetterUnitState empty =
      LetterUnitState(index: 0, total: 0, visited: {0});
}

/// Drives one letter unit's section sequencing + resume. Construct per letterId
/// via the [letterUnitControllerProvider] family (the family arg is the
/// letterId); call [start] once the section order is known, then [goTo] /
/// [advance] / [back] to navigate.
class LetterUnitController extends Notifier<LetterUnitState> {
  /// The family argument — which letter's unit this controller drives. Used as
  /// the default letterId so [start]'s argument is optional in practice.
  LetterUnitController(this._argLetterId);

  final String _argLetterId;

  /// The keep-alive resume store: the last section index per letterId, held for
  /// the app lifetime so re-entering a unit resumes where the child left off.
  static final Map<String, int> _resumeByLetter = <String, int>{};

  late String _letterId = _argLetterId;
  bool _masteryRecorded = false;

  @override
  LetterUnitState build() => LetterUnitState.empty;

  /// Initialise the controller for [letterId] with [total] sections. Resumes at
  /// [resumeSection] if given, else at the persisted resume index, else 0.
  void start({
    required String letterId,
    required int total,
    int? resumeSection,
  }) {
    _letterId = letterId;
    _masteryRecorded = false;
    final saved = _resumeByLetter[letterId];
    final start = (resumeSection ?? saved ?? 0).clamp(0, total > 0 ? total - 1 : 0);
    final visited = <int>{for (var i = 0; i <= start; i++) i};
    state = LetterUnitState(index: start, total: total, visited: visited);
    _onEnterSection(start);
  }

  /// Jump to section [n] (clamped). Marks it visited + persists the resume spot.
  void goTo(int n) {
    final total = state.total;
    if (total <= 0) return;
    final next = n.clamp(0, total - 1);
    final visited = {...state.visited, next};
    state = state.copyWith(index: next, visited: visited);
    _onEnterSection(next);
  }

  /// Advance to the next section (the section's onAdvance / a clean pass).
  void advance() => goTo(state.index + 1);

  /// Step back one section (the app bar back button). Never below 0.
  void back() => goTo(state.index - 1);

  void _onEnterSection(int index) {
    // Persist the resume position so re-entry resumes here.
    _resumeByLetter[_letterId] = index;
    // Reaching Mastery records the letter mastered (LOCAL Drift only).
    if (state.atMastery) _recordMastery();
  }

  Future<void> _recordMastery() async {
    if (_masteryRecorded) return;
    _masteryRecorded = true;
    try {
      await ref.read(progressRepositoryProvider).recordMastery(
            letterId: _letterId,
            cleanReps: 0,
          );
    } catch (_) {
      // A failed local write must never crash the celebration — the child
      // still sees their star; the mastery row can be re-recorded on re-entry.
      _masteryRecorded = false;
    }
  }
}

/// The per-letter unit controller (keep-alive so resume survives navigation).
/// Read `.notifier` to call [LetterUnitController.start] / advance / back.
final letterUnitControllerProvider =
    NotifierProvider.family<LetterUnitController, LetterUnitState, String>(
  LetterUnitController.new,
);
