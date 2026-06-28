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

  // ── T4: forward-reachability constraints ─────────────────────────────────────

  test('T4: a PASS does not advance into an unreached tier (forward reachability)', () {
    final graph = loadGraph();
    final walker = CurriculumGraphWalker(graph);

    // The child is at the last manqul node but has NOT yet cleared the manqul
    // tier, so manzur nodes are not reachable. A pass must NOT skip into manzur.
    const position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.completeWord.middle', // copyWrite, manqul
      clearedCompetencies: ['recognize', 'positionalForms'],
      clearedTiers: [], // manqul not yet cleared → manzur is locked
    );

    final next = walker.selectNext(facts(passed: true, section: 'completeWord'), position);
    // The next declaration-order node is baa.writeWord.copy (manzur) but manqul
    // is not cleared → that tier is not reachable. The walker must skip past
    // locked nodes or return null when the graph is exhausted for the child.
    if (next != null) {
      final tier = graph.tierOf(next);
      // Any returned node must be in a reachable tier for the cleared state.
      final reachable = graph.reachableTiers(position.clearedTiers);
      if (tier != null) {
        expect(reachable.contains(tier), isTrue,
            reason: 'a forward pass must not advance into an unreached tier (T4)');
      }
      // Its competency prerequisites must be met.
      expect(
        graph.prerequisitesMet(next, position.clearedCompetencies),
        isTrue,
        reason: 'a forward pass must not skip a prerequisite (T4)',
      );
    }
    // null is also valid (graph exhausted for this cleared state — no legal node).
  });

  test('T4: a PASS does not skip a competency prerequisite', () {
    final graph = loadGraph();
    final walker = CurriculumGraphWalker(graph);

    // Child is on the last positionalForms node with positionalForms NOT yet
    // cleared, so copyWrite nodes (which require positionalForms) are locked.
    const position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.writeLetter.writeForm', // positionalForms
      clearedCompetencies: ['recognize'], // positionalForms not cleared → copyWrite locked
      clearedTiers: [],
    );

    final next = walker.selectNext(facts(passed: true, section: 'writeLetter'), position);
    if (next != null) {
      expect(
        graph.prerequisitesMet(next, position.clearedCompetencies),
        isTrue,
        reason: 'a forward pass must not advance to a node whose competency prerequisites '
            'are unmet (T4 — no skipping ahead)',
      );
    }
  });

  test('T4: backward remediation still passes (a lower tier is always legal)', () {
    final graph = loadGraph();
    final walker = CurriculumGraphWalker(graph);

    // Child is at ghayrManzur and fails → walker remediates one tier DOWN to
    // manzur. Even though manzur < ghayrManzur, a backward step is always legal
    // (the child has already been at that level — Pitfall 3).
    const position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.writeWord.dictation', // copyWrite, ghayrManzur
      clearedCompetencies: ['recognize', 'positionalForms', 'copyWrite'],
      clearedTiers: ['manqul', 'manzur', 'ghayrManzur'],
    );

    final next = walker.selectNext(facts(passed: false, section: 'writeWord'), position);
    expect(next, isNotNull,
        reason: 'backward remediation must always return a node (Pitfall 3)');
    expect(graph.tierOf(next!), 'manzur',
        reason: 'a fail from ghayrManzur must step back to manzur');
    // The remediation must be legal for the cleared state.
    expect(
      graph.isLegalSelection(
        next,
        clearedTiers: position.clearedTiers,
        clearedCompetencies: position.clearedCompetencies,
      ),
      isTrue,
      reason: 'backward remediation must pass the legality gate (Pitfall 3)',
    );
  });

  test('T4: a PASS from a non-ramp (null-tier) node advances to the next reachable node', () {
    final graph = loadGraph();
    final walker = CurriculumGraphWalker(graph);

    // From baa.teachCard.meet (recognize, tier:null) with recognize cleared.
    // Next in declaration order is baa.traceLetter.isolated (positionalForms,
    // tier:null). Its only prerequisite is 'recognize' which IS cleared.
    const position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.teachCard.meet',
      clearedCompetencies: ['recognize'],
      clearedTiers: [],
    );

    final next = walker.selectNext(facts(passed: true, section: 'teachCard'), position);
    expect(next, isNotNull,
        reason: 'a pass from a null-tier node must advance to the next reachable node');
    expect(
      graph.prerequisitesMet(next!, position.clearedCompetencies),
      isTrue,
      reason: 'the advanced-to node must have its prerequisites met',
    );
  });
}
