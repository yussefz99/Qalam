/// Pure Dart. No cloud-AI / Firebase / network / Flutter-render / drift / riverpod
/// import — this is part of the OFFLINE selection floor of the durable v1 spine
/// (ADR-014 §4), guarded by the strict `lib/curriculum` ban in
/// `test/tutor/durable_layers_no_agent_imports_test.dart`.
///
/// `ChildModelSnapshot` is the ACROSS-SESSION half of the two-timescale child
/// model (Req 2 / D-15 / D-16): the compiled per-child profile the nightly job
/// produces (`strengths` / `struggles` / per-criterion EMA), decoded on boot from
/// the Drift `ChildProfileMirror` (18-06) and read by `SelectionPolicy` so a
/// RETURNING child's first pick reflects the previous session.
///
/// FIXED-VOCABULARY, non-PII by construction: every key is a `<letter>/<criterion>`
/// id (e.g. `baa/dot`) and every value a derived scalar — no nickname, no
/// geometry. The serialized [toMap] shape mirrors the wire `TutorFacts.profile`
/// field (18-05) so the compiled profile can ride the outgoing FACTS unchanged.
library;

/// An immutable, fixed-vocabulary, non-PII snapshot of the compiled child model.
class ChildModelSnapshot {
  const ChildModelSnapshot({
    this.strengths = const [],
    this.struggles = const [],
    this.perCriterion = const {},
    this.schemaVersion = 1,
  });

  /// The `<letter>/<criterion>` ids the child is reliably strong on (EMA above the
  /// strength band). Derived, non-PII strings.
  final List<String> strengths;

  /// The `<letter>/<criterion>` ids the child persistently struggles with (EMA
  /// below the struggle band). Derived, non-PII strings — the across-session
  /// signal the first pick / WHY line references (Req 2).
  final List<String> struggles;

  /// The per-criterion EMA map, keyed by `<letter>/<criterion>` id → estimate in
  /// [0, 1]. The within-session estimate agrees with this by sharing one formula
  /// (D-15). Derived scalars only.
  final Map<String, double> perCriterion;

  /// The compile schema version — lets the mirror decode evolve additively
  /// without breaking older rows.
  final int schemaVersion;

  /// The neutral, empty profile — offline first-run / no compiled profile yet.
  /// The policy treats it as "no across-session signal" (never a false struggle).
  factory ChildModelSnapshot.empty() => const ChildModelSnapshot();

  /// The whitelisted serialized form — fixed-vocabulary, non-PII. Mirrors the
  /// wire `TutorFacts.profile` field (18-05) so the compiled profile rides the
  /// outgoing FACTS byte-for-byte.
  Map<String, Object?> toMap() => {
        'strengths': strengths,
        'struggles': struggles,
        'perCriterion': perCriterion,
        'schemaVersion': schemaVersion,
      };
}
