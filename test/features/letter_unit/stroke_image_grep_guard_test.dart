// stroke_image_grep_guard — the client half of GROUND-04 / D-A (Plan 17-07).
//
// The Phase-17.1 "render the child's handwriting to a PNG and let the AI judge
// pass/fail" path is RETIRED (D-A: the deterministic on-device scorer owns the
// verdict). This source-scan guard makes the retirement regression-PROOF from the
// client side: it fails the build if `strokeImage` (the field / param / callback /
// pending stash) or `_renderStrokesToBase64Png` (the render) — or the `aiJudge`
// deferral seam — ever reappear in code under lib/. No rendered image of a child's
// handwriting can leave the device again without turning this red first.
//
// Comment lines are stripped BEFORE scanning (grep-gate hygiene) so a doc-comment
// that NAMES a retired token to explain its absence cannot self-trip the guard —
// mirrors the `grep -v "^.*//"` acceptance idiom, applied per-line.
//
// Pure Dart: file read + scan only. No Firebase, no network, no model — runs in a
// plain `flutter test`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `.dart` file under `lib/`, recursively (the whole client payload +
/// render surface — the acceptance scans lib/ for `strokeImage`, not just the two
/// cutover widgets).
Iterable<File> _libDartFiles() sync* {
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

/// [source] with whole-line `//` / `///` comment lines removed, so a doc mention
/// of a retired token cannot false-trip the token scan.
String _stripCommentLines(String source) => source
    .split('\n')
    .where((l) {
      final t = l.trimLeft();
      return !t.startsWith('//') && !t.startsWith('///');
    })
    .join('\n');

void main() {
  group('GROUND-04 / D-A — the strokeImage render path is gone from lib/', () {
    test('`strokeImage` appears in NO code line under lib/ (comments stripped)',
        () {
      final offenders = <String>[];
      for (final file in _libDartFiles()) {
        final code = _stripCommentLines(file.readAsStringSync());
        if (code.contains('strokeImage')) offenders.add(file.path);
      }
      expect(
        offenders,
        isEmpty,
        reason: 'strokeImage (field/param/callback/onStrokeImage) must not appear '
            'in lib/ code — the client stopped sending it (D-A / GROUND-04). '
            'Offending files: $offenders',
      );
    });

    test('the render + deferral seams (`_renderStrokesToBase64Png`, `aiJudge`, '
        '`_pendingStrokeImage`) appear in NO code line under lib/', () {
      const forbidden = <String>[
        '_renderStrokesToBase64Png',
        'aiJudge',
        '_pendingStrokeImage',
      ];
      final offenders = <String>[];
      for (final file in _libDartFiles()) {
        final code = _stripCommentLines(file.readAsStringSync());
        for (final token in forbidden) {
          if (code.contains(token)) offenders.add('${file.path}: $token');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'the retired render/deferral seams must be gone from lib/ code. '
            'Offending: $offenders',
      );
    });

    test('sanity: the scan reads real source — the SURVIVING transport '
        '`onStrokeDiff` is still present in the write surface', () {
      // Guards against a scan that silently matched nothing (e.g. a bad path): the
      // surviving derived-diff transport onStrokeDiff must still be found, proving
      // the scan reaches the touched widget's real code.
      final ws = File('lib/features/letter_unit/widgets/write_surface.dart')
          .readAsStringSync();
      expect(
        ws.contains('onStrokeDiff'),
        isTrue,
        reason: 'onStrokeDiff is the surviving transport — the scan must see it',
      );
    });
  });
}
