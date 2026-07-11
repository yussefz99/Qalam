/// Pure Dart. No cloud-AI / Firebase / network / Flutter-render import — this is
/// the OFFLINE selection floor of the durable v1 spine (ADR-014 §4), guarded by
/// `test/tutor/durable_layers_no_agent_imports_test.dart`.
///
/// `ExerciseSelector` is the selection seam — a DIFFERENT axis from `TutorBrain`
/// (selection of the next exercise vs. coaching the current one). Online,
/// selection rides the agent decision's `plan.nextExerciseId`
/// (`tutor_decision.dart`); offline, `CurriculumGraphWalker` drives the SAME
/// graph deterministically. The two axes degrade independently: coaching falls
/// back to `AuthoredFallbackBrain`, selection falls back to this walker.
///
/// **Pitfall 5 (D-09):** the offline walker must still WALK the graph
/// adaptively — advance on a pass, remediate ONE tier down on a fail — and must
/// NEVER revert to the old fixed 6-section linear sequence. A fail is a
/// remediation, not the next linear step.
library;

import '../tutor/tutor_decision.dart';
import '../tutor/tutor_facts.dart';
import 'curriculum_graph.dart';

/// Where a child currently is in a letter's graph — the durable cursor 15-04
/// persists in Drift and 15-05 reads. Pure non-PII ids: the current exercise,
/// plus the cleared competencies/tiers (so the walker and the online rail agree
/// on what is reachable). No child name, no geometry.
class GraphPosition {
  const GraphPosition({
    required this.letterId,
    required this.currentExerciseId,
    this.clearedCompetencies = const [],
    this.clearedTiers = const [],
  });

  /// The letter family this position belongs to (e.g. `baa`).
  final String letterId;

  /// The exercise the child is currently on (the walk cursor).
  final String currentExerciseId;

  /// The competency ids the child has already cleared (forward-progress state).
  final List<String> clearedCompetencies;

  /// The إملاء tiers the child has already cleared (ramp-progress state).
  final List<String> clearedTiers;
}

/// The single swappable selection seam. Given the non-PII [TutorFacts] verdict
/// for the just-finished attempt and the child's current [GraphPosition], answer
/// with the next exercise id (or null when the graph is exhausted). It never
/// decides pass/fail or the star — the scorer owns the verdict; this only
/// chooses what comes next.
///
/// An optional [decision] carries the online agent's reply (its
/// `plan.nextExerciseId` SUGGESTION). The OFFLINE walker ignores it entirely; the
/// ONLINE router (`lib/tutor/exercise_selector_provider.dart`) accepts the
/// agent's choice ONLY when it is graph-legal, else falls to the walker (Pitfall
/// 5 — selection degrades on a separate axis from coaching).
abstract class ExerciseSelector {
  String? selectNext(
    TutorFacts facts,
    GraphPosition position, {
    TutorDecision? decision,
  });
}

/// The OFFLINE deterministic [ExerciseSelector]. With zero model loaded, in
/// airplane mode, it still adapts to the child's mistakes by walking the SAME
/// curriculum graph the online rail uses:
///   • `facts.passed` → `graph.nextForward(currentExerciseId)` (advance).
///   • a fail         → `graph.remediateOneTier(currentExerciseId)` (one tier
///                      down within the same competency)
///                      ?? `currentExerciseId` (drill in place at the floor).
/// Never the old fixed linear sequence (Pitfall 5 / D-09).
class CurriculumGraphWalker implements ExerciseSelector {
  const CurriculumGraphWalker(this.graph);

  /// The graph this walker rails — the SAME single-source asset the online
  /// server rail reads (D-04).
  final CurriculumGraph graph;

  @override
  String? selectNext(
    TutorFacts facts,
    GraphPosition position, {
    TutorDecision? decision,
  }) {
    // The OFFLINE walker IGNORES the online agent decision (Pitfall 5 — selection
    // degrades on a separate axis; offline it walks the graph deterministically).
    final current = position.currentExerciseId;
    if (facts.passed) {
      // A pass walks the chain forward — but only to a node that is REACHABLE
      // (tier-legal + prerequisites-met) given the cleared state (T4).
      // A forward pass must not cross into an unreached tier or skip a
      // prerequisite. Scan declaration order from `current` for the next
      // node that passes the legality gate; null at the end of the graph.
      return _nextReachableForward(current, position);
    }
    // A fail remediates ONE tier down within the same competency — but only to a
    // LEGAL node (18-07/T-18-07-01): an unreachable lower tier or an unmet-prereq
    // remediation must NEVER be presented (the earlier `remediateOneTier ?? current`
    // could hand back an illegal node when the cleared state did not yet reach it).
    // At the manqul floor (no legal easier tier) it re-presents in place when that
    // is itself legal; otherwise it advances to the nearest legal forward node —
    // NEVER a dead-end illegal id, NEVER the old linear walk (Pitfall 5). This is
    // the offline mirror of the online rail: the walker narrows to legal ids only.
    final rem = graph.remediateOneTier(current);
    if (rem != null && _isLegal(rem, position)) return rem;
    if (_isLegal(current, position)) return current; // floor: drill in place
    return _nextReachableForward(current, position);
  }

  /// Pick deterministically FROM a policy-narrowed [candidates] set (18-07). Used
  /// online↔offline whenever the `SelectionPolicy` supplied candidates: on a fail
  /// prefer the one-tier-down remediation, else the drill-in-place; on a pass (or
  /// when no remediation candidate survived) take the nearest legal forward
  /// candidate. Every returned id is a MEMBER of [candidates] (already rail-legal
  /// by construction — the policy re-checked `isLegalSelection`), or null when the
  /// set is empty. This is the offline-parity twin of the online accept-if-legal
  /// branch: both the router and the walker choose from the SAME candidate set
  /// (D-11), so the offline floor is identical to the online degrade by design.
  String? selectFrom(
    List<String> candidates,
    TutorFacts facts,
    GraphPosition position,
  ) {
    if (candidates.isEmpty) return null;
    final current = position.currentExerciseId;
    if (!facts.passed) {
      final rem = graph.remediateOneTier(current);
      if (rem != null && candidates.contains(rem)) return rem;
      if (candidates.contains(current)) return current; // floor: drill in place
    }
    // The candidates arrive in declaration order (nearest-forward first), so the
    // first is the nearest legal forward node — matching `selectNext`'s pass walk.
    return candidates.first;
  }

  /// The single legality gate — the graph rail is the authority (mirrors the
  /// online router's `isLegalSelection` re-check, T-15-05-T / Pitfall 3).
  bool _isLegal(String id, GraphPosition position) => graph.isLegalSelection(
        id,
        clearedTiers: position.clearedTiers,
        clearedCompetencies: position.clearedCompetencies,
      );

  /// Scan forward from [currentId] in declaration order for the next node that
  /// is tier-reachable and has its prerequisites met given [position]'s cleared
  /// state. Null when the graph is exhausted or no legal forward node exists.
  String? _nextReachableForward(String currentId, GraphPosition position) {
    final nodes = graph.nodes;
    final startIndex = nodes.indexWhere((n) => n.exerciseId == currentId);
    if (startIndex < 0) return null;
    for (var i = startIndex + 1; i < nodes.length; i++) {
      final candidate = nodes[i].exerciseId;
      if (graph.isLegalSelection(
        candidate,
        clearedTiers: position.clearedTiers,
        clearedCompetencies: position.clearedCompetencies,
      )) {
        return candidate;
      }
    }
    return null; // graph exhausted (all remaining nodes are locked).
  }
}
