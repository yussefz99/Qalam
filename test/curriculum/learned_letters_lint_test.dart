// Phase 19-01 (Wave 0) — QP-07 / D-12 RED contract: the learned-letters lint.
//
// D-12 (locked, THE authoring rule Phases 20–21 inherit): a unit's cards may use
// only letters introduced up to and including that unit. The baa unit's learned
// set is {alif, baa} (letters.json `introOrder` ≤ 2 — the app's pedagogical lesson
// order, A2, NOT the classical ابجد list). Every LIVE baa-unit card's `letters`
// array must be a subset of the learned set.
//
// INTENTIONALLY RED today: seven baa cards demand unlearned letters and are still
// live nodes in curriculum_graph.json —
//   baa.connectWord.kitaab (kaaf,taa) · baa.transformWord.dual (noon) ·
//   baa.transformWord.plural (waaw) · baa.transformWord.opposite (saad,ghayn,yaa,
//   raa) · baa.fillBlank.adjective (kaaf,yaa,raa) · baa.buildSentence.hear /
//   .picture (laam,kaaf,yaa,raa).
//
// 19-05 greens this per D-09 — each offending card is either:
//   • REWRITTEN to an alif+baa-only word (its `letters` becomes ⊆ {alif,baa}), or
//   • GATED (D-19: removed from the baa graph, filed for the letter's own unit in
//     Phase 20/21) — which drops it from the live-node set this lint scopes over.
// The lint is disposition-agnostic: the graph-membership + subset rule self-greens
// for BOTH paths, with zero test edits. Ships `signedOff:false`; the mother's
// packet (D-10) decides rewrite-vs-gate per card.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('every LIVE baa-unit card uses only learned letters (alif+baa) — '
      'QP-07 / D-12', () {
    final exercises =
        (_loadJson('assets/curriculum/exercises.json')['exercises'] as List)
            .cast<Map<String, dynamic>>();
    final letters =
        (_loadJson('assets/curriculum/letters.json')['letters'] as List)
            .cast<Map<String, dynamic>>();
    final liveNodeIds =
        (_loadJson('assets/curriculum/curriculum_graph.json')['nodes'] as List)
            .cast<Map<String, dynamic>>()
            .map((n) => n['exerciseId'] as String)
            .toSet();

    // Rank every letter by its pedagogical intro order (A2 — alif=1, baa=2 …).
    final introOrder = <String, int>{
      for (final l in letters)
        l['id'] as String: (l['introOrder'] as num).toInt(),
    };

    // The baa unit teaches through introOrder 2 → learned = {alif, baa}.
    const unitLetter = 'baa';
    final unitIntroOrder = introOrder[unitLetter]!; // 2
    final learned = introOrder.entries
        .where((e) => e.value <= unitIntroOrder)
        .map((e) => e.key)
        .toSet();
    expect(learned, containsAll(<String>['alif', 'baa']),
        reason: 'the baa unit learned-set must include alif + baa');
    expect(learned, isNot(contains('taa')),
        reason: 'taa (introOrder 3) is not yet learned at the baa unit');

    // Only LIVE baa-unit graph nodes are linted. A card GATED to a later unit
    // (D-19: removed from curriculum_graph.json) is out of scope, exactly as a
    // rewritten card (letters ⊆ learned) becomes compliant.
    final unitCards = exercises.where((e) {
      final id = e['id'] as String;
      return id.startsWith('$unitLetter.') && liveNodeIds.contains(id);
    }).toList();

    // Non-vacuity: the baa unit must actually have live cards to lint.
    expect(unitCards, isNotEmpty,
        reason: 'the baa unit must have ≥1 live graph node to lint');

    final violations = <String, List<String>>{};
    for (final e in unitCards) {
      final cardLetters =
          ((e['letters'] as List<dynamic>?) ?? const []).cast<String>();
      final unlearned = cardLetters
          .where((l) => (introOrder[l] ?? 1 << 30) > unitIntroOrder)
          .toList();
      if (unlearned.isNotEmpty) violations[e['id'] as String] = unlearned;
    }

    expect(violations, isEmpty,
        reason: 'these live baa-unit cards demand letters not yet learned '
            '(introOrder > $unitIntroOrder). Each must be REWRITTEN to alif+baa '
            'or GATED out of the baa graph (D-09 / D-19) by 19-05: $violations');
  });
}
