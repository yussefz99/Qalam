"""Per-criterion EMA — the nightly-compile child-model estimate (Phase 18, D-15).

One exponential moving average per ``<letter>/<criterion>`` id. It answers a single
question: "how is this child doing on THIS geometric criterion, weighting recent
attempts more than old ones?" (RESEARCH §Code Examples).

PARITY (D-15): the formula + the provisional alpha are BYTE-IDENTICAL to
``lib/core/scoring/criterion_ema.dart`` (``updateEma``). The nightly Python compile
and the on-device within-session estimate MUST agree — a drift on either side goes
red against the shared fixtures in ``server/tests/test_criterion_ema.py`` and
``test/core/scoring/criterion_ema_test.dart``.

MODEL-FREE + OFFLINE: this module calls NO model and needs NO auth / Firebase. It is
pure arithmetic — a plain ``code`` check that gates every PR.
"""

from __future__ import annotations

# Provisional EMA constants (signed:false — mother-signed at 18-11, D-15/A4).
# BYTE-IDENTICAL to the kEma* constants in lib/core/scoring/criterion_ema.dart.
ALPHA = 0.4  # smoothing weight: "recent attempts count more" (mirror kEmaAlpha)
HI = 0.75    # at/above -> strength, once MIN evidence exists (mirror kEmaStrengthHi)
LO = 0.35    # at/below -> struggle, once MIN evidence exists (mirror kEmaStruggleLo)
MIN = 2      # min attempts before classifiable (mirror kEmaMinAttempts, Pitfall 4)

# Classification labels — mirror the Dart CriterionClass enum names.
STRENGTH = "strength"
STRUGGLE = "struggle"
UNKNOWN = "unknown"


def update_ema(prior: float, passed: bool, alpha: float) -> float:
    """The pure per-criterion EMA update (D-15).

    ``ema = alpha * (1.0 if passed else 0.0) + (1.0 - alpha) * prior``

    ``prior`` is the last stored EMA for this ``<letter>/<criterion>`` (cold-start
    with a neutral 0.5). ``passed`` is the fresh attempt outcome. ``alpha`` is the
    smoothing weight (callers pass :data:`ALPHA`). Pure + total — never raises.

    BYTE-IDENTICAL to ``updateEma`` in ``lib/core/scoring/criterion_ema.dart``.
    """
    return alpha * (1.0 if passed else 0.0) + (1.0 - alpha) * prior


def classify_criterion(ema: float, attempts: int) -> str:
    """Classify a criterion's current ``ema`` given how many ``attempts`` fed it.

    Sparse-data gate first (Pitfall 4): under :data:`MIN` attempts the criterion is
    :data:`UNKNOWN` regardless of the EMA — sparse data is never a false struggle
    (or a false strength). With enough evidence, an EMA at/above :data:`HI` is a
    strength, at/below :data:`LO` a struggle, and anything between the bands stays
    :data:`UNKNOWN`. Mirrors ``classifyCriterion`` in criterion_ema.dart.
    """
    if attempts < MIN:
        return UNKNOWN
    if ema >= HI:
        return STRENGTH
    if ema <= LO:
        return STRUGGLE
    return UNKNOWN
