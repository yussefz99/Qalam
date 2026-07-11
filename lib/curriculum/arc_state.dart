/// Pure Dart. No cloud-AI / Firebase / network / Flutter-render / drift / riverpod
/// import — this is part of the OFFLINE selection floor of the durable v1 spine
/// (ADR-014 §4), guarded by the strict `lib/curriculum` ban in
/// `test/tutor/durable_layers_no_agent_imports_test.dart`. It carries ONLY
/// non-PII ids / flags / counts — no child data, no geometry.
///
/// `ArcState` is the pure, immutable state of the confidence-rebuilding
/// REMEDIATION ARC (Req 4 / D-02 / D-04 / D-12, sketch 001 "The Teacher's
/// Margin"). It is threaded through `SelectionPolicy.narrow`, so the online
/// router and the offline walker consume the SAME output (offline parity by
/// construction, D-11); the Drift `ArcStateRows` mirror (18-03) persists it so a
/// mid-arc force-quit resumes where it left off (D-12).
///
/// The arc walks OBSERVABLE steps in order: entry → stepDown (the micro-drill) →
/// rebuild → retryOriginal. A clean win on the ORIGINAL exercise at
/// `retryOriginal` EXITS the arc; a floor-fail lands a guaranteed-doable trace
/// and ends warm (D-04) — never an endless loop.
library;

/// The ordered OBSERVABLE steps of the remediation arc (Req 4, sketch 001).
/// `ArcState.step` exposes each as its lowercase `.name` string
/// ('entry'/'stepDown'/'rebuild'/'retryOriginal').
enum ArcStep { entry, stepDown, rebuild, retryOriginal }

/// PROVISIONAL — `signed:false` (the owner-mother signs the number at the 18-11
/// HUMAN-UAT gate, D-02). The same-criterion fail streak that ENTERS the arc AND
/// forbids an identical third repeat: ONE counter drives BOTH anti-boredom (R1)
/// and arc entry (R4). Referenced BY NAME everywhere — never a magic literal.
const int kArcEntryFailStreak = 2;

/// PROVISIONAL — `signed:false` (mother-signed at 18-11, D-04). The hard ceiling
/// on arc attempts. The arc ALWAYS ends warm within this many steps (the floor
/// guard lands a guaranteed-doable trace) — never an endless remediation loop.
const int kArcMaxAttempts = 5;

/// The pure, immutable remediation-arc state. Non-PII ids / flags / counts only.
class ArcState {
  const ArcState({
    required this.active,
    required this.stepValue,
    this.targetCriterion,
    this.exerciseToRetry,
    this.failStreak = 0,
    this.attempts = 0,
  });

  /// True while a remediation arc is IN PROGRESS. `false` for the neutral
  /// (no-arc) state and for a NON-active tracking arc that is only counting the
  /// pre-entry fail streak.
  final bool active;

  /// The current arc step. Exposed to callers as the [step] name string so the
  /// RED contract can compare it to `'retryOriginal'` etc.
  final ArcStep stepValue;

  /// The scorer criterion the arc targets (e.g. `dot`/`shape`/`strokeOrder`) —
  /// the criterion the child keeps missing (D-02). Null before entry.
  final String? targetCriterion;

  /// The ORIGINAL exercise the child failed — the arc remembers it to retry on
  /// exit (D-04). Null before entry.
  final String? exerciseToRetry;

  /// The accumulated same-criterion fail streak on [exerciseToRetry] (the shared
  /// counter, D-02). Reaches [kArcEntryFailStreak] to enter the arc.
  final int failStreak;

  /// The number of arc steps taken. Bounded by [kArcMaxAttempts] — the ceiling
  /// that guarantees the arc ends warm and never loops (D-04).
  final int attempts;

  /// The observable step NAME ('entry'/'stepDown'/'rebuild'/'retryOriginal').
  String get step => stepValue.name;

  /// The neutral, inactive arc — no remediation in progress.
  factory ArcState.idle() =>
      const ArcState(active: false, stepValue: ArcStep.entry);

  /// A NON-active TRACKING arc: it only counts the same-criterion [failStreak] on
  /// [exerciseToRetry] before the streak reaches [kArcEntryFailStreak] (the
  /// shared counter, D-02). Not yet a live remediation.
  factory ArcState.tracking({
    required String targetCriterion,
    required String exerciseToRetry,
    required int failStreak,
  }) =>
      ArcState(
        active: false,
        stepValue: ArcStep.entry,
        targetCriterion: targetCriterion,
        exerciseToRetry: exerciseToRetry,
        failStreak: failStreak,
      );

  /// ENTER the arc at [ArcStep.entry], targeting [targetCriterion] and
  /// remembering [exerciseToRetry] to retry on exit (D-04).
  factory ArcState.enter({
    required String targetCriterion,
    required String exerciseToRetry,
    required int failStreak,
  }) =>
      ArcState(
        active: true,
        stepValue: ArcStep.entry,
        targetCriterion: targetCriterion,
        exerciseToRetry: exerciseToRetry,
        failStreak: failStreak,
      );

  // ── Transition helpers (stepDown / rebuild / retry) — each advances one step
  //    and ticks the [attempts] ceiling counter. ──────────────────────────────

  /// entry → stepDown (present the micro-drill).
  ArcState toStepDown() =>
      copyWith(stepValue: ArcStep.stepDown, attempts: attempts + 1);

  /// stepDown → rebuild.
  ArcState toRebuild() =>
      copyWith(stepValue: ArcStep.rebuild, attempts: attempts + 1);

  /// rebuild → retryOriginal (re-present the ORIGINAL exercise).
  ArcState toRetryOriginal() =>
      copyWith(stepValue: ArcStep.retryOriginal, attempts: attempts + 1);

  /// EXIT the arc (a clean win on the original, or the warm floor-guard end).
  ArcState exit() => copyWith(active: false, attempts: attempts + 1);

  ArcState copyWith({
    bool? active,
    ArcStep? stepValue,
    String? targetCriterion,
    String? exerciseToRetry,
    int? failStreak,
    int? attempts,
  }) =>
      ArcState(
        active: active ?? this.active,
        stepValue: stepValue ?? this.stepValue,
        targetCriterion: targetCriterion ?? this.targetCriterion,
        exerciseToRetry: exerciseToRetry ?? this.exerciseToRetry,
        failStreak: failStreak ?? this.failStreak,
        attempts: attempts ?? this.attempts,
      );
}
