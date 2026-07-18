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

  test('CurriculumGraph parses the baa asset (17 baa.* nodes: 14 core + 3 restored microDrills, 6 gated cards removed)',
      () {
    final graph = CurriculumGraph.fromJson(rawGraph());

    expect(graph.letterId, 'baa');
    expect(graph.signedOff, isTrue,
        reason: 'owner-mother signed the graph at the tier level (D-05); Plan 15-07 flipped it. '
            'Plan 19-05 (D-18 restore / D-19 gate) adds/removes nodes but does NOT touch her '
            'tier-structure sign-off — new/rewritten CONTENT is signedOff:false at the exercise level.');
    // Owner device-UAT decisions (2026-07-18) reversed both 19-05 graph moves:
    //   • micro-drills are REMOVED again (they interrupted the unit flow on device;
    //     policy stays pinned in microdrill_selection_test.dart via fixture injection);
    //   • the 6 gated cards are RESTORED — the owner judged them "perfect" on device;
    //     they carry an owner-approved exception in learned_letters_lint_test.dart.
    // Net: the original 20 live nodes (14 core incl. traceLetter.final + 6 restored), no drills.
    // MINUS the 2 buildSentence nodes (owner device decision 2026-07-19: the
    // sentence surface presents an empty canvas with nothing to work from, and
    // the sentences demand letters far beyond baa — removed from unit + graph;
    // the mother re-confirms alongside the demo-weight rep counts). Net: 18.
    expect(graph.nodes.length, 18,
        reason: '14 core baa.* nodes (incl. traceLetter.final) + 4 of the 6 '
            'owner-restored cards (both buildSentence cards removed 2026-07-19); '
            'micro-drills removed (owner device UAT 2026-07-18)');
    final microDrills =
        graph.nodes.where((n) => n.competency == 'microDrill').toList();
    expect(microDrills, isEmpty,
        reason: 'micro-drills are OUT of the live graph (owner device UAT 2026-07-18; '
            're-add nodes + competency to restore)');
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
    // Enrichment nodes (wordBuilding / grammarTransform) are excluded.
    expect(
      graph.essentialNodes.length < graph.nodes.length,
      isTrue,
      reason: 'enrichment nodes must NOT count as essential (70/30 split)',
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
