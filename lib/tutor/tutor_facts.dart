/// Pure Dart. No Flutter rendering import — there is deliberately NO `Offset`,
/// no stroke, no coordinate field anywhere in this file, and the type cannot
/// hold one.
///
/// `TutorFacts` is the **FACTS-in** side of the `TutorBrain` seam (ADR-014
/// §Decision part 4 / 14-CONTEXT `decisions`). It is the WHITELISTED, non-PII
/// snapshot the scorer hands the tutor: a derived verdict + the learner's recent
/// derived mistakes — never the child's raw strokes, never the nickname/PII.
///
/// GROUND-02 / non-PII guard: [toMap] / [toJson] emit ONLY the six whitelisted
/// scalar / string-list fields below. A unit test asserts the serialized payload
/// carries no key matching /stroke|offset|nick|name|x|y|point/i. Because the
/// builder ([buildTutorFacts]) is the only constructor path callers use and its
/// signature accepts no stroke parameter, raw geometry physically cannot reach
/// the model.
library;

/// An immutable, non-PII snapshot of one coaching moment.
///
/// Every field is a scalar or a list of short id/tag strings. The `mistakeId`
/// mirrors `CheckResult.mistakeId` (an authored feedback key / `MistakeId` enum
/// name), NOT a raw scorer internal — the same value the deterministic verdict
/// already exposed.
class TutorFacts {
  const TutorFacts({
    required this.letterId,
    required this.section,
    required this.passed,
    this.mistakeId,
    this.struggleTags = const [],
    this.recentMistakes = const [],
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

  /// The recent session mistake ids (most-recent-first), already non-PII.
  final List<String> recentMistakes;

  /// The whitelisted serialized form. Emits ONLY the six derived fields — no
  /// raw strokes, no PII. This is the exact shape that may cross the network as
  /// FACTS-as-text (GROUND-02).
  Map<String, Object?> toMap() => {
        'letterId': letterId,
        'mistakeId': mistakeId,
        'passed': passed,
        'section': section,
        'struggleTags': struggleTags,
        'recentMistakes': recentMistakes,
      };

  /// Alias of [toMap] — same whitelisted shape.
  Map<String, Object?> toJson() => toMap();
}
