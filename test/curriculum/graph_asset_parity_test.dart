// Quick task 260718-il4 (Stage 1 all-letters-live) — the baa graph-duplication
// DRIFT GUARD.
//
// Stage 1 intentionally duplicates the baa curriculum graph:
//   • `assets/curriculum/curriculum_graph.json` — read by the SERVER's
//     generate.py and the baa learned-letters lint (STAYS PUT this stage).
//   • `assets/curriculum/graphs/baa.json` — the per-letter copy the Flutter
//     provider (`curriculumGraphProvider('baa')`) now loads.
//
// The two MUST stay identical until Stage 2 unifies the server onto the
// per-letter scheme. This test is that guarantee: any edit to one that is not
// mirrored into the other fails here, before it can silently diverge the app
// from the server.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Object? _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync());

void main() {
  test('graphs/baa.json is a byte-parity copy of curriculum_graph.json '
      '(the Stage-1 duplication drift guard)', () {
    final canonical = _loadJson('assets/curriculum/curriculum_graph.json');
    final perLetter = _loadJson('assets/curriculum/graphs/baa.json');

    // JSON-decoded deep equality: the provider's per-letter baa graph must be
    // the SAME graph the server + baa lint read, so the app and server never
    // rail on divergent baa content until Stage 2 unifies them.
    expect(perLetter, equals(canonical),
        reason: 'graphs/baa.json must deep-equal curriculum_graph.json. If you '
            'edited one, mirror the change into the other (or re-run '
            '`python3 -m content.promote_letter --migrate-baa`) until Stage 2 '
            'unifies the server onto the per-letter scheme.');
  });
}
