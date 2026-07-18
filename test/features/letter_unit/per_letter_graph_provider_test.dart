// Quick task 260718-il4 Task 2 (TDD) — the per-letter curriculum-graph provider.
//
// RED contract (the behavior the family conversion must satisfy with these exact
// assertions — Phase-15 dead-wire lesson: prove the LIVE per-letter load, not a
// bare stub):
//   • curriculumGraphProvider('baa') resolves the baa graph (letterId=='baa');
//     curriculumGraphProvider('thaa') resolves the thaa graph (letterId=='thaa')
//     from graphs/thaa.json — the two are NOT the same object.
//   • The thaa graph rails on thaa nodes: isAuthored('thaa.traceLetter.isolated')
//     is true and isAuthored('baa.traceLetter.isolated') is false (and vice versa).
//   • OWNER AMENDMENT 1: a thaa unit's star requires exactly the thaa graph's
//     essential-competency nodes (its own ids) — never the baa graph's ids. A
//     thaa child with baa reps banked but no thaa reps must NOT earn the thaa star.
//
// The family is loaded from the REAL bundled assets (rootBundle over the promoted
// graphs/*.json), so this pins the on-device load path, not an in-memory fake.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalam/curriculum/curriculum_graph.dart';
import 'package:qalam/curriculum/mastery_condition.dart';
import 'package:qalam/tutor/exercise_selector_provider.dart'
    show curriculumGraphProvider;

/// A minimal AssetBundle-backed provider scope that reads the real
/// assets/curriculum/graphs/*.json from disk (flutter_test wires rootBundle to
/// the package assets, so the promoted graphs load exactly as on device).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('curriculumGraphProvider is a family: baa and thaa load distinct graphs',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final baa = await container.read(curriculumGraphProvider('baa').future);
    final thaa = await container.read(curriculumGraphProvider('thaa').future);

    expect(baa.letterId, 'baa');
    expect(thaa.letterId, 'thaa');
    expect(identical(baa, thaa), isFalse,
        reason: 'the family must load a DISTINCT graph per letterId, never a '
            'silent shared baa default');
  });

  test('the thaa graph rails on thaa nodes (not baa) and vice versa', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final baa = await container.read(curriculumGraphProvider('baa').future);
    final thaa = await container.read(curriculumGraphProvider('thaa').future);

    expect(thaa.isAuthored('thaa.traceLetter.isolated'), isTrue);
    expect(thaa.isAuthored('baa.traceLetter.isolated'), isFalse,
        reason: 'a thaa unit must never rail on baa exercise ids');

    expect(baa.isAuthored('baa.traceLetter.isolated'), isTrue);
    expect(baa.isAuthored('thaa.traceLetter.isolated'), isFalse);
  });

  test(
      'OWNER AMENDMENT 1: a thaa star requires the thaa graph essential nodes, '
      'never baa ids — baa reps do not earn the thaa star', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final thaa = await container.read(curriculumGraphProvider('thaa').future);

    // The exact essential-competency node ids of the thaa graph — the star bar.
    final thaaEssentialIds =
        thaa.essentialNodes.map((n) => n.exerciseId).toSet();
    expect(thaaEssentialIds, isNotEmpty,
        reason: 'thaa must have essential nodes to gate its star');
    // Every essential id belongs to thaa (no baa id can gate the thaa star).
    for (final id in thaaEssentialIds) {
      expect(id.startsWith('thaa.'), isTrue,
          reason: 'the thaa star gate must use only thaa ids, not $id');
    }

    // A child with baa reps banked but ZERO thaa reps must NOT earn the thaa star.
    final baaOnlyReps = <String, int>{
      for (final id in const [
        'baa.teachCard.meet',
        'baa.traceLetter.isolated',
        'baa.traceLetter.initial',
        'baa.traceLetter.medial',
        'baa.traceLetter.final',
        'baa.writeLetter.fromSound',
        'baa.writeWord.dictation',
        'baa.connectWord.baab',
      ])
        id: 99,
    };
    expect(isMasteryMet(thaa, baaOnlyReps), isFalse,
        reason: 'baa reps must never satisfy the thaa mastery condition');

    // The same child, now with every thaa essential node at its minCleanReps,
    // DOES earn the thaa star — proving the gate is the thaa graph itself.
    final thaaFullReps = <String, int>{
      for (final n in thaa.essentialNodes) n.exerciseId: n.minCleanReps,
    };
    expect(isMasteryMet(thaa, thaaFullReps), isTrue,
        reason: 'meeting exactly the thaa essential nodes earns the thaa star');
  });

  test('the thaa graph asset is bundled and readable via rootBundle', () async {
    // The pubspec must list assets/curriculum/graphs/ explicitly (a bare dir does
    // NOT include subdirectories) — otherwise this rootBundle read throws.
    final raw =
        await rootBundle.loadString('assets/curriculum/graphs/thaa.json');
    expect(raw, contains('"letterId": "thaa"'));
    final graph = CurriculumGraph.fromJson(
        json.decode(raw) as Map<String, Object?>);
    expect(graph.letterId, 'thaa');
  });
}
