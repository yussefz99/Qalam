// Phase 18 — Req 4 (remediation arc) — Wave-0 RED contract.
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built `SelectionPolicy` +
// `ArcState` + the provisional constants `kArcEntryFailStreak` / `kArcMaxAttempts`
// from package:qalam/curriculum/selection_policy.dart. Plans 18-04 / 18-07 write
// them and turn this green with ZERO test edits. Do NOT add a lib/ stub.
//
// The observable SPEC contract (18-SPEC.md Req 4 / RESEARCH D-02, D-04, D-12,
// sketch 001 "The Teacher's Margin"):
//   • A same-criterion fail streak reaching `kArcEntryFailStreak` ENTERS an arc that
//     TARGETS that criterion (the arc and the anti-boredom rule share one counter).
//   • The arc walks OBSERVABLE steps in order: entry → stepDown → rebuild →
//     retryOriginal (`ArcState.step`). Exit = a clean win on the ORIGINAL exercise.
//   • A struggling child reaches that clean win within `kArcMaxAttempts` — never an
//     endless loop.
//   • Floor guard (D-04): if even the arc's drill step fails, the policy lands on a
//     guaranteed-doable success (a trace) and ends the arc warm.
//
// `kArcEntryFailStreak` / `kArcMaxAttempts` are referenced BY NAME (provisional,
// signed:false) — never integer literals — so the mother's number is a single
// signed constant, not a magic number sprinkled through the code.

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

  const original = 'baa.writeLetter.fromSound'; // positionalForms, tier null
  const criterion = 'dot'; // the failing criterion the arc targets
  const dotMistake = 'noDot';

  final position = GraphPosition(
    letterId: 'baa',
    currentExerciseId: original,
    clearedCompetencies: const ['recognize'],
    clearedTiers: const [],
  );

  TutorFacts failOn(String exercise) => TutorFacts(
        letterId: 'baa',
        section: exercise,
        passed: false,
        mistakeId: dotMistake,
        weakestCriterion: criterion,
        criteria: const [
          {'criterion': 'dot', 'zone': 'certainlyWrong', 'score': 0.0},
        ],
        recentMistakes: const [dotMistake],
      );

  TutorFacts passOn(String exercise) => TutorFacts(
        letterId: 'baa',
        section: exercise,
        passed: true,
        weakestCriterion: criterion,
        criteria: const [
          {'criterion': 'dot', 'zone': 'certainlyCorrect', 'score': 1.0},
        ],
      );

  // Advance the arc through the policy: feed the streak of same-criterion fails, then
  // return the entered ArcState (or null if it never entered).
  ArcState? enterArc(SelectionPolicy policy) {
    ArcState? arc;
    for (var i = 0; i < kArcEntryFailStreak; i++) {
      final out = policy.narrow(failOn(original), position, arc: arc);
      arc = out.nextArc;
    }
    return arc;
  }

  // The ordered subsequence check: are [needles] present in [haystack] in order?
  bool containsInOrder(List<String> haystack, List<String> needles) {
    var i = 0;
    for (final h in haystack) {
      if (i < needles.length && h == needles[i]) i++;
    }
    return i == needles.length;
  }

  test('a same-criterion fail streak of kArcEntryFailStreak ENTERS an arc targeting '
      'that criterion', () {
    final policy = SelectionPolicy(loadGraph());
    final arc = enterArc(policy);

    expect(arc, isNotNull, reason: 'the streak must ENTER the remediation arc');
    expect(arc!.active, isTrue);
    expect(arc.targetCriterion, criterion,
        reason: 'Req 4/D-02: the arc targets the criterion the child keeps missing');
    expect(arc.exerciseToRetry, original,
        reason: 'D-04: the arc remembers the ORIGINAL exercise to retry on exit');
  });

  test('a struggling run reaches a clean win within kArcMaxAttempts via the ordered '
      'arc steps entry → stepDown → rebuild → retryOriginal', () {
    final policy = SelectionPolicy(loadGraph());
    var arc = enterArc(policy);

    final observedSteps = <String>[if (arc != null) arc.step];
    var attempts = 0;
    // Simulate the struggling child: fail every step EXCEPT the final retry of the
    // original, which is the clean win that exits the arc (D-04).
    while ((arc?.active ?? false) && attempts < kArcMaxAttempts) {
      final inRetry = arc!.step == 'retryOriginal';
      final facts = inRetry ? passOn(original) : failOn(arc.exerciseToRetry ?? original);
      final out = policy.narrow(facts, position, arc: arc);
      arc = out.nextArc;
      if (arc != null && arc.active) observedSteps.add(arc.step);
      attempts++;
    }

    expect(arc?.active ?? false, isFalse,
        reason: 'Req 4: a struggling child reaches a clean win and the arc EXITS');
    expect(attempts, lessThanOrEqualTo(kArcMaxAttempts),
        reason: 'Req 4: the win arrives within kArcMaxAttempts — never an endless loop');
    expect(
      containsInOrder(observedSteps, const ['entry', 'stepDown', 'rebuild', 'retryOriginal']),
      isTrue,
      reason: 'Req 4/sketch 001: the arc walks entry → stepDown → rebuild → '
          'retryOriginal in order (observed: $observedSteps)',
    );
  });

  test('floor guard (D-04): when even the drill step fails, the policy offers a '
      'guaranteed-doable trace and ends the arc — never loops past kArcMaxAttempts', () {
    final policy = SelectionPolicy(loadGraph());
    var arc = enterArc(policy);

    // The pathological child FAILS every single attempt, including the drill floor.
    var attempts = 0;
    var offeredTrace = false;
    while ((arc?.active ?? false) && attempts < kArcMaxAttempts + 1) {
      final out = policy.narrow(failOn(arc!.exerciseToRetry ?? original), position, arc: arc);
      if (out.candidates.any((id) => id.contains('traceLetter'))) offeredTrace = true;
      arc = out.nextArc;
      attempts++;
    }

    expect(offeredTrace, isTrue,
        reason: 'D-04: the floor guard lands on a guaranteed-doable trace success');
    expect(arc?.active ?? false, isFalse,
        reason: 'D-04: the arc ENDS warm even when every attempt fails — no endless loop');
    expect(attempts, lessThanOrEqualTo(kArcMaxAttempts),
        reason: 'D-04: bounded by kArcMaxAttempts (no infinite remediation)');
  });
}
