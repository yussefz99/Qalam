import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/reference_path.dart';
import 'package:qalam/models/letter.dart';

/// S1-04 — one source of truth.
///
/// `ReferencePath.resolve` must be a deterministic identity over authored
/// centerline strokes: the dotted guide, the stroke-order animation, and the
/// geometric scorer all resolve through it, so the path they see is identical
/// by construction. These tests pin that contract.
void main() {
  // A correct alif: one open top→bottom centerline (NOT a closed outline).
  StrokeSpec alifCenterline() => const StrokeSpec(
        order: 1,
        label: 'downstroke',
        type: 'line',
        direction: 'topToBottom',
        points: [
          [0.5, 0.0],
          [0.5, 0.5],
          [0.5, 1.0],
        ],
      );

  group('ReferencePath.resolve — identity over authored centerlines', () {
    test('returns the authored points unchanged (identity, no derivation)', () {
      final strokes = [alifCenterline()];

      final resolved = ReferencePath.resolve(strokes);

      // Exactly the authored centerline points the guide/animation/scorer use —
      // no outline-derivation step has touched them.
      expect(
        resolved,
        equals([
          [
            [0.5, 0.0],
            [0.5, 0.5],
            [0.5, 1.0],
          ],
        ]),
      );
    });

    test('is deterministic — same input yields equal results', () {
      final strokes = [alifCenterline()];

      final first = ReferencePath.resolve(strokes);
      final second = ReferencePath.resolve(strokes);

      // Guide == animation == scorer: every consumer gets the same path.
      expect(first, equals(second));
    });

    test('preserves stroke order (by `order`) and per-stroke point order', () {
      // Two-stroke letter authored OUT of draw order in the list. resolve must
      // emit them in `order` ascending, each stroke's points left untouched.
      const body = StrokeSpec(
        order: 1,
        label: 'body',
        type: 'curve',
        direction: 'rightToLeft',
        points: [
          [0.9, 0.4],
          [0.5, 0.5],
          [0.1, 0.4],
        ],
      );
      const dot = StrokeSpec(
        order: 2,
        label: 'dot',
        type: 'dot',
        direction: 'tap',
        points: [
          [0.5, 0.8],
        ],
      );

      final resolved = ReferencePath.resolve([dot, body]); // reversed on input

      expect(
        resolved,
        equals([
          [
            [0.9, 0.4],
            [0.5, 0.5],
            [0.1, 0.4],
          ],
          [
            [0.5, 0.8],
          ],
        ]),
      );
    });

    test('deep-copies points so callers cannot mutate the source strokes', () {
      final strokes = [alifCenterline()];

      final resolved = ReferencePath.resolve(strokes);
      resolved[0][0][0] = 999.0; // mutate the returned data

      // A second resolve is unaffected — the source StrokeSpec was not aliased.
      expect(ReferencePath.resolve(strokes)[0][0][0], equals(0.5));
    });
  });
}
