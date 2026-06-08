import 'package:flutter_test/flutter_test.dart';
import 'package:qalam/core/scoring/tolerances.dart';

/// SC#4 — tolerances are DATA, not code.
///
/// The `normal` preset is a LOCKED behavior-preserving anchor (RESEARCH A5): it
/// must equal today's hardcoded scorer constants pulled from
/// geometric_stroke_scorer.dart (minRawPoints==10, resampleN==32,
/// maxCurvature==0.25) so the data refactor does not shift alif's scoring.
///
/// `loose` is more permissive than `normal`; `strict` is stricter. Unknown or
/// absent presets fall back to `normal` (pure value parsing — never throws).
void main() {
  group('Tolerances.fromJson — presets', () {
    test('normal preset equals today\'s hardcoded constants (LOCKED — A5)', () {
      final t = Tolerances.fromJson(const {'preset': 'normal'});
      expect(t.minRawPoints, equals(10));
      expect(t.resampleN, equals(32));
      expect(t.maxCurvature, equals(0.25));
    });

    test('loose is more permissive than normal (higher maxCurvature)', () {
      final loose = Tolerances.fromJson(const {'preset': 'loose'});
      final normal = Tolerances.fromJson(const {'preset': 'normal'});
      // A higher maxCurvature ceiling lets a more-bowed stroke still pass.
      expect(loose.maxCurvature, greaterThan(normal.maxCurvature));
    });

    test('strict is stricter than normal (lower maxCurvature)', () {
      final strict = Tolerances.fromJson(const {'preset': 'strict'});
      final normal = Tolerances.fromJson(const {'preset': 'normal'});
      expect(strict.maxCurvature, lessThan(normal.maxCurvature));
    });

    test('an unknown preset falls back to normal (no throw)', () {
      final t = Tolerances.fromJson(const {'preset': 'banana'});
      expect(t.minRawPoints, equals(10));
      expect(t.resampleN, equals(32));
      expect(t.maxCurvature, equals(0.25));
    });

    test('an absent preset falls back to normal (no throw)', () {
      final t = Tolerances.fromJson(const {});
      expect(t.minRawPoints, equals(10));
      expect(t.resampleN, equals(32));
      expect(t.maxCurvature, equals(0.25));
    });
  });

  group('Tolerances.fromJson — numeric overrides', () {
    test('an override replaces one knob, leaving the others at preset value', () {
      final t = Tolerances.fromJson(const {
        'preset': 'normal',
        'overrides': {'maxCurvature': 0.30},
      });
      expect(t.maxCurvature, equals(0.30));
      // Other knobs remain at normal.
      expect(t.minRawPoints, equals(10));
      expect(t.resampleN, equals(32));
    });

    test('overrides apply on top of an unknown preset (normal base)', () {
      final t = Tolerances.fromJson(const {
        'preset': 'banana',
        'overrides': {'minRawPoints': 6},
      });
      expect(t.minRawPoints, equals(6));
      expect(t.maxCurvature, equals(0.25));
      expect(t.resampleN, equals(32));
    });
  });
}
