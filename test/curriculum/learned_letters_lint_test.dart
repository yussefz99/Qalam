// Phase 19-01 (Wave 0) — QP-07 / D-12 RED contract: the learned-letters lint.
// EXTENDED for quick task 260718-il4 (Stage 1 all-letters-live) to cover EVERY
// live letter unit, not just baa — so a newly promoted letter can never slip
// through unlinted.
//
// D-12 (locked, THE authoring rule Phases 20–21 inherit): a unit's cards may use
// only letters introduced up to and including that unit. A unit's learned set is
// {letters with introOrder ≤ that unit's introOrder} (letters.json `introOrder` —
// the app's pedagogical lesson order, A2, NOT the classical ابجد list). Every LIVE
// unit card's `letters` array must be a subset of the learned set.
//
// TWO DISPOSITIONS by the graph's `signedOff` flag (owner-locked, 260718-il4):
//   • signedOff:true  (baa) — ENFORCED. The tuned subset rule + the owner-approved
//     exception allowlist stand exactly as-is. Any live card demanding an unlearned
//     letter that is NOT owner-approved FAILS the build. (Do not weaken baa.)
//   • signedOff:false (thaa, and future draft-promoted letters) — ACKNOWLEDGED, not
//     enforced. The content is pending the mother's review (18.1 packets), so it is
//     NOT yet held to the learned-letters bar. We assert only NON-VACUITY (≥1 live
//     node) and SURFACE the reaching-ahead cards via `printOnFailure` — an explicit,
//     documented acknowledgement, NOT a build failure and NOT a silent skip. When
//     the mother signs the letter, its graph flips signedOff:true and it
//     auto-enforces here with zero test edits.
//
// COVERAGE (260718-il4): every discovered per-letter graph asset (graphs/*.json +
// the baa curriculum_graph.json) MUST be visited by this lint — the guard against
// the exact "a new letter slips through unlinted" failure the owner directive names.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// A live unit graph the lint scopes over: its letterId, its live node ids, and
/// whether the owner-mother has signed it (drives enforced-vs-acknowledged).
class _UnitGraph {
  _UnitGraph({
    required this.letterId,
    required this.signedOff,
    required this.liveNodeIds,
    required this.sourcePath,
  });
  final String letterId;
  final bool signedOff;
  final Set<String> liveNodeIds;
  final String sourcePath;
}

/// Enumerate every LIVE unit graph: the baa `curriculum_graph.json` (kept for the
/// server this stage) + every per-letter `graphs/<letter>.json`. graphs/baa.json
/// is a byte-parity copy of curriculum_graph.json (parity-guarded separately), so
/// baa is deduped to the single canonical source here.
List<_UnitGraph> _discoverUnitGraphs() {
  final graphs = <String, _UnitGraph>{};

  void add(String path) {
    final g = _loadJson(path);
    final letterId = g['letterId'] as String;
    final signedOff = (g['signedOff'] as bool?) ?? false;
    final nodeIds = (g['nodes'] as List)
        .cast<Map<String, dynamic>>()
        .map((n) => n['exerciseId'] as String)
        .toSet();
    // Prefer the canonical curriculum_graph.json for baa (the server's source);
    // its byte-parity graphs/baa.json copy is deduped away.
    graphs.putIfAbsent(
      letterId,
      () => _UnitGraph(
        letterId: letterId,
        signedOff: signedOff,
        liveNodeIds: nodeIds,
        sourcePath: path,
      ),
    );
  }

  // 1) The canonical baa graph the server + this lint's baa leg read.
  add('assets/curriculum/curriculum_graph.json');
  // 2) Every per-letter graph asset (graphs/*.json). baa is deduped to (1).
  final graphsDir = Directory('assets/curriculum/graphs');
  final files = graphsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    add(f.path);
  }
  return graphs.values.toList();
}

