/// Pure Dart. No Flutter rendering import — there is deliberately NO `Offset`,
/// no stroke, no coordinate field anywhere in this file, and the type cannot
/// hold one.
///
/// `TutorFacts` is the **FACTS-in** side of the `TutorBrain` seam (ADR-014
/// §Decision part 4 / 14-CONTEXT `decisions`). It is the WHITELISTED, non-PII
/// snapshot the scorer hands the tutor: a derived verdict + the learner's recent
/// derived mistakes + the session learner model — never the child's raw strokes,
/// never the nickname/PII.
///
/// CAPABLE AGENT (Plan 14-03 / ADR-015 §Seam impact / CAPABLE-AGENT-SPEC): the
/// server tutor reasons over the *trajectory* of scored attempts this session
/// PLUS the learner model (strengths AND struggles), not just the last
/// `mistakeId`. So `TutorFacts` now also carries [trajectory] (a list of derived
/// per-attempt non-PII records) and [strengthTags]. The serialized shape mirrors
/// the deployed server `TutorFactsIn` (`server/app/schema.py`, the SINGLE source
/// of truth) field-for-field, so the server's `extra="forbid"` never 422s a legit
/// enlarged payload.
///
/// GROUND-02 / non-PII guard: [toMap] / [toJson] emit ONLY the ten whitelisted
/// scalar / string-list / derived-record fields below (the eight base fields plus
/// the two Phase-15 graph-position fields `clearedTiers`/`clearedCompetencies`).
/// A unit test asserts the serialized payload (recursing into the trajectory
/// records) carries no coordinate/PII key (a real `x`/`y`/`strokes`/`offset`/
/// `childName` key trips the guard; the legit `trajectory`/`strengthTags`/
/// `clearedTiers`/`clearedCompetencies` pass it). Because the builder
/// ([buildTutorFacts]) is the only constructor path callers use and its signature
/// accepts no stroke/Offset parameter, raw geometry physically cannot reach the
/// model.
library;

/// One non-PII scored-attempt record in the session [TutorFacts.trajectory].
///
/// Mirrors the server's `AttemptFactIn` (`server/app/schema.py`):
/// `{passed: bool, mistakeId: String?, section: String}` — a bool, an authored
/// feedback key, and the section id. By construction it CANNOT hold a stroke, an
/// `Offset`, or any PII; it is built only from an already-derived `CheckResult`.
class AttemptFact {
  const AttemptFact({
    required this.passed,
    required this.section,
    this.mistakeId,
  });

  /// The deterministic scorer's frozen verdict for this attempt.
  final bool passed;

  /// Null on a pass. On a miss, the authored feedback key the scorer matched.
  final String? mistakeId;

  /// The exercise/section id this attempt belongs to (e.g. `traceLetter`).
  final String section;

  /// The whitelisted serialized form — exactly the server `AttemptFactIn` keys
  /// (`{passed, mistakeId, section}`), no more.
  Map<String, Object?> toMap() => {
        'passed': passed,
        'mistakeId': mistakeId,
        'section': section,
      };
}

/// An immutable, non-PII snapshot of one coaching moment.
///
/// Every field is a scalar, a list of short id/tag strings, or a list of derived
/// [AttemptFact] records. The `mistakeId` mirrors `CheckResult.mistakeId` (an
/// authored feedback key / `MistakeId` enum name), NOT a raw scorer internal —
/// the same value the deterministic verdict already exposed.
class TutorFacts {
  const TutorFacts({
    required this.letterId,
    required this.section,
    required this.passed,
    this.mistakeId,
    this.struggleTags = const [],
    this.strengthTags = const [],
    this.recentMistakes = const [],
    this.trajectory = const [],
    this.clearedTiers = const [],
    this.clearedCompetencies = const [],
    this.strokeDiff,
  });

  /// The letter family this moment belongs to (e.g. `baa`).
  final String letterId;

  /// The exercise/section id (e.g. `traceLetter`, `writeWord`).
  final String section;

  /// The deterministic scorer's verdict for THIS attempt.
  final bool passed;

  /// Null on a pass. On a miss, the authored feedback key / `MistakeId` enum
  /// name the scorer matched (e.g. `shallowBowl`).
  final String? mistakeId;

  /// Derived, deduplicated tags summarising what the child keeps missing this
  /// session — built from [recentMistakes] by the chokepoint. Pure strings.
  final List<String> struggleTags;

  /// Derived session-learner-model strengths: the sections the child has passed
  /// cleanly (no miss) this session — the inverse of struggles. Pure strings,
  /// built deterministically by the chokepoint from [trajectory].
  final List<String> strengthTags;

  /// The recent session mistake ids (most-recent-first), already non-PII.
  final List<String> recentMistakes;

  /// The scored-attempt trajectory this session — a list of derived, non-PII
  /// per-attempt records (`{passed, mistakeId, section}`). Never raw geometry.
  final List<AttemptFact> trajectory;

  /// The إملاء difficulty tiers the child has cleared (e.g. `['manqul','manzur']`)
  /// — read from the durable Drift graph position on resume (D-08 trajectory
  /// replay), so the agent's reasoning resumes where it left off. Pure non-PII
  /// tier-id strings; mirrors `TutorFactsIn.clearedTiers` (`server/app/schema.py`)
  /// byte-for-byte (Pitfall 1 — the 422 trap under `extra="forbid"`).
  final List<String> clearedTiers;

  /// The curriculum-graph competencies the child has cleared (e.g.
  /// `['recognize','positionalForms']`) — read from the durable Drift graph
  /// position on resume. Pure non-PII competency-id strings; mirrors
  /// `TutorFactsIn.clearedCompetencies` (`server/app/schema.py`) byte-for-byte.
  final List<String> clearedCompetencies;

  /// Phase 17 (STRK-01 / GROUND-04): a DERIVED, POINT-FREE stroke-geometry diff of
  /// THIS attempt vs the authored reference (bowl depth, which side is flat, the
  /// dot's placement, a tail, direction) — computed ON-DEVICE in
  /// `tutor/stroke_diff.dart` at the surface seam, where the raw strokes are still
  /// discarded. Holds ONLY derived scalars/strings (no `x`/`y`/`points`), so it
  /// honors GROUND-02/04. Null when none could be derived (write mode / no
  /// reference). Mirrors `TutorFactsIn.strokeDiff` (`server/app/schema.py`); the
  /// server's `extra="forbid"` 422s any stray coordinate key.
  final Map<String, Object?>? strokeDiff;

  /// The whitelisted serialized form. Emits ONLY the ten derived fields (the
  /// eight base + `clearedTiers`/`clearedCompetencies`) — no raw strokes, no PII.
  /// This is the exact shape that crosses the network as the `/coach` request
  /// body; its keys + casing mirror the deployed server `TutorFactsIn`
  /// (`server/app/schema.py`) so `extra="forbid"` returns 200, not 422 (GROUND-02).
  Map<String, Object?> toMap() => {
        'letterId': letterId,
        'section': section,
        'passed': passed,
        'mistakeId': mistakeId,
        'struggleTags': struggleTags,
        'recentMistakes': recentMistakes,
        'trajectory': [for (final a in trajectory) a.toMap()],
        'strengthTags': strengthTags,
        'clearedTiers': clearedTiers,
        'clearedCompetencies': clearedCompetencies,
        // Phase 17: include the derived diff only when present (omit the key when
        // null so an unchanged payload byte-matches the prior shape).
        if (strokeDiff != null) 'strokeDiff': strokeDiff,
      };

  /// Alias of [toMap] — same whitelisted shape.
  Map<String, Object?> toJson() => toMap();
}
