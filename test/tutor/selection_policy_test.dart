// Phase 18 — Req 1 (anti-boredom + explainable pick) — Wave-0 RED contract.
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built `SelectionPolicy`
// (+ `ChildModelSnapshot` / `ArcState` / `PolicyOutcome` and the provisional
// `kArcEntryFailStreak` constant) from package:qalam/curriculum/selection_policy.dart.
// Plans 18-04 / 18-07 write it and turn this green with ZERO test edits (the
// 15-01 / 17-01 "zero test edits" contract). Do NOT add a lib/ stub.
//
// The observable SPEC contract (18-SPEC.md Req 1 / RESEARCH D-02, D-09, D-10):
//   • A child who fails the SAME weakest criterion `kArcEntryFailStreak` times on
//     the SAME exercise never sees that identical exercise a third time — the
//     policy EXCLUDES it from `candidates` (anti-boredom).
//   • The pick TARGETS the failed criterion — `targetCriterion` == that criterion.
//   • The tutor line can say WHY — `whyFacts` is non-empty and NAMES the criterion
//     (online the coach LLM phrases it, offline an authored template; D-10).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: this library does not exist yet (Plans 18-04 / 18-07 write it).
import 'package:qalam/curriculum/selection_policy.dart';
import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/curriculum_graph_walker.dart' show GraphPosition;
import 'package:qalam/tutor/tutor_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CurriculumGraph loadGraph() {
    final raw = json.decode(
      File('assets/curriculum/curriculum_graph.json').readAsStringSync(),
    ) as Map<String, Object?>;
    return CurriculumGraph.fromJson(raw);
  }

  // `kArcEntryFailStreak` consecutive fails on the SAME weakest criterion, all on
  // the SAME exercise — the anti-boredom trigger (provisional threshold, signed:false).
  List<AttemptFact> sameCriterionFailStreak(String exercise, String mistakeId) => [
        for (var i = 0; i < kArcEntryFailStreak; i++)
          AttemptFact(passed: false, mistakeId: mistakeId, section: exercise),
      ];

  group('Req 1 — anti-boredom + criterion-targeted, explainable pick', () {
    const boredExercise = 'baa.writeLetter.fromSound'; // positionalForms, tier null
    const failedCriterion = 'shape'; // the bowl geometry criterion
    const shapeMistake = 'shallowBowl'; // a shape-family mistake key

    // The child sits on `boredExercise`, having cleared `recognize` so the rest of
    // positionalForms (other write/trace nodes) are legal alternative candidates.
    final position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: boredExercise,
      clearedCompetencies: const ['recognize'],
      clearedTiers: const [],
    );

    TutorFacts failingShapeFacts() => TutorFacts(
          letterId: 'baa',
          section: boredExercise,
          passed: false,
          mistakeId: shapeMistake,
          weakestCriterion: failedCriterion,
          criteria: const [
            {'criterion': 'strokeCount', 'zone': 'certainlyCorrect', 'score': 1.0},
            {'criterion': 'shape', 'zone': 'certainlyWrong', 'score': 0.0},
            {'criterion': 'dot', 'zone': 'certainlyCorrect', 'score': 1.0},
          ],
          trajectory: sameCriterionFailStreak(boredExercise, shapeMistake),
          recentMistakes: const [shapeMistake, shapeMistake],
        );

    test('after two same-criterion fails, the identical exercise is EXCLUDED from '
        'candidates (no identical third repeat)', () {
      final policy = SelectionPolicy(loadGraph());
      final PolicyOutcome out = policy.narrow(failingShapeFacts(), position);

      expect(out.candidates, isNotEmpty,
          reason: 'the policy must still offer SOMETHING to do next');
      expect(out.candidates, isNot(contains(boredExercise)),
          reason: 'Req 1: a child who fails the same criterion twice never sees '
              'the identical exercise a third time (anti-boredom)');
    });

    test('the pick TARGETS the failed criterion', () {
      final policy = SelectionPolicy(loadGraph());
      final PolicyOutcome out = policy.narrow(failingShapeFacts(), position);

      expect(out.targetCriterion, failedCriterion,
          reason: 'Req 1: the next pick targets the criterion the child keeps missing');
    });

    test('a non-empty WHY (`whyFacts`) is emitted and NAMES the targeted criterion', () {
      final policy = SelectionPolicy(loadGraph());
      final PolicyOutcome out = policy.narrow(failingShapeFacts(), position);

      expect(out.whyFacts, isNotEmpty,
          reason: 'Req 1: the tutor line must be able to say WHY it picked');
      expect(
        out.whyFacts.any((f) => f.toLowerCase().contains(failedCriterion)),
        isTrue,
        reason: 'Req 1: the justification names the targeted criterion "$failedCriterion"',
      );
    });
  });
}
