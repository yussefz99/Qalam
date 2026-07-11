// Phase 18 — per-criterion EMA (D-15), Dart↔Python PARITY — Wave-0 RED contract.
//
// INTENTIONALLY RED at Wave 0: imports the not-yet-built `updateEma` from
// package:qalam/core/scoring/criterion_ema.dart. Plan 18-03 writes the pure-Dart
// function and turns this green with ZERO test edits.
//
// EMA (D-15, RESEARCH §Code Examples): "recent attempts count more" —
//   updateEma(prior, passed, alpha) = alpha * (passed ? 1 : 0) + (1 - alpha) * prior
//
// PARITY CONTRACT: the fixture rows below are BYTE-IDENTICAL to
// server/tests/test_criterion_ema.py so on-device (within-session) and the nightly
// Python compile agree on the same math. If either side drifts, one of the two
// tests goes red. alpha is PROVISIONAL (signed:false) — the fixtures pin the
// FORMULA, not the mother's final α.

import 'package:flutter_test/flutter_test.dart';

// RED: this library does not exist yet (Plan 18-03 writes it).
import 'package:qalam/core/scoring/criterion_ema.dart';

/// One parity fixture row: (prior, passed, alpha) → expected. BYTE-IDENTICAL to the
/// `FIXTURES` list in server/tests/test_criterion_ema.py.
class _EmaRow {
  const _EmaRow(this.prior, this.passed, this.alpha, this.expected);
  final double prior;
  final bool passed;
  final double alpha;
  final double expected;
}

const _fixtures = <_EmaRow>[
  _EmaRow(0.5, true, 0.4, 0.7), // a pass pulls the estimate up
  _EmaRow(0.5, false, 0.4, 0.3), // a fail pulls it down
  _EmaRow(0.7, true, 0.4, 0.82), // step 2 of the chain
  _EmaRow(0.82, false, 0.4, 0.492), // step 3 of the chain
  _EmaRow(0.0, true, 0.5, 0.5), // cold-floor + a pass at α=0.5
  _EmaRow(1.0, false, 0.5, 0.5), // hot-ceiling + a fail at α=0.5
];

void main() {
  group('per-criterion EMA — fixed fixture table (Dart↔Python parity, D-15)', () {
    for (final row in _fixtures) {
      test('updateEma(${row.prior}, ${row.passed}, ${row.alpha}) == ${row.expected}',
          () {
        expect(
          updateEma(row.prior, row.passed, row.alpha),
          closeTo(row.expected, 1e-9),
          reason: 'the EMA formula must match the Python mirror byte-for-byte',
        );
      });
    }

    test('a 3-step pass/pass/fail chain lands on 0.492 (α=0.4, cold start 0.5)', () {
      const alpha = 0.4;
      var ema = 0.5; // cold-start neutral prior
      ema = updateEma(ema, true, alpha); // → 0.7
      ema = updateEma(ema, true, alpha); // → 0.82
      ema = updateEma(ema, false, alpha); // → 0.492
      expect(ema, closeTo(0.492, 1e-9));
    });
  });
}
