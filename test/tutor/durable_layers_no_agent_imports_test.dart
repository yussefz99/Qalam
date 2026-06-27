// TUTOR-04 / ADR-014 §4 — the durable v1 layers carry ZERO agent/framework/
// network imports (Plan 14-04 Task 2).
//
// "Durable v1 layers carry ZERO firebase_ai/genui/flutter_gemma imports" (ADR-014
// §4). The scorer, the practice canvas, and the curriculum model/data are the
// product's permanent spine; the capable tutor is a swappable seam BESIDE them.
// This static-scan guard fails the build if any of those layers ever takes an
// agent (firebase_ai/genui/flutter_gemma/langgraph), network (http), or
// tutor-seam (remote_agent_brain / json_schema_builder spike) dependency — the
// seam must stay one-directional (the tutor reads FACTS; the durable layers never
// reach into the tutor).
//
// Comment lines are stripped before scanning so a doc-comment that NAMES a
// forbidden package (header prose like this very file) cannot self-trip the gate.
//
// Pure Dart: reads source files off disk + scans strings. No Firebase, no
// network, no model.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The durable v1 layer globs (ADR-014 §4 / the plan's acceptance criteria):
///   • lib/core         — the scorer + exercise engine + recognition.
///   • lib/features/practice — the StrokeCanvas + practice widgets.
///   • lib/models       — the curriculum content models.
///   • lib/data         — the curriculum repository + codecs.
///   • lib/curriculum   — the pure-Dart graph parser + offline walker + the
///                        on-device mastery condition (Plan 15-03). These drive
///                        offline selection + the star ON-DEVICE; they must stay
///                        equally free of agent/cloud/network/render imports so
///                        the star is never granted off a server response (D-06,
///                        ADR-014 trust boundary).
const _durableDirs = <String>[
  'lib/core',
  'lib/features/practice',
  'lib/models',
  'lib/data',
  'lib/curriculum',
];

/// The forbidden import tokens. An import line containing any of these in a
/// durable file fails the build. `cloud_firestore`/`drift`/`flutter` are NOT
/// forbidden — `lib/data` legitimately persists curriculum/progress; the ban is
/// specifically on AGENT, on-device-model, NETWORK, and tutor-seam deps.
const _forbidden = <String>[
  'firebase_ai',
  'genui',
  'flutter_gemma',
  'langgraph',
  'package:http/', // the REST client — the tutor seam owns network, not the spine
  'package:http.dart',
  'tutor/remote_agent_brain.dart', // the tutor seam must not be imported BY the spine
  'json_schema_builder', // the structured-output spike
];

/// Every `.dart` source file under [dir] (recursively).
List<File> _dartFiles(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

/// The non-comment lines of [file] — strips `//` and `///` line comments so a
/// doc-comment that names a forbidden package does not self-trip the gate.
List<String> _codeLines(File file) {
  return file
      .readAsLinesSync()
      .where((l) {
        final t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .toList();
}

void main() {
  group('TUTOR-04 — durable v1 layers carry zero agent/framework/network imports',
      () {
    test('every durable .dart file imports no forbidden package', () {
      final offenders = <String>[];
      var scanned = 0;

      for (final dir in _durableDirs) {
        for (final file in _dartFiles(dir)) {
          scanned++;
          for (final line in _codeLines(file)) {
            if (!line.contains('import')) continue;
            for (final bad in _forbidden) {
              if (line.contains(bad)) {
                offenders.add('${file.path}: $bad  ->  ${line.trim()}');
              }
            }
          }
        }
      }

      // Sanity: the globs actually resolved to source files (a typo'd glob that
      // matched nothing would otherwise pass vacuously).
      expect(scanned, greaterThan(0),
          reason: 'no durable .dart files were scanned — check the globs');

      expect(
        offenders,
        isEmpty,
        reason: 'a durable v1 layer took a forbidden agent/network/seam import:\n'
            '${offenders.join('\n')}',
      );
    });

    test('the scan is non-vacuous: it would CATCH a forbidden import (self-test)',
        () {
      // Prove the matcher actually fires on a forbidden line, so the green above
      // means "clean", not "the matcher is broken".
      const leak = "import 'package:http/http.dart' as http;";
      final hit = _forbidden.any(leak.contains);
      expect(hit, isTrue,
          reason: 'the forbidden-import matcher must catch a real http import');

      // And a legit durable import must NOT trip it.
      const legit = "import 'package:cloud_firestore/cloud_firestore.dart';";
      expect(_forbidden.any(legit.contains), isFalse,
          reason: 'cloud_firestore is a legit durable persistence dep');
    });
  });

  // D-06 / ADR-014 trust boundary (Plan 15-03): lib/curriculum/ drives offline
  // selection AND the on-device star, so it must be STRICTER than the rest of the
  // spine — it carries only tier/competency/exercise ids and the pure walk, never
  // a cloud/Firebase/network/render/persistence import (the star is computed
  // on-device, never granted off a server response; the parser stays render-free
  // and unit-testable from a Map). `lib/data` legitimately persists via
  // cloud_firestore/drift/flutter; lib/curriculum must NOT — hence a separate,
  // tighter ban list scoped to lib/curriculum only.
  group('D-06 — lib/curriculum carries zero cloud-AI/Firebase/network/render import',
      () {
    // The stricter ban: agent + network (above) PLUS cloud/Firebase/render/
    // persistence. A `flutter/services` rootBundle read belongs in the loader
    // (lib/data), not in the pure parser, so `package:flutter/` is forbidden here.
    const curriculumForbidden = <String>[
      ..._forbidden,
      'cloud_firestore',
      'firebase_core',
      'firebase_auth',
      'firebase',
      'package:flutter/', // no Flutter render/services import in the pure layer
      'package:drift/',
      'drift.dart',
      'riverpod', // selection providers live in lib/tutor, not the pure layer
    ];

    test('every lib/curriculum .dart file imports no forbidden package', () {
      final offenders = <String>[];
      var scanned = 0;

      for (final file in _dartFiles('lib/curriculum')) {
        scanned++;
        for (final line in _codeLines(file)) {
          if (!line.contains('import')) continue;
          for (final bad in curriculumForbidden) {
            if (line.contains(bad)) {
              offenders.add('${file.path}: $bad  ->  ${line.trim()}');
            }
          }
        }
      }

      expect(scanned, greaterThan(0),
          reason: 'no lib/curriculum .dart files were scanned — check the glob');
      expect(
        offenders,
        isEmpty,
        reason: 'a lib/curriculum file took a forbidden cloud/Firebase/network/'
            'render import (the on-device star/selection layer must stay pure):\n'
            '${offenders.join('\n')}',
      );
    });

    test('the curriculum scan is non-vacuous (self-test)', () {
      // A Firebase import MUST trip the curriculum ban.
      const leak = "import 'package:cloud_firestore/cloud_firestore.dart';";
      expect(curriculumForbidden.any(leak.contains), isTrue,
          reason: 'the curriculum ban must catch a real Firebase import');
      // A Flutter render import MUST trip it too.
      const render = "import 'package:flutter/material.dart';";
      expect(curriculumForbidden.any(render.contains), isTrue,
          reason: 'the curriculum ban must catch a Flutter render import');
      // A legit pure-Dart sibling import must NOT trip it.
      const legit = "import 'curriculum_graph.dart';";
      expect(curriculumForbidden.any(legit.contains), isFalse,
          reason: 'a pure-Dart sibling import is legit in lib/curriculum');
    });
  });
}
