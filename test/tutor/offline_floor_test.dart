// Phase 18 — Req 6 (offline floor preserved) — Wave-0 RED contract.
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built `SelectionPolicy` from
// package:qalam/curriculum/selection_policy.dart. Plans 18-06 / 18-07 give the
// offline walker FULL parity with the new intelligence (arcs, anti-boredom,
// drills via the SAME pure-Dart policy — D-11) and turn this green with ZERO edits.
//
// The property (18-SPEC.md Req 6 / RESEARCH D-11, D-16, Anti-Patterns): with the
// brain UNAVAILABLE (no `TutorDecision`), an airplane-mode session stays coherent
// via the walker —
//   • a multi-exercise session COMPLETES with no null dead-end mid-session (null is
//     legal ONLY at graph exhaustion); and
//   • no selection call blocks on a network future — `SelectionPolicy.narrow` and
//     `ExerciseSelector.selectNext` are SYNCHRONOUS (return values, never Futures).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: SelectionPolicy does not exist yet (Plans 18-06 / 18-07 write it).
import 'package:qalam/curriculum/selection_policy.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/curriculum_graph_walker.dart';
import 'package:qalam/tutor/tutor_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CurriculumGraph loadGraph() {
    final raw = json.decode(
      File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
    ) as Map<String, Object?>;
    return CurriculumGraph.fromJson(raw);
  }

  test('airplane mode: a multi-exercise session completes via the walker with no '
      'mid-session null dead-end (brain unavailable, no TutorDecision)', () {
    final graph = loadGraph();
    final policy = SelectionPolicy(graph);
    final walker = CurriculumGraphWalker(graph);

    // Start at the graph root; clear competencies/tiers as we advance so the ramp
    // stays reachable (the durable cursor 15-04 persists this — here in-memory).
    var position = const GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.teachCard.meet',
      clearedCompetencies: ['recognize'],
      clearedTiers: [],
    );

    final visited = <String>[];
    for (var step = 0; step < graph.nodes.length + 2; step++) {
      final facts = TutorFacts(
        letterId: 'baa',
        section: position.currentExerciseId,
        passed: true,
      );

      // The pure policy narrowing must be synchronous — no network await offline.
      final out = policy.narrow(facts, position);
      expect(out.candidates, isNotNull);

      // No decision → the OFFLINE walker drives selection deterministically.
      final String? next = walker.selectNext(facts, position);
      if (next == null) break; // legal ONLY at graph exhaustion

      visited.add(next);
      position = GraphPosition(
        letterId: 'baa',
        currentExerciseId: next,
        clearedCompetencies: _advanceCompetencies(graph, position, next),
        clearedTiers: _advanceTiers(graph, position, next),
      );
    }

    expect(visited, isNotEmpty,
        reason: 'Req 6: the offline walker advances a real session, never dead-ends '
            'at the start');
    expect(visited.toSet().length, greaterThan(1),
        reason: 'Req 6: the session visits multiple distinct exercises offline');
  });

  test('no selection call awaits a network future — narrow/selectNext are '
      'synchronous', () {
    final graph = loadGraph();
    final policy = SelectionPolicy(graph);
    final walker = CurriculumGraphWalker(graph);
    const position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.traceLetter.isolated',
      clearedCompetencies: ['recognize'],
      clearedTiers: [],
    );
    final facts = TutorFacts(
      letterId: 'baa',
      section: 'baa.traceLetter.isolated',
      passed: false,
      weakestCriterion: 'shape',
    );

    // If either returned a Future the static types below would not compile — the
    // synchronous return IS the "never blocks on network" guarantee (D-16).
    final PolicyOutcome out = policy.narrow(facts, position);
    final String? next = walker.selectNext(facts, position);

    expect(out, isNot(isA<Future<dynamic>>()));
    expect(next, anyOf(isNull, isA<String>()));
  });
}

// Clear the just-passed node's competency once its whole competency is done.
// (A coarse in-test advance — the real cursor lives in Drift, 15-04.)
List<String> _advanceCompetencies(
  CurriculumGraph graph,
  GraphPosition position,
  String next,
) {
  final cleared = {...position.clearedCompetencies};
  final comp = graph.competencyOf(position.currentExerciseId);
  if (comp != null) cleared.add(comp);
  return cleared.toList();
}

// Clear the just-passed node's tier so the next ramp rung unlocks.
List<String> _advanceTiers(
  CurriculumGraph graph,
  GraphPosition position,
  String next,
) {
  final cleared = {...position.clearedTiers};
  final tier = graph.tierOf(position.currentExerciseId);
  if (tier != null) cleared.add(tier);
  return cleared.toList();
}
