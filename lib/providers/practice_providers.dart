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

import 'dart:math' as math;

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

  /// A stroke passed but mastery isn't reached yet — showing the warm
  /// per-rep praise panel. The child taps "Keep going" to trace again.
  showPraise,

  /// A stroke failed — showing the named-fix feedback panel.
  showFix,

  /// Required clean reps completed in a row — the mastery celebration is shown.
  celebrate,
}

/// Immutable snapshot of the practice session.
class PracticeState {
  const PracticeState({
    required this.phase,
    required this.cleanReps,
    required this.cleanRepsToAdvance,
    this.tolerancePreset = 'normal',
    this.lastMistakeId,
  });

  /// Current lifecycle phase.
  final PracticePhase phase;

  /// How many clean reps the child has completed this session.
  final int cleanReps;

  /// How many clean reps are required to earn mastery (from curriculum).
  /// Sourced from Letter.cleanRepsToAdvance via curriculum JSON.
  final int cleanRepsToAdvance;

  /// The tolerance-ramp preset name the CURRENT rep scores at (D-18/D-20):
  /// `ramp[min(cleanReps, ramp.length - 1)]`, recomputed whenever [cleanReps]
  /// changes. The index is the PERSISTED rep count, not the sitting — a child
  /// resuming at rep 2 scores at rep 2's preset. Defaults to 'normal' (the
  /// Phase-4 behavior-preserving anchor) until the lesson's ramp resolves.
  /// NEVER shown to the child (UI-SPEC: invisible scaffolding — no
  /// loose/strict labels anywhere).
  final String tolerancePreset;

  /// The most recent failing mistake, present only in the [PracticePhase.showFix]
  /// phase. Null in all other phases.
  final MistakeId? lastMistakeId;