void main() {
  test('every LIVE unit card obeys the learned-letters bar — QP-07 / D-12 '
      '(enforced when signed, acknowledged when unsigned; full coverage)', () {
    final exercises =
        (_loadJson('assets/curriculum/exercises.json')['exercises'] as List)
            .cast<Map<String, dynamic>>();
    final exercisesById = {for (final e in exercises) e['id'] as String: e};
    final letters =
        (_loadJson('assets/curriculum/letters.json')['letters'] as List)
            .cast<Map<String, dynamic>>();

    // Rank every letter by its pedagogical intro order (A2 — alif=1, baa=2 …).
    final introOrder = <String, int>{
      for (final l in letters)
        l['id'] as String: (l['introOrder'] as num).toInt(),
    };

    // Owner-approved exceptions for the SIGNED baa unit (device UAT, 2026-07-18):
    // these cards were gated by 19-05 (D-19) and RESTORED by explicit owner
    // decision — judged "perfect and really impressive" on device; the reworked
    // presentation carries the unlearned letters. Exact allowlist; any OTHER live
    // baa card demanding unlearned letters still fails.
    // 2026-07-19: both buildSentence cards REMOVED from the live unit (owner
    // device decision — empty-canvas surface + sentence letters far beyond baa),
    // so their allowlist entries are gone too; 4 exceptions remain.
    const baaOwnerApprovedExceptions = <String>{
      'baa.fillBlank.adjective',
      'baa.transformWord.dual',
      'baa.transformWord.plural',
      'baa.transformWord.opposite',
    };

    List<String> unlearnedFor(String id, int unitIntroOrder) {
      final e = exercisesById[id];
      if (e == null) return const [];
      final cardLetters =
          ((e['letters'] as List<dynamic>?) ?? const []).cast<String>();
      return cardLetters
          .where((l) => (introOrder[l] ?? 1 << 30) > unitIntroOrder)
          .toList();
    }

    final discovered = _discoverUnitGraphs();
    expect(discovered, isNotEmpty,
        reason: 'no live unit graphs discovered — the lint would vacuously pass');

    final visited = <String>{};

    for (final unit in discovered) {
      visited.add(unit.letterId);
      final unitIntroOrder = introOrder[unit.letterId];
      expect(unitIntroOrder, isNotNull,
          reason: '${unit.letterId} has no introOrder in letters.json');

      // The unit's live cards (live graph node ⇒ its exercises.json entry).
      final unitCards =
          unit.liveNodeIds.where(exercisesById.containsKey).toList()..sort();

      // NON-VACUITY (both dispositions): a live unit must actually have cards.
      expect(unitCards, isNotEmpty,
          reason: '${unit.letterId} unit must have ≥1 live graph node to lint');

      if (unit.signedOff) {
        // ── ENFORCED (signed) — the tuned baa assertion, unchanged. ──
        final learned = introOrder.entries
            .where((e) => e.value <= unitIntroOrder!)
            .map((e) => e.key)
            .toSet();
        // Baa-specific sanity pins preserved from the original contract.
        if (unit.letterId == 'baa') {
          expect(learned, containsAll(<String>['alif', 'baa']),
              reason: 'the baa unit learned-set must include alif + baa');
          expect(learned, isNot(contains('taa')),
              reason: 'taa (introOrder 3) is not yet learned at the baa unit');
        }
        final exceptions = unit.letterId == 'baa'
            ? baaOwnerApprovedExceptions
            : const <String>{};
        final violations = <String, List<String>>{};
        for (final id in unitCards) {
          if (exceptions.contains(id)) continue;
          final unlearned = unlearnedFor(id, unitIntroOrder!);
          if (unlearned.isNotEmpty) violations[id] = unlearned;
        }
        expect(violations, isEmpty,
            reason: 'these live ${unit.letterId}-unit cards demand letters not '
                'yet learned (introOrder > $unitIntroOrder) and are NOT '
                'owner-approved. Each must be REWRITTEN to learned letters, GATED '
                'out of the graph, or explicitly owner-approved: $violations');
        // The exception list must not rot: every listed id is a live node.
        for (final id in exceptions) {
          expect(unit.liveNodeIds, contains(id),
              reason: 'owner-approved exception $id is no longer a live node — '
                  'remove it from the exception list');
        }
      } else {
        // ── ACKNOWLEDGED (unsigned) — surface reaching-ahead, never fail. ──
        // The content is pending the mother's review (18.1 packet); it is not yet
        // held to the bar. Surface any reaching-ahead card as a documented
        // acknowledgement so the mother's packet lists exactly which cards demand
        // letters beyond this unit's learned set. NOT a failure, NOT a silent skip.
        final reachingAhead = <String, List<String>>{};
        for (final id in unitCards) {
          final unlearned = unlearnedFor(id, unitIntroOrder!);
          if (unlearned.isNotEmpty) reachingAhead[id] = unlearned;
        }
        if (reachingAhead.isEmpty) {
          printOnFailure('[learned-letters] ${unit.letterId} '
              '(signedOff:false): all live cards within learned set '
              '(introOrder ≤ $unitIntroOrder).');
        } else {
          printOnFailure('[learned-letters] ${unit.letterId} '
              '(signedOff:false, ACKNOWLEDGED — mother\'s packet review): '
              '${reachingAhead.length} reaching-ahead card(s) demand letters '
              'beyond introOrder $unitIntroOrder — $reachingAhead. These stay '
              'LIVE with an owner-approved-style exception until the mother '
              'signs the letter (then it auto-enforces).');
        }
      }
    }

    // ── COVERAGE (260718-il4): every discovered graph asset was visited. ──
    final discoveredLetters = discovered.map((u) => u.letterId).toSet();
    expect(visited, equals(discoveredLetters),
        reason: 'a live unit graph was discovered but not linted — a newly '
            'promoted letter must never slip through unlinted. Discovered: '
            '$discoveredLetters, visited: $visited');
    // Explicitly assert the two Stage-1 live letters are both covered.
    expect(visited, containsAll(<String>['baa', 'thaa']),
        reason: 'both live Stage-1 letters (baa signed, thaa unsigned) must be '
            'covered by this lint');
  });
}
