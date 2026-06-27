// DYN-01 / DYN-02 (Wave 0, RED) — the pure-Dart deterministic offline walker.
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built CurriculumGraphWalker (and the
// ExerciseSelector seam + GraphPosition) from package:qalam/curriculum/. Plan 15-03 writes
// them and turns this green. Do NOT add a lib/ stub.
//
// The observable contract (15-VALIDATION.md, Pitfall 5 — NEVER the old linear sequence):
//   • facts.passed                  → graph.nextForward(position)  (advance the chain)
//   • a fail                        → ONE tier down within the SAME competency
//                                     (ghayrManzur → manzur → manqul)
//   • at the manqul floor on a fail → re-present in place (drill, never jump back to linear)

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: these symbols do not exist yet (Plan 15-03 writes lib/curriculum/curriculum_graph_walker.dart).
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

  TutorFacts facts({required bool passed, required String section}) => TutorFacts(
        letterId: 'baa',
        section: section,
        passed: passed,
        mistakeId: passed ? null : 'shallowBowl',
      );

  test('the walker IS an ExerciseSelector (the selection seam)', () {
    final walker = CurriculumGraphWalker(loadGraph());
    expect(walker, isA<ExerciseSelector>());
  });

  test('a PASS advances to the next forward node (graph.nextForward)', () {
    final graph = loadGraph();
    final walker = CurriculumGraphWalker(graph);
    final position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.teachCard.meet',
      clearedCompetencies: const ['recognize'],
      clearedTiers: const [],
    );

    final next = walker.selectNext(facts(passed: true, section: 'meet'), position);
    expect(next, isNotNull);
    expect(next, graph.nextForward('baa.teachCard.meet'),
        reason: 'a pass walks the chain forward, never the old fixed section order');
  });

  test('a FAIL steps ONE tier down within the same competency (ghayrManzur → manzur)', () {
    final graph = loadGraph();
    final walker = CurriculumGraphWalker(graph);
    final position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.writeWord.dictation', // copyWrite, ghayrManzur
      clearedCompetencies: const ['recognize', 'positionalForms'],
      clearedTiers: const ['manqul', 'manzur', 'ghayrManzur'],
    );

    final next = walker.selectNext(facts(passed: false, section: 'writeWord'), position);
    expect(next, isNotNull);
    expect(graph.tierOf(next!), 'manzur',
        reason: 'a dictation fail remediates DOWN one tier (Pitfall 3), not forward');
  });

  test('at the manqul floor, a FAIL re-presents in place (no jump to the linear sequence)', () {
    final graph = loadGraph();
    final walker = CurriculumGraphWalker(graph);
    final position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.connectWord.baab', // copyWrite, manqul (the floor)
      clearedCompetencies: const ['recognize', 'positionalForms'],
      clearedTiers: const ['manqul'],
    );

    final next = walker.selectNext(facts(passed: false, section: 'connectWord'), position);
    // At the floor the walker drills in place — it does NOT revert to the old fixed walk.
    expect(next, 'baa.connectWord.baab',
        reason: 'manqul floor: re-present in place (Pitfall 5 — never the linear fallback)');
  });
}
