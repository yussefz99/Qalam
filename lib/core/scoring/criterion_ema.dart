/// Pure Dart, no dart:ui, no Flutter/Firebase imports.
///
/// Per-criterion EMA — the within-session child-model estimate (Phase 18, D-15).
///
/// One exponential moving average per `<letter>/<criterion>` id. It answers a
/// single question: "how is this child doing on THIS geometric criterion, weighting
/// recent attempts more than old ones?" (RESEARCH §Code Examples).
///
/// PARITY (D-15): the formula + the provisional α live BYTE-IDENTICALLY in
/// `server/app/criterion_ema.py` (`update_ema`). The on-device within-session
/// estimate and the nightly Python compile MUST agree — a drift on either side goes
/// red against the shared fixtures in `test/core/scoring/criterion_ema_test.dart`
/// and `server/tests/test_criterion_ema.py`.
///
/// This file is a durable-layer citizen under `lib/core` (scanned by
/// `durable_layers_no_agent_imports_test`): NO agent / network / Firebase / render
/// import may enter it.
library;

/// Provisional EMA weight (signed:false — mother-signed at 18-11, D-15/A4).
///
/// "Recent attempts count more": each new attempt pulls the estimate `kEmaAlpha`
/// of the way toward the fresh outcome (1.0 pass / 0.0 fail) and keeps
/// `1 - kEmaAlpha` of the prior. This is the PROVISIONAL α that pins the FORMULA,
/// not the mother's final smoothing choice. Mirrors `ALPHA` in criterion_ema.py.
const double kEmaAlpha = 0.4;

/// Provisional strength threshold (signed:false — mother-signed at 18-11).
///
/// An EMA at/above this — once the criterion has enough evidence
/// ([kEmaMinAttempts]) — reads as a STRENGTH. Mirrors `HI` in criterion_ema.py.
const double kEmaStrengthHi = 0.75;

/// Provisional struggle threshold (signed:false — mother-signed at 18-11).
///
/// An EMA at/below this — once the criterion has enough evidence
/// ([kEmaMinAttempts]) — reads as a STRUGGLE. Mirrors `LO` in criterion_ema.py.
const double kEmaStruggleLo = 0.35;

/// Provisional minimum attempts before a criterion is classifiable (signed:false).
///
/// Mirrors the `_deriveStruggleTags` ">= 2 occurrences" idiom
/// (`tutor_facts_builder.dart`): a one-off slip is not a struggle, and a single
/// lucky pass is not a strength. Below this count the criterion is [
/// CriterionClass.unknown] — sparse data is NEVER a false struggle (RESEARCH
/// Pitfall 4). Mirrors `MIN` in criterion_ema.py.
const int kEmaMinAttempts = 2;

/// How a criterion's EMA reads once it has enough evidence.
///
/// [unknown] is the sparse-data floor — neither a strength nor a struggle until the
/// criterion has been seen at least [kEmaMinAttempts] times (Pitfall 4).
enum CriterionClass { strength, struggle, unknown }

/// The pure per-criterion EMA update (D-15).
///
/// `ema = alpha * (passed ? 1.0 : 0.0) + (1.0 - alpha) * prior`
///
/// [prior] is the last stored EMA for this `<letter>/<criterion>` (cold-start with
/// a neutral 0.5). [passed] is the fresh attempt outcome. [alpha] is the smoothing
/// weight (default caller passes [kEmaAlpha]). Pure + total — never throws.
///
/// BYTE-IDENTICAL to `update_ema` in `server/app/criterion_ema.py`.
double updateEma(double prior, bool passed, double alpha) =>
    alpha * (passed ? 1.0 : 0.0) + (1.0 - alpha) * prior;

/// Classify a criterion's current [ema] given how many [attempts] fed it.
///
/// Sparse-data gate first (Pitfall 4): under [kEmaMinAttempts] the criterion is
/// [CriterionClass.unknown] regardless of the EMA — sparse data is never a false
/// struggle (or a false strength). With enough evidence, an EMA at/above
/// [kEmaStrengthHi] is a strength, at/below [kEmaStruggleLo] a struggle, and
/// anything between the bands is still [CriterionClass.unknown] (mid-mastery, not
/// yet decided). Mirrors `classify_criterion` in criterion_ema.py.
CriterionClass classifyCriterion(double ema, int attempts) {
  if (attempts < kEmaMinAttempts) return CriterionClass.unknown;
  if (ema >= kEmaStrengthHi) return CriterionClass.strength;
  if (ema <= kEmaStruggleLo) return CriterionClass.struggle;
  return CriterionClass.unknown;
}
