// Phase 19-01 (Wave 0) — QP-07 / D-12 RED contract: the learned-letters lint.
// EXTENDED for quick task 260718-il4 (Stage 1 all-letters-live) to cover EVERY
// live letter unit, not just baa. COLLAPSED for Phase 25-03 (D-04/D-05): the
// two-way `signedOff` dispatch is gone — every live letter is now held to the
// seen-letters bar identically.
//
// D-12 (locked, THE authoring rule Phases 20–21 inherit): a unit's cards may use
// only letters introduced up to and including that unit. A unit's learned set is
// {letters with introOrder ≤ that unit's introOrder} (letters.json `introOrder` —
// the app's pedagogical lesson order, A2, NOT the classical ابجد list). Every LIVE
// unit card's `letters` array must be a subset of the learned set.
//
// ONE DISPOSITION for every live letter (D-04/D-05, Phase 25-03):
//   • The draft exemption is REMOVED. `signedOff` no longer controls enforcement.
//     baa, taa, thaa, alif — signed or not — all run the SAME violation assertion:
//     any live card demanding an unlearned letter that is NOT owner-approved FAILS
//     the build.
//   • `signedOff` now means ONLY "the mother has confirmed THIS content." A letter
//     can be legal-and-enforced while `signedOff:false` (e.g. taa, thaa). The flag is
//     HUMAN sign-off, never an enforcement switch — verified decoupled from lib/
//     (no code reads it as an enforcement gate; see 25-03-SUMMARY grep proof).
//
// OWNER-APPROVED EXCEPTIONS (mother-approval PENDING — the Phase-25 packet rules on
// each): a small, explicit, provenance-tagged allowlist of reach-ahead cards kept
// LIVE by owner decision until the mother confirms / rejects / re-points them. This
// is the EXACT set validate.py's `OWNER_APPROVED_EXCEPTIONS` exempts, so all four
// wall layers refuse the same content:
//   • D-09 — 4 baa cards, owner-approved from DEVICE UAT (2026-07-18).
//   • D-16 — 18 taa/thaa word cards, kept live by OWNER DECISION (2026-07-19,
//     "the app is built for kids that know Arabic"); re-point is impossible (0 legal
//     learned-set words unlock at units 3/4) and REMOVE would gut both units.
// Anything OUTSIDE this allowlist that reaches ahead FAILS. Every allowlisted id must
// be a live node (the "no rot" check) so a stale exception can't silently linger.
//
// COVERAGE (260718-il4): every discovered per-letter graph asset (graphs/*.json +
// the baa curriculum_graph.json) MUST be visited by this lint — the guard against
// the exact "a new letter slips through unlinted" failure the owner directive names.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// A live unit graph the lint scopes over: its letterId, its live node ids, and its
/// `signedOff` flag. Since Phase 25-03, `signedOff` is parsed for provenance only —
/// it NO LONGER drives enforcement (D-04/D-05); every live letter is enforced.
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
      '(enforced for EVERY letter regardless of signedOff; owner-approved '
      'exceptions allowlisted; full coverage)', () {
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

    // ── Owner-approved, MOTHER-APPROVAL-PENDING reach-ahead exceptions ──
    // The EXACT set validate.py exempts (OWNER_APPROVED_EXCEPTIONS = the union of
    // both provenance groups below), scoped here per unit so the "no rot" liveness
    // check can hold each id to its own graph. Two provenance groups, kept distinct
    // so the Phase-25 packet (Plan 25-06) can rule on each separately.

    // D-09 — the 4 baa cards were owner-approved from DEVICE UAT (2026-07-18), then
    // made DORMANT 2026-07-20 (quick task 260720-up4): their NODES were removed from
    // the baa graph so they are no longer LIVE, and the "no rot" liveness check below
    // (every allowlisted id must be a live node) would FAIL if they stayed listed.
    // Emptying this set is what keeps the lint green alongside the node removal. This
    // REVERSES the mother's F1 verdict for these ids, PENDING her re-confirmation
    // packet. Any live baa card demanding unlearned letters still fails.
    const baaOwnerApprovedExceptions = <String>{};

    // D-16 — the taa reach-ahead word cards (unit 3, introOrder 3) were owner-approved
    // (2026-07-19), then made DORMANT 2026-07-20 (quick task 260720-wcs, F2-INTERIM —
    // supersedes D-16): the mother ruled they must become letter-FORM practice she has
    // not yet authored, so their NODES were removed from taa.json (taa goes 17->7
    // all-essential form nodes). They are no longer LIVE nodes, so the "no rot" liveness
    // check below (every allowlisted id must be a live node) would FAIL if they stayed
    // listed. Emptying this set is what keeps the lint green alongside the node removal
    // and collapses the allowlist toward ZERO. PENDING the mother's re-confirmation packet.
    const taaOwnerApprovedExceptions = <String>{};

    // D-16 — the thaa reach-ahead word cards (unit 4, introOrder 4), same F2-INTERIM
    // dormancy as the taa set (owner 2026-07-20, quick task 260720-wcs). Their nodes were
    // removed from thaa.json (thaa goes 17->7 all-essential form nodes); emptying this set
    // keeps the "no rot" check consistent. PENDING the mother's re-confirmation packet.
    const thaaOwnerApprovedExceptions = <String>{};

    // Per-unit allowlist. alif carries NO exceptions (letter-level, all legal).
    const ownerApprovedExceptions = <String, Set<String>>{
      'baa': baaOwnerApprovedExceptions,
      'taa': taaOwnerApprovedExceptions,
      'thaa': thaaOwnerApprovedExceptions,
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

      // NON-VACUITY: a live unit must actually have cards.
      expect(unitCards, isNotEmpty,
          reason: '${unit.letterId} unit must have ≥1 live graph node to lint');

      // ── ENFORCED for EVERY live letter (D-04/D-05) — one path, no dispatch. ──
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
      final exceptions =
          ownerApprovedExceptions[unit.letterId] ?? const <String>{};
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

    // ── PARITY (the four-layer wall) — the Dart predicate must flag the SAME
    // reach-ahead that validate.py's does. A crafted {letters:['taa']} card placed
    // at the baa unit (introOrder 2) must report taa (introOrder 3) as unlearned.
    // This is behavioral parity with
    //   tools/content/validate.py::unlearned_letters_for_exercise
    // which reads the STORED letters[] against introOrder with the identical
    // `introOrder[l] ?? 1<<30` reach-ahead sentinel (validate.py _UNLEARNED_SENTINEL
    // = 1<<30). If this ever diverges, the bundle lint (L1) and the seeder (L2)
    // could refuse DIFFERENT content — the wall's whole thesis is that all four
    // layers refuse identically. The crafted id is not a live graph node, so it
    // never touches the enforcement loop above; it exercises `unlearnedFor` directly.
    exercisesById['__parity.taaAtBaa__'] = <String, dynamic>{
      'id': '__parity.taaAtBaa__',
      'letters': <String>['taa'],
    };
    expect(unlearnedFor('__parity.taaAtBaa__', introOrder['baa']!),
        equals(<String>['taa']),
        reason: 'unlearnedFor must flag taa (introOrder 3) as reach-ahead at the '
            'baa unit (introOrder 2) — behavioral parity with '
            'validate.py::unlearned_letters_for_exercise');
  });
}
