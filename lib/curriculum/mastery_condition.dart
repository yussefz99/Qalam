/// Pure Dart. No cloud-AI / Firebase / network / Flutter-render import, no PII —
/// a durable v1 spine layer (ADR-014 §4), guarded by
/// `test/tutor/durable_layers_no_agent_imports_test.dart`.
///
/// `isMasteryMet` is the ON-DEVICE deterministic star condition (D-06). The
/// agent's `intent:"advance"` is a SUGGESTION; the star is NEVER granted off a
/// server `CoachOut` (ADR-014 trust boundary). It is computed strictly from the
/// child's Drift clean-rep counts over the ESSENTIAL nodes only — enrichment
/// (`wordBuilding` / `grammarTransform`) never gates the star (the 70/30 split).
///
/// This REPLACES `LetterUnitController._onEnterSection`'s "reaching Mastery
/// records mastered" auto-write (which records `cleanReps:0` on mere navigation —
/// Pitfall 2). Plan 15-04 supplies the per-exercise clean-rep counts from Drift;
/// Plan 15-05 wires the `recordMastery` gate strictly to this predicate. This
/// file only owns the pure condition.
library;

import 'curriculum_graph.dart';

/// True iff EVERY essential node has met the owner-mother's clean-reps for it.
///
/// - Returns `false` the moment any essential node's clean-reps fall below its
///   `minCleanReps` (a missing key counts as 0 — a clicked-through unit never
///   earns the star, Pitfall 2).
/// - Enrichment nodes are NOT iterated, so they can never gate the star (D-06,
///   the 70/30 essential/enrichment split).
/// - Pure over a `Map<String,int>` of clean-rep counts — no PII, no server
///   response read.
bool isMasteryMet(CurriculumGraph graph, Map<String, int> cleanRepsByExercise) {
  for (final node in graph.essentialNodes) {
    final reps = cleanRepsByExercise[node.exerciseId] ?? 0;
    if (reps < node.minCleanReps) return false;
  }
  return true;
}
