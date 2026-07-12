// Phase 18 — Req 3 (just-this-part micro-drills) — Wave-0 RED contract.
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built `SelectionPolicy` from
// package:qalam/curriculum/selection_policy.dart. Plans 18-02 (authors the drill
// nodes) / 18-04 / 18-07 turn this green with ZERO test edits. Do NOT add a stub.
//
// Calibration-harness style (mirrors test/core/scoring/calibration_harness_test.dart
// lines ~320-367): a per letter × form loop asserts a contract per case. Here: when
// a criterion DOMINATES the fail history, the policy injects THAT criterion's
// micro-drill id into `candidates` (18-SPEC.md Req 3 / RESEARCH D-06, D-07, sketch
// 002 "Spotlight").
//
// The drill id vocabulary (dot / bowl / start for baa — D-07) is the CONTRACT 18-02
// authors as new `microDrill`-type nodes (signed:false until the mother flips it).
// The criterion → drill mapping below is the observable selection contract; the
// drills are enrichment nodes (essential:false) so they never gate the star.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: this library does not exist yet (Plans 18-02 / 18-04 / 18-07 write it).
import 'package:qalam/curriculum/selection_policy.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/curriculum_graph_walker.dart' show GraphPosition;
import 'package:qalam/tutor/tutor_facts.dart';

/// One micro-drill selection case: on [letterId] × [form], a fail history where
/// [dominantCriterion] dominates must inject [expectedDrill] into the candidates.
class _DrillCase {
  const _DrillCase({
    required this.letterId,
    required this.form,
    required this.dominantCriterion,
    required this.mistakeId,
    required this.expectedDrill,
  });

  final String letterId;
  final String form;
  final String dominantCriterion;
  final String mistakeId;
  final String expectedDrill;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CurriculumGraph loadGraph() {
    final raw = json.decode(
      File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
    ) as Map<String, Object?>;
    // Owner decision 2026-07-12 (18-11 UAT): the micro-drill CONTENT is parked —
    // its nodes were removed from the live graph until the feature is reworked
    // after the advisor meeting. The POLICY's injection logic must stay proven
    // for its return, so this test re-adds the drill nodes as a FIXTURE on top
    // of the live asset (fixture-augmented graph, not live content).
    final competencies = (raw['competencies'] as List).cast<Map<String, Object?>>();
    if (!competencies.any((c) => c['id'] == 'microDrill')) {
      competencies.add({
        'id': 'microDrill',
        'essential': false,
        'prerequisites': <String>[],
      });
    }
    final nodes = (raw['nodes'] as List).cast<Map<String, Object?>>();
    const drillCriteria = {'dot': 'dot', 'bowl': 'shape', 'start': 'strokeOrder'};
    for (final entry in drillCriteria.entries) {
      final id = 'baa.microDrill.${entry.key}';
      if (!nodes.any((n) => n['exerciseId'] == id)) {
        nodes.add({
          'exerciseId': id,
          'competency': 'microDrill',
          'tier': null,
          'minCleanReps': 1,
          'criterion': entry.value,
          'essential': false,
        });
      }
    }
    return CurriculumGraph.fromJson(raw);
  }

  // baa's three named criteria → their mother-authored micro-drills (D-07: dot
  // placement, bowl depth/shape, start point). `shape` is the bowl geometry; a
  // `strokeOrder` miss is a start-point drill.
  const cases = <_DrillCase>[
    _DrillCase(
      letterId: 'baa',
      form: 'isolated',
      dominantCriterion: 'dot',
      mistakeId: 'noDot',
      expectedDrill: 'baa.microDrill.dot',
    ),
    _DrillCase(
      letterId: 'baa',
      form: 'isolated',
      dominantCriterion: 'shape',
      mistakeId: 'shallowBowl',
      expectedDrill: 'baa.microDrill.bowl',
    ),
    _DrillCase(
      letterId: 'baa',
      form: 'medial',
      dominantCriterion: 'strokeOrder',
      mistakeId: 'wrongStrokeOrder',
      expectedDrill: 'baa.microDrill.start',
    ),
  ];

  group('Req 3 — a dominant failing criterion injects its micro-drill', () {
    final position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.writeLetter.fromSound',
      clearedCompetencies: const ['recognize'],
      clearedTiers: const [],
    );

    for (final c in cases) {
      test('${c.letterId} [${c.form}]: dominant "${c.dominantCriterion}" → drill '
          '"${c.expectedDrill}"', () {
        // A fail history dominated by this criterion (3 fails on the same criterion).
        final trajectory = [
          for (var i = 0; i < 3; i++)
            AttemptFact(passed: false, mistakeId: c.mistakeId, section: 'baa.writeLetter.fromSound'),
        ];
        final facts = TutorFacts(
          letterId: c.letterId,
          section: 'baa.writeLetter.fromSound',
          passed: false,
          mistakeId: c.mistakeId,
          weakestCriterion: c.dominantCriterion,
          criteria: [
            {'criterion': c.dominantCriterion, 'zone': 'certainlyWrong', 'score': 0.0},
          ],
          trajectory: trajectory,
          recentMistakes: [for (var i = 0; i < 3; i++) c.mistakeId],
        );

        final policy = SelectionPolicy(loadGraph());
        final PolicyOutcome out = policy.narrow(facts, position);

        expect(out.candidates, contains(c.expectedDrill),
            reason: 'Req 3: the dominant "${c.dominantCriterion}" criterion triggers '
                'its micro-drill "${c.expectedDrill}" (sketch 002)');
        expect(out.targetCriterion, c.dominantCriterion,
            reason: 'the drill targets the dominant criterion');
      });
    }
  });
}
