// Phase 18 — Req 5 (rails hold) — Wave-0 RED property contract.
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built `SelectionPolicy` from
// package:qalam/curriculum/selection_policy.dart. Plan 18-07 wires the router to
// consume the policy candidates and turns this green with ZERO test edits.
//
// SEEDED-RANDOM PLAIN flutter_test — NO glados / flutter_glados (RESEARCH §Don't
// Hand-Roll: glados base sdk `<3.0.0` won't resolve on Dart 3.11; flutter_glados
// pins analyzer ^7.4.5 vs the project's analyzer 9.0.0 — a hard conflict that
// would break riverpod_lint). A fixed seed makes the run reproducible in CI.
//
// The property (18-SPEC.md Req 5 / T-18-01-02, trust boundary UNCHANGED — the
// agent is untrusted): over ≥200 generated (agent proposal, cleared-state, facts)
// cases against the new history-aware selector,
//   • EVERY accepted agent pick is graph-legal (`isLegalSelection` true) AND a
//     policy candidate — the policy narrows, it never widens the rail; and
//   • every illegal / off-graph / non-candidate proposal DEGRADES to the walker's
//     pick over the SAME policy-narrowed candidate set (or null at graph exhaustion).

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// RED: SelectionPolicy does not exist yet (Plan 18-07 wires the router to it).
import 'package:qalam/curriculum/selection_policy.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/curriculum_graph_walker.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart';
import 'package:qalam/tutor/tutor_decision.dart';
import 'package:qalam/tutor/tutor_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CurriculumGraph loadGraph() {
    final raw = json.decode(
      File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
    ) as Map<String, Object?>;
    return CurriculumGraph.fromJson(raw);
  }

  const int kIterations = 200; // ≥200 generated cases (Req 5)
  const int kFixedSeed = 0xB0A7; // reproducible: same seed → same case stream

  test('100% of accepted agent picks are graph-legal policy candidates; every '
      'illegal proposal degrades to the walker (≥$kIterations seeded cases)', () {
    final graph = loadGraph();
    final router = RouterExerciseSelector(graph);
    final policy = SelectionPolicy(graph);
    final walker = CurriculumGraphWalker(graph);

    final allIds = [for (final n in graph.nodes) n.exerciseId];
    // Off-graph noise the generator may propose — must NEVER be accepted.
    const offGraphIds = <String?>[
      null,
      '',
      'baa.notARealExercise',
      'ghost.node',
      'baa.writeWord.dictation.extra',
    ];
    final tiers = <String>['manqul', 'manzur', 'ghayrManzur'];
    final competencies = <String>[
      'recognize',
      'positionalForms',
      'copyWrite',
      'fluentReading',
    ];

    final rng = Random(kFixedSeed);

    List<T> randomSublist<T>(List<T> src) =>
        [for (final e in src) if (rng.nextBool()) e];

    for (var i = 0; i < kIterations; i++) {
      // Random cleared state anywhere in the lattice.
      final clearedTiers = randomSublist(tiers);
      final clearedCompetencies = randomSublist(competencies);
      final current = allIds[rng.nextInt(allIds.length)];
      final position = GraphPosition(
        letterId: 'baa',
        currentExerciseId: current,
        clearedCompetencies: clearedCompetencies,
        clearedTiers: clearedTiers,
      );

      // Random facts (pass/fail + a weakest criterion).
      final facts = TutorFacts(
        letterId: 'baa',
        section: current,
        passed: rng.nextBool(),
        weakestCriterion: const ['shape', 'dot', 'direction', 'strokeCount', 'strokeOrder'][rng.nextInt(5)],
      );

      // Random proposal: sometimes a real graph id, sometimes off-graph noise.
      final String? proposed = rng.nextBool()
          ? allIds[rng.nextInt(allIds.length)]
          : offGraphIds[rng.nextInt(offGraphIds.length)];
      final decision = Advance(plan: TutorPlan(nextExerciseId: proposed));

      final PolicyOutcome out = policy.narrow(facts, position);
      final picked = router.selectNext(facts, position, decision: decision);

      if (picked != null && picked == proposed) {
        // ACCEPTED the agent pick → it MUST be graph-legal AND a policy candidate.
        expect(
          graph.isLegalSelection(
            proposed,
            clearedTiers: clearedTiers,
            clearedCompetencies: clearedCompetencies,
          ),
          isTrue,
          reason: 'Req 5: an accepted agent pick is always graph-legal '
              '(case $i, proposed=$proposed)',
        );
        expect(out.candidates, contains(proposed),
            reason: 'Req 5: the policy narrows — an accepted pick is a candidate '
                '(case $i)');
      } else {
        // DEGRADED: the router fell to the deterministic walker's pick over the
        // same narrowed candidate set (or null at graph exhaustion).
        final walked = walker.selectNext(facts, position);
        expect(picked, walked,
            reason: 'Req 5: an illegal / non-candidate proposal degrades to the '
                'walker (case $i, proposed=$proposed)');
        // And whatever the router returns is null or a policy candidate — never
        // an out-of-rail id.
        expect(picked == null || out.candidates.contains(picked), isTrue,
            reason: 'Req 5: the router never returns an out-of-rail id (case $i)');
      }
    }
  });
}
