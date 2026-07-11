/// Pure Dart. No cloud-AI / Firebase / network / Flutter-render / drift / riverpod
/// import — this is part of the OFFLINE selection floor of the durable v1 spine
/// (ADR-014 §4), guarded by the strict `lib/curriculum` ban in
/// `test/tutor/durable_layers_no_agent_imports_test.dart`.
///
/// `SessionAttempt` is the CRITERION-TAGGED, CLIENT-ONLY within-session attempt
/// record the `SelectionPolicy` fail-streak counter reads (D-02). It exists
/// specifically BECAUSE `TutorFacts.trajectory` cannot be the streak source:
/// today `trajectory` is per-widget-instance state (it dies on every scaffold key
/// change — e.g. `FormsSection` keys per form) and its `AttemptFact` carries NO
/// criterion (only `{passed, mistakeId, section}`). This type adds the missing
/// [weakestCriterion] tag and a stable session-scoped identity.
///
/// CLIENT-ONLY: it NEVER crosses the wire — the `AttemptFactIn` / 422 `extra=forbid`
/// lockstep is untouched (zero 422 exposure). The session-scoped store that
/// SUPPLIES a `List<SessionAttempt>` is built in 18-07; this plan defines the pure
/// type and the counter that consumes it.
library;

/// One criterion-tagged, non-PII attempt in the CURRENT session's history.
class SessionAttempt {
  const SessionAttempt({
    required this.exerciseId,
    required this.passed,
    this.weakestCriterion,
  });

  /// The exercise/section id this attempt belongs to (e.g.
  /// `baa.writeLetter.fromSound`).
  final String exerciseId;

  /// The deterministic scorer's frozen verdict for this attempt.
  final bool passed;

  /// The lowest-score scorer criterion for this attempt (`dot`/`shape`/
  /// `strokeOrder`/...) — the tag `AttemptFact` lacks, so the policy can count a
  /// SAME-criterion streak. Null on a clean pass.
  final String? weakestCriterion;
}
