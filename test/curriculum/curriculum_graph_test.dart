// DYN-01 / DYN-02 — CurriculumGraph parses the signed baa asset.
//
// History: authored RED at Wave 0 (Plan 15-01) against the PROVISIONAL asset
// (signedOff:false); turned green by Plan 15-03's pure-Dart CurriculumGraph parser
// (essentialNodes filter, tierOf / nextForward / remediateOneTier helpers, signedOff getter).
//
// Plan 15-07 (the owner-mother sign-off gate, 2026-06-28) flipped
// assets/curriculum/curriculum_graph.json signedOff:false → true. The signedOff assertion
// below now pins the SIGNED reality (D-05) — it tracks the asset, not a frozen draft value.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// RED: lib/curriculum/curriculum_graph.dart does not exist yet (Plan 15-03 writes it).
import 'package:qalam/curriculum/curriculum_graph.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The graph as authored in Plan 15-01 — parsed straight off disk (no rootBundle so the
  // test stays hermetic; the production loader reads the same bytes via rootBundle).
  Map<String, Object?> rawGraph() {
    final file = File('assets/curriculum/curriculum_graph.json');
    return json.decode(file.readAsStringSync()) as Map<String, Object?>;
  }

  test('CurriculumGraph parses the baa asset (14 baa.* nodes: all-essential core, '
      'the 4 grammar reach-ahead cards made dormant 2026-07-20)', () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    expect(graph.letterId, 'baa');
    expect(graph.signedOff, isTrue,
        reason: 'owner-mother signed the graph at the tier level (D-05); Plan 15-07 flipped it. '
            'Node adds/removes do NOT touch her tier-structure sign-off — new/rewritten '
            'CONTENT is signedOff:false at the exercise level.');
    // Node history: 14 core (recognize/positionalForms/copyWrite, incl.
    // traceLetter.final) + 4 restored grammar cards (fillBlank.adjective +
    // transformWord.{dual,plural,opposite}); micro-drills + both buildSentence
    // cards already out. Quick task 260720-up4 (owner 2026-07-20): the 4 grammar
    // reach-ahead cards are made DORMANT — their nodes removed — so the
    // never-passable enrichment tail can no longer block the star ("baa never
    // advances"). Net: 14 nodes, all essential. Reverses the mother's F1 verdict
    // for these ids, pending her re-confirmation packet.
    expect(graph.nodes.length, 14,
        reason: '14 core baa.* nodes (incl. traceLetter.final); the 4 grammar '
            'reach-ahead cards made dormant (260720-up4); micro-drills + '
            'buildSentence already out');
    final microDrills =
        graph.nodes.where((n) => n.competency == 'microDrill').toList();
    expect(microDrills, isEmpty,
        reason: 'micro-drills are OUT of the live graph (owner device UAT 2026-07-18; '
            're-add nodes + competency to restore)');
    final enrichment = graph.nodes.where((n) => !n.essential).toList();
    expect(enrichment, isEmpty,
        reason: 'the 4 wordBuilding/grammarTransform enrichment nodes were made '
            'dormant (260720-up4) — baa is now an all-essential core; re-add their '
            'nodes to restore (the empty competency declarations are retained)');
    expect(
      graph.nodes.every((n) => n.exerciseId.startsWith('baa.')),
      isTrue,
      reason: 'baa-only — no ت/ث nodes (D-11)',
    );
  });

  test('essentialNodes filters to essential competencies only (the 70/30 split)', () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    // Every essentialNode belongs to an essential competency.
    final essentialCompetencyIds = graph.competencies
        .where((c) => c.essential)
        .map((c) => c.id)
        .toSet();
    expect(essentialCompetencyIds, isNotEmpty);
    for (final node in graph.essentialNodes) {
      expect(essentialCompetencyIds.contains(node.competency), isTrue,
          reason: 'an essentialNode must belong to an essential competency');
    }
    // The FILTER excludes any enrichment (non-essential) node. baa currently
    // carries NONE (the 4 wordBuilding/grammarTransform nodes were made dormant
    // 2026-07-20, quick task 260720-up4), so essentialNodes == nodes here — the
    // filter includes everything BECAUSE everything is essential. Assert the
    // filter never returns a non-essential node (the actual invariant), and that
    // the parser still tolerates the retained node-less enrichment competencies.
    expect(graph.essentialNodes.every((n) => n.essential), isTrue,
        reason: 'the essentialNodes filter must never return a non-essential node');
    expect(graph.essentialNodes.length, graph.nodes.length,
        reason: 'baa is all-essential after the 260720-up4 dormancy — every live '
            'node gates the star; no enrichment tail remains');
    expect(
      graph.competencies.map((c) => c.id),
      containsAll(<String>['wordBuilding', 'grammarTransform']),
      reason: 'the now node-less enrichment competency declarations are retained '
          '(parser-tolerated) so restoring the cards is a data-only change',
    );
  });

  test('tierOf is non-null only for إملاء writing nodes; recognize/trace are null', () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    // The trace nodes carry no tier (not the إملاء ramp).
    expect(graph.tierOf('baa.traceLetter.isolated'), isNull);
    // The dictation node sits at the hardest tier.
    expect(graph.tierOf('baa.writeWord.dictation'), 'ghayrManzur');
  });

  test('nextForward / remediateOneTier helpers are exposed for the walker', () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    // From the manqul→manzur→ghayrManzur ramp, remediating dictation steps down a tier.
    final remediated = graph.remediateOneTier('baa.writeWord.dictation');
    expect(remediated, isNotNull,
        reason: 'a ghayrManzur node must remediate down one tier (Pitfall 3 lattice)');
    // nextForward advances the chain (a non-null next node id from the start of the graph).
    expect(graph.nextForward('baa.teachCard.meet'), isNotNull);
  });
}
