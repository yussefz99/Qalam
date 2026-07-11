"""Phase 18 — per-criterion EMA (D-15), Python↔Dart PARITY — Wave-0 RED contract.

INTENTIONALLY RED at Wave 0: imports the not-yet-built `update_ema` from
`app.criterion_ema`. Plan 18-03 writes the pure function (byte-identical logic to
`lib/core/scoring/criterion_ema.dart`) and turns this green with ZERO test edits.

EMA (D-15): "recent attempts count more" —
    update_ema(prior, passed, alpha) = alpha * (1 if passed else 0) + (1 - alpha) * prior

PARITY CONTRACT: the FIXTURES table below is BYTE-IDENTICAL to the `_fixtures` list
in test/core/scoring/criterion_ema_test.dart (same prior / outcome / alpha /
expected). If either side drifts, one of the two tests goes red — that is how the
on-device (within-session) EMA and the nightly Python compile are held in lockstep.
Model-free / network-free: a plain `code` check that gates every PR.
"""

from __future__ import annotations

import pytest

pytestmark = pytest.mark.code

# RED: this module does not exist yet (Plan 18-03 writes app/criterion_ema.py).
from app.criterion_ema import update_ema

# (prior, passed, alpha, expected) — BYTE-IDENTICAL to the Dart `_fixtures`.
FIXTURES = [
    (0.5, True, 0.4, 0.7),      # a pass pulls the estimate up
    (0.5, False, 0.4, 0.3),     # a fail pulls it down
    (0.7, True, 0.4, 0.82),     # step 2 of the chain
    (0.82, False, 0.4, 0.492),  # step 3 of the chain
    (0.0, True, 0.5, 0.5),      # cold-floor + a pass at alpha=0.5
    (1.0, False, 0.5, 0.5),     # hot-ceiling + a fail at alpha=0.5
]


@pytest.mark.parametrize("prior,passed,alpha,expected", FIXTURES)
def test_update_ema_matches_dart_fixture(prior, passed, alpha, expected):
    """Each fixture row must yield the IDENTICAL result the Dart mirror asserts."""
    assert update_ema(prior, passed, alpha) == pytest.approx(expected, abs=1e-9)


def test_three_step_chain_lands_on_0_492():
    """A pass/pass/fail chain at alpha=0.4 from cold-start 0.5 → 0.492 (Dart parity)."""
    alpha = 0.4
    ema = 0.5  # cold-start neutral prior
    ema = update_ema(ema, True, alpha)   # -> 0.7
    ema = update_ema(ema, True, alpha)   # -> 0.82
    ema = update_ema(ema, False, alpha)  # -> 0.492
    assert ema == pytest.approx(0.492, abs=1e-9)
