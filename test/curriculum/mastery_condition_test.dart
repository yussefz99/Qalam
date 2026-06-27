// DYN-02 (Wave 0, RED) — the on-device deterministic mastery condition (D-06).
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built isMasteryMet from
// package:qalam/curriculum/mastery_condition.dart. Plan 15-03 writes it and turns this
// green. Do NOT add a lib/ stub.
//
// The observable contract (15-VALIDATION.md, Pitfall 2 — the star is REAL mastery, not
// navigation): isMasteryMet is true ONLY when EVERY essential node's clean-reps ≥ its
// minCleanReps; enrichment nodes NEVER gate; false on a clicked-through (zero-rep) unit.
// Mastery is computed on-device from Drift clean-rep counts — never trusted from a server.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: lib/curriculum/{curriculum_graph,mastery_condition}.dart do not exist yet (Plan 15-03).
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/mastery_condition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CurriculumGraph loadGraph() {
    final raw = json.decode(
      File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
    ) as Map<String, Object?>;
    return CurriculumGraph.fromJson(raw);
  }

  test('false on a clicked-through unit (zero clean reps everywhere) — Pitfall 2', () {
    final graph = loadGraph();
    expect(isMasteryMet(graph, const <String, int>{}), isFalse,
        reason: 'navigating without passing must NOT grant the star');
  });

  test('true ONLY when every essential node meets its minCleanReps', () {
    final graph = loadGraph();

    // Build a reps map that satisfies every ESSENTIAL node at exactly its minCleanReps.
    final reps = <String, int>{
      for (final node in graph.essentialNodes) node.exerciseId: node.minCleanReps,
    };
    expect(isMasteryMet(graph, reps), isTrue,
        reason: 'all essential nodes cleared at mom\'s reps → mastery');

    // Drop ONE essential node below its threshold → mastery must flip to false.
    final firstEssential = graph.essentialNodes.first.exerciseId;
    final short = Map<String, int>.from(reps)..[firstEssential] = 0;
    expect(isMasteryMet(graph, short), isFalse,
        reason: 'a single under-rep essential node blocks the star');
  });

  test('enrichment nodes never gate the star (the 70/30 split)', () {
    final graph = loadGraph();

    // Satisfy essential nodes but leave ALL enrichment nodes at zero reps.
    final essentialIds = graph.essentialNodes.map((n) => n.exerciseId).toSet();
    final reps = <String, int>{
      for (final node in graph.essentialNodes) node.exerciseId: node.minCleanReps,
    };
    // Sanity: there ARE enrichment nodes left unrepresented.
    final enrichment = graph.nodes.where((n) => !essentialIds.contains(n.exerciseId));
    expect(enrichment, isNotEmpty,
        reason: 'the graph must carry enrichment nodes for this assertion to mean anything');

    expect(isMasteryMet(graph, reps), isTrue,
        reason: 'enrichment (wordBuilding / grammarTransform) does NOT gate mastery (D-06)');
  });
}
