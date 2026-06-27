// DYN-01 / DYN-02 (Wave 0, RED) — CurriculumGraph parses the provisional asset.
//
// INTENTIONALLY RED at Wave 0: imports package:qalam/curriculum/curriculum_graph.dart,
// which does not exist yet. Plan 15-03 writes the pure-Dart CurriculumGraph (parse
// assets/curriculum/curriculum_graph.json: essentialNodes filter, tierOf / nextForward /
// remediateOneTier helpers, signedOff getter) and turns this green. Do NOT add a lib/ stub.
//
// The asset itself was authored in Plan 15-01 (signedOff:false, 19 baa.* nodes), so the
// parse target exists; only the parser is missing. This file names the observable parse
// behavior from 15-VALIDATION.md.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: lib/curriculum/curriculum_graph.dart does not exist yet (Plan 15-03 writes it).
import 'package:qalam/curriculum/curriculum_graph.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The graph as authored in Plan 15-01 — parsed straight off disk (no rootBundle so the
  // test stays hermetic; the production loader reads the same bytes via rootBundle).
  Map<String, Object?> rawGraph() {
    final file = File('assets/curriculum/curriculum_graph.json');
    return json.decode(file.readAsStringSync()) as Map<String, Object?>;
  }

  test('CurriculumGraph parses the provisional baa asset (19 baa.* nodes, signedOff false)',
      () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    expect(graph.letterId, 'baa');
    expect(graph.signedOff, isFalse,
        reason: 'the asset is PROVISIONAL until owner-mother signs (D-05)');
    expect(graph.nodes.length, 19, reason: 'all 19 signed baa.* exercises are nodes');
    expect(
      graph.nodes.every((n) => n.exerciseId.startsWith('baa.')),
      isTrue,
      reason: 'baa-only — no ت/ث nodes (D-11)',
    );
  });

  test('essentialNodes filters to essential competencies only (the 70/30 split)', () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    // Every essentialNode belongs to an essential competency.
    final essentialCompetencyIds = graph.competencies
        .where((c) => c.essential)
        .map((c) => c.id)
        .toSet();
    expect(essentialCompetencyIds, isNotEmpty);
    for (final node in graph.essentialNodes) {
      expect(essentialCompetencyIds.contains(node.competency), isTrue,
          reason: 'an essentialNode must belong to an essential competency');
    }
    // Enrichment nodes (wordBuilding / grammarTransform) are excluded.
    expect(
      graph.essentialNodes.length < graph.nodes.length,
      isTrue,
      reason: 'enrichment nodes must NOT count as essential (70/30 split)',
    );
  });

  test('tierOf is non-null only for إملاء writing nodes; recognize/trace are null', () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    // The trace nodes carry no tier (not the إملاء ramp).
    expect(graph.tierOf('baa.traceLetter.isolated'), isNull);
    // The dictation node sits at the hardest tier.
    expect(graph.tierOf('baa.writeWord.dictation'), 'ghayrManzur');
  });

  test('nextForward / remediateOneTier helpers are exposed for the walker', () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    // From the manqul→manzur→ghayrManzur ramp, remediating dictation steps down a tier.
    final remediated = graph.remediateOneTier('baa.writeWord.dictation');
    expect(remediated, isNotNull,
        reason: 'a ghayrManzur node must remediate down one tier (Pitfall 3 lattice)');
    // nextForward advances the chain (a non-null next node id from the start of the graph).
    expect(graph.nextForward('baa.teachCard.meet'), isNotNull);
  });
}
