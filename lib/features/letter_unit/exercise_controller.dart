// ExerciseController — the idle→think→pass|fix state machine for the Letter-Unit
// exercise engine (Plan 07-04). Riverpod-only (CLAUDE.md Decided: Riverpod, never
// BLoC/GetX). Mirrors the prototype's `tutorAndFeedback(pose, html, tone)`
// (components.js): a validator result drives the mascot POSE, the speech TONE,
// the FeedbackPanel state, and the resolved authored line.
//
// The controller holds NO child strokes — only the derived verdict. The strokes
// live in the WriteSurface's StrokeCanvas State and are scored + discarded there
// (T-07-04-01). What flows here is a CheckResult (a bool + an authored key).
//
// FEEDBACK RESOLUTION (T-07-04-02): the displayed line ALWAYS comes from the
// exercise's authored `feedback` map — `feedback['pass']` on a pass,
// `feedback[mistakeId]` on a miss — never raw scorer text.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exercise_engine/check_result.dart';
import '../../models/exercise.dart';
import '../../widgets/qalam_mascot.dart';

/// The feedback "tone" the prototype switches on (components.js): `coral` → a
/// miss (try-again), `leaf` → a pass (cheer), `neutral` → idle/thinking.
enum ExerciseTone { neutral, coral, leaf }

/// Which exercise phase the UI is in.
enum ExercisePhase {
  /// Before the child finishes writing — the prompt/hint is shown.
  idle,

  /// The validator is running (the brief "thinking" beat).
  think,

  /// The attempt passed — one star + praise.
  pass,

  /// The attempt missed — the specific authored fix.
  fix,
}

/// The immutable controller state: the phase, the mascot pose, the tone, the
/// resolved line, and the clean-rep progress toward the exercise's `policy.reps`.
class ExerciseState {
  const ExerciseState({
    required this.phase,
    required this.pose,
    required this.tone,
    required this.line,
    required this.cleanReps,
    required this.repsRequired,
  });

  final ExercisePhase phase;
  final QalamPose pose;
  final ExerciseTone tone;

  /// The resolved tutor line (empty in idle; praise on pass; the fix on a miss).
  final String line;

  /// How many clean reps the child has completed this exercise.
  final int cleanReps;

  /// How many clean reps `policy.reps` requires (defaults to 1).
  final int repsRequired;

  /// True once the child has met the rep policy on a pass (the section may
  /// advance). On a multi-rep exercise an interim clean rep stays in [pass] but
  /// [advanceReady] is false until the last rep.
  bool get advanceReady => phase == ExercisePhase.pass && cleanReps >= repsRequired;

  ExerciseState copyWith({
    ExercisePhase? phase,
    QalamPose? pose,
    ExerciseTone? tone,
    String? line,
    int? cleanReps,
    int? repsRequired,
  }) {
    return ExerciseState(
      phase: phase ?? this.phase,
      pose: pose ?? this.pose,
      tone: tone ?? this.tone,
      line: line ?? this.line,
      cleanReps: cleanReps ?? this.cleanReps,
      repsRequired: repsRequired ?? this.repsRequired,
    );
  }

  static const ExerciseState initial = ExerciseState(
    phase: ExercisePhase.idle,
    pose: QalamPose.idle,
    tone: ExerciseTone.neutral,
    line: '',
    cleanReps: 0,
    repsRequired: 1,
  );
}

/// Drives one exercise's idle→think→pass|fix lifecycle. Construct per exercise
/// via [load]; feed it a [CheckResult] via [applyResult].
class ExerciseController extends Notifier<ExerciseState> {
  Exercise? _exercise;

  @override
  ExerciseState build() => ExerciseState.initial;

  /// Resets to the prompt/idle state for [exercise]. A teachCard (no surface /
  /// no check) has nothing to grade — it simply rests in [ExercisePhase.idle].
  void load(Exercise exercise) {
    _exercise = exercise;
    state = ExerciseState.initial.copyWith(
      repsRequired: (exercise.policy?.reps ?? 1).clamp(1, 99),
    );
  }

  /// The brief thinking beat while the validator runs (the prototype's
  /// `think` mascot). The UI calls this on stylus-up, then [applyResult].
  void think() {
    state = state.copyWith(
      phase: ExercisePhase.think,
      pose: QalamPose.think,
      tone: ExerciseTone.neutral,
      line: '',
    );
  }

  /// Applies a validator [result], resolving the AUTHORED line and the mascot
  /// pose + tone — exactly like the prototype's `tutorAndFeedback`:
  ///   • pass → leaf  → cheer + `feedback['pass']`; increments the clean-rep count.
  ///   • fail → coral → tryAgain + `feedback[mistakeId]`.
  void applyResult(CheckResult result) {
    final fb = _exercise?.feedback ?? const <String, String>{};
    if (result.passed) {
      final reps = state.cleanReps + 1;
      state = state.copyWith(
        phase: ExercisePhase.pass,
        pose: QalamPose.cheer,
        tone: ExerciseTone.leaf,
        line: fb['pass'] ?? '',
        cleanReps: reps,
      );
    } else {
      final id = result.mistakeId;
      state = state.copyWith(
        phase: ExercisePhase.fix,
        pose: QalamPose.tryAgain,
        tone: ExerciseTone.coral,
        line: (id != null ? fb[id] : null) ?? _firstMiss(fb),
      );
    }
  }

  /// Phase 17.1 (owner directive): the AI image-judge OVERRULED the scorer's FAIL
  /// and passed the attempt. Promote the current state to a pass — cheer pose, leaf
  /// tone, the AI's celebration [line], and increment the clean-rep count exactly
  /// like a scorer pass. Used ONLY when the scorer failed but the AI (judging the
  /// rendered letter on its own expertise) found it correct — fixing the scorer's
  /// false negatives on real handwriting. The AI never DOWNGRADES a scorer pass.
  void upgradeToPass(String line) {
    final fb = _exercise?.feedback ?? const <String, String>{};
    final reps = state.cleanReps + 1;
    state = state.copyWith(
      phase: ExercisePhase.pass,
      pose: QalamPose.cheer,
      tone: ExerciseTone.leaf,
      line: line.isNotEmpty ? line : (fb['pass'] ?? ''),
      cleanReps: reps,
    );
  }

  /// Returns to the prompt/idle state (the "Clear"/"Try again" CTA). The
  /// clean-rep count is preserved (a retry of the same rep, not a reset).
  void reset() {
    state = state.copyWith(
      phase: ExercisePhase.idle,
      pose: QalamPose.idle,
      tone: ExerciseTone.neutral,
      line: '',
    );
  }

  /// The first non-`pass` authored line, so a miss with an unmatched id still
  /// shows AUTHORED copy (never raw scorer text). Empty if none authored.
  String _firstMiss(Map<String, String> fb) {
    for (final entry in fb.entries) {
      if (entry.key != 'pass') return entry.value;
    }
    return '';
  }
}

/// The provider the section screens (07-05/07-06) read. `.notifier` exposes
/// [ExerciseController.load]/[ExerciseController.applyResult].
final exerciseControllerProvider =
    NotifierProvider<ExerciseController, ExerciseState>(ExerciseController.new);
