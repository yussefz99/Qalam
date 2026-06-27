/// Pure Dart. No Flutter rendering import — there is deliberately NO `Offset`,
/// no stroke, no coordinate field anywhere in this file, and the type cannot
/// hold one. No cloud-AI / Firebase / network import either: this is a durable
/// v1 spine layer (ADR-014 §4), guarded by
/// `test/tutor/durable_layers_no_agent_imports_test.dart`.
///
/// `CurriculumGraph` is the on-device parse of the single-source
/// `assets/curriculum/curriculum_graph.json` asset (authored, PROVISIONAL, in
/// Plan 15-01). It answers the three questions the offline walker and the
/// on-device mastery condition need — and NOTHING about the child:
///   • `essentialNodes`            — the essential 70/30 core the star gates on.
///   • `tierOf(id)`                — the إملاء difficulty tier (null off-ramp).
///   • `nextForward(id)`           — the next node along the prerequisite chain.
///   • `remediateOneTier(id)`      — one tier down within the SAME competency
///                                   (ghayrManzur→manzur→manqul; null at floor).
///
/// The defensive parse idiom mirrors `lib/tutor/tutor_facts.dart`: whitelisted
/// fields only, `fromJson(Map)` so the parser is unit-testable from a Map (no
/// `rootBundle` inside the parser itself — the production loader reads the same
/// bytes via `rootBundle` and hands the decoded Map straight in).
library;

/// The difficulty tiers of the إملاء (dictation) writing ramp, EASIEST first.
/// A backward remediation walks this list DOWN one step (ghayrManzur → manzur →
/// manqul); `manqul` is the floor (no easier tier). Nodes that are not part of
/// the writing ramp (recognize / trace / recall / morphology) carry `tier:null`.
const List<String> kTierOrder = ['manqul', 'manzur', 'ghayrManzur'];

/// One competency in the prerequisite chain (e.g. `recognize`, `copyWrite`).
/// `essential` drives the 70/30 split — only essential competencies' nodes gate
/// the star (see [CurriculumGraph.essentialNodes]).
class GraphCompetency {
  const GraphCompetency({
    required this.id,
    required this.essential,
    required this.prerequisites,
  });

  /// The competency id (e.g. `copyWrite`).
  final String id;

  /// Essential competencies form the mastery core; enrichment competencies
  /// (`wordBuilding`, `grammarTransform`) never gate the star (D-06, 70/30).
  final bool essential;

  /// The competency ids that must be cleared before this one is reachable.
  final List<String> prerequisites;

  /// Defensive parse — whitelisted fields only.
  factory GraphCompetency.fromJson(Map<String, Object?> json) {
    return GraphCompetency(
      id: (json['id'] as String?) ?? '',
      essential: (json['essential'] as bool?) ?? false,
      prerequisites: [
        for (final p in (json['prerequisites'] as List<Object?>? ?? const []))
          if (p is String) p,
      ],
    );
  }
}

/// One exercise node in the graph. It carries ONLY pedagogy metadata — an
/// exercise id, its competency, its (optional) difficulty tier, the
/// owner-mother's clean-rep threshold, and whether it is essential. No child
/// data, no geometry.
class GraphNode {
  const GraphNode({
    required this.exerciseId,
    required this.competency,
    required this.tier,
    required this.minCleanReps,
    required this.essential,
  });

  /// The signed baa.* exercise id this node maps (byte-identical to the
  /// `baa_authored_ids.json` set — the graph invents no exercises).
  final String exerciseId;

  /// The competency id this node belongs to.
  final String competency;

  /// The إملاء difficulty tier, or null for non-ramp nodes (trace / recall /
  /// morphology).
  final String? tier;

  /// The owner-mother's DRAFT clean-reps threshold for this node (D-07).
  final int minCleanReps;

  /// True iff this node's competency is essential — only these gate the star.
  final bool essential;
}

/// The parsed, immutable curriculum graph. Pure data + pure queries.
class CurriculumGraph {
  CurriculumGraph._({
    required this.letterId,
    required this.signedOff,
    required this.competencies,
    required this.tiers,
    required this.nodes,
  });

  /// The letter family this graph rails (e.g. `baa`).
  final String letterId;

  /// `false` while the asset is PROVISIONAL — the owner-mother has not yet
  /// signed the tier-level mapping (D-05). Plan 15-07 owns the flip to `true`.
  final bool signedOff;

