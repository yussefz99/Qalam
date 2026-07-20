// Phase 25-05 (L3) — the seen-letters predicate PARITY pin.
//
// The whole seen-letters wall's thesis is that all FOUR layers refuse the SAME
// thing and exempt the SAME thing. This pure unit test pins the Dart runtime
// predicate ([SeenLettersFilter.unlearnedFor] / [isSeenLegal]) + the exemption set
// ([kApprovedReachAheadExceptions]) to the exact rule the L1 lint enforces
// (learned_letters_lint_test.dart `unlearnedFor` + `baaOwnerApprovedExceptions`)
// and the L2 seeder / L0 audit enforce (tools/content/validate.py
// `unlearned_letters_for_exercise` + `OWNER_APPROVED_EXCEPTIONS`) — an
// advisory-4 drift guard: if L3 ever disagrees with L1/L2 this test goes red.
//
// PURE test: reads the bundled content off disk (File, not rootBundle) and builds
// the predicate from the SAME letters.json / exercises.json the app ships. No
// widgets, no Firebase, no network.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:qalam/tutor/exercise_selector_provider.dart';

Map<String, Object?> _json(String path) =>
    json.decode(File(path).readAsStringSync()) as Map<String, Object?>;

void main() {
  // The learned-set filter for the BAA unit (introOrder 2 → learned = {alif, baa}),
  // built from the REAL bundled content (not a fixture).
  final baaFilter = SeenLettersFilter.fromAssets(
    letterId: 'baa',
    lettersJson: _json('assets/curriculum/letters.json'),
    exercisesJson: _json('assets/curriculum/exercises.json'),
  );

  group('L3 seen-letters predicate parity (Plan 25-05 / QP-07 / D-12)', () {
    test('a reach-ahead NON-exception id is DROPPED (isSeenLegal == false)', () {
      // taa.traceLetter.isolated demands taa (introOrder 3) — it reaches ahead for
      // a baa unit (introOrder 2) and is NOT an owner-approved exception.
      expect(baaFilter.unlearnedFor('taa.traceLetter.isolated'), contains('taa'),
          reason: 'taa reaches ahead of the baa learned set');
      expect(baaFilter.isSeenLegal('taa.traceLetter.isolated'), isFalse,
          reason: 'a reach-ahead non-exception card must be dropped by L3');
    });

    test('a within-learned-set id is KEPT (isSeenLegal == true)', () {
      // baa.traceLetter.isolated demands [baa] — within the learned set.
      expect(baaFilter.unlearnedFor('baa.traceLetter.isolated'), isEmpty);
      expect(baaFilter.isSeenLegal('baa.traceLetter.isolated'), isTrue);
      // baa.connectWord.baab demands [baa, alif] — both learned at the baa unit.
      expect(baaFilter.unlearnedFor('baa.connectWord.baab'), isEmpty);
      expect(baaFilter.isSeenLegal('baa.connectWord.baab'), isTrue);
    });

    test('an id with no known letters[] reads as legal (matches L1 unknown-id)', () {
      // The lint returns `const []` for an unknown id; the runtime filter must too
      // (never drop what it cannot evaluate — L0/L1/L2 gate authoring/seeding).
      expect(baaFilter.unlearnedFor('does.not.exist'), isEmpty);
      expect(baaFilter.isSeenLegal('does.not.exist'), isTrue);
    });

    // The former 'each of the 4 D-09 baa exceptions is KEPT' test was REMOVED
    // 2026-07-20 (quick task 260720-up4): those 4 baa reach-ahead grammar cards were
    // made DORMANT (nodes removed from the baa graph; ids removed from every
    // allowlist), so they are no longer owner-approved exceptions — they are simply
    // gone from the live surface. The taa/thaa D-16 ids followed on 2026-07-20 (quick
    // task 260720-wcs, F2-INTERIM): their nodes were removed too, so the allowlist is
    // now EMPTY across all four layers.

    test(
        'kApprovedReachAheadExceptions is EMPTY — all reach-ahead now refused '
        '(F2-interim, L0/L1/L2 parity)', () {
      // The exact union tools/content/validate.py exposes as
      // OWNER_APPROVED_EXCEPTIONS is now EMPTY (_BAA_D09_EXCEPTIONS is empty |
      // _TAA_THAA_D16_EXCEPTIONS is empty), because both the baa (260720-up4) and the
      // taa/thaa (260720-wcs, F2-interim) reach-ahead cards were made DORMANT (nodes
      // removed from the graphs). With the allowlist empty, ANY reach-ahead card is
      // refused by every wall layer by design. If L3 ever drifts from this empty set, a
      // reach-ahead card could silently slip through at runtime.
      const expected = <String>{};
      expect(kApprovedReachAheadExceptions, hasLength(0));
      expect(kApprovedReachAheadExceptions, equals(expected));
    });
  });
}
