// Phase 18 — Req 2 (across-session memory) — Wave-0 RED contract.
//
// INTENTIONALLY RED at Wave 0: references the not-yet-built `ChildModelSnapshot`
// (package:qalam/curriculum/selection_policy.dart), the not-yet-added
// `TutorFacts.profile` wire field, and `SelectionPolicy`. Plans 18-05 (compiler +
// wire field) / 18-06 (Drift mirror) turn this green with ZERO test edits.
//
// The property (18-SPEC.md Req 2 / GROUND-04 / RESEARCH D-15, D-16): a RETURNING
// child's first session reflects the previous one —
//   • the compiled per-child profile (strengths/struggles/EMA, fixed-vocabulary,
//     non-PII) rides the outgoing `TutorFacts.profile` field; and
//   • the first pick / `whyFacts` REFERENCES a stored struggle from that profile.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: ChildModelSnapshot / SelectionPolicy do not exist yet (Plans 18-05 / 18-06).
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

  // A returning child whose last-session compile recorded a persistent struggle on
  // baa's dot criterion and a strength on shape (fixed-vocabulary letter/criterion
  // keys, per-criterion EMA — all derived, non-PII).
  const storedStruggle = 'baa/dot';
  const storedStrength = 'baa/shape';
  const snapshot = ChildModelSnapshot(
    strengths: [storedStrength],
    struggles: [storedStruggle],
    perCriterion: {'baa/dot': 0.18, 'baa/shape': 0.92},
    schemaVersion: 1,
  );

  test('the compiled profile rides the outgoing TutorFacts.profile (fixed-vocabulary, '
      'non-PII)', () {
    final facts = TutorFacts(
      letterId: 'baa',
      section: 'baa.traceLetter.isolated',
      passed: true,
      profile: snapshot.toMap(), // the new wire field (18-05)
    );

    final json = facts.toJson();
    expect(json['profile'], isNotNull,
        reason: 'Req 2: the first-session facts carry the compiled profile');
    final profile = json['profile'] as Map<String, Object?>;
    expect(profile['struggles'], contains(storedStruggle),
        reason: 'Req 2: the outgoing profile carries the stored struggle');
    expect(profile['strengths'], contains(storedStrength));
    expect((profile['perCriterion'] as Map).keys, contains('baa/dot'));
  });

  test('the first pick / whyFacts REFERENCES a stored struggle from the profile', () {
    final policy = SelectionPolicy(loadGraph());
    const position = GraphPosition(
      letterId: 'baa',
      currentExerciseId: 'baa.traceLetter.isolated',
      clearedCompetencies: ['recognize'],
      clearedTiers: [],
    );
    // A fresh session boot — the FIRST facts, no in-session trajectory yet, only the
    // across-session profile.
    final facts = TutorFacts(
      letterId: 'baa',
      section: 'baa.traceLetter.isolated',
      passed: true,
      profile: snapshot.toMap(),
    );

    final PolicyOutcome out = policy.narrow(facts, position, profile: snapshot);

    expect(
      out.whyFacts.any((f) => f.contains('dot')),
      isTrue,
      reason: 'Req 2: the returning child\'s first justification references the '
          'stored struggle (dot) from the previous session',
    );
  });
}