  /// The competencies in declaration order (the prerequisite chain).
  final List<GraphCompetency> competencies;

  /// The difficulty tiers EASIEST-first (`[manqul, manzur, ghayrManzur]`).
  final List<String> tiers;

  /// The exercise nodes in declaration order (the canonical forward walk).
  final List<GraphNode> nodes;

  /// Defensive parse of the single-source asset Map. Whitelisted fields only;
  /// no `rootBundle` here so the parser stays hermetic and unit-testable.
  factory CurriculumGraph.fromJson(Map<String, Object?> json) {
    final competencies = [
      for (final c in (json['competencies'] as List<Object?>? ?? const []))
        if (c is Map) GraphCompetency.fromJson(Map<String, Object?>.from(c)),
    ];
    // Build the essential lookup once so every node can derive its own flag.
    final essentialByCompetency = <String, bool>{
      for (final c in competencies) c.id: c.essential,
    };
    final nodes = [
      for (final n in (json['nodes'] as List<Object?>? ?? const []))
        if (n is Map)
          _nodeFromJson(
            Map<String, Object?>.from(n),
            essentialByCompetency,
          ),
    ];
    return CurriculumGraph._(
      letterId: (json['letterId'] as String?) ?? '',
      signedOff: (json['signedOff'] as bool?) ?? false,
      competencies: List<GraphCompetency>.unmodifiable(competencies),
      tiers: List<String>.unmodifiable([
        for (final t in (json['tiers'] as List<Object?>? ?? const []))
          if (t is String) t,
      ]),
      nodes: List<GraphNode>.unmodifiable(nodes),
    );
  }

  static GraphNode _nodeFromJson(
    Map<String, Object?> json,
    Map<String, bool> essentialByCompetency,
  ) {
    final competency = (json['competency'] as String?) ?? '';
    return GraphNode(
      exerciseId: (json['exerciseId'] as String?) ?? '',
      competency: competency,
      tier: json['tier'] as String?,
      minCleanReps: (json['minCleanReps'] as num?)?.toInt() ?? 0,
      essential: essentialByCompetency[competency] ?? false,
    );
  }

  /// The essential 70/30 core — every node whose competency is essential.
  /// Enrichment nodes (`wordBuilding` / `grammarTransform`) are excluded; they
  /// never gate the star (D-06).
  List<GraphNode> get essentialNodes =>
      [for (final n in nodes) if (n.essential) n];

  /// The node for [exerciseId], or null if it is not in the graph.
  GraphNode? _nodeFor(String exerciseId) {
    for (final n in nodes) {
      if (n.exerciseId == exerciseId) return n;
    }
    return null;
  }

  /// The إملاء difficulty tier of [exerciseId], or null for off-ramp nodes
  /// (trace / recall / morphology) and unknown ids.
  String? tierOf(String exerciseId) => _nodeFor(exerciseId)?.tier;

  /// The competency id of [exerciseId], or null if unknown.
  String? competencyOf(String exerciseId) => _nodeFor(exerciseId)?.competency;

  /// The next node id along the canonical forward walk (declaration order),
  /// starting from [exerciseId]. Null at the very end of the graph or for an
  /// unknown id. A PASS advances here — never the old fixed linear section order
  /// (the graph IS the order now; Pitfall 5).
  String? nextForward(String exerciseId) {
    final index = nodes.indexWhere((n) => n.exerciseId == exerciseId);
    if (index < 0 || index + 1 >= nodes.length) return null;
    return nodes[index + 1].exerciseId;
  }

  /// One tier DOWN within the SAME competency as [exerciseId]
  /// (ghayrManzur → manzur → manqul). Returns the id of an easier same-competency
  /// node, or null when [exerciseId] is already at the `manqul` floor, is an
  /// off-ramp (tier:null) node, or is unknown. This is the backward-remediation
  /// move the offline walker takes on a fail (D-09, Pitfall 3 lattice).
  String? remediateOneTier(String exerciseId) {
    final node = _nodeFor(exerciseId);
    final tier = node?.tier;
    if (node == null || tier == null) return null;

    final tierIndex = tiers.indexOf(tier);
    if (tierIndex <= 0) return null; // floor (or tier not in the ramp): no step.
    final lowerTier = tiers[tierIndex - 1];

    // The first same-competency node at the next-lower tier (declaration order).
    for (final n in nodes) {
      if (n.competency == node.competency && n.tier == lowerTier) {
        return n.exerciseId;
      }
    }
    return null;
  }
}