  PracticeState copyWith({
    PracticePhase? phase,
    int? cleanReps,
    int? cleanRepsToAdvance,
    String? tolerancePreset,
    // Use Object sentinel so callers can explicitly clear lastMistakeId to null.
    Object? lastMistakeId = _sentinel,
  }) {
    return PracticeState(
      phase: phase ?? this.phase,
      cleanReps: cleanReps ?? this.cleanReps,
      cleanRepsToAdvance: cleanRepsToAdvance ?? this.cleanRepsToAdvance,
      tolerancePreset: tolerancePreset ?? this.tolerancePreset,
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
  /// The resolved tolerance ramp for this lesson (D-19): the per-lesson
  /// `toleranceRamp` override when present, else the file-level
  /// `defaultToleranceRamp` from lessons.json. Null until [_loadLetter]
  /// resolves it — [_presetFor] degrades to 'normal' (the Phase-4 anchor).
  List<String>? _ramp;

  /// The lesson's letter id, cached by [_loadLetter] for the per-rep
  /// write-through (D-10). Only this id and an int count ever reach storage —
  /// never stroke data (T-06-01).
  String? _letterId;

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

  /// Loads the letter for this lesson, updates cleanRepsToAdvance from
  /// curriculum data, resolves the tolerance ramp (D-19), and primes the
  /// session's rep count from the persisted LetterReps row (D-20) so a
  /// resumed session scores at the rep index the child actually reached.
  /// Idempotent — safe to call multiple times.
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

    _letterId = letterItem.ref;

    // D-19: the ramp is DATA — per-lesson override, else the lessons.json
    // file-level default. An empty override is treated as absent (defensive,
    // T-06-07: the owner's mother edits this by hand).
    final lessonRamp = lesson.toleranceRamp;
    _ramp = (lessonRamp != null && lessonRamp.isNotEmpty)
        ? lessonRamp
        : await curriculumRepo.getDefaultToleranceRamp();

    // D-20: prime the rep count from the persisted row — best-effort, a
    // storage failure degrades to 0 and never blocks the session. D-15 fold
    // (19-04): reads the folded LetterExerciseReps aggregate, not the legacy
    // LetterReps `getCleanReps`.
    var persisted = 0;
    try {
      persisted = await ref
          .read(progressRepositoryProvider)
          .letterCleanReps(_letterId!);
    } catch (_) {
      // Swallow — start the sitting at 0.
    }

    // Riverpod 3 throws on touching `state` after dispose — an unlistened
    // autoDispose provider can be torn down while the awaits above resolve.
    if (!ref.mounted) return;

    // Update cleanRepsToAdvance from actual curriculum data and seed the
    // persisted rep index + its ramp preset.
    state = state.copyWith(
      cleanRepsToAdvance: letter.cleanRepsToAdvance,
      cleanReps: persisted,
      tolerancePreset: _presetFor(persisted),
    );
  }

  /// The ramp preset name for [cleanReps] (D-18): index = the persisted rep
  /// count, clamped to the last ramp entry. 'normal' until the ramp resolves.
  String _presetFor(int cleanReps) {
    final ramp = _ramp;
    if (ramp == null || ramp.isEmpty) return 'normal';
    return ramp[math.min(cleanReps, ramp.length - 1)];
  }

  /// Best-effort write-through of the banked clean-rep count (D-10),
  /// including the explicit reset to 0 on a miss (Pitfall 7). Mirrors the
  /// [_recordMastery] try/swallow: a storage failure must never interrupt
  /// the session. SECURITY: only letterId + an int count leave here (T-06-01).
  ///
  /// D-15 fold (19-04): the write-through now targets the folded
  /// LetterExerciseReps table via [ProgressRepository.setLetterCleanReps]
  /// (a single synthetic per-letter row) — LetterReps is off the live write
  /// path so 19-06 can drop it.
  Future<void> _persistCleanReps(int cleanReps) async {
    final letterId = _letterId;
    if (letterId == null) return; // load not finished — nothing to address
    try {
      await ref
          .read(progressRepositoryProvider)
          .setLetterCleanReps(letterId: letterId, cleanReps: cleanReps);
    } catch (_) {
      // Swallow — the in-memory session continues.
    }
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

  /// Submit a whole-letter result from the canvas (Plan 04-04).
  ///
  /// Called by the practice screen after `scoreLetter` evaluates the whole
  /// accumulated multi-stroke letter (count → order → shape → dot → advisory ML
  /// Kit identity). A clean letter is a clean rep; any miss (count/order/shape/
  /// dot/identity) resets the streak and shows the named fix — the same warm
  /// coaching beat as a single-stroke miss. Only [LetterResult] enters — never
  /// raw Offset points (Anti-Pattern 3 / T-04-08).
  Future<void> onLetterResult(LetterResult result) async {
    if (result.passed) {
      await _registerCleanRep();
    } else {
      // Whole-letter miss — reset the streak and surface the named fix.
      await _registerMiss(result.mistakeId);
    }
  }

  /// Records one clean rep and advances to praise or mastery accordingly.
  /// Shared by the whole-letter and (legacy) per-stroke pass paths.
  Future<void> _registerCleanRep() async {
    final newReps = state.cleanReps + 1;
    // D-10: write the new count through to the folded LetterExerciseReps
    // aggregate on EVERY change (best-effort — never blocks the session).
    await _persistCleanReps(newReps);
    if (!ref.mounted) return; // disposed mid-await (Riverpod 3)
    if (newReps >= state.cleanRepsToAdvance) {
      // Mastery earned — required clean reps achieved IN A ROW. DB write is
      // best-effort: a storage failure must not block the celebration.
      try {
        await _recordMastery(newReps);
      } catch (_) {
        // Swallow — celebrate regardless.
      }
      if (!ref.mounted) return; // disposed mid-await (Riverpod 3)
      state = state.copyWith(
        cleanReps: newReps,
        tolerancePreset: _presetFor(newReps),
        phase: PracticePhase.celebrate,
      );
    } else {
      // Clean rep, not mastery yet — show warm per-rep praise.
      state = state.copyWith(
        cleanReps: newReps,
        tolerancePreset: _presetFor(newReps),
        phase: PracticePhase.showPraise,
      );
    }
  }

  /// Records a miss: resets the streak to 0 IN STATE AND IN STORAGE
  /// (D-10 / Pitfall 7 — the reset is an explicit write of 0, not a skipped
  /// write) and surfaces the named fix. Shipped default: the banked count
  /// resets across sittings too — whether a fresh sitting should soften this
  /// is the owner's mother's call (flagged in the 06-04 SUMMARY).
  Future<void> _registerMiss(MistakeId? mistakeId) async {
    await _persistCleanReps(0);
    if (!ref.mounted) return; // disposed mid-await (Riverpod 3)
    state = state.copyWith(
      cleanReps: 0,
      tolerancePreset: _presetFor(0),
      phase: PracticePhase.showFix,
      lastMistakeId: mistakeId ?? MistakeId.fallback,
    );
  }

  /// Submit a completed stroke result from the canvas.
  ///
  /// Called by the practice screen after scoring a submitted stroke.
  /// Only [StrokeResult] enters — never raw Offset points (Anti-Pattern 3).
  Future<void> onStrokeResult(StrokeResult result) async {
    if (result.passed) {
      // Same pass path as the whole-letter flow — praise/mastery + the D-10
      // write-through live in one place.
      await _registerCleanRep();
    } else {
      // Miss — reset the streak to 0 (mastery requires N clean reps IN A ROW),
      // persist the reset (D-10), and show the named fix.
      await _registerMiss(result.mistakeId);
    }
  }

  /// Return from ShowPraise to Trace so the child traces the next clean rep.
  void continueAfterPraise() {
    if (state.phase != PracticePhase.showPraise) return;
    state = state.copyWith(phase: PracticePhase.trace);
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
