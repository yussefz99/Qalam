// PracticeSessionController — Phase-3 session state machine (plan 03-04).
//
// Tracks the Watch → Trace → ShowFix → Celebrate lifecycle for one lesson
// (family-keyed by lessonId String).
//
// ANTI-PATTERN 3 GUARD: this controller NEVER holds List<Offset> live stroke
// points. High-frequency point capture lives in StrokeCanvas widget State.
// Only the completed StrokeResult enters here. grep for "List<Offset>" in this
// file must return 0.
//
// SECURITY (T-03-01/T-01-05): no stroke coordinates are stored or transmitted.
// Only letterId + cleanReps are persisted (via ProgressRepository) on mastery.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/scoring/scoring_models.dart';
import '../data/curriculum_repository.dart';
import '../data/drift_progress_repository.dart';

part 'practice_providers.g.dart';

/// The phase the practice session is in at any given moment.
enum PracticePhase {
  /// The child is watching the stroke-order demonstration.
  watch,

  /// The child is tracing (stylus on canvas, waiting for a stroke result).
  trace,

  /// A stroke failed — showing the named-fix feedback panel.
  showFix,

  /// 3 clean reps completed — the mastery celebration is shown.
  celebrate,
}

/// Immutable snapshot of the practice session.
class PracticeState {
  const PracticeState({
    required this.phase,
    required this.cleanReps,
    required this.cleanRepsToAdvance,
    this.lastMistakeId,
  });

  /// Current lifecycle phase.
  final PracticePhase phase;

  /// How many clean reps the child has completed this session.
  final int cleanReps;

  /// How many clean reps are required to earn mastery (from curriculum).
  /// Sourced from Letter.cleanRepsToAdvance via curriculum JSON.
  final int cleanRepsToAdvance;

  /// The most recent failing mistake, present only in the [PracticePhase.showFix]
  /// phase. Null in all other phases.
  final MistakeId? lastMistakeId;

  PracticeState copyWith({
    PracticePhase? phase,
    int? cleanReps,
    int? cleanRepsToAdvance,
    // Use Object sentinel so callers can explicitly clear lastMistakeId to null.
    Object? lastMistakeId = _sentinel,
  }) {
    return PracticeState(
      phase: phase ?? this.phase,
      cleanReps: cleanReps ?? this.cleanReps,
      cleanRepsToAdvance: cleanRepsToAdvance ?? this.cleanRepsToAdvance,
      lastMistakeId: lastMistakeId == _sentinel
          ? this.lastMistakeId
          : lastMistakeId as MistakeId?,
    );
  }
}

// Sentinel value used by copyWith to distinguish "not provided" from null.
const Object _sentinel = Object();

/// Riverpod Notifier: session controller keyed by lessonId.
///
/// autoDispose — the session is torn down when the practice screen is popped,
/// preventing stale state if the child re-enters the same lesson.
/// family(String lessonId) — each lesson gets its own controller instance.
@riverpod
class PracticeSessionController extends _$PracticeSessionController {
  @override
  PracticeState build(String lessonId) {
    // Load the lesson to get cleanRepsToAdvance for the letter.
    // We prime state immediately with defaults and update after the async load.
    // The UI reads state.cleanRepsToAdvance so it must always be valid.
    _loadLetter(lessonId);
    return const PracticeState(
      phase: PracticePhase.watch,
      cleanReps: 0,
      cleanRepsToAdvance: 3, // sensible default; overwritten by _loadLetter
    );
  }

  /// Loads the letter for this lesson and updates cleanRepsToAdvance from
  /// curriculum data. Idempotent — safe to call multiple times.
  Future<void> _loadLetter(String lessonId) async {
    final curriculumRepo = ref.read(curriculumRepositoryProvider);
    final lesson = await curriculumRepo.getLesson(lessonId);
    if (lesson == null) return;

    // Find the first letter item in the lesson.
    final letterItem = lesson.items
        .where((item) => item.type == 'letter')
        .firstOrNull;
    if (letterItem == null) return;

    final letter = await curriculumRepo.getLetter(letterItem.ref);
    if (letter == null) return;

    // Update cleanRepsToAdvance from actual curriculum data.
    state = state.copyWith(cleanRepsToAdvance: letter.cleanRepsToAdvance);
  }

  // ---------------------------------------------------------------------------
  // Public events
  // ---------------------------------------------------------------------------

  /// Advance from Watch phase to Trace phase.
  ///
  /// Safe to call only when phase == [PracticePhase.watch].
  void advanceToTrace() {
    if (state.phase != PracticePhase.watch) return;
    state = state.copyWith(phase: PracticePhase.trace);
  }

  /// Submit a completed stroke result from the canvas.
  ///
  /// Called by the practice screen after scoring a submitted stroke.
  /// Only [StrokeResult] enters — never raw Offset points (Anti-Pattern 3).
  Future<void> onStrokeResult(StrokeResult result) async {
    if (result.passed) {
      final newReps = state.cleanReps + 1;
      if (newReps >= state.cleanRepsToAdvance) {
        // Mastery earned — persist and celebrate.
        await _recordMastery(newReps);
        state = state.copyWith(
          cleanReps: newReps,
          phase: PracticePhase.celebrate,
        );
      } else {
        // Another clean rep needed.
        state = state.copyWith(
          cleanReps: newReps,
          phase: PracticePhase.trace,
        );
      }
    } else {
      // Miss — show the named fix. cleanReps does NOT increment (D-05).
      state = state.copyWith(
        phase: PracticePhase.showFix,
        lastMistakeId: result.mistakeId ?? MistakeId.fallback,
      );
    }
  }

  /// Return from ShowFix to Trace so the child can retry the same stroke.
  void retry() {
    if (state.phase != PracticePhase.showFix) return;
    // Clear lastMistakeId and go back to trace.
    state = state.copyWith(
      phase: PracticePhase.trace,
      lastMistakeId: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _recordMastery(int cleanReps) async {
    // Derive letterId from the lesson's first letter item.
    // We look it up fresh here; the value is deterministic from lessonId.
    final curriculumRepo = ref.read(curriculumRepositoryProvider);
    final lesson = await curriculumRepo.getLesson(lessonId);
    if (lesson == null) return;

    final letterItem = lesson.items
        .where((item) => item.type == 'letter')
        .firstOrNull;
    if (letterItem == null) return;

    final progressRepo = ref.read(progressRepositoryProvider);
    await progressRepo.recordMastery(
      letterId: letterItem.ref,
      cleanReps: cleanReps,
    );
  }
}
