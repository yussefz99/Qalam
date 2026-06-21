// THROWAWAY SPIKE GUARD (Phase 11 — GenUI/native-canvas kill-shot).
//
// Enforces Success Criterion 4 (SC-4) and the TUTOR-01 invariant as an
// executable test: the spike is ADDITIVE + imports-only, so it MUST NOT modify
// any durable layer. This guard runs `git diff --quiet HEAD --` over the five
// SACRED paths and asserts an empty diff (exit 0). If any committed durable file
// drifts from HEAD, the diff is non-empty, git exits 1, and this test goes RED —
// the build refuses to pretend the spike stayed in its lane.
//
// The sacred paths (D-09/D-10):
//   • lib/features/practice/widgets/stroke_canvas.dart  (the canvas under test)
//   • lib/features/letter_unit/                          (exercise UI)
//   • lib/core/scoring/                                  (the scorer)
//   • lib/core/exercise_engine/                          (the engine)
//   • assets/curriculum/                                 (signed-off curriculum)
//
// Imports/modifies no durable file. This test file itself lives under
// test/spike_genui/ (additive).
//
// NOTE on semantics: `git diff HEAD --` reports changes in the WORKING TREE and
// INDEX relative to the last commit. Because the spike commits its own additive
// files (under lib/spike_genui/ + test/spike_genui/) and never the sacred paths,
// a clean run means "no sacred file was edited since the last commit." Combined
// with the additive-only construction, the durable layers are provably untouched.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const sacredPaths = <String>[
    'lib/features/practice/widgets/stroke_canvas.dart',
    'lib/features/letter_unit/',
    'lib/core/scoring/',
    'lib/core/exercise_engine/',
    'assets/curriculum/',
  ];

  test('git is available (the guard needs it to inspect durable diffs)', () {
    final result = Process.runSync('git', ['rev-parse', '--is-inside-work-tree']);
    expect(result.exitCode, 0,
        reason: 'this guard must run inside a git work tree; '
            'stderr: ${result.stderr}');
  });

  test('SC-4: durable layers are unchanged (empty git diff over sacred paths)',
      () {
    // `--quiet` makes git exit 1 on any difference (and 0 on none) without
    // printing the diff. `HEAD --` scopes the comparison to the committed tree.
    final result = Process.runSync(
      'git',
      <String>['diff', '--quiet', 'HEAD', '--', ...sacredPaths],
    );

    if (result.exitCode != 0) {
      // Surface WHICH paths drifted for a readable failure.
      final names = Process.runSync(
        'git',
        <String>['diff', '--name-only', 'HEAD', '--', ...sacredPaths],
      );
      fail('SC-4 VIOLATION — a durable layer was modified by the spike.\n'
          'Changed durable files:\n${names.stdout}\n'
          'The spike must be additive + imports-only; revert any edit to:\n'
          '${sacredPaths.join('\n')}');
    }

    expect(result.exitCode, 0,
        reason: 'durable layers must be byte-for-byte unchanged (SC-4 / TUTOR-01)');
  });
}
