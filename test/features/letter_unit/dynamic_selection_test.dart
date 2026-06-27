// DYN-02 (Wave 0, RED) — the baa unit driven by the ExerciseSelector, NOT the fixed walk.
//
// INTENTIONALLY RED at Wave 0: references the not-yet-built selection seam — the
// exerciseSelectorProvider router (Plan 15-05) + the CurriculumGraphWalker/GraphPosition
// (Plan 15-03). Plan 15-05 replaces letter_unit_screen.dart's fixed _section(index) switch
// with a single config-presenter fed by the selector, then turns this green. Do NOT add a
// lib/ stub here.
//
// The observable contract (15-VALIDATION.md, Pitfall 5): with the dynamic flow active, a
// FAIL re-surfaces a REMEDIATION exercise (one tier down within the competency), NOT the next
// linear section. This is the end-to-end "replace the fixed walk" proof — selection responds
// to the verdict, not a fixed index.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/curriculum_graph_walker.dart';
// RED: the selection-seam provider does not exist yet (Plan 15-05 wires it in lib/tutor/).
import 'package:qalam/tutor/exercise_selector_provider.dart';
import 'package:qalam/tutor/tutor_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CurriculumGraph loadGraph() {
    final raw = json.decode(
      File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
    ) as Map<String, Object?>;
    return CurriculumGraph.fromJson(raw);
  }

  test(
    'a FAIL re-surfaces a remediation exercise, not the next linear section (DYN-02 / Pitfall 5)',
    () {
      final graph = loadGraph();
      // The offline selector (the deterministic walker) is the seam the unit drives.
      final ExerciseSelector selector = CurriculumGraphWalker(graph);

      final position = GraphPosition(
        letterId: 'baa',
        currentExerciseId: 'baa.writeWord.dictation', // ghayrManzur — the hardest tier
        clearedCompetencies: const ['recognize', 'positionalForms'],
        clearedTiers: const ['manqul', 'manzur', 'ghayrManzur'],
      );

      final failFacts = TutorFacts(
        letterId: 'baa',
        section: 'writeWord',
        passed: false,
        mistakeId: 'missingDot',
      );

      final next = selector.selectNext(failFacts, position);
      expect(next, isNotNull);
      // It must be a REMEDIATION (one tier down), never the next forward/linear node.
      expect(graph.tierOf(next!), 'manzur',
          reason: 'a fail steps DOWN a tier — selection responds to the verdict, '
              'not the fixed section order');
      expect(next, isNot('baa.writeWord.dictation'),
          reason: 'remediation must move off the failed node, not the next linear section');
    },
  );

  test('the exercise-selector router provider is exposed for the unit (online↔offline)', () {
    // The router provider is the single switch point the unit reads (online RemoteAgent
    // plan.nextExerciseId vs. offline CurriculumGraphWalker). RED until Plan 15-05 wires it.
    expect(exerciseSelectorProvider, isNotNull);
  });
}
